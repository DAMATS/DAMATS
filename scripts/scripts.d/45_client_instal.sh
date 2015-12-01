#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: DAMATS client installation
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing DAMATS client ..."

[ -z "$CONTRIB_DIR" ] && error "Missing the required CONTRIB_DIR variable!"
[ -z "$DAMATS_CLIENT_HOME" ] && error "Missing the required DAMATS_CLIENT_HOME variable!"
[ -z "$DAMATS_USER" ] && error "Missing the required DAMATS_USER variable!"
[ -z "$DAMATS_GROUP" ] && error "Missing the required DAMATS_GROUP variable!"

TMPDIR='/tmp/eoxc'

# locate lates TGZ package
FNAME="`ls "$CONTRIB_DIR"/DAMATSClient-*.tar.gz | sort | tail -n 1`"

[ -n "$FNAME" -a -f "$FNAME" ] || { error "Failed to locate the installation package." ; exit 1 ; }

# installing the ODA-Client

# clean-up the previous installation if needed
[ -d "$DAMATS_CLIENT_HOME" ] && rm -fR "$DAMATS_CLIENT_HOME"
[ -d "$TMPDIR" ] && rm -fR "$TMPDIR"

# init
mkdir -p "$TMPDIR"

# unpack
tar -xzf "$FNAME" --directory="$TMPDIR"

# move to destination
ROOT="`find "$TMPDIR" -mindepth 1 -maxdepth 1 -name 'DAMATSClient*' -type d | head -n 1`"
mv -f "$ROOT" "$DAMATS_CLIENT_HOME"

# fix permisions
chown -R "$DAMATS_USER:$DAMATS_GROUP" "$DAMATS_CLIENT_HOME"

info "DAMATS Client installed to: $DAMATS_CLIENT_HOME"
