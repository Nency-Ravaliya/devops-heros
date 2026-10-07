# File Operations in Shell Scripting

**What I learned from `hello.sh` and `script1.sh`:**

- `mkdir folder_name` creates a new folder/directory.
- `touch file.txt` creates an empty file.
- `echo "text" > file.txt` writes text to file (overwrites existing content).
- `echo "text" >> file.txt` appends text to file (adds at the end).
- `cat file.txt` displays the content of a file.
- `>` means overwrite, `>>` means append (add to existing).

**Example:**
```bash
mkdir myproject
cd myproject
echo "First line" > notes.txt    # Creates file with "First line"
echo "Second line" >> notes.txt  # Adds "Second line" below
cat notes.txt                    # Shows both lines
```
