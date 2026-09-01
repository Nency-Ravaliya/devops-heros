#!/bin/bash

# Session 3 Homework
# System information script

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter directory name to save report: " dir_name

today=$(date)
my_host=$(hostname)
my_user=$(whoami)

echo "----------------------------------------"
echo "Name        : $name"
echo "Roll Number : $roll_no"
echo "Date        : $today"
echo "Hostname    : $my_host"
echo "Username    : $my_user"
echo "----------------------------------------"

echo "Disk usage:"
df -h

echo "----------------------------------------"

echo "Running processes:"
ps

echo "----------------------------------------"

mkdir -p "$dir_name"
touch "$dir_name/process.log"

ps > "$dir_name/process.log"

echo "Process information saved in $dir_name/process.log"
echo "Script completed successfully"
