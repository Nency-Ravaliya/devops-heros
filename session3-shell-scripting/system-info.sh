#!/bin/bash

echo "===== System Information ====="

echo "Hostname:"
hostname

echo "Operating System:"
cat /etc/os-release | grep PRETTY_NAME

echo "Kernel:"
uname -r

echo "Current User:"
whoami

echo "System Uptime:"
uptime

echo "Date and Time:"
date

echo "Disk Usage:"
df -h

echo "Memory Usage:"
free -h