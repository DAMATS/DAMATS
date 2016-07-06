#!/bin/sh
#-------------------------------------------------------------------------------
#
# Project: DAMATS
# Purpose: DAMATS installation script - common shared defaults
# Authors: Martin Paces <martin.paces@eox.at>
#
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies of this Software or works derived from this Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-------------------------------------------------------------------------------

# version
VERSION_FILE="`dirname $0`/../version.txt"
export DAMATS_VERSION="`cat "$VERSION_FILE"`"

# flag indicating whether the installation script shall enable the firewall
export ENABLE_FIREWALL=${ENABLE_FIREWALL:-YES}

# public hostname (or IP number) under which the ODA-OS shall be accessable
# NOTE: Critical parameter! Be sure you set it to the proper value.
export DAMATS_HOSTNAME=${DAMATS_HOSTNAME:-$HOSTNAME}

# root directory of the DAMATS - by default set to '/srv/damats'
export DAMATS_ROOT=${DAMATS_ROOT:-/srv/damats}

# directory where the log files shall be placed - by default set to '/var/log/damats'
export DAMATS_LOGDIR=${DAMATS_LOGDIR:-/var/log/damats}

# directory of the short-term data storage - by default set to '/tmp/damats'
export DAMATS_TMPDIR=${DAMATS_TMPDIR:-/tmp/damats}

# directory where the PosgreSQL DB stores the files
export DAMATS_PGDATA_DIR=${DAMATS_PGDATA_DIR:-/srv/pgdata}

# directory of the long-term data storage - by default set to '/srv/eodata'
export DAMATS_DATADIR=${DAMATS_DATADIR:-/srv/eodata}

# names of the ODA-OS user and group - by default set to 'damats:damats'
export DAMATS_GROUP=${DAMATS_GROUP:-damats}
export DAMATS_USER=${DAMATS_USER:-damats}

# location of the DAMATS Server home directory
export DAMATS_SERVER_HOME=${DAMATS_SERVER_HOME:-$DAMATS_ROOT/eoxs}
# WSGI daemon - number of processes to be used by the DAMATS EOxServer instances
export EOXS_WSGI_NPROC=${EOXS_WSGI_NPROC:-4}
# WSGI daemon - process group to be used by the DAMATS EOxServer instances
export EOXS_WSGI_PROCESS_GROUP=${EOXS_WSGI_PROCESS_GROUP:-damats_eoxs_ows}

# location of the DAMATS Client home directory
export DAMATS_CLIENT_HOME=${DAMATS_CLIENT_HOME:-$DAMATS_ROOT/eoxc}

# location of the installed DAMATS algorightms
export DAMATS_ALGS_ROOT=${DAMATS_ALGS_ROOT:-$DAMATS_ROOT/algs}

# WPS configuration - permanent storage location
export DAMATS_WPS_ROOT=${DAMATS_WPS_ROOT:-/srv/wps}
# WPS configuration - temporary workspace location
export DAMATS_WPS_TEMP=${DAMATS_WPS_TEMP:-$DAMATS_WPS_ROOT/temp}
# WPS configuration - permanent storage location
export DAMATS_WPS_PERM=${DAMATS_WPS_PERM:-$DAMATS_WPS_ROOT/perm}
# WPS configuration - permanent storage - public URL path
export DAMATS_WPS_URL=${DAMATS_WPS_URL:-/wps}
