#!/bin/bash

while true
do
    sleep 120
    perl /root/pdfscan.pl | tee -a /var/log/pdfscan.pl.log
done
