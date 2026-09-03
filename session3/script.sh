#!/bin/bash

date > output.log
hostname >> output.log
whoami >> output.log
df -h >> output.log
ps aux >> output.log
read -p "Enter your name: " name
echo "Hello, $name!" >> output.log
mkdir test_folder
touch test_folder/test_file.txt
cat output.log

