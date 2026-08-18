# print date
echo "Current date and time: $(date)"

# print hostname and username
echo "Hostname: $(hostname)"
echo "Username: $(whoami)"

# add process info inside a file name process.log
echo "Process information:" > process.log
ps -e >> process.log

# print name, rollnumber, comment
read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter your comment: " comment

echo  "My name is $name"
echo "My roll number is $roll_no"
echo "I am $comment"