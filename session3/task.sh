current_date=$(date)
echo $current_date

echo $hostname
echo $whoami

ps > process.log

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter your comment: " comment

echo "My name is $name"
echo "My roll number is $roll_no"
echo "My comment is: $comment"