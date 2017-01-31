#!/bin/sh -x
sudo -u apache mapcache_seed -c /srv/damats/mapcache/mapcache.xml -t CLC2012 -e "-26,34,45,72" -g WGS84 -i level-by-level -n 8 -z 10,12 -M 8,8
