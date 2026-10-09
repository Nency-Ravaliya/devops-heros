#!/bin/bash

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no

current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)
disk_usage=$(df -h)
processes=$(ps -e -o pid,user,comm)

mkdir -p result_file
cd result_file
touch result.log process.log

echo "===== System Information ====="
echo "Name        : $name"
echo "Roll number : $roll_no"
echo "Date        : $current_date"
echo "Hostname    : $host_name"
echo "Username    : $user_name"

echo ""
echo "===== Disk Usage ====="
echo "$disk_usage"

echo ""
echo "===== Running Processes ====="
echo "$processes" | head -8

echo "$processes" > process.log

echo "This is my result file" > result.log
echo "Hi I am $name" >> result.log
echo "My roll number is $roll_no" >> result.log
echo "Today is $current_date" >> result.log

echo ""
echo "Saved process list to result_file/process.log"
echo "Saved details to result_file/result.log"
