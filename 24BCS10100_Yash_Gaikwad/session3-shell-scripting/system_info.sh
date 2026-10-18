#!/bin/bash
# system_info.sh - System Information Script
# Author: Yash Gaikwad (24BCS10100)
#
# Prints date, hostname, username, disk usage and running processes,
# then asks for a directory and file name, creates them and saves the
# process list into that file.

# ---- variables that store data ----
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

echo "=============================================="
echo "          SYSTEM INFORMATION REPORT"
echo "=============================================="
echo "Current date : $current_date"
echo "Hostname     : $host_name"
echo "Username     : $user_name"

echo
echo "------------- Disk usage ---------------------"
df -h

echo
echo "------------- Running processes --------------"
ps aux

# ---- take user input with read -p ----
echo
echo "------------- User input ---------------------"
read -p "Enter your name: " name
read -p "Enter directory name to create: " dir_name
read -p "Enter file name to create: " file_name

# fall back to defaults when the user just presses Enter
name=${name:-Student}
dir_name=${dir_name:-system_report}
file_name=${file_name:-processes.log}

# ---- create directory and file ----
mkdir -p "$dir_name"
touch "$dir_name/$file_name"
echo "Hello $name, created directory '$dir_name' and file '$file_name'."

# ---- store the running processes in the file using > redirection ----
ps aux > "$dir_name/$file_name"
echo "Running processes saved to $dir_name/$file_name"
echo "Total lines saved: $(wc -l < "$dir_name/$file_name")"
