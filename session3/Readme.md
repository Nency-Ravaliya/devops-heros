# Session 3 — Shell Scripting

This session covers the fundamentals of **Shell Scripting** through practical scripts involving variables, user input, command substitution, loops, conditions, file creation, and process management.

---

## 1. Variables — `variable.sh`

This script demonstrates how to:

* Declare and assign variables.
* Store strings and numbers.
* Access variable values using `$variable`.
* Print variable values using `echo`.

### Code

```bash
name="Tanmay Mittal"
roll_no=10491
comment="I am a DevOps Engineer."

echo "My name is $name"
echo "My roll number is $roll_no"
echo "I am $comment"
```

### Output

![Variable Script Output](images/variable.png)

---

## 2. User Input — `input.sh`

This script demonstrates how to take input from the user using the `read` command.

It takes the user's:

* Name
* Roll number
* Comment

and then prints the entered values.

### Code

```bash
read -p "Enter Your Name: " name
read -p "Enter Your Roll Number: " roll_no
read -p "Enter Your Comment: " comment

echo "My name is $name"
echo "My roll number is $roll_no"
echo "My comment is $comment"
```

### Output

![Input Script Output](images/input.png)

---

## 3. Command Substitution & Process Information — `task.sh`

This script demonstrates:

* Command substitution using `$()`.
* Getting the current date.
* Accessing system information.
* Listing running processes using `ps`.
* Redirecting process information into a file.
* Taking user input.

### Code

```bash
current_date=$(date)

echo $current_date

echo $hostname

echo $whoami

ps > process.log

read -p "Enter your name: " name

read -p "Enter your roll number: " roll_no

read -p "Enter your comment: " comment

echo "My name is $name"

echo "My roll number is $roll_no"

echo "My comment is: $comment"
```

### Output

![Task Script Output](images/task.png)

### Process Log

The `ps > process.log` command redirects the currently running process information into `process.log`.

---

## 4. Loops & Addition — `loop.sh`

This script demonstrates a `for` loop that takes a **start number** and an **end number** from the user and calculates their sum.

### Code

```bash
read -p "Enter start number: " start
read -p "Enter end number: " end

sum=0

for ((i=start; i<=end; i++))
do
    sum=$((sum + i))
done

echo "Sum = $sum"
```

### Example

For input:

```text
Enter start number: 1
Enter end number: 5
```

The script calculates:

```text
1 + 2 + 3 + 4 + 5 = 15
```

### Output

![Loop Addition Output](images/AddLoop.png)

### Concept

The loop iterates from the user-provided `start` value to the `end` value. During every iteration, the current value of `i` is added to `sum`.

---

## 5. Conditional Statements — `condition.sh`

This script demonstrates conditional logic using `if`, `elif`, and `else`.

It takes the user's age and categorizes it as:

* Invalid age
* Child
* Teenager
* Adult

### Code

```bash
read -p "Enter your age: " age

if [ $age -lt 0 ]; then
    echo "Invalid age. Please enter a valid age."

elif [ $age -lt 13 ]; then
    echo "You are a child."

elif [ $age -lt 20 ]; then
    echo "You are a teenager."

else
    echo "You are an adult."

fi
```

### Output

![Condition Script Output](images/condition.png)

---

## Commands & Concepts Used

| Command / Concept  | Purpose                                |
| ------------------ | -------------------------------------- |
| `echo`             | Prints text or variable values         |
| `read`             | Takes input from the user              |
| `$variable`        | Accesses a variable's value            |
| `$(command)`       | Command substitution                   |
| `date`             | Displays the current date and time     |
| `ps`               | Displays running processes             |
| `>`                | Redirects output and overwrites a file |
| `chmod +x`         | Gives execute permission to a script   |
| `./script.sh`      | Executes a shell script                |
| `for`              | Creates a loop                         |
| `if / elif / else` | Conditional execution                  |
| `mkdir`            | Creates a directory                    |
| `touch`            | Creates an empty file                  |

---

## Running the Scripts

Give execute permission before running a script:

```bash
chmod +x script.sh
```

Then execute it:

```bash
./script.sh
```

For example:

```bash
chmod +x loop.sh
./loop.sh
```

---

## Directory Structure

```text
session3/
├── data1/
├── images/
│   ├── AddLoop.png
│   ├── condition.png
│   ├── input.png
│   ├── task.png
│   └── variable.png
├── condition.sh
├── data.sh
├── input.sh
├── loop.sh
├── process.log
├── Readme.md
├── task.sh
└── variable.sh
```
