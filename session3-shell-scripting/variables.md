# Variables in Shell Scripting

**What I learned from `variable.sh`:**

- A variable is like a box where we store data (text or numbers).
- We create a variable using `name="value"` (no spaces around `=`).
- To use/print a variable, we add `$` before it like `$name`.
- We cannot use command names (like `ls`, `cd`) as variable names because shell will get confused.

**Example:**
```bash
name="Chhavi"
echo "Hello $name"   # Output: Hello Chhavi
```
