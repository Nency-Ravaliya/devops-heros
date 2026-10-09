# print current date
# hostname and username
# process (ps)
# add process info inside a file name process.log

## use variables, take input, create file and directory

# -----------------------------------------------------

#!/bin/bash

read -p "Enter your name: " name

curDate=$(date)
host=$(hostname)
username=$(whoami)
process=$(ps)

mkdir -p task_output

{
    echo "Name: $name"
    echo "Date: $curDate"
    echo "Hostname: $host"
    echo "Username: $username"
    echo "Process:"
    echo "$process"
} >> task_output/process.log