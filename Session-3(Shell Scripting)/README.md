# Shell Scripting Basics

This directory contains introductory examples to shell scripting. Here are some of the basic commands and concepts covered.

## 1. Directory and File Operations (`hello.sh`)
This script demonstrates creating a directory, creating a file, redirecting text to it, and reading from it.
```bash
mkdir hello                
cd hello                    
touch app.log               
echo "This is my logfile" > app.log 
cat app.log                 
```
**Sample Output:**
```
This is my logfile
```

## 2. Variables (`variable.sh`)
This script shows how to declare string and integer variables, and print them using variable expansion (`$name`).
```bash
name="Srujan Gowda"
roll_no=10339
comment="Devopist"

echo "My name is $name"
echo "My roll number is $roll_no"
echo "I am $comment"
```
**Sample Output:**
```
My name is Srujan Gowda
My roll number is 10339
I am Devopist
```

## 3. If/Else Conditions (`if_condtion.sh`)
This script checks numerical conditions using operators like `-lt` (less than) and `-ge` (greater than or equal to).
```bash
read -p "Enter your age: " age

if [ $age -lt 0 ]; then
    echo "Invalid Age"
elif [ $age -ge 0 ] && [ $age -lt 18 ]; then
    echo "You are a minor and not eligible to vote"
else
    echo "You are an adult and eligible to vote"
fi
```

## 4. User Inputs (`input.sh`)
Demonstrates taking input interactively from the user using `read -p`.
```bash
read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
echo  "My name is $name and My roll number is $roll_no"
```

## 5. Loops
### For Loop (`for_loop.sh`)
Iterates through a sequence of numbers from 1 to 5.
```bash
for i in {1..5}
do
    echo "Number: $i"
done
```

### While Loop (`while_loop.sh`)
A counter-based loop using arithmetic evaluation `((count++))`.
```bash
count=1
while [ $count -le 5 ]
do
    echo "Count: $count"
    ((count++))
done
```

## 6. Functions (`function.sh`)
Groups commonly used commands inside functions that can be called repeatedly.
```bash
show_system_user(){
    echo "Hostname: $(hostname)"
    echo "Username: $(whoami)"
}

show_date(){
    date
}

show_system_user
show_date
```

## 7. Practical Task Script (`task.sh`)
This script ties multiple concepts together. It creates a directory, retrieves system information, stores running processes into a file, takes user input, and appends formatted information to `result.log`.
```bash
current_date=$(date) 
echo "Hostname: $(hostname)"
echo "Username: $(whoami)"

ps > process.log

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter your comment: " comment

echo "My name is $name and comment is $comment and date is $current_date" >> result.log
```
