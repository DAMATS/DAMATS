#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: GeoTIFF tools and library installation.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing GeoTIFF library and tools ..."

apt-get --assume-yes install libgeotiff2 geotiff-bin
