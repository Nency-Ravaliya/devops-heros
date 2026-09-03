# User Input in Shell Scripting

**What I learned from `input.sh`:**

- We use `read` command to take input from the user.
- `read -p "message"` shows a message and waits for user to type something.
- Whatever user types gets stored in the variable we specify.
- This makes our scripts interactive instead of hardcoded values.

**Example:**
```bash
read -p "Enter your name: " name
echo "Hello $name"
```
