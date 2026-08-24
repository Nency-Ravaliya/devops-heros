#!/bin/bash

date
echo $(hostname)
echo $(whoami)

ps > process.log

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter comment": comment

echo "My name is $name"
echo "My roll number is $roll_no"
echo "Comment: $comment"
