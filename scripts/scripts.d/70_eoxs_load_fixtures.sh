#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: Load fixtures to the EOxServer instance.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH


. `dirname $0`/../lib_logging.sh

info "Loading provided EOxServer fixtures ... "

[ -z "$CONTRIB_DIR" ] && error "Missing the required CONTRIB_DIR variable!"
[ -z "$DAMATS_SERVER_HOME" ] && error "Missing the required DAMATS_SERVER_HOME variable!"
[ -z "$DAMATS_USER" ] && error "Missing the required DAMATS_USER variable!"
[ -z "$DAMATS_GROUP" ] && error "Missing the required DAMATS_GROUP variable!"

INSTANCE="`basename "$DAMATS_SERVER_HOME"`"
INSTROOT="`dirname "$DAMATS_SERVER_HOME"`"
FIXTURES_DIR_SRC="$CONTRIB_DIR/fixtures"
FIXTURES_DIR_DST="${INSTROOT}/${INSTANCE}/${INSTANCE}/data/fixtures"
MNGCMD="${INSTROOT}/${INSTANCE}/manage.py"

{ ls "$FIXTURES_DIR_SRC/"*.json || true ; } | while read SRC 
do
    FNAME="`basename "$SRC" .json`"
    info "Loading fixture '$FNAME' ..."
    DST="${FIXTURES_DIR_DST}/${FNAME}.json"
    cp "$SRC" "$DST"
    chown -v "$DAMATS_USER:$DAMATS_GROUP" "$DST"
    sudo -u "$DAMATS_USER" python "$MNGCMD" loaddata "$FNAME"
done
