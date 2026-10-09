#!/bin/bash

# for loop
# Write a Bash script that uses a for loop to go through the numbers 1 to 20.

# Your program should:
# Print only the even numbers
# Skip the odd numbers

for i in {1..20}
do 
  if ((i % 2 == 0)); then   # [ ] for tests, and (( )) for arithmetic 
    # Inside arithmetic context (( )), Bash automatically treats i as a variable hence we didn't put $
    echo "Even Number: $i"
  else
    echo "Skipping $i"
  fi 
done


# while loop

# Write a Bash script that repeatedly asks the user to guess a secret number.
# Set the secret number to 7.
# Your program should:
# Keep asking the user to enter a number.
# If the guess is less than 7, print: Too low!
# If the guess is greater than 7, print: Too high!
# If the guess is equal to 7, print: Correct! You guessed it and exit the loop.
# Keep track of how many attempts the user makes.
# When they guess correctly, print: You got it in 4 attempts! (example)

secret_num=7
attempts=0

while true
do
  read -p "Enter a number: " num
  ((attempts++))

  if [ $num -lt $secret_num ]; then
    echo "Too low!"
  elif [ $num -gt $secret_num ]; then
    echo "Too high!"
  else
    echo "Correct! You guessed it"
    echo "You got it in $attempts attempt(s)!"
    break
  fi
done 