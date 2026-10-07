#!/usr/bin/env bash
# sysinfo.sh - collect basic system information and save the process list to a file
# Usage: ./sysinfo.sh   (asks for a report folder name and a label)

set -u

# ---------- variables ----------
today=$(date "+%A, %d %B %Y %H:%M:%S %Z")
host=$(hostname)
user=$(whoami)
os=$(uname -srm)
proc_count=$(ps -e | tail -n +2 | wc -l | tr -d ' ')

# ---------- user input ----------
read -p "Name a folder for the report: " report_dir
read -p "Add a one-line label for this run: " label

# fall back to a default folder name if the user just hits Enter
report_dir=${report_dir:-sysinfo-report}
report_file="$report_dir/processes.txt"

# ---------- create directory and file ----------
mkdir -p "$report_dir"
touch "$report_file"

# ---------- print information ----------
echo
echo "================ SYSTEM INFORMATION ================"
echo "Label            : $label"
echo "Date             : $today"
echo "Hostname         : $host"
echo "Logged-in user   : $user"
echo "Kernel           : $os"
echo "Running processes: $proc_count"
echo

echo "---------------- DISK USAGE (df -h) ----------------"
df -h
echo

echo "------------- RUNNING PROCESSES (top 15 by CPU) -------------"
ps -eo pid,user,%cpu,%mem,comm -r | head -n 16 || true
echo

# ---------- save the full process list with > redirection ----------
{
  echo "# $label"
  echo "# generated on $today by $user@$host"
  ps -ef
} > "$report_file"

echo "Full process list ($proc_count processes) written to: $report_file"
echo "Report folder contents:"
ls -l "$report_dir"
