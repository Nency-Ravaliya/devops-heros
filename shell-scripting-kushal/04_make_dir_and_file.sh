#!/bin/bash
# create a directory and a file, store the details inside the file

out_dir="student_records"
out_file="$out_dir/record.txt"

mkdir -p "$out_dir"

read -r -p "Name    : " u_name
read -r -p "Roll No : " u_roll
read -r -p "Comment : " u_comment

{
    echo "Date     : $(date)"
    echo "Hostname : $(hostname)"
    echo "Username : $(whoami)"
    echo "Name     : $u_name"
    echo "Roll No  : $u_roll"
    echo "Comment  : $u_comment"
} > "$out_file"

echo "Details saved to $out_file"
cat "$out_file"
