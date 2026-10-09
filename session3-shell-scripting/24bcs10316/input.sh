# Input name, roll number and comment and print them in separate lines

#! /bin/bash

read -p "Enter your name: " name
read -p "Enter your roll number: " roll
read -p "Enter a comment: " comment

echo -e "My name is $name\nMy roll number is $roll\n$comment"