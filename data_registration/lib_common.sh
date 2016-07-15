#!/bin/bash
#
# common shared definitions
#
info () { echo "INFO: $*" ; }
error () { echo "ERROR: $*" >&2 ; exit 1 ; }
expand () { cd $1 ; pwd ; }

export PATH="$PATH:$(expand "`dirname "$0"`/../../tools/imgproc")"
export PATH="$PATH:`dirname "$0"`"

MNG="$(expand "`dirname "$0"`/../scripts")/manage.sh"
