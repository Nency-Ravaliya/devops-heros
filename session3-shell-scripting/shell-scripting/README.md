# Session 3 Homework - Shell Scripting

## Task
Write a shell script that:
- Prints the current date
- Prints the hostname
- Prints the username
- Prints the disk usage
- Prints the running processes
- Takes input using `read -p` and stores values in variables
- Creates a directory and saves the process information in a file inside it

## Commands used
| Command | Purpose |
|---------|---------|
| `read -p` | Take input from the user |
| `date` | Print the current date |
| `hostname` | Print the machine name |
| `whoami` | Print the current username |
| `df -h` | Print disk usage in human readable form |
| `ps` | Print running processes |
| `mkdir` | Create a directory |
| `touch` | Create an empty file |
| `echo` | Print output on the screen |
| `>` | Redirect output into a file |

## How to run
```bash
chmod +x system_info.sh
./system_info.sh
```

## Output
The script creates the directory you enter and stores:
- `process.log` -> running processes
- `disk_usage.log` -> disk usage
