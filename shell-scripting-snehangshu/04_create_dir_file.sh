#!/bin/bash

dir_name="my_details"
file_name="$dir_name/details.txt"

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter a comment: " comment

if [ -d "$dir_name" ]; then
    echo "Directory $dir_name already exists"
else
    mkdir "$dir_name"
    echo "Directory $dir_name created"
fi

echo "Date     : $(date)" > "$file_name"
echo "Hostname : $(hostname)" >> "$file_name"
echo "Username : $(whoami)" >> "$file_name"
echo "Name     : $name" >> "$file_name"
echo "Roll No  : $roll_no" >> "$file_name"
echo "Comment  : $comment" >> "$file_name"

ps -ef > "$dir_name/process.log"

echo
echo "Details written to $file_name"
cat "$file_name"
