#
# Load all the Landsat product found.
#
. "`dirname "$0"`/lib_common.sh"

# 1 rangetypes
# NOTE: rangetypes are loaded by the installer
#for F in "$BASE"/Landsat{MSS,TM,ETM,OLI_TIRS}_rangetype.json ; do $MNG eoxs_rangetype_load < $F ; done

# 2 collections
for C in LandsatMSS LandsatTM LandsatETM LandsatOLI ; do $MNG eoxs_collection_create -i "$C" ; done

# 3 products
DATA_BASE="/srv/EOData/Landsat_Damats/"
find $DATA_BASE -type d -name LM\* | while read D ; do register_landsat_mss_product_merged.sh $D LandsatMSS ; done
find $DATA_BASE -type d -name LT\* | grep -v crop | while read D ; do register_landsat_tm_product_merged.sh $D LandsatTM ; done
find $DATA_BASE -type d -name LE\* | while read D ; do register_landsat_etm_product_merged.sh $D LandsatETM ; done
find $DATA_BASE -type d -name LC\* | while read D ; do register_landsat_oli_tirs_product_merged.sh $D LandsatOLI ; done
find $DATA_BASE -type d -name LO\* | while read D ; do register_landsat_oli_product_merged.sh $D LandsatOLI ; done
