#!/bin/sh
#
# unpack landsat package and repack imagery
#
. "`dirname "$0"`/lib_common.sh"

# gdal_translate options
GTOTP="-co TILED=YES -co COMPRESS=DEFLATE -co PREDICTOR=2"

EXT=".tar.gz"
PKG="$1"
[ -n "$PKG" -a -f "$PKG" ] || error "Missing mandatory package file." 

PRODUCTID="`basename "$PKG" $EXT`"
BASE_DIR="`dirname "$PKG"`"
BASE_DIR="`expand "$BASE_DIR"`"
DST_DIR="$BASE_DIR/$PRODUCTID"

info "$PKG"
info "$DST_DIR"

info "initial clean-up ..."
[ -d "$DST_DIR" ] && rm -fvR "$DST_DIR"
mkdir "$DST_DIR"

cd "$DST_DIR"

info "unpacking archive ..."
tar -xvzf "$PKG"

for IMG in *.TIF 
do
    info "$IMG compressing image ..." 
    TMP="${IMG}.tmp.tif"
    trap "rm -fv '$TMP'" EXIT
    gdal_translate $GTOTP "$IMG" "$TMP" && mv -vf "$TMP" "$IMG" || error "gdal_translate failed!"
    info "$IMG generating overviews ..." 
    generate_external_overviews.sh "$IMG"
done

