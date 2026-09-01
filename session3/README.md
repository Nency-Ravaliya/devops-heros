# Shell Scripting Tasks

This repository contains several basic shell scripts demonstrating fundamental concepts in Bash scripting, including taking user input, file and directory operations, conditional statements, and loops.

## 1. Task (`task.sh` & `task.md`)
**What we have done**: We created a script that gathers system information and user details, and saves them into a specific directory and log files.

**Requirements**: 
- Print current date, hostname, username, and running processes.
- Add process information inside a file named `process.log`.
- Take user input for name, roll number, and a comment, then print them.
- Use variables, take input, and create files and directories.

**Logic Applied**: 
- The script uses `mkdir` and `cd` to create and enter a `result` directory.
- It uses built-in commands like `date`, `hostname`, `whoami`, `ps`, and `df -h` and stores their outputs in variables.
- It uses `read -p` to take user input interactively.
- Finally, it redirects the outputs to `result.log` using `>>` (append) and to `process.log` using `>` (overwrite).

## 2. Conditions (`condition1.sh`)
**What we have done**: We created an electricity bill estimator based on the units consumed by a user.

**Requirements**:
- Ask the user to enter their electricity units consumed.
- Categorize consumption:
  - < 0: "Invalid units"
  - = 0: "No electricity consumed"
  - 1-100: "Low consumption"
  - 101-300: "Medium consumption"
  - > 300: "High consumption"

**Logic Applied**:
- The script takes input using `read -p`.
- It uses an `if-elif-else` ladder to evaluate the units.
- It demonstrates both standard single-bracket `[ ]` conditions with external logical operators (like `&&`) and double-bracket `[[ ]]` conditions which allow internal logical operators. It uses numerical comparison operators like `-lt` (less than), `-eq` (equal to), `-gt` (greater than), and `-le` (less than or equal to).

## 3. For Loops (`forloop.sh`)
**What we have done**: We demonstrated different ways to use a `for` loop, specifically focusing on skipping a specific iteration.

**Requirements**:
- Loop through a range and print the iteration number.
- Perform the same loop but exclude the number `5`.

**Logic Applied**:
- The script uses the brace expansion `{1..5}` to iterate through numbers 1 to 5.
- It shows three ways to exclude the number 5:
  1. Simply looping up to 4 instead (`{1..4}`).
  2. Using an `if` condition with the `continue` statement to skip the rest of the loop block when `i` equals 5.
  3. Using an `if` condition with the `-ne` (not equal) operator to only print when `i` is not 5.

## 4. Loops and Game (`loops.sh`)
**What we have done**: We wrote two programs using loops: one filtering even/odd numbers and a number guessing game.

**Requirements**:
- **For loop**: Go through numbers 1 to 20, print only the even numbers, and state when an odd number is being skipped.
- **While loop**: Set a secret number (7). Repeatedly ask the user to guess it. Tell the user if their guess is too high or too low. Once they guess correctly, print a success message along with the total number of attempts.

**Logic Applied**:
- **For loop**: Uses arithmetic context `((i % 2 == 0))` to check for even numbers (modulo operator). It prints the even number and uses the `else` block to announce skipped odd numbers.
- **While loop**: Uses an infinite loop `while true`. It increments an `attempts` counter variable on each iteration using `((attempts++))`. It then uses an `if-elif-else` statement to compare the user's guess (`$num`) against the `$secret_num` (7). When the guess is correct, it prints the attempts and uses `break` to exit the infinite loop.
