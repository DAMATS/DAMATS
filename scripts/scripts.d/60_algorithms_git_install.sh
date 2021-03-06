#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: DAMATS Alogorithms - installation from the GIT repository
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

# NOTE: provate GIT repository -> pulls must be done manually!

info "Installing DAMATS algorithms from the GIT repository."

[ -z "$DAMATS_REPO_ROOT" ] && error "Missing the required DAMATS_REPO_ROOT variable!"

# Path to the EOxServer development directory tree:
ALGS_GIT_PATH="${ALGS_GIT_PATH:-$DAMATS_REPO_ROOT/damats-alg}"
ALGS_GIT_BRANCH="eox_final"

# STEP 1: INSTALL DEPENDENCIES
# NOTE: EOxServer and its dependencies are required!
yum --assumeyes install scikit-learn scipy python-pillow python-matplotlib numpy Cython

# STEP 2: CLONE GIT REPO - skippend - needs to be done manually
#if [ ! -d "$ALGS_GIT_PATH" ]
#then
#    pushd .
#        cd $DAMATS_REPO_ROOT
#        git clone  ...
#    popd
#fi

# STEP 3: INSTALL PACKAGE
# Install DAMATS algorithms in the development mode.
pushd .
cd $ALGS_GIT_PATH
PACKAGE="DAMATS-Algorithms"
[ -z "`pip freeze | grep "^$PACKAGE==" `" ] || pip uninstall -y "$PACKAGE"
[ ! -d build/ ] || rm -fvR build/
[ ! -d dist/ ] || rm -fvR dist/
#git fetch
#git checkout $ALGS_GIT_BRANCH
#git pull
python ./setup.py install 
popd
