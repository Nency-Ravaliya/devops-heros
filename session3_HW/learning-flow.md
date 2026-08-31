# Session 3 Bash Learning Flow

The files below are arranged so that each exercise uses concepts from the files before it.

## 1. `hello.sh` - Create and read a file

Learn:

- `mkdir` to create a directory
- `cd` to move into a directory
- `touch` to create a file
- `>` to write or replace file content
- `cat` to display file content

Practice goal: create a `hello` directory, create `app.log`, write one message, and display it.

## 2. `script1.sh` - Write and append content

Learn:

- The difference between `>` and `>>`
- Adding multiple lines to the same file

Practice goal: create a `test` directory and append two messages to `app.log` without deleting the first message.

## 3. `variable.sh` - Store and reuse values

Learn:

- Assigning variables without spaces around `=`
- Reading variables with `$variable`
- Storing text and numbers
- Avoiding command names as variable names

Practice goal: store a person's name, roll number, and comment, then print a formatted introduction.

## 4. `input.sh` - Accept user input

Learn:

- `read -p` for interactive input
- Saving input in variables
- Printing the values entered by the user

Practice goal: ask for a name and roll number, then display them.

## 5. `test1.sh` - Combine the basic concepts

Learn:

- Combining commands, variables, input, and file output
- `date` for the current date and time
- `df -h` for disk usage
- `ps` for process information
- Saving command output with `>`

Practice goal: create a result directory and log file, collect system information, ask for student details, and save the result.

Note: use `$HOSTNAME` and `$USER` for environment variables. `hostname` and `whoami` are commands, so `$hostname` and `$whoami` do not run those commands.

## 6. `condition.sh` - Make decisions

Learn:

- `if`, `elif`, `else`, and `fi`
- Numeric comparisons such as `-lt`
- Choosing output based on user input

Practice goal: classify an entered age as invalid, child, teenager, or adult.

## 7. `loop.sh` - Repeat a fixed set of values

Learn:

- `for` loops
- Brace expansion such as `{1..5}`
- Reusing a loop variable

Practice goal: print a message for iterations 1 through 5.

## 8. `while_loop1.sh` - Repeat while a condition is true

Learn:

- `while` loops
- Counters and arithmetic with `((count++))`
- Numeric conditions in a loop

Practice goal: count from 0 through 4 and stop automatically.

## 9. `while_loop.sh` - Build an interactive loop

Learn:

- `while true`
- `[[ ... ]]` tests
- Regular-expression validation with `=~`
- `break` to exit
- `continue` to restart an iteration

Practice goal: repeatedly accept numbers, reject invalid input, and quit when the user enters `q`.

## 10. `function.sh` - Reuse a group of commands

Learn:

- Defining a function
- Calling a function
- Grouping related output into a reusable unit

Practice goal: create a function that prints a consistent information section.

## 11. Final project - `system_report.sh`

Create this new script after completing the exercises. It should combine all major concepts:

1. Create a report directory and report file.
2. Store the reporter's name, roll number, and comment in variables.
3. Ask the user for any missing values.
4. Print the date, hostname, username, disk usage, and running processes.
5. Use a function for each report section.
6. Use a condition to validate the roll number or another input.
7. Use a loop to print a short list of report checks.
8. Save the complete report to `system_report.log`.

Suggested run order:

```text
hello.sh -> script1.sh -> variable.sh -> input.sh -> test1.sh
-> condition.sh -> loop.sh -> while_loop1.sh -> while_loop.sh
-> function.sh -> system_report.sh
```

Run each script from the `session3` directory and inspect the files it creates before moving to the next exercise.
