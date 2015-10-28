#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: Java 8 installation.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing Java8 JRE ..."

yum --assumeyes install java-1.8.0-openjdk-headless
