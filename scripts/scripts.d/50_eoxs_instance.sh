#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: EOxServer instance configuration
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh
. `dirname $0`/../lib_apache.sh

info "Configuring EOxServer instance ... "

# NOTE: Multiple EOxServer instances are not foreseen in DAMATS.

[ -z "$DAMATS_HOSTNAME" ] && error "Missing the required DAMATS_HOSTNAME variable!"
[ -z "$DAMATS_SERVER_HOME" ] && error "Missing the required DAMATS_SERVER_HOME variable!"
[ -z "$DAMATS_USER" ] && error "Missing the required DAMATS_USER variable!"
[ -z "$DAMATS_GROUP" ] && error "Missing the required DAMATS_GROUP variable!"
[ -z "$DAMATS_LOGDIR" ] && error "Missing the required DAMATS_LOGDIR variable!"
[ -z "$DAMATS_TMPDIR" ] && error "Missing the required DAMATS_TMPDIR variable!"

HOSTNAME="$DAMATS_HOSTNAME"
INSTANCE="`basename "$DAMATS_SERVER_HOME"`"
INSTROOT="`dirname "$DAMATS_SERVER_HOME"`"

BASIC_AUTH_PASSWD_FILE="/etc/httpd/authn/damats-passwords"
SETTINGS="${INSTROOT}/${INSTANCE}/${INSTANCE}/settings.py"
URLS="${INSTROOT}/${INSTANCE}/${INSTANCE}/urls.py"
FIXTURES_DIR="${INSTROOT}/${INSTANCE}/${INSTANCE}/data/fixtures"
INSTSTAT_URL="/${INSTANCE}_static" # DO NOT USE THE TRAILING SLASH!!!
INSTSTAT_DIR="${INSTROOT}/${INSTANCE}/${INSTANCE}/static"
WSGI="${INSTROOT}/${INSTANCE}/${INSTANCE}/wsgi.py"
MNGCMD="${INSTROOT}/${INSTANCE}/manage.py"

DBENGINE="django.contrib.gis.db.backends.postgis"
DBNAME="eoxs_${INSTANCE}"
DBUSER="eoxs_admin_${INSTANCE}"
DBPASSWD="${INSTANCE}_admin_eoxs_`head -c 24 < /dev/urandom | base64 | tr '/' '_'`"
DBHOST=""
DBPORT=""

PG_HBA="`sudo -u postgres psql -qA -d template_postgis -c "SHOW data_directory;" | grep -m 1 "^/"`/pg_hba.conf"

EOXSLOG="${DAMATS_LOGDIR}/eoxserver/${INSTANCE}/eoxserver.log"
EOXSCONF="${INSTROOT}/${INSTANCE}/${INSTANCE}/conf/eoxserver.conf"
EOXSURL="http://${HOSTNAME}/${INSTANCE}/ows?"
EOXSMAXSIZE="20480"
EOXSMAXPAGE="200"

# process group label
EOXS_WSGI_PROCESS_GROUP=${EOXS_WSGI_PROCESS_GROUP:-eoxs_ows}

#-------------------------------------------------------------------------------
# STEP 1: CREATE INSTANCE

info "Creating EOxServer instance '${INSTANCE}' in '$INSTROOT/$INSTANCE' ..."

if [ -d "$INSTROOT/$INSTANCE" ]
then
    info " The instance seems to already exist. All files will be removed!"
    rm -fvR "$INSTROOT/$INSTANCE"
fi

# check availability of the EOxServer
#HINT: Does python complain that the apparently installed EOxServer
#      package is not available? First check that the 'eoxserver' tree is
#      readable by anyone. (E.g. in case of read protected home directory when
#      the development setup is used.)
sudo -u "$DAMATS_USER" python -c 'import eoxserver' || {
    error "EOxServer does not seem to be installed!"
    exit 1
}

sudo -u "$DAMATS_USER" mkdir -p "$INSTROOT/$INSTANCE"
sudo -u "$DAMATS_USER" eoxserver-admin.py create_instance "$INSTANCE" "$INSTROOT/$INSTANCE"

#-------------------------------------------------------------------------------
# STEP 2: CREATE POSTGRES DATABASE

info "Creating EOxServer instance's Postgres database '$DBNAME' ..."

# deleting any previously existing database
sudo -u postgres psql -q -c "DROP DATABASE $DBNAME ;" 2>/dev/null \
  && warn " The already existing database '$DBNAME' was removed." || /bin/true

# deleting any previously existing user
TMP=`sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DBUSER' ;"`
if [ 1 == "$TMP" ]
then
    sudo -u postgres psql -q -c "DROP USER $DBUSER ;"
    warn " The alredy existing database user '$DBUSER' was removed"
fi

# create new users
sudo -u postgres psql -q -c "CREATE USER $DBUSER WITH ENCRYPTED PASSWORD '$DBPASSWD' NOSUPERUSER NOCREATEDB NOCREATEROLE ;"
sudo -u postgres psql -q -c "CREATE DATABASE $DBNAME WITH OWNER $DBUSER TEMPLATE template_postgis ENCODING 'UTF-8' ;"

# prepend to the beginning of the acess list
{ sudo -u postgres ex "$PG_HBA" || /bin/true ; } <<END
g/# EOxServer instance:.*\/$INSTANCE/d
g/^\s*local\s*$DBNAME/d
/#\s*TYPE\s*DATABASE\s*USER\s*.*ADDRESS\s*METHOD/a
# EOxServer instance: $INSTROOT/$INSTANCE
local	$DBNAME	$DBUSER	md5
local	$DBNAME	all	reject
.
wq
END

sudo systemctl restart postgresql.service
sudo systemctl status postgresql.service

#-------------------------------------------------------------------------------
# STEP 3: SETUP DJANGO DB BACKEND

sudo -u "$DAMATS_USER" ex "$SETTINGS" <<END
1,\$s/\('ENGINE'[	 ]*:[	 ]*\).*\(,\)/\1'$DBENGINE',/
1,\$s/\('NAME'[	 ]*:[	 ]*\).*\(,\)/\1'$DBNAME',/
1,\$s/\('USER'[	 ]*:[	 ]*\).*\(,\)/\1'$DBUSER',/
1,\$s/\('PASSWORD'[	 ]*:[	 ]*\).*\(,\)/\1'$DBPASSWD',/
1,\$s/\('HOST'[	 ]*:[	 ]*\).*\(,\)/#\1'$DBHOST',/
1,\$s/\('PORT'[	 ]*:[	 ]*\).*\(,\)/#\1'$DBPORT',/
1,\$s:\(STATIC_URL[	 ]*=[	 ]*\).*:\1'$INSTSTAT_URL/':
wq
END
#ALLOWED_HOSTS = []

#-------------------------------------------------------------------------------
# STEP 4: APACHE WEB SERVER INTEGRATION

info "Mapping EOxServer instance '${INSTANCE}' to URL path '${INSTANCE}' ..."

# locate proper configuration file (see also apache configuration)
{
    locate_apache_conf 80
    #locate_apache_conf 443
} | while read CONF
do
    { ex "$CONF" || /bin/true ; } <<END
/EOXS00_BEGIN/,/EOXS00_END/de
/^[ 	]*<\/VirtualHost>/i
    # EOXS00_BEGIN - EOxServer instance - Do not edit or remove this line!

    # EOxServer instance configured by the automatic installation script

    # WSGI service endpoint
    Alias /$INSTANCE "${INSTROOT}/${INSTANCE}/${INSTANCE}/wsgi.py"
    <Directory "${INSTROOT}/${INSTANCE}/${INSTANCE}">
        Options +ExecCGI -MultiViews +FollowSymLinks
        AddHandler wsgi-script .py
        WSGIProcessGroup $EOXS_WSGI_PROCESS_GROUP
        Header set Access-Control-Allow-Origin "*"
        Header set Access-Control-Allow-Headers Content-Type
        Header set Access-Control-Allow-Methods "GET, PUT, POST, DELETE, OPTIONS"
        #Require all granted
        AuthType basic
        AuthName "DAMATS server login"
        AuthBasicProvider file
        AuthUserFile "$BASIC_AUTH_PASSWD_FILE"
        Require valid-user
    </Directory>

    # static content
    Alias $INSTSTAT_URL "$INSTSTAT_DIR"
    <Directory "$INSTSTAT_DIR">
        Options -MultiViews +FollowSymLinks
        Require all granted
        Header set Access-Control-Allow-Origin "*"
    </Directory>

    # EOXS00_END - EOxServer instance - Do not edit or remove this line!
.
wq
END
done

# create basic authentication password file
mkdir -p "`dirname "$BASIC_AUTH_PASSWD_FILE"`"
touch "$BASIC_AUTH_PASSWD_FILE"
chown "root:apache" "$BASIC_AUTH_PASSWD_FILE"
chmod 0640 "$BASIC_AUTH_PASSWD_FILE"

#-------------------------------------------------------------------------------
# STEP 5: EOXSERVER CONFIGURATION

# set the service url and log-file
#/^[	 ]*logging_filename[	 ]*=/s;\(^[	 ]*logging_filename[	 ]*=\).*;\1${EOXSLOG};
sudo -u "$DAMATS_USER" ex "$EOXSCONF" <<END
/^[	 ]*http_service_url[	 ]*=/s;\(^[	 ]*http_service_url[	 ]*=\).*;\1${EOXSURL};
g/^#.*supported_crs/,/^$/d
/\[services\.ows\.wms\]/a

supported_crs=4326,3857,#900913, # WGS84, WGS84 Pseudo-Mercator, and GoogleEarth spherical mercator
        3035, #ETRS89
        2154, # RGF93 / Lambert-93
        32601,32602,32603,32604,32605,32606,32607,32608,32609,32610, # WGS84 UTM  1N-10N
        32611,32612,32613,32614,32615,32616,32617,32618,32619,32620, # WGS84 UTM 11N-20N
        32621,32622,32623,32624,32625,32626,32627,32628,32629,32630, # WGS84 UTM 21N-30N
        32631,32632,32633,32634,32635,32636,32637,32638,32639,32640, # WGS84 UTM 31N-40N
        32641,32642,32643,32644,32645,32646,32647,32648,32649,32650, # WGS84 UTM 41N-50N
        32651,32652,32653,32654,32655,32656,32657,32658,32659,32660, # WGS84 UTM 51N-60N
        32701,32702,32703,32704,32705,32706,32707,32708,32709,32710, # WGS84 UTM  1S-10S
        32711,32712,32713,32714,32715,32716,32717,32718,32719,32720, # WGS84 UTM 11S-20S
        32721,32722,32723,32724,32725,32726,32727,32728,32729,32730, # WGS84 UTM 21S-30S
        32731,32732,32733,32734,32735,32736,32737,32738,32739,32740, # WGS84 UTM 31S-40S
        32741,32742,32743,32744,32745,32746,32747,32748,32749,32750, # WGS84 UTM 41S-50S
        32751,32752,32753,32754,32755,32756,32757,32758,32759,32760  # WGS84 UTM 51S-60S
        #32661,32761, # WGS84 UPS-N and UPS-S
.
/\[services\.ows\.wcs\]/a

supported_crs=4326,3857,#900913, # WGS84, WGS84 Pseudo-Mercator, and GoogleEarth spherical mercator
        3035, #ETRS89
        2154, # RGF93 / Lambert-93
        32601,32602,32603,32604,32605,32606,32607,32608,32609,32610, # WGS84 UTM  1N-10N
        32611,32612,32613,32614,32615,32616,32617,32618,32619,32620, # WGS84 UTM 11N-20N
        32621,32622,32623,32624,32625,32626,32627,32628,32629,32630, # WGS84 UTM 21N-30N
        32631,32632,32633,32634,32635,32636,32637,32638,32639,32640, # WGS84 UTM 31N-40N
        32641,32642,32643,32644,32645,32646,32647,32648,32649,32650, # WGS84 UTM 41N-50N
        32651,32652,32653,32654,32655,32656,32657,32658,32659,32660, # WGS84 UTM 51N-60N
        32701,32702,32703,32704,32705,32706,32707,32708,32709,32710, # WGS84 UTM  1S-10S
        32711,32712,32713,32714,32715,32716,32717,32718,32719,32720, # WGS84 UTM 11S-20S
        32721,32722,32723,32724,32725,32726,32727,32728,32729,32730, # WGS84 UTM 21S-30S
        32731,32732,32733,32734,32735,32736,32737,32738,32739,32740, # WGS84 UTM 31S-40S
        32741,32742,32743,32744,32745,32746,32747,32748,32749,32750, # WGS84 UTM 41S-50S
        32751,32752,32753,32754,32755,32756,32757,32758,32759,32760  # WGS84 UTM 51S-60S
        #32661,32761, # WGS84 UPS-N and UPS-S
.
wq
END

#set the limits
sudo -u "$DAMATS_USER" ex "$EOXSCONF" <<END
g/^[ 	#]*maxsize[ 	]/d
/\[services\.ows\.wcs\]/a
# maximum allowed output coverage size
# (nether width nor height can exceed this limit)
maxsize = $EOXSMAXSIZE
.
/^[	 ]*source_to_native_format_map[	 ]*=/s#\(^[	 ]*source_to_native_format_map[	 ]*=\).*#\1application/x-esa-envisat,application/x-esa-envisat#
/^[	 ]*paging_count_default[	 ]*=/s/\(^[	 ]*paging_count_default[	 ]*=\).*/\1${EOXSMAXPAGE}/

wq
END

# set the allowed hosts
sudo -u "$DAMATS_USER" ex "$SETTINGS" <<END
1,\$s/\(^ALLOWED_HOSTS\s*=\s*\).*/\1['$HOSTNAME','127.0.0.1','::1']/
wq
END

# set-up logging
sudo -u "$DAMATS_USER" ex "$SETTINGS" <<END
g/^DEBUG\s*=/s#\(^DEBUG\s*=\s*\).*#\1False#
g/^LOGGING\s*=/,/^}/d
a
LOGGING = {
    'version': 1,
    'disable_existing_loggers': True,
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse'
        }
    },
    'formatters': {
        'simple': {
            'format': '[%(module)s] %(levelname)s: %(message)s'
        },
        'verbose': {
            'format': '[%(asctime)s][%(module)s] %(levelname)s: %(message)s'
        }
    },
    'handlers': {
        'eoxserver_file': {
            'level': 'DEBUG',
            'class': 'logging.handlers.WatchedFileHandler',
            'filename': '${EOXSLOG}',
            'formatter': 'verbose',
            'filters': [],
        },
        'stderr_stream': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
            'filters': [],
        },
    },
    'loggers': {
        'eoxserver': {
            'handlers': ['eoxserver_file'],
            'level': 'DEBUG' if DEBUG else 'INFO',
            'propagate': False,
        },
        '': {
            'handlers': ['eoxserver_file'],
            'level': 'INFO' if DEBUG else 'WARNING',
            'propagate': False,
        },
    }
}
.
wq
END

# touch the logfifile and set the right permissions
[ ! -f "$EOXSLOG" ] || rm -fv "$EOXSLOG"
[ -d "`dirname "$EOXSLOG"`" ] || mkdir -p "`dirname "$EOXSLOG"`"
touch "$EOXSLOG"
chown -v "$DAMATS_USER:$DAMATS_GROUP" "$EOXSLOG"
chmod -v 0664 "$EOXSLOG"

#setup logrotate configuration
cat >"/etc/logrotate.d/damats_eoxserver_${INSTANCE}" <<END
$EOXSLOG {
    copytruncate
    daily
    minsize 1M
    compress
    rotate 7
    missingok
}
END

# create fixtures directory
sudo -u "$DAMATS_USER" mkdir -p "$FIXTURES_DIR"

#-------------------------------------------------------------------------------
# STEP 6: DAMATS SPECIFIC SETTINGS

info "DAMATS specific configuration ..."

sudo -u "$DAMATS_USER" ex "$SETTINGS" <<END
/^INSTALLED_APPS\s*=/
/^)/
a
# DAMATS specific apps
INSTALLED_APPS += (
    'damats.webapp',
)
.
/^COMPONENTS\s*=/
/^)/a
# DAMATS specific components
COMPONENTS += (
    'damats.processes.**',
)
.
wq
END

sudo -u "$DAMATS_USER" ex "$URLS" <<END
$ a

# DAMATS specific views
urlpatterns += patterns('',
    (r'^damats/?$', 'damats.webapp.views.user_profile'),
    (r'^damats/user?$', 'damats.webapp.views.user_view'),
    (r'^damats/groups?$', 'damats.webapp.views.groups_view'),
    (r'^damats/processes?$', 'damats.webapp.views.processes_view'),
    (r'^damats/sources$', 'damats.webapp.views.sources_view'),
    (r'^damats/sources/([0-9A-Za-z][-_0-9A-Za-z]{1,255})$', 'damats.webapp.views.sources_item_view'),
    (r'^damats/time_series$', 'damats.webapp.views.time_series_view'),
    (r'^damats/time_series/([0-9A-Za-z][-_0-9A-Za-z]{1,255})$', 'damats.webapp.views.time_series_item_view'),
    (r'^damats/jobs$', 'damats.webapp.views.jobs_view'),
    (r'^damats/jobs/([0-9A-Za-z][-_0-9A-Za-z]{1,255})$', 'damats.webapp.views.jobs_view'),
)
.
wq
END

EOXSCONF="${INSTROOT}/${INSTANCE}/${INSTANCE}/conf/eoxserver.conf"
sudo -u "$DAMATS_USER" ex "$EOXSCONF" <<END
$ a
[damats]
# DAMATS specific settings

# default user identifier set in case of missing authentication subsystem.
#default_user=<username>

.
wq
END

#-------------------------------------------------------------------------------
# STEP 7: EOXSERVER INITIALISATION
info "Initializing EOxServer instance '${INSTANCE}' ..."

# collect static files
sudo -u "$DAMATS_USER" python "$MNGCMD" collectstatic -l --noinput

# setup new database
sudo -u "$DAMATS_USER" python "$MNGCMD" syncdb --noinput

# load range types (when available)
#INITIAL_RANGETYPES="$DAMATS__IEAS_HOME/range_types.json"
#[ -f "$INITIAL_RANGETYPES" ] && sudo -u "$DAMATS_USER" python "$MNGCMD" eoxs_rangetype_load < "$INITIAL_RANGETYPES"

#-------------------------------------------------------------------------------
# STEP 8: FINAL WEB SERVER RESTART
sudo systemctl restart httpd.service
sudo systemctl status httpd.service
