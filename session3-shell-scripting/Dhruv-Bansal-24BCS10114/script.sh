#!/usr/bin/env bash
set -euo pipefail

read -r -p "Enter your name: " name
read -r -p "Enter your roll number: " roll_no
read -r -p "Enter your comment: " comment

mkdir -p sysinfo_output

{
  echo "Date: $(date)"
  echo "Hostname: $(hostname)"
  echo "Username: $(whoami)"
  echo "Logged-in users:"
  who
  w
  echo "Name: $name"
  echo "Roll number: $roll_no"
  echo "Comment: $comment"
} | tee sysinfo_output/result.log

ps > sysinfo_output/process.log
echo "Process list saved to sysinfo_output/process.log"
