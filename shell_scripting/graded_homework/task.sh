#!/bin/bash

# create a directory
mkdir demo && cd demo

# current date
echo "Current Date: "
date

# hostname
echo "\nhostname: "
hostname

# username
echo "\nusername: "
whoami

# diskusage
echo "\nDisk Usage: \n" 
df -h

# create a file for storing processes
touch processes
ps -h > processes

echo "\nRunning Processes: \n"
cat processes

# read input from user
read -p "How was your experience ? " feedback

echo "\nThank you for your feedback: $feedback" 