#!/bin/bash
#
# generate external overviews
#
. "`dirname "$0"`/lib_common.sh"

# gdaladdo options
GAOTP="--config COMPRESS_OVERVIEW DEFLATE --config PREDICTOR_OVERVIEW 2"

IMG="$1"
[ -n "$IMG" -a -f "$IMG" ] || error "Missing mandatory image file."
[ -f "$IMG.ovr" ] && rm -fv "$IMG.ovr"

info "$IMG"
gdaladdo -ro -r average $GAOT "$IMG" `get_gdaladdo_levels.py "$IMG" 32 8`
