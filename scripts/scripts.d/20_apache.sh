#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: Apache web server installation.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

# To enable HTTPS see https://help.ubuntu.com/14.04/serverguide/httpd.html

. `dirname $0`/../lib_logging.sh
. `dirname $0`/../lib_apache.sh

info "Installing Apache HTTP server ... "

# path to the apache configuration
CONF_DEFAULT="/etc/httpd/conf.d/damats.conf"
CONF_DEFAULT_SSL="/etc/httpd/conf.d/damats_ssl.conf"

# WSGI socket prefix
SOCKET_PREFIX="run/wsgi"
#======================================================================

# STEP 1:  INSTALL PACKAGES
yum --assumeyes install httpd mod_wsgi mod_ssl crypto-utils


# STEP 2: FIREWALL SETUP (OPTIONAL)
# We enable access to port 80 and 443 from anywhere
# and make the firewal chages permanent.
if [ "$ENABLE_FIREWALL" = "YES" ]
then
    for SERVICE in http https
    do
        sudo firewall-cmd --add-service=$SERVICE
        sudo firewall-cmd --permanent --add-service=$SERVICE
    done
fi

# STEP 3: SETUP THE SITE
#NOTE 1: Current setup does not support multiple virtual hosts.

# setup default unsecured site
CONF=`locate_apache_conf 80`
if [ -z "$CONF" ]
then
    CONF="$CONF_DEFAULT"
    echo "Default virtual host not located creting own one in: $CONF"
    cat >"$CONF" <<END
# default site generated by the automatic DAMATS installer
<VirtualHost _default_:80>
</VirtualHost>
END
else
    echo "Default virtual host located in: $CONF"
fi

## setup default secured site
#CONF=`locate_apache_conf 443`
#
## disable the default settings from the ssl.conf
#if [ "$CONF" == "/etc/httpd/conf.d/ssl.conf" ]
#then
#    echo "Disabling the default SSL configutation in: $CONF"
#    disable_virtual_host "$CONF"
#    CONF=
#fi
#
#if [ -z "$CONF" ]
#then
#    CONF="$CONF_DEFAULT_SSL"
#    echo "Default secured virtual host not located creting own one in: $CONF"
#    cat >"$CONF" <<END
## default site generated by the automatic EOxServer instance configuration
#<VirtualHost _default_:443>
#
#    # common SSL settings
#    ErrorLog logs/ssl_error_log
#    TransferLog logs/ssl_access_log
#    LogLevel warn
#    SSLEngine on
#    SSLProtocol all -SSLv2
#    SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW
#    SSLCertificateFile /etc/pki/tls/certs/localhost.crt
#    SSLCertificateKeyFile /etc/pki/tls/private/localhost.key
#
#</VirtualHost>
#END
#else
#    echo "Default secured virtual host located in: $CONF"
#fi

# check whether WSGI socket is set already - if not do so
CONF="`locate_wsgi_socket_prefix_conf`"
if [ -z "$CONF" ]
then # set socket prefix if not already set
    echo "WSGISocketPrefix is not configured."
#    echo "WSGISocketPrefix is set to: $SOCKET_PREFIX"
#    echo "WSGISocketPrefix $SOCKET_PREFIX" >> /etc/httpd/conf.d/wsgi.conf
else
    echo "WSGISocketPrefix set already:"
    grep -nH WSGISocketPrefix "$CONF"
fi

# STEP 4: START THE SERVICE

# enable start the httpd service
sudo systemctl enable httpd.service
sudo systemctl start httpd.service
sudo systemctl status httpd.service
