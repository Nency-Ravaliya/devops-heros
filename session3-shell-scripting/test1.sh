#!/bin/bash

mkdir -p result_file
cd result_file
touch result.log
echo "This is my result file" > result.log

date
echo "$(hostname)"
echo "$(whoami)"
df -h
ps > process.log

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no

current_date=$(date)
echo "My name is $name" >> result.log
echo "My roll number is $roll_no" >> result.log
echo "Created on: $current_date" >> result.log
