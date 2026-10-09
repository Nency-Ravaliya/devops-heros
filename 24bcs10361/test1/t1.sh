#!/bin/bash
# print current data
# hostname and username
# process
# add process info inside a file name process.log

# print name,roll_no, comment 

## use variables, take input, create file and directory
mkdir result
cd result
echo "This is the result file" > result.log
date
echo "Current Date: $(date)"
echo "Hostname: $(hostname)"
echo "Username: $(whoami)"

df -h
ps > process.log

read -p "Enter your name: " name
read -p "Enter your roll number: " roll

current_date=$(date)
echo "Name: $name" >> result.log

