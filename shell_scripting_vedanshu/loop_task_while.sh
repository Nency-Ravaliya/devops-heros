#!/bin/bash

sum=0;
read -p "Enter your number: " num
while [ $num -gt 0 ]
do
    sum=$((sum + num))
    num=$((num-1))
done

echo $sum
