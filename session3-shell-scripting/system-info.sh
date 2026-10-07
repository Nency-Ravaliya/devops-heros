#!/bin/bash
# =============================================================
#  System Information Script
#  Session 3 - Shell Scripting Homework
#  Name: Chhavi Ahlawat | Enrollment: 24BCS10201
# =============================================================

echo "=============================================="
echo "        SYSTEM INFORMATION REPORT"
echo "=============================================="
echo

# ---------- VARIABLES: store command output using $( ) ----------
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)
uptime_info=$(uptime)

# ---------- 1. Current date ----------
echo "1. CURRENT DATE"
echo "----------------------------------------------"
echo "Date : $current_date"
echo

# ---------- 2. Hostname ----------
echo "2. HOSTNAME"
echo "----------------------------------------------"
echo "Hostname : $host_name"
echo

# ---------- 3. Username ----------
echo "3. USERNAME"
echo "----------------------------------------------"
echo "Logged in as : $user_name"
echo

# ---------- 4. Disk usage ----------
echo "4. DISK USAGE"
echo "----------------------------------------------"
df -h
echo

# ---------- 5. Running processes ----------
echo "5. RUNNING PROCESSES (top 10)"
echo "----------------------------------------------"
ps aux | head -10
echo

# ---------- 6. Take user input with read -p ----------
echo "6. USER DETAILS (input taken with read -p)"
echo "----------------------------------------------"
read -p "Enter your name        : " name
read -p "Enter your roll number : " roll_no
read -p "Enter a comment        : " comment
echo
echo "My name is        : $name"
echo "My roll number is : $roll_no"
echo "My comment is     : $comment"
echo

# ---------- 7. Create a directory with mkdir ----------
report_dir="system_report"
echo "7. CREATING DIRECTORY AND FILES"
echo "----------------------------------------------"
mkdir -p "$report_dir"
echo "Directory created : $report_dir"

# ---------- 8. Create files with touch ----------
process_file="$report_dir/process.log"
summary_file="$report_dir/summary.log"
touch "$process_file"
touch "$summary_file"
echo "File created      : $process_file"
echo "File created      : $summary_file"
echo

# ---------- 9. Store running processes in the file using > redirection ----------
ps aux > "$process_file"
echo "Running processes saved to $process_file using > redirection"

# ---------- Build a summary file using > and >> ----------
echo "===== SYSTEM SUMMARY =====" >  "$summary_file"
echo "Generated on : $current_date" >> "$summary_file"
echo "Hostname     : $host_name"    >> "$summary_file"
echo "Username     : $user_name"    >> "$summary_file"
echo "Name         : $name"         >> "$summary_file"
echo "Roll Number  : $roll_no"      >> "$summary_file"
echo "Comment      : $comment"      >> "$summary_file"
echo "--- Disk Usage ---"           >> "$summary_file"
df -h                               >> "$summary_file"
echo "Summary saved to $summary_file"
echo

# ---------- 10. Verify ----------
echo "8. VERIFICATION"
echo "----------------------------------------------"
echo "Contents of $report_dir :"
ls -l "$report_dir"
echo
echo "Line count of $process_file : $(wc -l < "$process_file") lines"
echo
echo "--- First 5 lines of $process_file ---"
head -5 "$process_file"
echo
echo "--- Contents of $summary_file ---"
cat "$summary_file"
echo
echo "=============================================="
echo "              REPORT COMPLETE"
echo "=============================================="
