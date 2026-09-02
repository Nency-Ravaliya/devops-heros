#!/bin/bash

read -p "Enter a number: " num

if (( $num % 2 == 0 )); then
    echo "Even number!"
else
    echo "Odd number!"
fi