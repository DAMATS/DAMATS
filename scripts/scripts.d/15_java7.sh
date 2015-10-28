#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: Java 7 installation.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing Java7 JRE ..."

yum --assumeyes install java-1.7.0-openjdk-headless
