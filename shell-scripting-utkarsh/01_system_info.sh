#!/bin/bash
# Task 1: print current date, hostname, username and process info
# Process info is also saved into process.log

echo "===== System Information ====="

# current date
current_date=$(date)
echo "Current date : $current_date"

# hostname of the machine
host_name=$(hostname)
echo "Hostname     : $host_name"

# currently logged in user
user_name=$(whoami)
echo "Username     : $user_name"

echo ""
echo "===== Running Processes ====="
ps

# save the process info inside process.log
ps > process.log
echo ""
echo "Process info saved in process.log"
