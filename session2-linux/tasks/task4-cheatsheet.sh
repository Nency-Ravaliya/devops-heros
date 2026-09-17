#!/bin/bash

# File and Directory Commands
pwd
ls -l
mkdir devops_logs
touch index.html
cp index.html devops_logs/
mv index.html backup_index.html
rm backup_index.html

# File Viewing and Search
cat /etc/os-release
head -n 10 /etc/os-release
tail -n 100 /var/log/syslog
grep ERROR /var/log/syslog

# Networking Commands
ping google.com
ip a
curl https://api.github.com

# Permissions and Ownership
touch script.sh
chmod 755 script.sh

# Disk and Storage
df -h
du -sh /var/log

# User Management
id
groups

# System Information and Utilities
uname -a
hostname
uptime
whoami
date

# Process and Service Management
ps
top