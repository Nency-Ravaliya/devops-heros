# Bash While Loop

## What this code does

It keeps asking the user for a number.

- Enter a **number** → prints the number.
- Enter **e** → exits the loop.
- Enter anything else → shows an error and asks again.

## Code Explanation

```bash
while true; do
```
true is always true, so the loop keeps running until break.

```bash
    read -p "Enter a number (or 'e' to exit): " input
```
takes an input from the user

```bash
    if [[ $input == "e" ]]; then
        echo "Exiting the loop."
        break
```
if user enters e then a statement is printed and loop exists

```bash
    elif ! [[ $input =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a valid number."
        continue
    fi
```
if user enters anything apart from numbers then it is considered as an invalid input and loop continues

```bash
    echo "You entered: $input"
done
```

this prints the number entered by the user if its a valid entry