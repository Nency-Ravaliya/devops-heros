#!/bin/bash

_date=$(date "+%Y-%m-%d %H:%M:%S")
_host=$(hostname)
_user=$(whoami)
_disk=$(df -h /)

echo "Identify yourself for the audit"
read -p "Enter your name: " _author

echo -e "\t$_host\n\t$_user\n\t$_disk\nAudit timestamp: $date, by: $_author\n" >> comprehensive.log

cat comprehensive.log
