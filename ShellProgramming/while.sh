#!bin/bash
while true; do
    read -p "Enter a number (or type q to quit): " num
    if [ $num == "q" ]; then
        echo "Exiting the loop"
        break
    elif ! [[ $num =~ ^[0-9]+$ ]]; then
        echo "Invalid"
    fi
    echo "You entered : $num!!"
done
