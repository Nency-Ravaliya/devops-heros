# Number Input Loop

A small Bash script that repeatedly asks the user to enter a number. It validates the input, displays valid numbers, and exits when the user enters `q`.

## Script

```bash
#!/bin/bash

while true; do
    read -p "Enter a number (or 'q' to quit): " input

    if [[ $input == "q" ]]; then
        echo "Exiting the loop."
        break
    elif ! [[ $input =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a valid number."
        continue
    fi

    echo "You entered: $input"
done
```

## How It Works

### 1. Bash interpreter

```bash
#!/bin/bash
```

Tells the system to run the script using Bash.

### 2. Infinite loop

```bash
while true; do
```

Starts a loop that continues until `break` is used.

### 3. Read user input

```bash
read -p "Enter a number (or 'q' to quit): " input
```

Displays a prompt and stores the user's input in the `input` variable.

### 4. Check for `q`

```bash
if [[ $input == "q" ]]; then
    echo "Exiting the loop."
    break
```

If the user enters `q`, the script prints a message and `break` exits the loop.

### 5. Validate the input

```bash
elif ! [[ $input =~ ^[0-9]+$ ]]; then
```

Checks whether the input contains only digits.

The pattern `^[0-9]+$` means:

* `^` — start of input
* `[0-9]` — any digit from 0 to 9
* `+` — one or more digits
* `$` — end of input

Examples of valid input:

```text
0
5
42
12345
```

Examples of invalid input:

```text
abc
12abc
-5
3.14
```

### 6. Handle invalid input

```bash
echo "Invalid input. Please enter a valid number."
continue
```

Displays an error message and uses `continue` to restart the loop.

### 7. Display valid input

```bash
echo "You entered: $input"
```

If the input is a valid number, the script displays it and then asks for another number.

## Flow

```text
Ask for input
      |
      v
   Is it "q"? ---- Yes ---> Exit
      |
      No
      |
      v
 Is it a number?
   /        \
 No          Yes
 |            |
 v            v
Show error   Show number
 |            |
 └──────┬─────┘
        |
        v
   Ask again
```

## Running the Script

Save the script as `script.sh`, then:

```bash
chmod +x script.sh
./script.sh
```

### Example

```text
Enter a number (or 'q' to quit): 42
You entered: 42

Enter a number (or 'q' to quit): hello
Invalid input. Please enter a valid number.

Enter a number (or 'q' to quit): q
Exiting the loop.
```

## Bash Concepts Used

* `while` — creates a loop
* `read` — gets user input
* `if` / `elif` — makes decisions
* `[[ ]]` — performs Bash conditional tests
* `=~` — matches input against a regular expression
* `break` — exits the loop
* `continue` — skips to the next loop iteration
* `$input` — accesses the value stored in the variable
* `echo` — prints text to the terminal
