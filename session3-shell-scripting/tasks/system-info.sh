#!/bin/bash
# Session 3 - Shell Scripting
# System Information Script
#
# Run: bash system-info.sh
# Screenshot: the printed system info, the two prompts, and the confirmation lines.

# ---- Variables: command substitution runs once, up front ------------------
# $(...) captures a command's output into a variable. Doing it here means every
# later use prints the same snapshot instead of re-running the command.
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

# ---- Print the system information ----------------------------------------
echo "=============== SYSTEM INFORMATION ==============="
echo "Current date : $current_date"
echo "Hostname     : $host_name"
echo "Username     : $user_name"
echo

echo "--- Logged in users (who) ---"
# who reads /var/run/utmp, which WSL does not always populate. Fall back to the
# current user so the section is never blank.
who
if [ -z "$(who)" ]; then
    echo "(who returned nothing - not a login shell; current user is $user_name)"
fi
echo

echo "--- Disk usage (df -h) ---"
df -h
echo

echo "--- Running processes (ps) ---"
ps
echo

# ---- Take user input with read -p ----------------------------------------
# -p prints the prompt on the same line, then reads one line into the variable.
echo "=============== USER DETAILS ==============="
read -p "Enter your name: "        name
read -p "Enter your roll number: " roll_no
read -p "Enter your comment: "     comment
echo

echo "My name is $name"
echo "My roll number is $roll_no"
echo "My comment is: $comment"
echo

# ---- Create a directory and a file ---------------------------------------
read -p "Enter output directory name [logs]: " dir_name
read -p "Enter process log filename [processes.txt]: " file_name

# ${var:-default} expands to "default" when var is unset OR empty. Without this,
# pressing ENTER leaves file_name empty, the path collapses to "$dir_name/", and
# the redirection below fails with "Is a directory".
dir_name="${dir_name:-logs}"
file_name="${file_name:-processes.txt}"
echo "Using directory: $dir_name"
echo "Using filename : $file_name"
echo

# -p so a re-run does not fail with "File exists".
mkdir -p "$dir_name"
echo "Created directory: $dir_name"

# touch creates the file up front, before anything writes to it.
touch "$dir_name/$file_name"
echo "Created file: $dir_name/$file_name"
echo

# ---- Store process info in the file using > ------------------------------
# > overwrites, so the file always holds one clean snapshot.
# >> would append instead, growing the file on every run.
ps aux > "$dir_name/$file_name"
echo "Saved running processes to $dir_name/$file_name"
echo

# ---- Also record the user details, this time appending with >> -----------
details_file="$dir_name/details.log"
echo "Name        : $name"    >  "$details_file"
echo "Roll number : $roll_no" >> "$details_file"
echo "Comment     : $comment" >> "$details_file"
echo "Recorded on : $current_date" >> "$details_file"
echo "Saved user details to $details_file"
echo

# ---- Show what was written -----------------------------------------------
echo "--- $details_file ---"
cat "$details_file"
echo

echo "--- first 10 lines of $dir_name/$file_name ---"
head -n 10 "$dir_name/$file_name"
echo

echo "--- ls -l $dir_name ---"
ls -l "$dir_name"
