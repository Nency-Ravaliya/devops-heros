#!/bin/bash

# Take user input
read -p "Enter directory name: " dir_name

# Create directory
mkdir -p "$dir_name"

# Create file inside the directory
file_name="$dir_name/processes.txt"
touch "$file_name"

# Store system information in variables
current_date=$(date)
hostname=$(hostname)
username=$(whoami)

# Display system information
echo "===== SYSTEM INFORMATION ====="
echo "Date: $current_date"
echo "Hostname: $hostname"
echo "Username: $username"

echo ""
echo "===== DISK USAGE ====="
df -h

echo ""
echo "===== RUNNING PROCESSES ====="
ps

# Store running processes in the file
ps > "$file_name"

echo ""
echo "Running processes have been saved to: $file_name"