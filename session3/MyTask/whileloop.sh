#!/bin/bash

while true; do
    read -p "Enter a number (or 'e' to exit): " input

    if [[ $input == "e" ]]; then
        echo "Exiting the loop."
        break
    elif ! [[ $input =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a valid number."
        continue
    fi

    echo "You entered: $input"
done