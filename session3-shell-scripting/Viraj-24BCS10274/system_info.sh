#!/usr/bin/env bash
# Viraj Bhanage — 24BCS10274
# Prints date, host, user, disk usage, and a process snapshot.
set -euo pipefail

read -r -p "Enter your name: " student_name
read -r -p "Enter your roll number: " roll_number
read -r -p "Enter a comment: " comment

stamp="$(date)"
host_name="$(hostname)"
login_name="$(whoami)"

out_dir="viraj-24bcs10274-lab"
mkdir -p "$out_dir"
touch "$out_dir/process-snapshot.log"

{
  echo "Name: $student_name"
  echo "Roll: $roll_number"
  echo "Comment: $comment"
  echo "Date: $stamp"
  echo "Host: $host_name"
  echo "Login: $login_name"
  echo
  echo "Disk:"
  df -h /
} | tee "$out_dir/summary.txt"

ps aux > "$out_dir/process-snapshot.log"
echo "Process lines: $(wc -l < "$out_dir/process-snapshot.log")"
echo "Wrote $out_dir/summary.txt and $out_dir/process-snapshot.log"
