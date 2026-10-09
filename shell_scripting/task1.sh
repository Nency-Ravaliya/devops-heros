# print current date
# hostname and username
# process
# add process info inside a file name process.log
# print name, roll_no, comment
# use variables, take input, create file and directory

#!/bin/bash

# take input
read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter a comment: " comment

echo "My name is $name"
echo "My roll number is $roll_no"
echo "I am $comment"

# store command outputs in variables
current_date=$(date)
host=$(hostname)
username=$(whoami)

echo "Date now is $current_date"
echo "Hostname: $host"
echo "Username: $username"

df -h

# create directory and file, then save the process list
mkdir output
cd output
touch process.log

ps > process.log

echo "process.log content:"
cat process.log
