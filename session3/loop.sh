read -p "Enter start number: " start
read -p "Enter end number: " end

sum=0

for ((i=start; i<=end; i++))
do
    sum=$((sum + i))
done

echo "Sum = $sum"