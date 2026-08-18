#!/bin/bash
# Task 4: create a directory and a file, then write into the file

dir_name="my_details"
file_name="details.log"

# create the directory only if it does not exist
mkdir -p "$dir_name"
cd "$dir_name" || exit 1

# create the file
touch "$file_name"

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter your comment: " comment

current_date=$(date)

# > creates or overwrites, >> appends
echo "Date       : $current_date" > "$file_name"
echo "Hostname   : $(hostname)" >> "$file_name"
echo "Username   : $(whoami)" >> "$file_name"
echo "Name       : $name" >> "$file_name"
echo "Roll number: $roll_no" >> "$file_name"
echo "Comment    : $comment" >> "$file_name"

# keep a copy of the process info here as well
ps > process.log

echo ""
echo "Contents of $dir_name/$file_name :"
cat "$file_name"
