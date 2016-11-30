#!/usr/bin/env python
#
# extract S2 tile geometry from the AWS tile-info
#

import re
import sys
import json
from osgeo import osr

RE_EPSG_URI=re.compile(r"urn:ogc:def:crs:EPSG:[^:]*:(\d+)")

def sr_from_srid(srid):
    """ Get instance of the osr.SpatialReference. """
    sref = osr.SpatialReference()
    sref.ImportFromEPSG(srid)
    return sref

SR_WGS84 = sr_from_srid(4326)

def extract_footprint(data):
    """ Extract geo-json polygon geometry. """
    crs = data['crs']
    if crs['type'] == 'name':
        srid = int(RE_EPSG_URI.match(crs['properties']['name']).group(1))
    else:
        raise ValueError("crs")

    if data['type'] != "Polygon":
        raise ValueError("Unexpected geometry type %r." % data['type'])

    ct_ = osr.CoordinateTransformation(sr_from_srid(srid), SR_WGS84)

    return [[
        ct_.TransformPoint(float(x), float(y))[:2]
        for x, y in loop
    ] for loop in data['coordinates']]

def polygon_to_wkt(coords):
    """ Convert polygon coordinates to WKT. """
    return "POLYGON(%s)" % (",".join(
        "(%s)" % ",".join("%.14g %.14g" % (x, y) for x, y in loop)
        for loop in coords
    ))

if __name__ == "__main__":
    try:
        tile_info_file = sys.argv[1]
    except IndexError:
        print >>sys.stderr, "ERROR: Not enough input arguments."
        sys.exit(1)
    with open(tile_info_file) as fobj:
        tile_info = json.load(fobj)
    coords = extract_footprint(tile_info['tileDataGeometry'])
    print polygon_to_wkt(coords)
