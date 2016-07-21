#!/bin/sh
sudo systemctl restart eoxs_wps_async.service
sudo systemctl restart httpd.service
sudo systemctl status httpd.service
sleep 5
sudo systemctl status eoxs_wps_async.service
