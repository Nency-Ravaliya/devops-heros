#! /bin/bash

mkdir result
cd result 
touch result.log

today_date=$(date +"%Y-%m-%d")
host_name=$(hostname)
username=$(whoami)
process=$(ps)
diskspace=$(df -h)

read -p "Enter your name: " name
read -p "Enter your roll no: " roll_no
read -p "Enter the comment: " cmt


echo "today's date is $today_date" >> result.log
echo "hostname: $host_name" >> result.log
echo "username: $username" >> result.log
echo "disk space: $diskspace" >> result.log
echo $process > process.log


echo "My name is $name" >> result.log
echo "My roll number is $roll_no" >> result.log
echo "My comment is $cmt" >> result.log