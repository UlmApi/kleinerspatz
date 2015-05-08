kleinerspatz
============
A project to view the KITAs of Ulm on a nice map.

Requirements (Front-end)
------------
The front-end uses:
 * the fancybox JS/CSS library, downloaded from here: `http://fancyapps.com/fancybox/#license`
 * LeafletJS
 * OpenStreetMap card material

Requirements (Parser)
------------
This version of the parser produces GeoJSON; the parser is written in python and works in both Python 2.7.x and Python 3 (tested with 2.7.6 and 3.4.2). It requires the python library geojson, which you can install using `pip install geojson`; it was tested with version 1.0.9. In addition, the parser uses proj (more precisely, `cs2cs`) to translate coordinate systems. On Debian, that means you'll need the `proj-bin` package.

Scraping
-------

This briefly explains the scraping process. Refer to the actual documentation in the source code for more information.

[This page](http://suche.kita.ulm.de/homepage/liste.php?Traeger=null&Stadtteil=null&Strasse=null&PLZ=null&Altersstufe=null&Angebotsform=null&Paedagogisches_Konzept=null&Integrationsangebot=null&Freie_Plaetze=Nein&Submit=Suchen) contains a list of all KITAs known to the city. Each KITA is described by two HTML tables; one contains a line (a bunch of `_` characters) and name, phone number, ID and address; the other contains whether the KITA has places for kids under 3 or over 3 (or both). The coordinates of the KITA are listed on that KITA's page (`einrichtung_allgemein.php?id=ID`), which requires the ID of the KITA. Therefore, we do not need to worry about resolving the addresses to coordinates, but we can grab them from that page.

The coordinates are in a specific format, called (3 Degree) Gauss-Krüger Zone coordinates; however, we need the more common latitude/longitude format to get valid GeoJSON (and more importantly, to be able to work with LeafletJS). To convert these coordinates, we currently use the program `cs2cs` contained in the Debian package `proj-bin`. This means that our solution currently doesn't run on Windows systems. At some later point we may implement the use of a library like pyproj, which is a set of python wrappers for the `proj` package.

Notes
--------

* There are some KITAs that lack coordinates; we may add a call to some address resolution service to determine the coordinates for these at some point. 
* There is (at least) one KITA that contains the wrong coordinates in the original source (the street exists both in Ulm and in Neu-Ulm).
