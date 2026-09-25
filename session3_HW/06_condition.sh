#!/bin/bash

read -p "Enter your age: " age

if [ $age -lt 0 ]; then
    echo "Invalid age"
elif [ $age -lt 18 ]; then
    echo "You are not elligible for voting."
else
    echo "You are elligble for voting"
fi