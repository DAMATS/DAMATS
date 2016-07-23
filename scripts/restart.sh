#!/bin/sh -x
sudo systemctl restart eoxs_wps_async.service
sleep 1
sudo systemctl restart httpd.service
sleep 1
sudo systemctl status httpd.service
sleep 10
sudo systemctl status eoxs_wps_async.service
