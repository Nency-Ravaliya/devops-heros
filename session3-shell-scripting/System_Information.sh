#!/bin/bash

echo "===== System Information ====="

echo "Hostname:"
hostname

echo "Operating System:"
cat /etc/os-release | grep PRETTY_NAME

echo "Take user input using read:"
read -p "Enter your name: " name
echo "Hello, $name!"

echo "Create a new directory:"
mkdir new_directory

echo "Create new file:"
touch new_file.txt

echo "Kernel:"
uname -r

echo "Current User:"
whoami

echo "System Uptime:"
uptime

echo "Date and Time:"
date

echo "Disk Usage:"
df -h

echo "Memory Usage:"
free -h