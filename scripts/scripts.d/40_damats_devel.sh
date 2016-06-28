#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: DAMATS extention of the EOxServer - development mode installation
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing DAMATS server in the development mode."

# Path to the EOxServer development directory tree:
DAMATS_DEV_PATH="${DAMATS_DEV_PATH:-/usr/local/damats}"


# STEP 1: INSTALL DEPENDENCIES
# NOTE: EOxServer and its dependencies are required!
yum --assumeyes install python-ipaddr python-setuptools

# STEP 2: INSTALL DAMATS
# Install EOxServer in the development mode.
pushd .
cd $DAMATS_DEV_PATH
python ./setup.py develop
popd

