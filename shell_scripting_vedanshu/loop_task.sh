#!/bin/bash

sum=0;
read -p "Enter your number: " num
for((i=1;i<=num;i++))
do
    sum=$((sum + i))
done

echo $sum
