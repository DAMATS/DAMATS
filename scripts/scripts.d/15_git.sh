#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: GIT installation.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2016 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing GIT ..."

yum --assumeyes install git

