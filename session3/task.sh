# print current data
# hostname and username
# process
# add process info inside a file name process.log

# print name,roll_no, comment 

## use variables, take input, create file and directory 

currdate=$(date)
echo $currdate
hostname=$(hostname)
echo $hostname
username=$(whoami)
echo $username

ps > process.log

read -p "Name:" name
read -p "Roll:" roll

echo "Name: $name"
echo "Roll: $roll"

cat process.log