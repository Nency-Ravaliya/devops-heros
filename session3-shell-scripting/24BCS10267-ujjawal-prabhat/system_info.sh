#!/bin/bash
# system_info.sh - Session 03 Shell Scripting task
# Author: Ujjawal Prabhat (24BCS10267)
#
# Prints basic system information, asks the user for a directory name,
# creates that directory, creates a file inside it and saves the
# running-process list into that file.

# ---------- variables ----------
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)
file_name="process.log"

echo "========== SYSTEM INFO =========="
echo "Date      : $current_date"
echo "Hostname  : $host_name"
echo "Username  : $user_name"
echo

echo "---------- Disk usage (df -h) ----------"
df -h
echo

echo "---------- Running processes (ps) ----------"
ps
echo

# ---------- user input ----------
read -p "Enter a directory name to create: " dir_name

if [ -z "$dir_name" ]; then
    echo "No directory name given, exiting."
    exit 1
fi

mkdir -p "$dir_name"
echo "Directory '$dir_name' created."

touch "$dir_name/$file_name"
echo "File '$dir_name/$file_name' created."

# ---------- redirect ps output into the file ----------
ps aux > "$dir_name/$file_name"
echo "Process list saved to '$dir_name/$file_name' ($(wc -l < "$dir_name/$file_name") lines)."

echo "Done."
