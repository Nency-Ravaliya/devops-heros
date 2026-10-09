#!/bin/bash

# Session 3 Homework - System information script
# Uses: variables, read -p, mkdir, touch, echo, date, hostname, whoami, df, ps, >

# Take input from the user
read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter a directory name to store the report: " dir_name

# Store system information in variables
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

# Print the details
echo "-----------------------------------"
echo "My name is $name"
echo "My roll number is $roll_no"
echo "-----------------------------------"
echo "Current date  : $current_date"
echo "Hostname      : $host_name"
echo "Username      : $user_name"
echo "-----------------------------------"

# Print the disk usage
echo "Disk Usage:"
df -h

echo "-----------------------------------"

# Print the running processes
echo "Running Processes:"
ps

echo "-----------------------------------"

# Create a directory and a file inside it
mkdir -p $dir_name
touch $dir_name/process.log

# Store the process information inside the file
ps > $dir_name/process.log

# Also save the disk usage in the same directory
df -h > $dir_name/disk_usage.log

echo "Process information saved in $dir_name/process.log"
echo "Disk usage saved in $dir_name/disk_usage.log"
echo "Script completed successfully!"
