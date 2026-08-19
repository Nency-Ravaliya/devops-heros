#!bin/bash
while true; do
    read -p "Enter a number (or type q to quit): " num
    if [ $num == "q" ]; then
        echo "Exiting the loop"
        break
    elif [[ $num =~ ^[0-9]+$ ]]; then
        echo "Invalid"
    fi
    echo "You entered : $num!!"
done

in the above code we are operating a while loop where it is true always only break when q is entered .
in the while loop we have if a person enter q then it break , If the variable has any letters, spaces, symbols, decimals, or negative signs, the check fails andprints Invalid .
and if it is a valid number then the loop does not end till the num ber a valid number 