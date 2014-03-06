#!/bin/bash

while true
do
    sleep 120
    perl /root/pdfscan.pl | tee /var/log/pdfscan.pl.log
done
