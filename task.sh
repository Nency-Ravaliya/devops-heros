#!/bin/bash

mkdir task
cd task
# print current date
echo "Current Date: $(date)"> task.log
# process
echo "Process : $(ps) ">> task.log
# hostname and username
echo "Hostname: $(hostname) and username $(whoami)" >> task.log

# add process info inside a file name process.log
echo "Process Info: $(ps )" > process.log
echo "disk usage: $(df -h)" >> process.log
# print name,roll_no, comment 


read -p "Enter your name: " variable
read -p "Enter your roll number: " roll_no
read -p "Enter your comment: " comment
echo "Name: $variable, Roll No: $roll_no, Comment: $comment"

# use variables, take input, create file and directory










 
