# print current date
# hostname and username
# process (ps)
# add process info inside a file name process.log

## use variables, take input, create file and directory

# ----------

#!/bin/bash

curDate=$(date)
host=$(hostname)
username=$(whoami)

mkdir task1_output

echo "Date now is $curDate" >> task1_output/process.log
echo "Hostname: $host" >> task1_output/process.log
echo "Username: $username" >> task1_output/process.log

# echo "Date now is $(date)"
# echo "Hostname: $(hostname)"
# echo "Username: $(whoami)"

# date
# hostname
# whoami
# df -h

process=$(ps)
echo "process: $process" >> task1_output/process.log
# echo "process.log content:" $cat task1_output/process.log