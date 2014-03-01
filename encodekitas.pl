#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use WWW::Mechanize;

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
      #we also want the coordinates of the kita
      #so we go on the following page
      $mech->get( "http://suche.kita.ulm.de/homepage/einrichtung_allgemein.php?id=$currentkita{'id'}" ) or die "Could not access http://suche.kita.ulm.de/homepage/einrichtung_allgemein.php?id$currentkita{'id'}";
      #and then the first link is something like http://www.stadtplan.ulm.de/stadtplan/cgi-bin/cityguide.pl?action=show&lang=de&size=1076&mapper=2&zoom=100&mapX=3573150&mapY=5363969
      #looky-look what have we here: mapX=3573150 mapY=5363969
      if ($mech->content() =~m/mapX=(\d+)&mapY=(\d+)/){
        #now $1 is easting and $2 is northing
        #convert from gauss krueger zone 3 coordinates into WGS84 Coordinate Reference System
        my @coords=split(/\s+/, `echo $1 $2 | cs2cs -f "%.8f" +init=epsg:31467 +to +init=epsg:4326`);
        #note that this is not a stupid security hole, since $1 and $2 contain integers, because of my regexp
        ($currentkita{'wgs84-east'}, $currentkita{'wgs84-north'}, @_)=@coords;
        #okay, here's a small perl hack, split gives us strings, but we want doubles
        $currentkita{'wgs84-east'} +=0;
        $currentkita{'wgs84-north'} +=0;
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
