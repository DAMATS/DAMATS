#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: DAMATS client installation
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh
. `dirname $0`/../lib_apache.sh

info "Configuring DAMATS client ..."

[ -z "$DAMATS_SERVER_HOME" ] && error "Missing the required DAMATS_SERVER_HOME variable!"
[ -z "$DAMATS_CLIENT_HOME" ] && error "Missing the required DAMATS_CLIENT_HOME variable!"
[ -z "$DAMATS_USER" ] && error "Missing the required DAMATS_USER variable!"


BASIC_AUTH_PASSWD_FILE="/etc/httpd/authn/damats-passwords"
DAMATS_SERVER_URL="/`basename "$DAMATS_SERVER_HOME"`"
DAMATS_CLIENT_URL="/`basename "$DAMATS_CLIENT_HOME"`"
CONFIG_JSON="${DAMATS_CLIENT_HOME}/config.json"

#-------------------------------------------------------------------------------
# Client configuration.

# define JQ filters
_F1=".mapConfig.products=[]"
_F2=".damats.url=\"${DAMATS_SERVER_URL}\""
FILTERS="$_F1|$_F2"

sudo -u "$DAMATS_USER" cp "$CONFIG_JSON" "$CONFIG_JSON~" && \
sudo -u "$DAMATS_USER" jq "$FILTERS" >"$CONFIG_JSON" <"$CONFIG_JSON~" && \
sudo -u "$DAMATS_USER" rm -f "$CONFIG_JSON~"

#-------------------------------------------------------------------------------
# Integration with the Apache web server

info "Configuring Apache web server"

# locate proper configuration file (see also apache configuration)
{
    locate_apache_conf 80
    locate_apache_conf 443
} | while read CONF
do
    { ex "$CONF" || /bin/true ; } <<END
/EOXC00_BEGIN/,/EOXC00_END/de
/^[ 	]*<\/VirtualHost>/i
    # EOXC00_BEGIN - DAMATS Client - Do not edit or remove this line!

    # DAMATS Client
    Alias $DAMATS_CLIENT_URL "$DAMATS_CLIENT_HOME"
    <Directory "$DAMATS_CLIENT_HOME">
        Options -MultiViews +FollowSymLinks
        #Require all granted
        AuthType basic
        AuthName "DAMATS server login"
        AuthBasicProvider file
        AuthUserFile "$BASIC_AUTH_PASSWD_FILE"
        Require valid-user
    </Directory>

    # EOXC00_END - DAMATS Client - Do not edit or remove this line!
.
wq
END
done

#-------------------------------------------------------------------------------
# Restart Apache web server.

sudo systemctl restart httpd.service
sudo systemctl status httpd.service
