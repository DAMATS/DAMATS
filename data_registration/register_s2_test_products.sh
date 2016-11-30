#!/bin/bash
#
# register Landsat OLI product to EOxServer
#
. "`dirname "$0"`/lib_common.sh"

BASE_DIR="`expand $1`"
COLLECTION="$2"
RT="S2:L1C:10m:uint16"
MIN="1,1,1,1"
MAX="2048,2048,2048,2048"

info "$BASE_DIR"

B02="`ls "${BASE_DIR}"/B02.jp2 2>/dev/null | tail -n 1`"
B03="`ls "${BASE_DIR}"/B03.jp2 2>/dev/null | tail -n 1`"
B04="`ls "${BASE_DIR}"/B04.jp2 2>/dev/null | tail -n 1`"
B08="`ls "${BASE_DIR}"/B08.jp2 2>/dev/null | tail -n 1`"
INFO=`ls "${BASE_DIR}"/tileInfo.json 2>/dev/null | tail -n 1`

# check the inputs
[ -d "$BASE_DIR" ] || error "Not a S2 L1C tile! Passed path must be a directory! BASE_DIR=$BASE_DIR"
[ -f "$B02" ] || error "Not a S2 L1C tile! Cannot locate band #2 image! B02=$B02"
[ -f "$B03" ] || error "Not a S2 L1C tile! Cannot locate band #3 image! B03=$B03"
[ -f "$B04" ] || error "Not a S2 L1C tile! Cannot locate band #4 image! B04=$B04"
[ -f "$B08" ] || error "Not a S2 L1C tile! Cannot locate band #8 image! B05=$B05"
[ -f "$INFO" ] || error "Not a S2 L1C tile! Cannot locate tile info JSON! INFO=$INFO"

TIMESTAMP=`jq -r .timestamp "$INFO"`
PRODUCT_NAME=`jq -r .productName "$INFO"`
UTM_ZONE="0`jq -r .utmZone "$INFO"`"
UTM_ZONE="${UTM_ZONE: -2}"
LAT_BAND=`jq -r .latitudeBand "$INFO"`
MGRS_SQUARE=`jq -r .gridSquare "$INFO"`
PRODUCTID="${PRODUCT_NAME:0:3}_${PRODUCT_NAME:13:3}_${PRODUCT_NAME:16:3}_${PRODUCT_NAME:25:15}_T$UTM_ZONE$LAT_BAND$MGRS_SQUARE"

echo $PRODUCTID
VRT="${BASE_DIR}/${PRODUCTID}.vrt"

# merge bands to a virtual dataset
info "building VRT ... "
[ -f "$VRT" ] && rm -fv "$VRT"
gdalbuildvrt "$VRT" -separate "$B02" "$B03" "$B04" "$B08"

START="$TIMESTAMP"
STOP="$START"
FOOTPRINT="`s2_tile_geomery.py "$INFO"`"

echo "START: $START"
echo "STOP: $STOP"
echo "FOOTPRINT: $FOOTPRINT"

[ -z "$FOOTPRINT" ] && { error "Failed to extract footprint!" ; exit 1 ; }
set -x
$MNG eoxs_dataset_register -r "$RT" -i "$PRODUCTID" -d "$VRT" \
    --begin-time="$START" --end-time="$STOP" \
	${COLLECTION:+--collection} $COLLECTION -f "$FOOTPRINT" && \
$MNG wms_options_set "$PRODUCTID" -r 3 -g 2 -b 1 --min "$MIN" --max "$MAX"
