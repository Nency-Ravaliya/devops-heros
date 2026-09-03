# For Loop in Shell Scripting

**What I learned from `loop.sh`:**

- A `for` loop repeats the same code multiple times automatically.
- `{1..5}` creates a range of numbers from 1 to 5.
- The loop variable (`i`) changes value in each iteration (1, then 2, then 3...).
- Code between `do` and `done` runs for each value.

**Example:**
```bash
for i in {1..5}
do
    echo "Number: $i"
done
# Output: Number: 1, Number: 2, Number: 3, Number: 4, Number: 5
```
