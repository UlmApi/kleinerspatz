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
    if ($infoblock =~m/color:#0E4276;font-weight:bold;" href="einrichtung_allgemein\.php\?id=(\d+)">(.*)<\/a><\/b><\/td>/){ #line with id
      $currentkita{'id'}=$1;
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

my $json = encode_json({kitas => \@kitas}); #convert the list of all kitas to json
print "$json \n";
