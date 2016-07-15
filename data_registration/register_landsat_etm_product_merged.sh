#!/bin/bash
#
# register Landsat ETM product to EOxServer
#
. "`dirname "$0"`/lib_common.sh"

BASE_DIR="`expand $1`"
COLLECTION="$2"
PRODUCTID="`basename $1`"
RT="LandsatETM:radiance:uint8"
# histogram_to_range.py LE_merged.histogram 0.5 97
MIN=46,31,23,31,13,113,117,9
MAX=92,88,100,145,127,146,176,102

info "$BASE_DIR"

if [ -n "`$MNG eoxs_id_list "$PRODUCTID" `" ]
then
    error "Product "$PRODUCTID" is already registered."
    exit 1
fi

B1="`ls "${BASE_DIR}"/*_B1.{TIF,tif} 2>/dev/null | tail -n 1`"
B2="`ls "${BASE_DIR}"/*_B2.{TIF,tif} 2>/dev/null | tail -n 1`"
B3="`ls "${BASE_DIR}"/*_B3.{TIF,tif} 2>/dev/null | tail -n 1`"
B4="`ls "${BASE_DIR}"/*_B4.{TIF,tif} 2>/dev/null | tail -n 1`"
B5="`ls "${BASE_DIR}"/*_B5.{TIF,tif} 2>/dev/null | tail -n 1`"
B61="`ls "${BASE_DIR}"/*_B6_VCID_1.{TIF,tif} 2>/dev/null | tail -n 1`"
B62="`ls "${BASE_DIR}"/*_B6_VCID_2.{TIF,tif} 2>/dev/null | tail -n 1`"
B7="`ls "${BASE_DIR}"/*_B7.{TIF,tif} 2>/dev/null | tail -n 1`"
VRT="${BASE_DIR}/${PRODUCTID}.vrt"

# check the inputs
[ -d "$BASE_DIR" ] || error "Not a landsat product! Passed path must be a directory! BASE_DIR=$BASE_DIR"
[ -f "$B1" ] || error "Not a landsat product! Cannot locate band #1 image! B1=$B1"
[ -f "$B2" ] || error "Not a landsat product! Cannot locate band #2 image! B2=$B2"
[ -f "$B3" ] || error "Not a landsat product! Cannot locate band #3 image! B3=$B3"
[ -f "$B4" ] || error "Not a landsat product! Cannot locate band #4 image! B4=$B4"
[ -f "$B5" ] || error "Not a landsat product! Cannot locate band #5 image! B5=$B5"
[ -f "$B61" ] || error "Not a landsat product! Cannot locate band #6.1 image! B61=$B61"
[ -f "$B62" ] || error "Not a landsat product! Cannot locate band #6.2 image! B62=$B62"
[ -f "$B7" ] || error "Not a landsat product! Cannot locate band #7 image! B7=$B7"
[ -f "$VRT" ] && rm -fv "$VRT"

# merge bands to a virtual dataset
info "building VRT ... "
[ -f "$VRT" ] && rm -fv "$VRT"
gdalbuildvrt "$VRT" -separate "$B1" "$B2" "$B3" "$B4" "$B5" "$B61" "$B62" "$B7"

FTP="${BASE_DIR}/${PRODUCTID}.footprint"
#[ -f "$FTP" ] && rm -fv "$FTP"
[ ! -f "$FTP" ] && { footprint.sh "$VRT" 0 5e2 > "$FTP" || rm -fv "$FTP" ; }
FOOTPRINT="`cat "$FTP"`"

START="`landsat_date.py ${PRODUCTID:9:4} ${PRODUCTID:13:3}`"
STOP="$START"

[ -z "$FOOTPRINT" ] && { error "Failed to extract footprint!" ; exit 1 ; }
set -x
$MNG eoxs_dataset_register -r "$RT" -i "$PRODUCTID" -d "$VRT" \
    --begin-time="$START" --end-time="$STOP" \
	${COLLECTION:+--collection} $COLLECTION -f "$FOOTPRINT"
$MNG wms_options_set "$PRODUCTID" -r 3 -g 2 -b 1 --min "$MIN" --max "$MAX"
