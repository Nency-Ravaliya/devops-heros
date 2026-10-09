#!/bin/bash
# Homework: System Information Script
# date, hostname, username, disk usage, running processes, variables, read -p, mkdir, touch, > redirection

current_date=$(date)
host=$(hostname)
user=$(whoami)

echo "===== System Information ====="
echo "Date     : $current_date"
echo "Hostname : $host"
echo "Username : $user"
echo
echo "----- Disk usage -----"
df -h /
echo
echo "----- Running processes (top 5 by CPU) -----"
ps aux --sort=-%cpu | head -6
echo

read -p "Enter a name for the report directory: " report_dir
mkdir -p "$report_dir"
touch "$report_dir/processes.txt"
ps aux > "$report_dir/processes.txt"

echo "Saved $(wc -l < "$report_dir/processes.txt") lines of process information to $report_dir/processes.txt"
ls -l "$report_dir"
