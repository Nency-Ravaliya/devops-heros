# Shell Scripting Examples

This directory contains shell scripting exercises and scripts covering fundamental Bash concepts such as variables, user input, conditional statements, loops, file operations, and system commands.

---

## Table of Contents

1. [Variables (`variable.sh`)](#1-variables-variablesh)
2. [User Input (`input.sh`)](#2-user-input-inputsh)
3. [Conditionals (`condition.sh`)](#3-conditionals-conditionsh)
4. [For Loop (`for.sh`)](#4-for-loop-forsh)
5. [Sum Calculation (`sum.sh`)](#5-sum-calculation-sumsh)
6. [While Loop (`while.sh`)](#6-while-loop-whilesh)
7. [File & Directory Operations (`hello.sh`)](#7-file--directory-operations-hellosh)
8. [System Info & Task Operations (`task.sh`)](#8-system-info--task-operations-tasksh)

---

## 1. Variables (`variable.sh`)

Demonstrates defining and accessing variables in Bash.

```bash
name="Tejas"
rollno="10313"
batch="B"

echo "My name is $name"
echo "Rollno is $rollno"
echo "Current Batch : $batch"
```

---

## 2. User Input (`input.sh`)

Demonstrates reading interactive user input using `read -p`.

```bash
read -p "Enter your name: " name
read -p "Enter your rollno: " rollno
read -p "Anddd your comment: " comment

echo "My name is $name, rollno: $rollno and your comment is $comment"
```

---

## 3. Conditionals (`condition.sh`)

Demonstrates conditional decision making using `if`, `elif`, and `else` statements with numerical comparisons (`-lt`).

```bash
read -p "Enter your age: " age

if [ $age -lt 0 ]; then 
    echo "Invalid Age" 
elif [ $age -lt 13 ]; then
    echo "You are a child"
elif [ $age -lt 20 ]; then 
    echo "You are a teenager" 
else 
    echo "You are an adult"
fi
```

---

## 4. For Loop (`for.sh`)

Demonstrates iterating through a range sequence `{1..5}` using a `for` loop.

```bash
for i in {1..5}
do 
    echo ${i}
done
```

---

## 5. Sum Calculation (`sum.sh`)

Calculates the sum of numbers from `1` to `N` (user input) using a C-style `for` loop and arithmetic evaluation `$(( ... ))`.

```bash
read -p "Enter any number : " num
sum=0

for ((i=1; i<=num; i++))
do 
    sum=$((sum+i))
done 

echo "Sum : $sum"
```

---

## 6. While Loop (`while.sh`)

Demonstrates simple iteration using a `while` loop and counter increment `((count++))`.

```bash
count=0

while [ $count -lt 5 ] 
do 
    echo "Current Iteration : $count" 
    ((count++))
done
```

---

## 7. File & Directory Operations (`hello.sh`)

Demonstrates creating directories (`mkdir`), navigating directories (`cd`), creating log files (`touch`), redirecting output (`>`), and inspecting files (`cat`).

```bash
mkdir hello
cd hello
touch app.log
echo "This is new log" > app.log
cat app.log
echo "This is another new log" > app.log
cat app.log
```

---

## 8. System Info & Task Operations (`task.sh`)

Demonstrates retrieving system metadata (`date`, `hostname`, `whoami`), capturing process logs (`ps aux > process.log`), and prompting for input.

```bash
echo "Current Date: $(date)" 
echo "Hostname: $(hostname)"
echo "Usename: $(whoami)"

mkdir logs
cd logs
ps aux > process.log

read -p "Enter your name: " name
read -p "Enter your rollno: " rollno
read -p "Anddd your comment: " comment

echo "My name is $name, rollno: $rollno and your comment is $comment"
```
