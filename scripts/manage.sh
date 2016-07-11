#!/bin/sh
#
# Django manage.py convenience wrapper. 
#

[ -f "`dirname $0`/user.conf" ] && . `dirname $0`/user.conf
. `dirname $0`/lib_common.sh

sudo -u "$DAMATS_USER" python "$DAMATS_SERVER_HOME/manage.py" $*
