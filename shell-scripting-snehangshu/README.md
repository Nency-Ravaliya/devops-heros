# Session 3 - Shell Scripting Tasks

**Name:** Snehangshu Roy
**Roll No:** 24BCS10155

Solutions for the tasks listed in [session3/task.md](../session3/task.md).

## Scripts

| Script | What it does |
| --- | --- |
| `01_system_info.sh` | Prints the current date, hostname and username, shows the running processes and saves the full process list into `process.log` |
| `02_variables.sh` | Stores name, roll number and a comment in variables and prints them |
| `03_input.sh` | Takes name, roll number and a comment as input from the user and prints them back |
| `04_create_dir_file.sh` | Creates a directory and a file inside it, then writes the system details along with the user input into that file |

## How to run

```bash
cd shell-scripting-snehangshu
chmod +x *.sh
./01_system_info.sh
./02_variables.sh
./03_input.sh
./04_create_dir_file.sh
```

## Output files

These are created when the scripts run, so they are not committed:

- `process.log` from `01_system_info.sh`
- `my_details/details.txt` and `my_details/process.log` from `04_create_dir_file.sh`
