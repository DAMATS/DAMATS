#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: EOX server installation - from a GIT repository
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing EOxServer from GIT repository."

[ -z "$DAMATS_REPO_ROOT" ] && error "Missing the required DAMATS_REPO_ROOT variable!"

# Path to the EOxServer development directory tree:
EOXS_GIT_PATH="${EOXS_GIT_PATH:-$DAMATS_REPO_ROOT/eoxserver}"
EOXS_GIT_BRANCH="0.4"


# STEP 1: INSTALL DEPENDENCIES
yum --assumeyes install python-dateutil python-lxml proj-epsg python-setuptools mapserver mapserver-python


# STEP 2: CLONE GIT REPO
if [ ! -d "$EOXS_GIT_PATH" ]
then
    pushd .
        cd $DAMATS_REPO_ROOT
        git clone https://github.com/EOxServer/eoxserver.git
    popd
fi

# STEP 2: INSTALL
PACKAGE="EOxServer"
[ -z "`pip freeze | grep "^$PACKAGE==" `" ] || pip uninstall -y "$PACKAGE"
pushd .
cd $EOXS_GIT_PATH
[ ! -d build/ ] || rm -fvR build/
[ ! -d dist/ ] || rm -fvR dist/
git fetch
git checkout $EOXS_GIT_BRANCH
git pull
python ./setup.py install 
popd
