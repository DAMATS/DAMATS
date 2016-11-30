#
# Load all the Landsat product found.
#
. "`dirname "$0"`/lib_common.sh"

# 1 rangetypes
# NOTE: rangetypes are loaded by the installer
#for F in "$BASE"/Landsat{MSS,TM,ETM,OLI_TIRS}_rangetype.json ; do $MNG eoxs_rangetype_load < $F ; done

# 2 collections
for C in S2L1C ; do $MNG eoxs_collection_create -i "$C" ; done

# 3 products
DATA_BASE="/srv/EOData/S2_test/"
find $DATA_BASE -name tileInfo.json -exec dirname {} \; | grep HH | while read D ; do register_s2_test_products.sh "$D" S2L1C ; done
#echo "/srv/EOData/S2_test/18/Q/YF/2016/1/23/0" | while read D ; do register_s2_test_products.sh "$D" S2L1C ; done
