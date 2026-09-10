mkdir result_file
cd result_file
touch result.log
echo "This is my result file" > result.log
date
echo $hostname
echo $whoami
df -h
ps > process.log

read -p "Enter your name: " name
read -p "Enter your roll number; " roll_number

current_date=$(date)
echo "Name: $name" >> result.log
echo "Roll Number: $roll_number" >> result.log
echo "Current Date: $current_date" >> result.log