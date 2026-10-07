# Conditions (if-else) in Shell Scripting

**What I learned from `condition.sh`:**

- `if` lets us make decisions in our script based on conditions.
- We use `[ ]` with spaces to check conditions like `[ $age -lt 13 ]`.
- `-lt` means "less than", `-gt` means "greater than", `-eq` means "equal to".
- `elif` is used for multiple conditions, `else` is the default case.
- Every `if` must end with `fi` (which is "if" spelled backwards).

**Example:**
```bash
if [ $age -lt 18 ]; then
    echo "You are a minor"
else
    echo "You are an adult"
fi
```
