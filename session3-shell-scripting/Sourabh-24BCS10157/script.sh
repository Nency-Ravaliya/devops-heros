#!/bin/bash

# ─── User Input ────────────────────────────────────────────────────────────────
read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no

# ─── System Variables ──────────────────────────────────────────────────────────
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)
disk_usage=$(df -h)
processes=$(ps -eo pid,user,comm)

# ─── Create Directory & Files ──────────────────────────────────────────────────
dir_name="sysinfo_output"
mkdir -p "$dir_name"
touch "$dir_name/result.log" "$dir_name/process.log"

# ─── Print System Information ──────────────────────────────────────────────────
echo "======================================"
echo "       SYSTEM INFORMATION REPORT      "
echo "======================================"
echo "Name        : $name"
echo "Roll Number : $roll_no"
echo "Date        : $current_date"
echo "Hostname    : $host_name"
echo "Username    : $user_name"

echo ""
echo "======================================"
echo "            DISK USAGE               "
echo "======================================"
echo "$disk_usage"

echo ""
echo "======================================"
echo "         RUNNING PROCESSES (top 10)  "
echo "======================================"
echo "$processes" | head -11

# ─── Write to Files ────────────────────────────────────────────────────────────
echo "$processes" > "$dir_name/process.log"
echo "System info captured on: $current_date" > "$dir_name/result.log"
echo "Name: $name" >> "$dir_name/result.log"
echo "Roll Number: $roll_no" >> "$dir_name/result.log"
echo "Host: $host_name" >> "$dir_name/result.log"
echo "User: $user_name" >> "$dir_name/result.log"

echo ""
echo "Output written to $dir_name/result.log and $dir_name/process.log"