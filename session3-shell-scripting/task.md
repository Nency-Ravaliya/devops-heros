# Shell Scripting Homework - Task Notes

## Requirements
- print current date            -> `date`
- print hostname and username   -> `hostname`, `whoami`, `who`, `w`
- print disk usage              -> `df -h`
- print running processes       -> `ps`
- save process info into a file -> `ps > process.log`
- print name, roll_no, comment  -> variables + `read -p`
- use variables, take input, create a directory and a file

## Rough working

```bash
current_date=$(date)
echo "$current_date"

echo "$(hostname)"
echo "$(whoami)"

ps > process.log

read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter your comment: " comment

echo "My name is $name"
echo "My roll number is $roll_no"
echo "My comment is: $comment"
```

The final, cleaned-up version of this task is in **`system-info.sh`**,
and the full output is documented in **`README.md`**.
