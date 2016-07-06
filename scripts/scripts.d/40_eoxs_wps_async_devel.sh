#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: EOxServer - Asynchronous WPS backend - development mode installation
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2016 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing WPS-backend in the development mode."

# Path to the EOxServer development directory tree:
WPS_ASYNC_BACKEND_DEV_PATH="${WPS_ASYNC_BACKEND_DEV_PATH:-/usr/local/eox-wps-async/}"

# STEP 1: INSTALL DEPENDENCIES
# NOTE: EOxServer and its dependencies are required!
#yum --assumeyes install python-ipaddr python-setuptools

# STEP 2: INSTALL DAMATS
# Install EOxServer in the development mode.
pushd .
cd $WPS_ASYNC_BACKEND_DEV_PATH
python ./setup.py develop
popd
