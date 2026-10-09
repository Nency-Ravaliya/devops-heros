#!/bin/bash

# Create a directory
mkdir -p hello

# Change to the directory
cd hello

# Add content to the log file , this automatocally creates the file
echo "This is my log file" > app.log

# Display the content of the log file
cat app.log

