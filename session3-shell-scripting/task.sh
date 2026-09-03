#!/bin/bash
# System Information Script
# Task: print current date, hostname/username, disk usage, running processes,
#       take user input (name, roll_no, comment) and store everything under
#       a report directory using variables, read -p, mkdir, touch, echo,
#       df, ps and output redirection.

report_dir="sysinfo_report"
report_file="$report_dir/system_info.txt"

# create directory and file to store the report
mkdir -p "$report_dir"
touch "$report_file"

current_date=$(date)
current_hostname=$(hostname)
current_user=$(whoami)

echo "===== System Information Report =====" > "$report_file"
echo "Date: $current_date" >> "$report_file"
echo "Hostname: $current_hostname" >> "$report_file"
echo "Username: $current_user" >> "$report_file"

echo "" >> "$report_file"
echo "----- Logged in users (who) -----" >> "$report_file"
who >> "$report_file"

echo "" >> "$report_file"
echo "----- System load (w) -----" >> "$report_file"
w >> "$report_file"

echo "" >> "$report_file"
echo "----- Disk Usage (df -h) -----" >> "$report_file"
df -h >> "$report_file"

# running processes redirected into their own file
ps > process.log
echo "" >> "$report_file"
echo "----- Running Processes (see process.log) -----" >> "$report_file"
echo "Process snapshot saved to process.log ($(wc -l < process.log) lines)" >> "$report_file"

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter your comment: " comment

echo "" >> "$report_file"
echo "----- Submitted By -----" >> "$report_file"
echo "Name: $name" >> "$report_file"
echo "Roll No: $roll_no" >> "$report_file"
echo "Comment: $comment" >> "$report_file"

echo ""
echo "Report generated at: $report_file"
cat "$report_file"
