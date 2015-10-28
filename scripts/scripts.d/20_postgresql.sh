#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: PostgreSQL and PostGIS installation.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Installing PosgreSQL RDBMS ... "

#[ -z "$DAMATS_USER" ] && error "Missing the required DAMATS_USER variable!"

PG_CONF="/etc/postgresql/9.3/main/postgresql.conf"
PG_DATA_DIR="${DAMATS_PGDATA_DIR:-/var/lib/postgresql/9.3/main}"
PG_INITDB="/usr/lib/postgresql/9.3/bin/initdb"
#======================================================================

# STEP 1: INSTALL PACKAGES
apt-get --assume-yes install postgresql postgis postgresql-9.3-postgis-2.1 python-psycopg2

# STEP 2: Shut-down the postgress if already installed and running.
if [ -f "/etc/init.d/postgresql" ]
then
    service postgresql stop || :
    info "Removing the existing PosgreSQL DB cluster ..."
    PG_OLD_DATA_DIR="`sed  -ne "s/\s*data_directory\s*=\s*'\([^']*\)'.*/\1/p" $PG_CONF`"
    # remove existing DB cluster - all data will be lost
    [ ! -d "$PG_OLD_DATA_DIR" ] || rm -fR "$PG_OLD_DATA_DIR"
fi


# STEP 3: CONFIGURE THE STORAGE DIRECTORY
if [ -n "$PG_DATA_DIR" ]
then
    info "Setting the PostgreSQL data location to: $PG_DATA_DIR"
    { ex "$PG_CONF" || /bin/true ; } <<END
/\s*data_directory\s*=\s*/s#\(\s*data_directory\s*=\s*'\)[^']*\(.*\)\$#\1$PG_DATA_DIR\2#
wq
END
fi

# STEP 4: INIT THE DB AND START THE SERVICE
info "New database initialisation ... "
# database initiaisation
mkdir -p "$PG_DATA_DIR"
chown -R postgres:postgres "$PG_DATA_DIR"
sudo -u postgres "$PG_INITDB" -D "$PG_DATA_DIR"

#service postgresql initdb
sysv-rc-conf postgresql on
service postgresql start

# STEP 5: SETUP POSTGIS DATABASE TEMPLATE
if [ -z "`sudo sudo -u postgres psql --list | grep template_postgis`" ]
then
    sudo -u postgres createdb template_postgis
    #sudo -u postgres createlang plpgsql template_postgis

    PG_POSTGIS_SCRIPTS=/usr/share/postgresql/9.3/contrib/postgis-2.1
    sudo -u postgres psql -q -d template_postgis -f "$PG_POSTGIS_SCRIPTS/postgis.sql"
    sudo -u postgres psql -q -d template_postgis -f "$PG_POSTGIS_SCRIPTS/spatial_ref_sys.sql"
    sudo -u postgres psql -q -d template_postgis -c "GRANT ALL ON geometry_columns TO PUBLIC;"
    sudo -u postgres psql -q -d template_postgis -c "GRANT ALL ON geography_columns TO PUBLIC;"
    sudo -u postgres psql -q -d template_postgis -c "GRANT ALL ON spatial_ref_sys TO PUBLIC;"
fi
