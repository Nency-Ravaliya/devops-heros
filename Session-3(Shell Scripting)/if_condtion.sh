#!/bin/bash

read -p "Enter your age: " age

if [ $age -lt 0 ]; then
    echo "Invalid Age"
elif [ $age -ge 0 ] && [ $age -lt 18 ]; then
    echo "You are a minor and not eligible to vote"
else
    echo "You are an adult and eligible to vote"
fi