#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: EOX server installation - WSGI daemon
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh
. `dirname $0`/../lib_apache.sh

info "Configuring WSGI daemon to be used by the EOxServer instances."

[ -z "$DAMATS_USER" ] && error "Missing the required DAMATS_USER variable!"
[ -z "$DAMATS_GROUP" ] && error "Missing the required DAMATS_GROUP variable!"

# number of EOxServer daemon processes
EOXS_WSGI_NPROC=${EOXS_WSGI_NPROC:-4}
# process group label
EOXS_WSGI_PROCESS_GROUP=${EOXS_WSGI_PROCESS_GROUP:-eoxs_ows}
# path to import script (http://modwsgi.readthedocs.io/en/develop/configuration-directives/WSGIImportScript.html)
#EOXS_WSGI_IMPORT_SCRIPT=${EOXS_WSGI_IMPORT_SCRIPT:-wsgi.py}
#TODO add: WSGIRestrictEmbedded On

CONF="`locate_wsgi_daemon $EOXS_WSGI_PROCESS_GROUP`"
[ -n "$CONF" ] || CONF="/etc/httpd/conf.d/wsgi.conf"
[ -f "$CONF" ] || cat >> "/etc/httpd/conf.d/wsgi.conf" <<END

# WSGI process daemon used by the EOxServer
END
ex "$CONF" <<END
g/^[ 	]*WSGIDaemonProcess[ 	]*$EOXS_WSGI_PROCESS_GROUP/d
\$a
WSGIDaemonProcess $EOXS_WSGI_PROCESS_GROUP processes=$EOXS_WSGI_NPROC threads=1 user=$DAMATS_USER group=$DAMATS_GROUP maximum-requests=50000
.
wq
END

[ -z "$EOXS_WSGI_IMPORT_SCRIPT" ] || ex "$CONF" <<END
g/^[ 	]*WSGIImportScript.*process-group=$EOXS_WSGI_PROCESS_GROUP/d
\$a
WSGIImportScript $EOXS_WSGI_IMPORT_SCRIPT process-group=$EOXS_WSGI_PROCESS_GROUP application-group=%{GLOBAL}
.
wq
END

#systemctl restart httpd.service
