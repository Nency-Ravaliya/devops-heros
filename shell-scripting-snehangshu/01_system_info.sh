#!/bin/bash

log_file="process.log"

echo "===== System Info ====="
echo "Date     : $(date)"
echo "Hostname : $(hostname)"
echo "Username : $(whoami)"

echo
echo "===== Running Processes ====="
ps -ef | head -15

ps -ef > "$log_file"
echo
echo "Process info saved in $log_file"
