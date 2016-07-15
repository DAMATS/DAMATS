#!/bin/bash -ex
#
# footprint extraction
#
. "`dirname "$0"`/lib_common.sh"

MASK="`mktemp --suffix="_mask.tif"`"
trap "rm -fv '$MASK' 1>&2" EXIT

SIMPL="${3:-1e2}"
SEGM="${4:-2.5e4}"

extract_mask.py "$1" "$MASK" "$2" ALL_VALID  1>&2 && extract_mask_footprint.py "$MASK" 255 | geom_simplify.py - "$SIMPL" | geom_segmentize.py - "$SEGM" | geom_to_wgs84.py - WKT | cut -f 2- -d ';' | tr '\n' ' ' | sed -e 's/\s\+$//'
