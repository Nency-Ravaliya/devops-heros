username=$(whoami)
hostname=$(hostname)
date=$(date)
processes=$(df -h)

mkdir -p stats
cd stats

echo "username = $username " > stats.txt
echo "hostname = $hostname " >> stats.txt
echo "date = $date " >> stats.txt
echo "processes = $processes " >> stats.txt
cat stats.txt

read -p "Naam daal bhai: " name
read -p "rollno daal bhai: " rollno 
read -p "kaise ho bhai: " commentl

echo "Welcome $name" >> stats.txt
echo "your rollno is $rollno" >> stats.txt
echo $comment >> stats.txt
echo "Thik hai " >> stats.txt

cat stats.txt
