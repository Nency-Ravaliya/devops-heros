#!/bin/bash

# location where bash is stored
# it is called as shebang

# name="Mayank Soni"
# rollno="24bcs10127"
# comment="This devops class is awesome!"

# echo "Hello, I'm $name and my roll no is $rollno. Here are my thoughts about devops class, $comment"

read -p "Enter your name: " name
read -p "Enter your roll no: " rollno
read -p "Enter your comment: " comment
# -p: prompts the msg to user

echo "Hello, I'm $name and my roll no is $rollno. Here are my thoughts about devops class, $comment"