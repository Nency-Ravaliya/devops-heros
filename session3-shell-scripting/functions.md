# Functions in Shell Scripting

**What I learned from `function.sh`:**

- A function is a reusable block of code that we can call by name.
- We define it using `function_name() { ... }` syntax.
- To run the function, we just write its name like `show_info`.
- Functions help us avoid writing the same code again and again.
- We can call a function multiple times after defining it once.

**Example:**
```bash
greet() {
    echo "Hello!"
    echo "Welcome to shell scripting"
}

greet   # This calls the function
greet   # We can call it again!
```
