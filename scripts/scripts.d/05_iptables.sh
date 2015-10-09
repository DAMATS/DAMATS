#!/bin/sh
#-------------------------------------------------------------------------------
#
# Purpose: Initial IPTables firewall configuration.
# Author(s): Martin Paces <martin.paces@eox.at>
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH

. `dirname $0`/../lib_logging.sh

info "Setting the iptables firewall ... "

[ "$CONFIGURE_IPTABLES" = "YES" ] || {
    info "Iptables firewall configuration skipped."
    exit 0
}

# install IP tables saver
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get --assume-yes install iptables-persistent

# set the defualt rules
for IPTABLES in /sbin/ip6tables /sbin/iptables
do
    $IPTABLES -P INPUT DROP
    $IPTABLES -P FORWARD DROP
    $IPTABLES -P OUTPUT ACCEPT
    $IPTABLES -F
    $IPTABLES -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
    $IPTABLES -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    $IPTABLES -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    $IPTABLES -A INPUT -i lo -j ACCEPT
    $IPTABLES -A INPUT -j DROP
done

# save the rules
invoke-rc.d iptables-persistent save
