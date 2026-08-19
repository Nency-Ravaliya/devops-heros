# print current data
echo "Current date: "
date

echo "Hostname: $(hostname)"
echo "Username: $(whoami)"

echo "Running Processes: "
ps

ps > processes.log
cat processes.log

read -p "Enter name: " name
read -p "Enter rollno: " rollno
read -p "Comment: " comment