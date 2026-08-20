#!/bin/bash

mkdir result_file
cd result_file
touch result.log
echo "This is my result file" > result.log

current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)
disk_usage=$(df -h)
ps > process.log

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no

current_date=$(date)
echo "My name is $name" >> result.log

echo "User: $user_name" >> result.log
echo "Roll Number: $roll_no" >> result.log
echo "Date: $current_date" >> result.log
echo "Host Name: $host_name" >> result.log
echo "Disk Usage:" >> result.log
echo "$disk_usage" >> result.log
echo "Process List:" >> result.log
cat process.log >> result.log

cat result.log