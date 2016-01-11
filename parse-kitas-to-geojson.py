#!/usr/bin/python
# coding: utf-8

__author__ = 'Daniel'

import re
import subprocess

from bs4 import BeautifulSoup
import requests
import geojson


OUT_FILENAME = 'kitas.geojson'
KITAS_URL = r'http://suche.kita.ulm.de/homepage/liste.php?Traeger=null&Stadtteil=null&Strasse=null&PLZ=null&Altersstufe=null&Angebotsform=null&Paedagogisches_Konzept=null&Integrationsangebot=null&Freie_Plaetze=Nein&Submit=Suchen'
COORDS_URL = r'http://suche.kita.ulm.de/homepage/einrichtung_allgemein.php'


# Regular expressions
free_over3_regex  = re.compile(u'Freie Plätze über 3 Jahre:')
free_below3_regex = re.compile(u'Freie Plätze unter 3 Jahre:')
coords_regex      = re.compile(r'mapX=(\d+)&mapY=(\d+)')


def gkz_to_wgs(gk_x, gk_y):
    """Convert Gauss-Krueger coordinates to WGS coordinates."""
    p = subprocess.Popen('cs2cs -f %.8f" +init=epsg:31467 +to +init=epsg:4326'.split(' '),
                         stdout=subprocess.PIPE, stdin=subprocess.PIPE)
    out, err = p.communicate("%s %s" % (gk_x, gk_y))
    outputs = out.split('"')
    return float(outputs[0]), float(outputs[1])


# This one goes out to the Kita server which likes to sometimes throw 500 errors randomly.
def get_until_its_right(url):
    """Repeatedly try to get a response. Give up after a number of times."""
    for __ in range(5):
        response = requests.get(url)
        if response.ok:
            return response

    raise requests.HTTPError('Could not access ' + url + '.')


def main():
    response = get_until_its_right(KITAS_URL)
    soup = BeautifulSoup(response.text)
    # Each Kita is split in two tables, so merge the tables and get their tds.
    # Compare http://stackoverflow.com/questions/23286254/convert-list-to-a-list-of-tuples-python
    it = iter(soup('table'))
    kita_cells = [tables[0]('td') + tables[1]('td') for tables in zip(it, it)]

    feature_collection = geojson.FeatureCollection([])

    for cells in kita_cells:
        # Check if there is space for over/under three year olds.
        over3_cell = cells[4].parent.parent.find(text=free_over3_regex)
        over3_allowed = None
        if over3_cell:
            color = over3_cell.next.next.img.get('title')
            if color == u'grün':
                over3_allowed = True
            elif color == 'rot':
                over3_allowed = False

        under3_cell = cells[4].parent.parent.find(text=free_below3_regex)
        under3_allowed = None
        if under3_cell:
            color = under3_cell.next.next.img.get('title')
            if color == u'grün':
                under3_allowed = True
            elif color == 'rot':
                under3_allowed = False

        properties = {
            'address': cells[1].text,
            'telefon': cells[2].text[9:],
            'mail': cells[3].text[8:]
        }
        if over3_allowed is not None:
            properties['over3'] = over3_allowed
        if under3_allowed is not None:
            properties['under3'] = under3_allowed

        id = cells[1].a['href'][29:]

        # Scrape the coordinates of the Kita.
        response = get_until_its_right(COORDS_URL + '?id=' + id)
        coords = coords_regex.search(response.text)
        if not coords:
            print("No coordinates found for this KITA: " + str(properties))
            # No coordinates, no geojson!
            continue
        wgs_coords = gkz_to_wgs(coords.group(1), coords.group(2))

        feature = geojson.Feature(geometry=geojson.Point(wgs_coords),
                                  properties=properties,
                                  id=id)

        feature_collection.features.append(feature)

    with open(OUT_FILENAME, 'w') as f:
        f.write(geojson.dumps(feature_collection, sort_keys=True, indent=4, separators=(',', ': ')))


if __name__ == '__main__':
    main()
