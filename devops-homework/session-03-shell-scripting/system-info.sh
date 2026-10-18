#!/usr/bin/env bash
set -euo pipefail
current_date=$(date --iso-8601=seconds)
machine=$(hostname)
current_user=$(id -un)
echo "Date: $current_date"
echo "Hostname: $machine"
echo "Username: $current_user"
echo 'Disk usage:'
df -h
echo 'Running processes:'
ps -ef
read -r -p 'Directory for the process report: ' report_dir
if [[ -z "$report_dir" || "$report_dir" == -* ]]; then
  echo 'Please enter a nonempty directory path that does not begin with -.' >&2
  exit 1
fi
mkdir -p -- "$report_dir"
report_file="$report_dir/processes.txt"
touch -- "$report_file"
ps -ef > "$report_file"
echo "Process report saved to $report_file"
