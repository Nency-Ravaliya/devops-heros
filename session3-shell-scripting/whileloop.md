# While Loop in Shell Scripting

**What I learned from `while_loop.sh` and `while_loop1.sh`:**

- A `while` loop keeps running AS LONG AS a condition is true.
- `while true` creates an infinite loop that runs forever until we stop it.
- `break` exits the loop immediately (like emergency stop).
- `continue` skips the current iteration and jumps to the next one.
- `((count++))` increases the counter by 1 each time.

**Simple While Loop Example:**
```bash
count=0
while [ $count -lt 5 ]
do
    echo "Count is $count"
    ((count++))
done
```

**While Loop with Break Example:**
```bash
while true; do
    read -p "Enter q to quit: " input
    if [ $input == "q" ]; then
        break
    fi
done
```
