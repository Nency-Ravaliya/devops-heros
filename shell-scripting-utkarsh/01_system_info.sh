#!/bin/bash

echo "===== System Information ====="

current_date=$(date)
echo "Current date : $current_date"

host_name=$(hostname)
echo "Hostname     : $host_name"

user_name=$(whoami)
echo "Username     : $user_name"

echo ""
echo "===== Running Processes ====="
ps

ps > process.log
echo ""
echo "Process info saved in process.log"
