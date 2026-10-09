#!/bin/bash
# Script to calculate the sum of numbers from 1 to N

read -p "Enter a number: " num

if ! [[ $num =~ ^[0-9]+$ ]]; then
    echo "Error: Please enter a valid positive integer."
    exit 1
fi

sum=0
for ((i=1; i<=num; i++)); do
    sum=$((sum + i))
done

echo "The sum of numbers from 1 to $num is: $sum"
