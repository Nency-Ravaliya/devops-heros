#!/bin/bash
# system_info.sh
# Session 3 homework: System Information Script
#
# Prints current date, hostname, username, disk usage and running
# processes; takes user input; creates a directory and a file; and
# stores the process list in that file using output redirection.

# --- Variables ---
current_date=$(date)
current_host=$(hostname)
current_user=$(whoami)

echo "===== System Information ====="
echo "Date      : $current_date"
echo "Hostname  : $current_host"
echo "User      : $current_user"

echo
echo "===== Disk Usage ====="
df -h

echo
echo "===== Running Processes (top 10) ====="
ps aux | head -n 11

# --- Take user input ---
read -p "Enter your name: " name
read -p "Enter your roll/enrollment number: " roll_no
read -p "Enter a comment: " comment

echo
echo "Hello, $name (Roll No: $roll_no)."
echo "Your comment: $comment"

# --- Create a directory ---
output_dir="sysinfo_output"
mkdir -p "$output_dir"

# --- Create a file ---
output_file="$output_dir/processes.log"
touch "$output_file"

# --- Store running processes info in the file using > redirection ---
{
  echo "System info captured for $name (Roll No: $roll_no) on $current_date"
  echo "Host: $current_host | User: $current_user"
  echo
  echo "Disk usage:"
  df -h
  echo
  echo "Running processes:"
  ps aux
} > "$output_file"

echo
echo "Process information saved to $output_file"
