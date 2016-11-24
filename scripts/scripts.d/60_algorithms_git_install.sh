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
[ -z "$DAMATS_ALGS_ROOT" ] && error "Missing the required DAMATS_ALGS_ROOT variable!"
[ -z "$DAMATS_USER" ] && error "Missing the required DAMATS_USER variable!"
[ -z "$DAMATS_GROUP" ] && error "Missing the required DAMATS_GROUP variable!"

# Path to the EOxServer development directory tree:
ALGS_GIT_PATH="${ALGS_GIT_PATH:-$DAMATS_REPO_ROOT/damats-alg}"
ALGS_GIT_BRANCH="eox_ar"
ALGS_DIR="$DAMATS_ALGS_ROOT"

# STEP 1: INSTALL DEPENDENCIES
# NOTE: EOxServer and its dependencies are required!
yum --assumeyes install scikit-learn scipy python-pillow python-matplotlib

# STEP 2: CLONE GIT REPO
#if [ ! -d "$ALGS_GIT_PATH" ]
#then
#    pushd .
#        cd $DAMATS_REPO_ROOT
#        git clone 
#    popd
#fi

# STEP 3: COPY THE DIRECTORY

# remove the algorithm's directory if existing and create a new one
[ ! -d "$ALGS_DIR" ] || rm -vfR "$ALGS_DIR"
[ -d "$ALGS_DIR" ] || mkdir "$ALGS_DIR"

pushd .
cd "$ALGS_GIT_PATH"
#git fetch
git checkout $ALGS_GIT_BRANCH
#git pull
git archive HEAD | tar -x -C "$ALGS_DIR" 
popd

# fix the ownership and permissions
chown -R "$DAMATS_USER:$DAMATS_GROUP" "$ALGS_DIR"
