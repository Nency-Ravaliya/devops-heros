#!/bin/bash

CURRENT_DATE=$(date)
HOST_NAME=$(hostname)
USER_NAME=$(whoami)

echo "==============================================="
echo "Date & Time: $CURRENT_DATE"
echo "Host name: $HOST_NAME"
echo "User name: $USER_NAME"
echo "==============================================="
echo "Disk Usage"
df -h
echo ""

read -p "Enter directory name to create: " DIR_NAME
read -p "Enter log filename to create: " FILE_NAME

mkdir -p "$DIR_NAME"
touch "$DIR_NAME/$FILE_NAME"
echo "Create directory '$DIR_NAME' and file '$FILE_NAME' ."

ps aux > "$DIR_NAME/$FILE_NAME"
echo "Successfully send running processs into $DIR_NAME/$FILE_NAME"

