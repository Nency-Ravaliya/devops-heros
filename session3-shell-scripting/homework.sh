#!/bin/bash

clear

CURRENT_DATE=$(date)
SYSTEM_HOSTNAME=$(hostname)
CURRENT_USER=$(whoami)
DISK_USAGE=$(df -h)

echo "[+] Current Date & Time : ${CURRENT_DATE}"
echo "[+] System Hostname     : ${SYSTEM_HOSTNAME}"
echo "[+] Active Username     : ${CURRENT_USER}"
echo ""

echo "DISK USAGE OVERVIEW"
echo ""
echo "${DISK_USAGE}"
echo ""


echo "[+] Setting up log directory and process file..."
read -p "Enter directory name to create [default: system_logs]: " TARGET_DIR
TARGET_DIR=${TARGET_DIR:-system_logs}

read -p "Enter log filename to save running processes [default: process_list.txt]: " TARGET_FILE
TARGET_FILE=${TARGET_FILE:-process_list.txt}

echo ""
echo "[+] Processing your input..."

echo "[+] Executing: mkdir -p ${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

FILE_PATH="${TARGET_DIR}/${TARGET_FILE}"
echo "[+] Executing: touch ${FILE_PATH}"
touch "${FILE_PATH}"

echo "[+] Collecting running processes using 'ps aux'..."
ps aux > "${FILE_PATH}"

echo ""
echo " SUCCESS: Running processes stored successfully!"
echo " Log Saved At : ${FILE_PATH}"
echo " Log File Size: $(wc -c < "${FILE_PATH}") bytes"
echo " Total Lines  : $(wc -l < "${FILE_PATH}") lines"
echo ""
echo "[+] First 10 lines of stored processes log:"
head -n 10 "${FILE_PATH}"