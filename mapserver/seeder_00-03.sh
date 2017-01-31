#!/bin/sh -x
sudo -u apache mapcache_seed -c /srv/damats/mapcache/mapcache.xml -t CLC2012 -e "-180,-90,180,90" -g WGS84 -i level-by-level -n 2 -z 0,3 -M 1,1
