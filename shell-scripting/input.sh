#!/bin/bash

read -p "Enter your name: " _name
read -p "Enter your roll no: " _roll
read -p "Enter your comments: " _comm

echo -e "Comment posted successfully with the following data:\n\t$_name\n\t$_roll\n\t$_comm"
