echo "Current Date: $(date)" 
echo "Hostname: $(hostname)"
echo "Usename: $(whoami)"

mkdir logs
cd logs
ps aux > process.log

read -p "Enter your name: " name
read -p "Enter your rollno: " rollno
read -p "Anddd your comment: " comment

echo "My name is $name, rollno: $rollno and your comment is $comment"