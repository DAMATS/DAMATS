#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: DAMATS extention of the EOxServer - development mode installation
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing DAMATS algorithms in the development mode."

# Path to the EOxServer development directory tree:
DAMATS_ALGS_DEV_PATH="${DAMATS_ALGS_DEV_PATH:-/usr/local/damats-alg}"

# STEP 1: INSTALL DEPENDENCIES
# NOTE: EOxServer and its dependencies are required!
yum --assumeyes install scikit-learn scipy python-pillow python-matplotlib numpy Cython

# STEP 2: INSTALL PACKAGE
# Install EOxServer in the development mode.
pushd .
cd $DAMATS_ALGS_DEV_PATH
PACKAGE="DAMATS-Algorithms"
[ -z "`pip freeze | grep "^$PACKAGE==" `" ] || pip uninstall -y "$PACKAGE"
[ ! -d build/ ] || rm -fvR build/
[ ! -d dist/ ] || rm -fvR dist/
python setup.py develop --uninstall
python ./setup.py develop
popd
