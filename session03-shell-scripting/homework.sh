#!/bin/bash

date=$(date)
hostname=$(hostname)
username=$(whoami)

#Print sys info
echo "current date: $date"
echo "Hostname: $hostname"
echo "Username: $username"

echo "disk usage: "
df -h

#Make dir
read -p "Enter a dir name: " dir_name

mkdir -p $dir_name
cd $dir_name

#Store info in file
echo "current date: $date" > file.txt
echo "Hostname: $hostname" >> file.txt
echo "Username: $username" >> file.txt

echo "" >> file.txt

df -h >> file.txt

echo "" >> file.txt

ps aux >> file.txt

echo "" >> file.txt
echo ""

echo "Directory created and information stored in $dir_name/file.txt"