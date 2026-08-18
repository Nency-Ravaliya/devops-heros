#!/bin/bash

read -p "Enter a number: " num

sum=0
for (( i=1; i<=num; i++ ))
do
  sum=$((sum + i))
done
echo "The sum of numbers from 1 to $num is: $sum"