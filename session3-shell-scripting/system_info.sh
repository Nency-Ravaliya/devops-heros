#!/bin/bash

# ==============================================================================
# Script Name: system_info.sh
# Description: Automated System Information & Process Monitoring Script
# Requirements:
#   - Prints current date, hostname, and username
#   - Displays disk usage
#   - Uses variables for data storage
#   - Interactive input using read -p
#   - Directory creation with mkdir
#   - File creation with touch
#   - Stores process list using > redirection
# ==============================================================================

# Header
echo "======================================================"
echo "          SYSTEM INFORMATION MONITORING SCRIPT        "
echo "======================================================"

# 1. Variables to store system information
CURRENT_DATE=$(date)
SYSTEM_HOSTNAME=$(hostname)
CURRENT_USER=$(whoami)

# 2. Display basic system info using variables
echo "Current Date & Time : $CURRENT_DATE"
echo "Hostname            : $SYSTEM_HOSTNAME"
echo "Username            : $CURRENT_USER"
echo "------------------------------------------------------"

# 3. Display Disk Usage
echo "Disk Usage Overview:"
df -h
echo "------------------------------------------------------"

# 4. Take User Input using read -p
read -p "Enter directory name to create (e.g., system_logs): " DIR_NAME
read -p "Enter log filename to create (e.g., process_report.log): " FILE_NAME

# Fallback defaults if user presses Enter
DIR_NAME=${DIR_NAME:-system_logs}
FILE_NAME=${FILE_NAME:-process_report.log}

# 5. Create Directory using mkdir
echo "Creating directory: '$DIR_NAME'..."
mkdir -p "$DIR_NAME"

# 6. Create File using touch
TARGET_FILE="$DIR_NAME/$FILE_NAME"
echo "Creating file: '$TARGET_FILE'..."
touch "$TARGET_FILE"

# 7. Store Running Processes Information in file using > output redirection
echo "Gathering running processes and writing to '$TARGET_FILE'..."
ps aux > "$TARGET_FILE"

echo "------------------------------------------------------"
echo "Process information saved successfully to '$TARGET_FILE'!"
echo "Sample contents of generated process log file (Top 10 lines):"
head -n 10 "$TARGET_FILE"
echo "======================================================"
