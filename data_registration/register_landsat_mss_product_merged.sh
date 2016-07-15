#!/bin/bash 
#
# register Landsat MSS product to EOxServer
#
. "`dirname "$0"`/lib_common.sh"

BASE_DIR="`expand $1`"
COLLECTION="$2"
PRODUCTID="`basename $1`"
RT="LandsatMSS:radiance:uint8"
#MIN=24,0,0,0,0,0,0
#MAX=164,90,90,255,255,255,255

info "$BASE_DIR"

if [ -n "`$MNG eoxs_id_list "$PRODUCTID" `" ]
then
    #$MNG eoxs_dataset_deregister "$PRODUCTID"
    error "Product "$PRODUCTID" is already registered."
    exit 1
fi

B4="`ls "${BASE_DIR}"/*_B4.{TIF,tif} 2>/dev/null | tail -n 1`"
B5="`ls "${BASE_DIR}"/*_B5.{TIF,tif} 2>/dev/null | tail -n 1`"
B6="`ls "${BASE_DIR}"/*_B6.{TIF,tif} 2>/dev/null | tail -n 1`"
B7="`ls "${BASE_DIR}"/*_B7.{TIF,tif} 2>/dev/null | tail -n 1`"
VRT="${BASE_DIR}/${PRODUCTID}.vrt"

# check the inputs 
[ -d "$BASE_DIR" ] || error "Not a landsat product! Passed path must be a directory! BASE_DIR=$BASE_DIR" 
[ -f "$B4" ] || error "Not a landsat product! Cannot locate band #4 image! B4=$B4" 
[ -f "$B5" ] || error "Not a landsat product! Cannot locate band #5 image! B5=$B5" 
[ -f "$B6" ] || error "Not a landsat product! Cannot locate band #6 image! B6=$B6" 
[ -f "$B7" ] || error "Not a landsat product! Cannot locate band #7 image! B7=$B7" 
[ -f "$VRT" ] && rm -fv "$VRT"

# merge bands to a virtual dataset
info "building VRT ... " 
[ -f "$VRT" ] && rm -fv "$VRT"
gdalbuildvrt "$VRT" -separate "$B4" "$B5" "$B6" "$B7"

FTP="${BASE_DIR}/${PRODUCTID}.footprint"
#[ -f "$FTP" ] && rm -fv "$FTP"
[ ! -f "$FTP" ] && { footprint.sh "$VRT" 0 1e4 > "$FTP" || rm -fv "$FTP" ; } 
FOOTPRINT="`cat "$FTP"`"

START="`landsat_date.py ${PRODUCTID:9:4} ${PRODUCTID:13:3}`"
STOP="$START"

[ -z "$FOOTPRINT" ] && { error "Failed to extract footprint!" ; exit 1 ; }
set -x 
$MNG eoxs_dataset_register -r "$RT" -i "$PRODUCTID" -d "$VRT" \
    --begin-time="$START" --end-time="$STOP" \
	${COLLECTION:+--collection} $COLLECTION -f "$FOOTPRINT"
$MNG wms_options_set "$PRODUCTID" -r 3 -g 2 -b 1 #--min "$MIN" --max "$MAX"
