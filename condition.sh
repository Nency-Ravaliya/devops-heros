#!/bin/bash
read -p "Enter your age: " age

if [ $age -lt 0 ] || [ $age -gt 120 ]; then
    echo "Invalid age. Please enter a valid age."
elif [ $age -lt 18 ]; then
    echo "You are a minor."
else
    echo "You are an adult."
fi