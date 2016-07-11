#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: EOxServer - Asynchronous WPS backend - GIT installation 
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2016 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing WPS-backend from the GIT repository."

[ -z "$DAMATS_REPO_ROOT" ] && error "Missing the required DAMATS_REPO_ROOT variable!"

# Path to the EOxServer development directory tree:
WPS_ASYNC_BACKEND_GIT_PATH="${WPS_ASYNC_BACKEND_GIT_PATH:-$DAMATS_REPO_ROOT/WPS-Backend}"
WPS_ASYNC_BACKEND_GIT_BRANCH="master"

# STEP 1: INSTALL DEPENDENCIES
# NOTE: EOxServer and its dependencies are required!
yum --assumeyes install python-ipaddr python-setuptools

# STEP 2: CLONE GIT REPO
if [ ! -d "$WPS_ASYNC_BACKEND_GIT_PATH" ]
then
    pushd .
        cd $DAMATS_REPO_ROOT
        git clone https://github.com/DAMATS/WPS-Backend.git
    popd
fi

# STEP 3: INSTALL
PACKAGE="eoxs-wps-async"
[ -z "`pip freeze | grep "^$PACKAGE==" `" ] || pip uninstall -y "$PACKAGE"
pushd .
cd $WPS_ASYNC_BACKEND_GIT_PATH
[ ! -d build/ ] || rm -fvR build/
[ ! -d dist/ ] || rm -fvR dist/
git fetch
git checkout $WPS_ASYNC_BACKEND_GIT_BRANCH
git pull
python ./setup.py install 
popd
