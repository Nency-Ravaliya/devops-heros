# Explanation of `while_loop.sh`

This Bash script repeatedly asks the user to enter a number. It uses `while true` to create an infinite loop, which continues until the user chooses to exit.

Inside the loop, `read -p` displays a prompt and stores the user's response in the variable `input`. The script then checks the value:

- If the user enters `e`, it prints an exit message and uses `break` to stop the loop.
- If the input contains anything other than digits, it prints an error message. The `continue` command skips the remaining code and starts the next loop iteration.
- If the input is valid, the script displays the entered number and asks for input again.

The regular expression `^[0-9]+$` ensures that the input contains one or more digits from beginning to end. Therefore, values such as `0`, `7`, and `125` are accepted, while text, decimal values, and negative numbers are rejected.

Example output:

```text
Enter a number (or 'e' to exit): 25
You entered: 25
Enter a number (or 'e' to exit): hello
Invalid input. Please enter a valid number.
Enter a number (or 'e' to exit): e
Exiting the loop.
```

Overall, the script demonstrates user input, an infinite `while` loop, conditional statements, input validation, and the use of `break` and `continue` in Bash.
