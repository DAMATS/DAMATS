#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: PIP Python package mamager installation.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing PIP Python package manager ..."

apt-get --assume-yes install python-pip python-pip-whl
