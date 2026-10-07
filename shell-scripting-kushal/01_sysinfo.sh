#!/bin/bash
# print current date, hostname, username and processes
# save process info inside process.log

echo "Date     : $(date)"
echo "Hostname : $(hostname)"
echo "Username : $(whoami)"

echo "Processes:"
ps -e

ps -e > process.log
echo "Process info saved to process.log"
