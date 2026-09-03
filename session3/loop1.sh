read -p "Enter your number: " num
sum=0
for ((i=1; i<=$num; i++))
do
    # echo "iteration $i"
    sum=$((sum + i))
done
echo "Sum: $sum"