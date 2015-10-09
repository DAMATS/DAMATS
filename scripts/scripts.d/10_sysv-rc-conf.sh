#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: sysv-rc-conf installation.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing sysv-rc-conf ..."

apt-get --assume-yes install sysv-rc-conf

