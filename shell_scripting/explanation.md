# Shell Scripting Overview & Explanations

This folder contains shell script examples covering foundational Bash scripting concepts such as conditional statements, infinite loops with validation, standard while loops, and functions.

---

## 1. `conditions.sh` — Conditional Statements (`if-else`)

Demonstrates interactive user input handling and numeric comparison using `if-else` branching.

### Code
```bash
read -p "Enter age: " age

if [ $age -lt 18 ]; then
    echo "You are a minor"
else
    echo "You are an adult"
fi
```

### Explanation
- **`read -p "Enter age: " age`**: Prompts the user with `"Enter age: "` and stores the entered value in the variable `$age`.
- **`if [ $age -lt 18 ]; then`**: Evaluates whether the value of `$age` is strictly **less than** (`-lt`) `18`.
- **`echo "You are a minor"`**: Executes if the condition evaluates to true (age < 18).
- **`else ... echo "You are an adult"`**: Executes if the condition is false (age >= 18).
- **`fi`**: Marks the end of the `if-else` block.

---

## 2. `while_loop.sh` — Infinite Loop with Validation & Break/Continue

Demonstrates an interactive loop using `while true` along with pattern matching (`regex`), `break`, and `continue` control flow statements.

### Code
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

### Explanation
- **`while true; do`**: Starts an infinite loop that runs until explicitly stopped.
- **`read -p ... input`**: Takes user input on every iteration.
- **Exit Condition (`break`)**: If `$input == "q"`, it prints an exit message and terminates the loop using `break`.
- **Input Validation (`continue`)**: `! [[ $input =~ ^[0-9]+$ ]]` uses regular expressions to check if the input is **not** a valid integer. If invalid, `continue` skips the rest of the loop and prompts the user again.
- **`echo "You entered: $input"`**: Prints the valid number when validation succeeds.

---

## 3. `while_loop1.sh` — Counter-based While Loop

Demonstrates a standard counted `while` loop that iterates until a condition evaluates to false.

### Code
```bash
#!/bin/bash

count=0
while [ $count -lt 5 ]
do
  echo "This is iteration number $count"
  ((count++))
done
```

### Explanation
- **`count=0`**: Initializes the counter variable `count` to `0`.
- **`while [ $count -lt 5 ]`**: Runs the loop body as long as `$count` is strictly **less than 5** (`0`, `1`, `2`, `3`, `4`).
- **`echo "This is iteration number $count"`**: Outputs the current iteration index.
- **`((count++))`**: Increments the `count` variable by `1` using arithmetic evaluation on each pass.
- **`done`**: Closes the loop block once `count` reaches `5`.

---

## 4. `functions.sh` — Bash Functions

Demonstrates defining and invoking reusable functions in Bash.

### Code
```bash
#!/bin/bash

show_info(){
  echo "This is a function"
  echo "This is a function to show information"
}

show_info()
```

### Explanation
- **`show_info(){ ... }`**: Defines a reusable function block named `show_info`.
- **Function Body**: Encapsulates commands (`echo`) to display informational messages.
- **`show_info()`**: Calls and executes the function.
