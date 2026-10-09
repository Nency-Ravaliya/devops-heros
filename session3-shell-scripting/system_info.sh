#!/bin/bash

current_date="$(date)"
host_name="$(hostname)"
user_name="$(whoami)"
disk_usage="$(df -h)"

echo "Current date: $current_date"
echo "Hostname: $host_name"
echo "Username: $user_name"
echo "Disk usage:"
echo "$disk_usage"

read -p "Enter directory name to create: " dir_name
mkdir -p "$dir_name"

read -p "Enter file name to create inside $dir_name: " file_name
touch "$dir_name/$file_name"

process_output_file="$dir_name/$file_name"
ps -ef > "$process_output_file"

echo "Running processes saved to: $process_output_file"
echo "Top 10 running processes:"
ps -ef | head -n 10
