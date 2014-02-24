#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use WWW::Mechanize;

use URI;
use Web::Scraper;

my $kitainstancescraper = scraper {
	process "a.list-link08", mapurl => '@href';
};
	#process "tr:contains('Stand')"

my $url="http://suche.kita.ulm.de/homepage/liste.php?Traeger=null&Stadtteil=null&Strasse=null&PLZ=null&Altersstufe=null&Angebotsform=null&Paedagogisches_Konzept=null&Integrationsangebot=null&Freie_Plaetze=Nein&Submit=Suchen"; # urls must be absolute
my $mech = WWW::Mechanize->new();
$mech->get( $url ) or die "Could not access website";
my @kitas; #list of all kitas

foreach my $kitablock (split('<td>__________________________________________________________</td>',$mech->content())) { #each kitablock contains one kite
  my %currentkita;
  foreach my $infoblock (split('tr>', $kitablock)){ #each infoblock contains some kind of info like email or telefon
    if ($infoblock =~m/color:#0E4276;font-weight:bold;" href="einrichtung_allgemein\.php\?id=(\d+)">(.*)<\/a><\/b><\/td>/){ #line with id and name
      $currentkita{'id'}=$1;
      $currentkita{'name'}=$2;
      #download kita metadata from the following URI:
      my $res = $kitainstancescraper->scrape(URI->new("http://suche.kita.ulm.de/homepage/einrichtung.php?id=$currentkita{'id'}"));
      #match the coordinates from the map URL, if the coordinates are present there
      if ($res->{mapurl} =~m/mapX=(\d+)&mapY=(\d+)/){
        #now $1 is easting and $2 is northing
        #convert from gauss krueger zone 3 coordinates into WGS84 Coordinate Reference System
        my @coords=split(/\s+/, `echo $1 $2 | cs2cs -f "%.8f" +proj=tmerc +lat_0=0 +lon_0=9 +k=1.000000 +x_0=3500000 +y_0=0 +ellps=bessel +datum=potsdam +units=m +no_defs`);
        #note that this is not a stupid security hole, since $1 and $2 contain integers, because of my regexp
        ($currentkita{'wgs84-east'}, $currentkita{'wgs84-north'}, @_)=@coords;
        #okay, here's a small perl hack, split gives us strings, but we want doubles
        $currentkita{'wgs84-east'} +=0;
        $currentkita{'wgs84-north'} +=0;
      } else {
        #mapurl does not contain coordinates. Could parse groupID and objectID here, or the address
      }
    }
    if ($infoblock =~m/<td>Telefon: (.*)<\/td>/){ #line with telefon
      $currentkita{'telefon'}=$1;
    }
    if ($infoblock =~m/<td>E-Mail: (.*)<\/td>/){ #line with mail
      $currentkita{'mail'}=$1;
    }

    #Plätze unter 3 Jahren
    if ($infoblock =~m/Freie Pl.tze unter 3 Jahre:.*<img src='inc\/amp_green\.gif' title='gr.n'>/s){ #line with unter 3 jahren state
      $currentkita{'under3'}="true";
    }
    if ($infoblock =~m/Freie Pl.tze unter 3 Jahre:.*<img src='inc\/amp_rot\.gif' title='rot'>/s){ #line with unter 3 jahren state
      $currentkita{'under3'}="false";
      #wieso mache ich auch den negativtest?
      #damit ich redundanz habe und so das ergebnis auf plausibilität prüfen kann
    }

    #Plätze über 3 Jahren
    if ($infoblock =~m/Freie Pl.tze .ber 3 Jahre:.*<img src='inc\/amp_green\.gif' title='gr.n'>/s){ #line with unter 3 jahren state
      $currentkita{'over3'}="true";
    }
    if ($infoblock =~m/Freie Pl.tze .ber 3 Jahre:.*<img src='inc\/amp_rot\.gif' title='rot'>/s){ #line with unter 3 jahren state
      $currentkita{'over3'}="false";
    }
  }

  push(@kitas,\%currentkita) if (%currentkita);
  #push the data only, if it is nontrivial
  #i.e., if a kita was found in the current kitablock
}

my $json = encode_json(\@kitas); #convert the list of all kitas to json
open KITAFILE, "+>kita_final.json", or die "Could not open kitadata.json";
print KITAFILE "$json \n";
