#!/bin/bash
#
# unregister all product from a given collection
#
. "`dirname "$0"`/lib_common.sh"

COLLECTIONID="$1"

[ -z "$COLLECTIONID" ] && error "Missing the mandatory collection." 

CLIST="`$MNG eoxs_id_list -r "$COLLECTIONID" | grep -v DatasetSeries | sed -e "s/^\s*//" | cut -f 1 -d ' ' `"
$MNG eoxs_dataset_deregister $CLIST
