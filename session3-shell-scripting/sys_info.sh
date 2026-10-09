#!/bin/bash
# ==============================================================================
# Script Name: sys_info.sh
# Description: System Information Script collecting system metrics and process data
# ==============================================================================

echo "======================================================"
echo "          SYSTEM INFORMATION REPORT SCRIPT           "
echo "======================================================"

# 1. Variables to store and use system information
CURRENT_DATE=$(date)
SYSTEM_HOSTNAME=$(hostname)
CURRENT_USER=$(whoami)

# 2. Print collected information
echo ""
echo "[*] Date & Time : $CURRENT_DATE"
echo "[*] Hostname    : $SYSTEM_HOSTNAME"
echo "[*] Current User: $CURRENT_USER"

# 3. Print Disk Usage using df
echo ""
echo "======================================================"
echo "                   DISK USAGE (df -h)                 "
echo "======================================================"
df -h

# 4. Print Running Processes using ps
echo ""
echo "======================================================"
echo "             RUNNING PROCESSES (Top 10)               "
echo "======================================================"
ps aux | head -n 11

# 5. Take user input using read -p
echo ""
echo "======================================================"
echo "                    USER INPUT                        "
echo "======================================================"
read -p "Enter your full name: " USER_NAME
read -p "Enter your student/roll number: " ROLL_NO
read -p "Enter a comment for this report: " USER_COMMENT

echo ""
echo "Summary of Input:"
echo "-> Student Name : $USER_NAME"
echo "-> Roll Number  : $ROLL_NO"
echo "-> Comment      : $USER_COMMENT"

# 6. Create a directory using mkdir
OUTPUT_DIR="output_data"
echo ""
echo "[+] Creating output directory: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 7. Create a file using touch
LOG_FILE="$OUTPUT_DIR/running_processes.log"
echo "[+] Creating file: $LOG_FILE"
touch "$LOG_FILE"

# 8. Store the running processes information in the file using > output redirection
echo "[+] Saving running processes into $LOG_FILE using '>' output redirection..."
ps aux > "$LOG_FILE"

echo ""
echo "[✓] Task completed successfully!"
echo "[✓] Process details saved to: $LOG_FILE"
echo "======================================================"
