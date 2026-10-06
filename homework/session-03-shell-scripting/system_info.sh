#!/usr/bin/env bash
# Session 3 homework: system information script.
# Prints date, hostname, user, disk usage, and running processes.
# Stores process output in a file and creates a directory from user input.

set -euo pipefail

current_date="$(date)"
host_name="$(hostname)"
user_name="$(whoami)"

echo "Current date: ${current_date}"
echo "Hostname: ${host_name}"
echo "Username: ${user_name}"
echo
echo "Disk usage:"
df -h
echo

read -r -p "Enter your name: " student_name
read -r -p "Enter your enrollment number: " enrollment_number
read -r -p "Enter a short comment: " comment

echo "My name is ${student_name}"
echo "My enrollment number is ${enrollment_number}"
echo "My comment is: ${comment}"

output_dir="student-output"
mkdir -p "${output_dir}"
touch "${output_dir}/processes.log"

ps aux > "${output_dir}/processes.log"

echo
echo "Created directory: ${output_dir}"
echo "Stored running processes in: ${output_dir}/processes.log"
echo "Process log line count: $(wc -l < "${output_dir}/processes.log")"
