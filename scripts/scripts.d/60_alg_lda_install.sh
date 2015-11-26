#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: algorightm installation
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing LDA algorithm ... "

[ -z "$CONTRIB_DIR" ] && error "Missing the required CONTRIB_DIR variable!"
[ -z "$DAMATS_ALGS_ROOT" ] && error "Missing the required DAMATS_ALGS_ROOT variable!"
[ -z "$DAMATS_USER" ] && error "Missing the required DAMATS_USER variable!"
[ -z "$DAMATS_GROUP" ] && error "Missing the required DAMATS_GROUP variable!"

SRC_FILE="$CONTRIB_DIR/damats-LDA-alg-EOX.zip"
ALG_DIR="$DAMATS_ALGS_ROOT/lda/"

# create algorithms' directory if missing
mkdir -vp "$DAMATS_ALGS_ROOT"
chmod 0755 "$DAMATS_ALGS_ROOT"

# remove the algorithm's directory if existing
[ ! -d "$ALG_DIR" ] || rm -vfR "$ALG_DIR"

# create the algorithm's directory if missing
mkdir -vp "$ALG_DIR"
chmod 0755 "$ALG_DIR"

pushd .
info "Unpacking $SRC_FILE ..."
cd "$ALG_DIR"
unzip "$SRC_FILE"

popd

info "Installing dependencies ..."
yum --assumeyes install scikit-learn scipy python-pillow python-matplotlib
#yum --assumeyes install gcc-c++
#pip install -U scikit-learn
