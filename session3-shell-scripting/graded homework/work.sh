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
# Stores the running processes information in the file using > output redirection.


mkdir folder
cd folder
read -p "Bhai date daal aaj ki : " date
host=$(hostname)
user=$(whoami)
usage=$(df -h)
touch processs.txt
ps > processs.txt

echo "------------------------OUTPUT----------------------------"
echo "Aaj ki date hai, $date, magic!"
echo "HOST : $host"
echo "USER : $user"
echo "DISK USAGE :- "
echo $usage
echo "Process Data :-"
cat processs.txt


