
#!/bin/bash

while true; do
    read -p "enter a number (or 'q' to quit): " input

    if [[ $input == "q" ]]; then
        echo "exiting the loop!"
        break
    elif ! [[ $input =~ ^[0-9]+$ ]]; then
        echo "invalid input, enter a valid number"
        continue
    fi

    echo "you entered: $input"
done
