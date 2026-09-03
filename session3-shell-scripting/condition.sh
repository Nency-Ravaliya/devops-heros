#!/bin/bash

read -p "Enter your age: " age

if [ $age -lt 0 ]; then
    echo "Invalid age. Please enter a valid age."
elif [ $age -lt 13 ]; then
    echo "You are a child."
elif [ $age -lt 20 ]; then
    echo "You are a teenager."
else
    echo "You are an adult."
fi