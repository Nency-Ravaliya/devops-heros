# Shell Scripting Tasks (Session 3)

Name: Utkarsh Bahuguna
Roll number: 24bcs10161

Solutions for the tasks listed in [session3/task.md](../session3/task.md).

| Script | What it does |
| --- | --- |
| `01_system_info.sh` | Prints the current date, hostname, username and the running processes, and saves the process info into `process.log`. |
| `02_variables.sh` | Stores name, roll number and a comment in variables and prints them. |
| `03_input.sh` | Reads name, roll number and comment from the user with `read` and prints them back. |
| `04_create_dir_file.sh` | Creates the `my_details` directory and a `details.log` file inside it, then writes the system details and the user input into that file. |

## How to run

```bash
chmod +x *.sh
./01_system_info.sh
./02_variables.sh
./03_input.sh
./04_create_dir_file.sh
```

## Output files

- `process.log` : process list captured by `01_system_info.sh`
- `my_details/details.log` : details collected by `04_create_dir_file.sh`
- `my_details/process.log` : process list captured by `04_create_dir_file.sh`
