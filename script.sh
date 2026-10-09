#!/bin/bash

mkdir -p result_file
cd result_file
touch result.log
echo "This is my result file" > result.log
date
echo $hostname
echo $whoami
df -h
ps > process.log

read -p "Enter your name: " name
read -p "Enter your roll number " roll_no

current_date=$(date)

echo "Hi I am $name" >> result.log
echo "Today is $current_date" >> result.log 