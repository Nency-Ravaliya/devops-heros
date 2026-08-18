# print current data
# hostname and username
# process
# add process info inside a file name process.log

# print name,roll_no, comment 

## use variables, take input, create file and directory


#!bin/bash

echo "Hostname: "
hostname

echo "Username: "
uname

mkdir tasks
cd tasks
touch process.log

ps > process.log

read -p name
read -p roll_no

current_date = ${date}
