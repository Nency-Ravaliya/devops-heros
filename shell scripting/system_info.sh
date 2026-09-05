#!/bin/bash

# Ask name
read -p "Enter your name: " name

# Store system information in variables
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

# Print a welcome message
echo "Hello, $name!"
echo "=============================="
echo "System Information"
echo "=============================="

# Print the current date
echo "Current Date: $current_date"

# Print the hostname
echo "Hostname: $host_name"

# Print the username
echo "Username: $user_name"

# Print disk usage
echo ""
echo "Disk Usage:"
df -h

# Create a directory
mkdir -p system_info

# Create a file
touch system_info/processes.txt

# Store running processes in the file using output redirection
ps aux > system_info/processes.txt

# Print running processes
echo ""
echo "Running Processes:"
ps aux

echo ""
echo "Running processes have been saved to:"
echo "system_info/processes.txt"