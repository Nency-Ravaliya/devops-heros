#!/bin/bash

# Write a Bash script that asks the user to enter their electricity units consumed.
# Your program should print:
# If units are less than 0 → "Invalid units"
# If units are equal to 0 → "No electricity consumed"
# If units are greater than 0 and less than or equal to 100 → "Low consumption"
# If units are greater than 100 and less than or equal to 300 → "Medium consumption"
# If units are greater than 300 → "High consumption"

read -p "Enter the electricity units consumed: " units

if [ $units -lt 0 ]; then
  echo "Invalid units"
elif [ $units -eq 0 ]; then
  echo "No electricity consumed"
elif [ $units -gt 0 ] && [ $units -le 100 ]; then    # && should generally be outside the [ ]
  echo "Low consumption"
elif [[ $units -gt 100 && $units -le 300 ]]; then  # or we can also use [[ ... ]], where && can be written inside the condition
  echo "Medium consumption"
else
  echo "High consumption"
fi
