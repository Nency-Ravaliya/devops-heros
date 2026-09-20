# Q : -

# print current date (take input from user for now)
# hostname and username
# process
# add process info inside a file name process.log

# print name,roll_no, comment 

## use variables, take input, create file and directory


read -p "Date enter pls : " date

host=$(hostname)
user=$(whoami)

mkdir process_info
cd process_info
ps > process.log

read -p "Naam nakh taru : " name
read -p "Roll no aapo : " roll
read -p "Comment pls : " comm

echo $date
echo "HostName : $host, UserName : $user"
cat process.log
echo $name $roll $comm
