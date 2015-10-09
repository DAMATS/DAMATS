#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: Java 7 installation.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing Java7 JRE ..."

apt-get --assume-yes install openjdk-7-jre-headless
