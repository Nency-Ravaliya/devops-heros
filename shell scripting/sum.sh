read -p "Enter any number : " num
sum=0

for ((i=1; i<=num; i++))
do 
    sum=$((sum+i))
done 

echo "Sum : $sum" 