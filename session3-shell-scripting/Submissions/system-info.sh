#!/usr/bin/env bash
#
# Shell Scripting Homework — System Information Script
# ---------------------------------------------------
# Demonstrates:
#   * variables to store and use data
#   * read -p  (take user input)
#   * date / hostname / whoami / df / ps
#   * mkdir to create a directory
#   * touch to create a file
#   * > output redirection to store data in a file
#
set -u

# ------------------------------------------------------------------
# 1) Variables — store data once, reuse it everywhere
# ------------------------------------------------------------------
TODAY="$(date '+%A, %d %B %Y  %T')"
HOST="$(hostname)"
CURRENT_USER="$(whoami)"
# columns: filesystem size used avail use% mount  -> keep the numbers, drop noise
DISK_USAGE="$(df -h / | awk 'NR==2 {printf "%s total / %s used / %s free (%s)", $2, $3, $4, $5}')"

# ------------------------------------------------------------------
# 2) User input with read -p
# ------------------------------------------------------------------
read -p "Enter your name: " NAME
read -p "Enter a directory name to create [default: sysinfo-demo]: " DIR_NAME
DIR_NAME="${DIR_NAME:-sysinfo-demo}"          # default if the user just presses Enter

REPORT_FILE="system-info.txt"
PROCESS_FILE="running-processes.txt"

# ------------------------------------------------------------------
# 3) Print the system information
# ------------------------------------------------------------------
echo
echo "================ System Information Report ================"
echo "Date        : $TODAY"
echo "Hostname    : $HOST"
echo "User        : $CURRENT_USER"
echo "Disk usage  : $DISK_USAGE"
echo "Hello $NAME!  Report will be written to ./$DIR_NAME/"
echo "==========================================================="
echo
echo "Running processes (top 5 by memory):"
ps aux 2>/dev/null | head -n 6 || ps | head -n 6
echo

# ------------------------------------------------------------------
# 4) Create a directory (mkdir) and a file (touch)
# ------------------------------------------------------------------
echo ">> mkdir -p $DIR_NAME"
mkdir -p "$DIR_NAME"
echo ">> touch $DIR_NAME/$REPORT_FILE"
touch "$DIR_NAME/$REPORT_FILE"

# ------------------------------------------------------------------
# 5) Store the running-processes output in a file using > redirection
# ------------------------------------------------------------------
echo ">> ps aux > $DIR_NAME/$PROCESS_FILE"
ps aux > "$DIR_NAME/$PROCESS_FILE"

echo
echo "Wrote $(wc -l < "$DIR_NAME/$PROCESS_FILE") lines of process information to $DIR_NAME/$PROCESS_FILE"
echo "Contents of ./$DIR_NAME :"
ls -l "$DIR_NAME"

echo
echo "### SHELL-TASK-DONE ###"
