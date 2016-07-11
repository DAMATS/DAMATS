#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: Load range-types to the EOxServer instance.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2016 EOX IT Services GmbH


. `dirname $0`/../lib_logging.sh

info "Loading available EOxServer range-types ... "

[ -z "$RANGE_TYPE_DIR" ] && error "Missing the required RANGE_TYPE_DIR variable!"
[ -z "$DAMATS_SERVER_HOME" ] && error "Missing the required DAMATS_SERVER_HOME variable!"
[ -z "$DAMATS_USER" ] && error "Missing the required DAMATS_USER variable!"

INSTANCE="`basename "$DAMATS_SERVER_HOME"`"
INSTROOT="`dirname "$DAMATS_SERVER_HOME"`"
MNGCMD="${INSTROOT}/${INSTANCE}/manage.py"

{ ls "$RANGE_TYPE_DIR/"*.json 2>/dev/null || true ; } | while read RT
do
    info "Loading range-types from $RT ..."
    sudo -u "$DAMATS_USER" python "$MNGCMD" eoxs_rangetype_load -i "$RT"
done
