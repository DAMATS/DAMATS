#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: DAMATS extention of the EOxServer - installation from GIT repository
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing DAMATS server from the GIT repository."

[ -z "$DAMATS_REPO_ROOT" ] && error "Missing the required DAMATS_REPO_ROOT variable!"

# Path to the EOxServer development directory tree:
DAMATS_GIT_PATH="${DAMATS_GIT_PATH:-$DAMATS_REPO_ROOT/DAMATS-Server}"
DAMATS_GIT_BRANCH="master"

# STEP 1: INSTALL DEPENDENCIES
# NOTE: EOxServer and its dependencies are required!
yum --assumeyes install python-ipaddr python-setuptools

# STEP 2: CLONE GIT REPO
if [ ! -d "$DAMATS_GIT_PATH" ]
then
    pushd .
        cd $DAMATS_REPO_ROOT
        git clone https://github.com/DAMATS/DAMATS-Server.git
    popd
fi

# STEP 3: INSTALL
PACKAGE="DAMATS"
[ -z "`pip freeze | grep "^$PACKAGE==" `" ] || pip uninstall -y "$PACKAGE"
pushd .
cd $DAMATS_GIT_PATH
[ ! -d build/ ] || rm -fvR build/
[ ! -d dist/ ] || rm -fvR dist/
git fetch
git checkout $DAMATS_GIT_BRANCH
git pull
python ./setup.py install 
popd
