#!/bin/bash

# print current data
# hostname and username
# process
# add process info inside a file name process.log

# print name,roll_no, comment 

## use variables, take input, create file and directory
mkdir result_file
cd result_file

echo "This is my result file" > result.log

curr_date=$(date)
hostname=$(hostname)
username=$(whoami)
process=$(ps)

echo $curr_date
echo $hostname
echo $username
echo $process > process.log
cat process.log
