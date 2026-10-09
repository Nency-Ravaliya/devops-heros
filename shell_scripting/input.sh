read -p "Naam daal bhai: " name
read -p "rollno daal bhai: " rollno 
read -p "kaise ho bhai: " comment

echo "Welcome $name" > info.txt
echo "your rollno is $rollno" >> info.txt
echo $comment >> info.txt
echo "Thik hai " >> info.txt

cat info.txt
