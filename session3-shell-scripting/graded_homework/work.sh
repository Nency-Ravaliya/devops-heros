#!/bin/bash

# Prints the current date.
# Prints the hostname.
# Prints the username.
# Prints the disk usage.
# Prints the running processes.
# Uses variables to store and use data.
# Takes user input using read -p.
# Creates a directory using mkdir.
# Creates a file using touch.
# Stores running process information in a file using > redirection.

mkdir folder
cd folder

read -p "Enter today's date : " date

host=$(hostname)
user=$(whoami)
usage=$(df -h)

touch processs.txt
ps > processs.txt

echo "------------------------ OUTPUT ------------------------"
echo "TODAY'S DATE : $date"
echo "HOST : $host"
echo "USER : $user"
echo "DISK USAGE :-"
echo "$usage"
echo "PROCESS DATA :-"
cat processs.txt