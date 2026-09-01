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


This script runs an endless loop (while true) that keeps asking you to type a number.

Here is how it handles what you type:

If you type 'q': It stops the loop and the program ends.
If you type letters or symbols: It notices it's not a number, gives you an "Invalid input" warning, and asks again.
If you type a valid number: It just repeats the number back to you and starts the cycle all over again.