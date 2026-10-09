mkdir log_dir
cd log_dir

date > results.log

host=$(hostname)
user=$(whoami)

echo "Host: $host" >> results.log
echo "User: $user" >> results.log

ps > processes.log

read -p "Enter your name: " name
read -p "Enter your roll number: " rollno
read -p "Enter your comment: " comment

cat results.log

echo "Processes: "
cat processes.log