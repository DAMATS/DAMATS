#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: EOxServer instance development configuration customisation
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh
. `dirname $0`/../lib_apache.sh

info "Configuring EOxServer instance (developepment mods)... "

[ -z "$DAMATS_SERVER_HOME" ] && error "Missing the required DAMATS_SERVER_HOME variable!"
[ -z "$DAMATS_WPS_PERM_DIR" ] && error "Missing the required DAMATS_WPS_PERM_DIR variable!"
[ -z "$DAMATS_WPS_URL" ] && error "Missing the required DAMATS_WPS_URL variable!"

HOSTNAME="$DAMATS_HOSTNAME"
INSTANCE="`basename "$DAMATS_SERVER_HOME"`"
INSTROOT="`dirname "$DAMATS_SERVER_HOME"`"

BASIC_AUTH_PASSWD_FILE="/etc/httpd/authn/damats-passwords"
SETTINGS="${INSTROOT}/${INSTANCE}/${INSTANCE}/settings.py"
URLS="${INSTROOT}/${INSTANCE}/${INSTANCE}/urls.py"
INSTSTAT_URL="/${INSTANCE}_static" # DO NOT USE THE TRAILING SLASH!!!
INSTSTAT_DIR="${INSTROOT}/${INSTANCE}/${INSTANCE}/static"

EOXSCONF="${INSTROOT}/${INSTANCE}/${INSTANCE}/conf/eoxserver.conf"

# process group label
EOXS_WSGI_PROCESS_GROUP=${EOXS_WSGI_PROCESS_GROUP:-eoxs_ows}

#-------------------------------------------------------------------------------
# STEP 4: APACHE WEB SERVER INTEGRATION

info "Mapping EOxServer instance '${INSTANCE}' to URL path '${INSTANCE}' ..."

# locate proper configuration file (see also apache configuration)
{
    locate_apache_conf 80
    locate_apache_conf 443
} | while read CONF
do
    { ex "$CONF" || /bin/true ; } <<END
/EOXS00_BEGIN/,/EOXS00_END/de
/^[ 	]*<\/VirtualHost>/i
    # EOXS00_BEGIN - EOxServer instance - Do not edit or remove this line!

    # EOxServer instance configured by the automatic installation script

    <Location "/">
        Require all granted
        #AuthType basic
        #AuthName "DAMATS server login"
        #AuthBasicProvider file
        #AuthUserFile "$BASIC_AUTH_PASSWD_FILE"
        #Require valid-user
    </Location>

    # static content
    Alias "$INSTSTAT_URL" "$INSTSTAT_DIR"
    <Directory "$INSTSTAT_DIR">
        #EnableSendfile off
        Options -MultiViews +FollowSymLinks
        Header set Access-Control-Allow-Origin "*"
    </Directory>

    # WPS static content
    Alias "$DAMATS_WPS_URL" "$DAMATS_WPS_PERM_DIR"
    <Directory "$DAMATS_WPS_PERM_DIR">
        #EnableSendfile off
        Options -MultiViews +FollowSymLinks +Indexes
        Header set Access-Control-Allow-Origin "*"
    </Directory>

    # WSGI service endpoint
    WSGIScriptAlias "/$INSTANCE" "${INSTROOT}/${INSTANCE}/${INSTANCE}/wsgi.py"
    <Directory "${INSTROOT}/${INSTANCE}/${INSTANCE}">
        <Files "wsgi.py">
            WSGIProcessGroup $EOXS_WSGI_PROCESS_GROUP
            WSGIApplicationGroup %{GLOBAL}
            Header set Access-Control-Allow-Origin "*"
            Header set Access-Control-Allow-Headers Content-Type
            Header set Access-Control-Allow-Methods "GET, PUT, POST, DELETE, OPTIONS"
        </Files>
    </Directory>

    # EOXS00_END - EOxServer instance - Do not edit or remove this line!
.
wq
END
done

#-------------------------------------------------------------------------------
# STEP 5: EOXSERVER CONFIGURATION

# set-up logging
sudo -u "$DAMATS_USER" ex "$SETTINGS" <<END
g/^DEBUG\s*=/s#\(^DEBUG\s*=\s*\).*#\1True#
.
wq
END

#-------------------------------------------------------------------------------
# STEP 6: DAMATS SPECIFIC SETTINGS

# set the service url and log-file
#/^[	 ]*logging_filename[	 ]*=/s;\(^[	 ]*logging_filename[	 ]*=\).*;\1${EOXSLOG};
sudo -u "$DAMATS_USER" ex "$EOXSCONF" <<END
/\[damats\]/
g/^[\#\s]*default_user\s*=/d
a
default_user=test_user
.
wq
END

#-------------------------------------------------------------------------------
# STEP 8: FINAL WEB SERVER RESTART
systemctl restart httpd.service
systemctl status httpd.service
