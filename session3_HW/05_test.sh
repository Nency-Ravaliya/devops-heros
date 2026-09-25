#!/bin/bash
mkdir results
cd results
touch result.log
date
echo "$(hostname)"
echo "$(whoami)"

df -h 
ps > process.log 

read -p "Enter Student's name: " name
read -p "Enter marks " marks 
current_date=$(date)
echo "$name got $marks percentage - $current_date" >> result.log
