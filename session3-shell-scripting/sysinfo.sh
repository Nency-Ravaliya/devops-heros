#!/bin/bash
# ==============================================================
#  System Information Script
#  Session 3 - Shell Scripting Homework
# ==============================================================
set -u

# ---------- Variables to store and use data ----------
CURRENT_DATE=$(date)
HOST_NAME=$(hostname)
USER_NAME=$(whoami)
KERNEL=$(uname -r)
UPTIME_INFO=$(uptime -p 2>/dev/null || uptime)
PROCESS_COUNT=$(ps -e --no-headers | wc -l)

echo "==============================================================="
echo "                  SYSTEM INFORMATION REPORT"
echo "==============================================================="
echo
echo "Current date  : $CURRENT_DATE"
echo "Hostname      : $HOST_NAME"
echo "Username      : $USER_NAME"
echo "Kernel        : $KERNEL"
echo "Uptime        : $UPTIME_INFO"
echo "Processes     : $PROCESS_COUNT running"
echo
echo "--------------------- DISK USAGE (df -h) ----------------------"
df -h
echo
echo "------------------ RUNNING PROCESSES (ps -ef) -----------------"
ps -ef | head -n 12
echo "   ... showing the first 12 only; the complete list is written"
echo "       to the log file created at the end of this script."

# ---------- Takes user input using read -p ----------
echo
echo "-------------------------- USER INPUT -------------------------"
read -p "Enter your name           : " NAME
read -p "Enter your roll number    : " ROLL_NO
read -p "Enter a comment           : " COMMENT
read -p "Directory to create [sysinfo_reports] : " DIR_NAME
DIR_NAME=${DIR_NAME:-sysinfo_reports}

echo
echo "My name is $NAME"
echo "My roll number is $ROLL_NO"
echo "My comment is: $COMMENT"

# ---------- Creates a directory using mkdir ----------
echo
echo "--------------------- CREATING OUTPUT FILES -------------------"
mkdir -p "$DIR_NAME"
echo "Created directory : $DIR_NAME"

# ---------- Creates files using touch ----------
PROCESS_FILE="$DIR_NAME/process.log"
SUMMARY_FILE="$DIR_NAME/system_report.txt"
touch "$PROCESS_FILE"
touch "$SUMMARY_FILE"
echo "Created file      : $PROCESS_FILE"
echo "Created file      : $SUMMARY_FILE"

# ---------- Stores running processes using > output redirection ----------
ps -ef > "$PROCESS_FILE"
echo
echo "Saved full process list to $PROCESS_FILE using '>' redirection"

# ---------- Summary file: > for the first write, >> to append the rest ----------
echo "=============== SYSTEM REPORT ===============" > "$SUMMARY_FILE"
echo "Generated at : $(date '+%Y-%m-%d %H:%M:%S')" >> "$SUMMARY_FILE"
echo "Name         : $NAME" >> "$SUMMARY_FILE"
echo "Roll number  : $ROLL_NO" >> "$SUMMARY_FILE"
echo "Comment      : $COMMENT" >> "$SUMMARY_FILE"
echo "---------------------------------------------" >> "$SUMMARY_FILE"
echo "Date         : $CURRENT_DATE" >> "$SUMMARY_FILE"
echo "Hostname     : $HOST_NAME" >> "$SUMMARY_FILE"
echo "Username     : $USER_NAME" >> "$SUMMARY_FILE"
echo "Kernel       : $KERNEL" >> "$SUMMARY_FILE"
echo "Processes    : $PROCESS_COUNT" >> "$SUMMARY_FILE"
echo "--------------- DISK USAGE ------------------" >> "$SUMMARY_FILE"
df -h >> "$SUMMARY_FILE"
echo "Saved summary to $SUMMARY_FILE"

echo
echo "------------------------ VERIFICATION -------------------------"
echo "\$ ls -l $DIR_NAME"
ls -l "$DIR_NAME"
echo
echo "\$ wc -l $PROCESS_FILE"
wc -l "$PROCESS_FILE"
echo
echo "\$ head -n 5 $PROCESS_FILE"
head -n 5 "$PROCESS_FILE"
echo
echo "\$ cat $SUMMARY_FILE"
cat "$SUMMARY_FILE"

echo
echo "==============================================================="
echo "  Done. Report written for $NAME (roll no: $ROLL_NO)"
echo "==============================================================="
