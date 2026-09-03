#!/bin/bash

#!/bin/bash

# Store information in variables
current_date=$(date)
hostname=$(hostname)
username=$(whoami)
disk_usage=$(df -h)
processes=$(ps)

# Print the information
echo "Current Date: $current_date"
echo "Hostname: $hostname"
echo "Username: $username"

echo "Disk Usage: $disk_usage"

echo "Running Processes: $processes"

# Take user input
read -p "Enter the directory name: " directory
read -p "Enter the file name: " filename

# Create directory
mkdir -p "$directory"

# Create file inside the directory
touch "$directory/$filename"

# Store running processes in the file using > redirection
ps > "$directory/$filename"

echo "Running processes have been saved to $directory/$filename"