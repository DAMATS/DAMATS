#!/bin/bash
#
# register Landsat OLI product to EOxServer
#
. "`dirname "$0"`/lib_common.sh"

BASE_DIR="`expand $1`"
COLLECTION="$2"
PRODUCTID="`basename $1`"
RT="LandsatOLI:radiance:uint16"
MIN=8667,7915,6603,5763,4315,4370,4711,4943,17046,16123
MAX=16165,15480,14822,15053,26237,19555,15316,5130,24658,22387

info "$BASE_DIR"

if [ -n "`$MNG eoxs_id_list "$PRODUCTID" `" ]
then
    #$MNG eoxs_dataset_deregister "$PRODUCTID"
    error "Product "$PRODUCTID" is already registered."
    exit 1
fi

B1="`ls "${BASE_DIR}"/*_B1.{TIF,tif} 2>/dev/null | tail -n 1`"
B2="`ls "${BASE_DIR}"/*_B2.{TIF,tif} 2>/dev/null | tail -n 1`"
B3="`ls "${BASE_DIR}"/*_B3.{TIF,tif} 2>/dev/null | tail -n 1`"
B4="`ls "${BASE_DIR}"/*_B4.{TIF,tif} 2>/dev/null | tail -n 1`"
B5="`ls "${BASE_DIR}"/*_B5.{TIF,tif} 2>/dev/null | tail -n 1`"
B6="`ls "${BASE_DIR}"/*_B6.{TIF,tif} 2>/dev/null | tail -n 1`"
B7="`ls "${BASE_DIR}"/*_B7.{TIF,tif} 2>/dev/null | tail -n 1`"
B9="`ls "${BASE_DIR}"/*_B9.{TIF,tif} 2>/dev/null | tail -n 1`"
VRT="${BASE_DIR}/${PRODUCTID}.vrt"

# check the inputs
[ -d "$BASE_DIR" ] || error "Not a landsat product! Passed path must be a directory! BASE_DIR=$BASE_DIR"
[ -f "$B1" ] || error "Not a landsat product! Cannot locate band #1 image! B1=$B1"
[ -f "$B2" ] || error "Not a landsat product! Cannot locate band #2 image! B2=$B2"
[ -f "$B3" ] || error "Not a landsat product! Cannot locate band #3 image! B3=$B3"
[ -f "$B4" ] || error "Not a landsat product! Cannot locate band #4 image! B4=$B4"
[ -f "$B5" ] || error "Not a landsat product! Cannot locate band #5 image! B5=$B5"
[ -f "$B6" ] || error "Not a landsat product! Cannot locate band #6 image! B6=$B6"
[ -f "$B7" ] || error "Not a landsat product! Cannot locate band #7 image! B7=$B7"
[ -f "$B9" ] || error "Not a landsat product! Cannot locate band #9 image! B9=$B9"
[ -f "$VRT" ] && rm -fv "$VRT"

# merge bands to a virtual dataset
info "building VRT ... "
[ -f "$VRT" ] && rm -fv "$VRT"
gdalbuildvrt "$VRT" -separate "$B1" "$B2" "$B3" "$B4" "$B5" "$B6" "$B7" "$B9"

FTP="${BASE_DIR}/${PRODUCTID}.footprint"
#[ -f "$FTP" ] && rm -fv "$FTP"
[ ! -f "$FTP" ] && { footprint.sh "$VRT" 0 > "$FTP" || rm -fv "$FTP" ; }
FOOTPRINT="`cat "$FTP"`"
START="`landsat_date.py ${PRODUCTID:9:4} ${PRODUCTID:13:3}`"
STOP="$START"

[ -z "$FOOTPRINT" ] && { error "Failed to extract footprint!" ; exit 1 ; }
$MNG eoxs_dataset_register -r "$RT" -i "$PRODUCTID" -d "$VRT" \
    --begin-time="$START" --end-time="$STOP" \
	${COLLECTION:+--collection} $COLLECTION -f "$FOOTPRINT" && \
$MNG wms_options_set "$PRODUCTID" -r 4 -g 3 -b 2 --min "$MIN" --max "$MAX"
