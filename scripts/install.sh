#!/bin/sh
#-------------------------------------------------------------------------------
#
# Project: DAMATS
# Purpose: DAMATS installation script
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

INSTALL_LOG="./install.log"

#source common parts
. `dirname $0`/lib_common.sh
. `dirname $0`/lib_logging.sh

{
    info "#"
    info "#  --= DAMATS =-- "
    info "#"
    info "#   version: $DAMATS_VERSION"
    info "# "

    #export location of the contrib directory
    export CONTRIB_DIR="$(cd "$(dirname "$0")/../contrib"; pwd )"

    #-------------------------------------------------------------------------------
    # check whether the user and group exists
    # if not create them

    _mkdir()
    { # <owner>[:<group>] <permissions> <dirname> <label>
        if [ ! -d "$3" ]
        then
            info "Creating $4: $3"
            mkdir -p "$3"
        fi
        chown -v "$1" "$3"
        chmod -v "$2" "$3"
    }

    id -g "$DAMATS_GROUP" >/dev/null 2>&1 || \
    {
        info "Creatting system group: $DAMATS_GROUP"
        groupadd -r "$DAMATS_GROUP"
    }

    id -u "$DAMATS_USER" >/dev/null 2>&1 || \
    {
        info "Creatting system user: $DAMATS_USER"
        useradd -r -M -g "$DAMATS_GROUP" -d "$DAMATS_ROOT" -s /sbin/nologin -c "DAMATS system user" "$DAMATS_USER"
        usermod -L "$DAMATS_USER"
    }

    # just in case the ODA-OS directories do not exists create them
    # and set the right permissions

    _mkdir "$DAMATS_USER:$DAMATS_GROUP" 0755 "$DAMATS_ROOT" "subsytem's root directory"
    _mkdir "$DAMATS_USER:$DAMATS_GROUP" 0775 "$DAMATS_LOGDIR" "subsytem's logging directory"
    _mkdir "$DAMATS_USER:$DAMATS_GROUP" 0775 "$DAMATS_DATADIR" "subsytem's long-term data storage directory"
    _mkdir "$DAMATS_USER:$DAMATS_GROUP" 0775 "$DAMATS_TMPDIR" "subsytem's short-term data stoarage directory"

    #-------------------------------------------------------------------------------
    # execute specific installation scripts

    SCRIPTS=""
    PROFILE="install.d"


    # parse command line arguments
    while [ "$#" -gt 0 ]
    do
        case "$1" in
            -d | --devel )
                info "Development installation profile selected."
                PROFILE="devel.d"
                ;;
            *)
                SCRIPTS="$SCRIPTS $1"
            ;;
        esac
        shift
    done

    # in case of no script select all in the chosen profile
    if [ -z "$SCRIPTS" ]
    then
        SCRIPTS="`dirname $0`/$PROFILE/"*.sh
    fi

    for SCRIPT in $SCRIPTS
    do
        info "Executing installation script: $SCRIPT"
        sh -e $SCRIPT
        [ 0 -ne "$?" ] && warn "Installation script ended with an error: $SCRIPT"
    done

    info "Installation has been completed."

} 2>&1 | tee -a "$INSTALL_LOG"
