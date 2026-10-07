#!/bin/bash

curr_date=$(date)
hostname=$(hostname)
username=$(whoami)


read -p "Enter your name: " name
read -p "Enter your roll number: " rollNumber
read -p "Enter your comment: " comment
echo

mkdir -p process_info
cd process_info
echo "$(ps -ef)" > process.log

echo "current date: $curr_date"
echo "hostname: $hostname"
echo "username: $username"

df -h

echo
echo "Name: $name"
echo "Roll Number: $rollNumber"
echo "Comment: $comment"
echo

cat process.log
echo

