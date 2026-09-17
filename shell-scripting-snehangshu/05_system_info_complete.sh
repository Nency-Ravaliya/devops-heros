#!/bin/bash
# Session 3 - Shell Scripting Homework
# System Information Script covering every requirement in one place.
# Snehangshu Roy | 24BCS10155

# ---- variables ----
dir_name="system_report"
process_file="$dir_name/processes.txt"
summary_file="$dir_name/summary.txt"
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

echo "==================================================="
echo "            SYSTEM INFORMATION REPORT"
echo "==================================================="

# ---- date / hostname / username, printed from variables ----
echo "Date      : $current_date"
echo "Hostname  : $host_name"
echo "Username  : $user_name"

# ---- disk usage ----
echo
echo "===== Disk Usage (df -h) ====="
df -h

# ---- running processes ----
echo
echo "===== Running Processes (ps -ef | head -10) ====="
ps -ef | head -10

# ---- user input ----
echo
read -p "Enter your name: " input_name
read -p "Enter your roll number: " input_roll
read -p "Enter a comment: " input_comment

# ---- create a directory ----
echo
if [ -d "$dir_name" ]; then
    echo "Directory '$dir_name' already exists"
else
    mkdir "$dir_name"
    echo "Directory '$dir_name' created with mkdir"
fi

# ---- create files with touch ----
touch "$process_file"
touch "$summary_file"
echo "Empty files created with touch:"
ls -l "$dir_name"

# ---- store running processes in a file using > redirection ----
ps -ef > "$process_file"
echo
echo "Running processes stored in $process_file using > redirection"
echo "Lines captured: $(wc -l < "$process_file")"

# ---- build the summary file: > creates/overwrites, >> appends ----
echo "===== System Summary =====" >  "$summary_file"
echo "Date      : $current_date"  >> "$summary_file"
echo "Hostname  : $host_name"     >> "$summary_file"
echo "Username  : $user_name"     >> "$summary_file"
echo "Disk used : $(df -h / | awk 'NR==2 {print $3 " of " $2 " (" $5 ")"}')" >> "$summary_file"
echo "Processes : $(ps -e --no-headers | wc -l) running" >> "$summary_file"
echo "Name      : $input_name"    >> "$summary_file"
echo "Roll No   : $input_roll"    >> "$summary_file"
echo "Comment   : $input_comment" >> "$summary_file"

echo
echo "===== Contents of $summary_file ====="
cat "$summary_file"

echo
echo "===== First 5 lines of $process_file ====="
head -5 "$process_file"

echo
echo "Report complete."
