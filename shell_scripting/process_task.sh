# print current date
# hostname and username
# process
# add process info inside a file name process.log

# print name,roll_no, comment 

## use variables, take input, create file and directory

mkdir log_dir && cd log_dir
DATE

# hostname and username
user=$(whoami)
hostname=$(hostname)
echo "username: $user"
echo "hostname: $hostname"

# process

ps > process.log 

# name roll no comment
read -p "Enter your name: " name
read -p "Enter your roll no: " rollno
read -p "Enter your comment: " comment

echo "name: $name"
echo "roll no: $rollno"
echo "comment: $comment"

# printing ps
echo "Processes: "
cat process.log
