#!/bin/bash

num=$(( (RANDOM % 100) + 1 ))
guess=0

echo "--- Welcome to Guess the Number! ---"
echo "I have picked a secret number between 1 and 100."
echo ""

while [ $guess -ne $num ];
do
    read -p "Enter your guess: " guess
    
    if [ $guess -lt $num ]; then
        echo "Too low! Try again."
    elif [ $guess -gt $num ]; then
        echo "Too high! Try again."
    else
        echo "Congratulations! You guessed the number $num."
    fi
done