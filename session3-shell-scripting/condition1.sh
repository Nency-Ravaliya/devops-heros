#!/bin/bash

read -s -p "Enter password: " password
echo ""

if [ -z "$password" ]; then
    echo "Password cannot be empty. Please enter a valid password."
    exit 1
fi

length=${#password}

if [ $length -lt 6 ]; then
    echo "Weak password. Password must be at least 6 characters long."
elif [ $length -lt 10 ]; then
    echo "Moderate password. Consider using a longer password for better security."
else
    echo "Strong password."
fi


