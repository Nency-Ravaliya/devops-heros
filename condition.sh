#!/bin/bash

read -p "Enter your age: " age

if [ $age -lt 0 ]; then
    echo "Invalid age. Please enter valid age."
elif [ $age -lt 13 ]; then
    echo "You are a child."
elif [ $age -lt 20 ]; then
    echo "You are a teenager."
elif [ $age -lt 90 ]; then
    echo "You are an adult."
else
    echo "You are dead."
fi