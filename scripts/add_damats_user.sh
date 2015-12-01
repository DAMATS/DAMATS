#!/bin/sh
#-------------------------------------------------------------------------------
#
# Project: DAMATS
# Purpose: CLI interface to add a new DAMATS user.
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

. ./lib_common.sh
. ./lib_logging.sh

[ -z "$DAMATS_USER" ] && error "Missing the required DAMATS_USER variable!"
[ -z "$DAMATS_SERVER_HOME" ] && error "Missing the required DAMATS_SERVER_HOME variable!"
INSTANCE="`basename "$DAMATS_SERVER_HOME"`"
INSTROOT="`dirname "$DAMATS_SERVER_HOME"`"
MNGCMD="${INSTROOT}/${INSTANCE}/manage.py"
BASIC_AUTH_PASSWD_FILE="/etc/httpd/authn/damats-passwords"
USERNAME="$1"

[ $# -lt 1 -o -z "$USERNAME" ] && {
    info "Usage: $0 <username>"
    error "Missing the madatory username argument."
}

if [ -n "`sudo cat "$BASIC_AUTH_PASSWD_FILE" | cut -f 1 -d ':' | grep "$USERNAME"`" ]
then
    info "Changing password on an existing DAMATS user '$USERNAME' ..."
else
    info "Adding new DAMATS user '$USERNAME' ..."
fi
set -x
htpasswd "$BASIC_AUTH_PASSWD_FILE" "$USERNAME"
set +x

# add user among the authorised users
#TODO: make a proper command
sudo -u "$DAMATS_USER" python "$MNGCMD" shell <<END
from damats.webapp.models import User
try:
  User.objects.get(identifier="$USERNAME")
except User.DoesNotExist:
  User.objects.create(identifier="$USERNAME")

print User.objects.all()
END
