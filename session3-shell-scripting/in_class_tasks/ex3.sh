# Q : -

# Print current date (take input from user for now)
# Hostname and username
# Process information
# Add process information inside a file named process.log

# Print name, roll_no, and comment

## Use variables, take input, create a file and directory


read -p "Please enter the date: " date

host=$(hostname)
user=$(whoami)

mkdir process_info
cd process_info
ps > process.log

read -p "Please enter your name: " name
read -p "Please enter your roll number: " roll
read -p "Please enter your comment: " comm

echo $date
echo "HostName : $host, UserName : $user"
cat process.log
echo $name $roll $comm