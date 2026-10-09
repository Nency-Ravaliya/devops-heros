#!//bin/bash

cd hello
ls 

# name="Aryan Sirohi"
# rollno=10283
# comment="This is a simple bash script that prints the name and roll number of a student."

# echo "Name: $name"
# echo "Roll Number: $rollno"
# echo "$comment"


#QUESTION:  
# print current data
# hostname and username
# process
# add process info inside a file name process.log
# print name,roll_no, comment 
## use variables, take input, create file and directory

touch process.log
ps > process.log
hostname >> process.log
whoami >> process.log

# process=$(ps)
# hostname=$(hostname)
# username=$(whoami)
# echo $process > process.log
# echo $hostname >> process.log
# echo $username >> process.log
cat process.log
