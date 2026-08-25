# 🍿 CINERA (Netflix Clone) - Complete Shell Scripting & Automation Guide & Notes

Welcome to the **Complete Shell Scripting Guide** built around automating a production streaming infrastructure: **CINERA** (a full-stack Netflix clone).

This guide walks you through every core Bash scripting concept, variable usage, conditional statement, loop structure, and Linux command taught in DevOps Session 3, using **CINERA** as our hands-on example.

---

## 🐚 1. Shell Scripting Basics & Shebang (`#!/bin/bash`)

A **Shell Script** is an executable text file containing a sequence of commands for the Bash shell to execute automatically.

### A. The Shebang Line
Every shell script must start with the **Shebang** (`#!/bin/bash`) as the first line.
* It tells the operating system kernel which interpreter to use (`/bin/bash`).

### B. Making Scripts Executable
To run a script, you must set executable permissions using `chmod`:
```bash
chmod +x deploy_cinera.sh
./deploy_cinera.sh
```

---

## 💲 2. Variables, Command Substitution & User Input

### A. Variables in Bash
Variables store temporary data such as server ports, database URLs, or application names.
* **Rules**: No spaces around the `=` sign!

```bash
#!/bin/bash

# Define CINERA configuration variables
APP_NAME="CINERA"
APP_PORT=5000
ENVIRONMENT="Production"

echo "Deploying $APP_NAME ($ENVIRONMENT) on port $APP_PORT..."
```

---

### B. Command Substitution (`$(command)`)
Captures the output of a system command and stores it into a variable.

```bash
#!/bin/bash

# Capture system metrics for CINERA status report
CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)
CURRENT_USER=$(whoami)

echo "[$CURRENT_DATE] CINERA status check by $CURRENT_USER on $HOSTNAME"
```

---

### C. Reading User Input (`read -p`)
Prompts the administrator for input during execution.

```bash
#!/bin/bash

read -p "Enter CINERA environment [development/production]: " ENV_INPUT
read -p "Enter developer name: " DEV_NAME
read -p "Enter deployment comment: " DEPLOY_COMMENT

echo "Deploying CINERA in $ENV_INPUT mode by $DEV_NAME ($DEPLOY_COMMENT)..."
```

---

## 🔀 3. Conditionals & Logic (`if / elif / else`)

Conditionals allow your scripts to make decisions (e.g., checking if CINERA API port is occupied or if disk space is low).

```bash
#!/bin/bash

read -p "Enter CINERA server port: " PORT

# Integer comparison: -lt (less than), -eq (equal), -gt (greater than)
if [ $PORT -lt 1024 ]; then
    echo "⚠️ Warning: Port $PORT is a restricted system port!"
elif [ $PORT -eq 5000 ]; then
    echo "✅ Port $PORT is the standard CINERA Express API port."
else
    echo "ℹ️ Running CINERA on custom port $PORT."
fi
```

### Common Bash Test Operators:
* **Strings**: `==` (equal), `!=` (not equal), `-z` (string is empty).
* **Integers**: `-eq` (equal), `-ne` (not equal), `-gt` (greater than), `-lt` (less than).
* **Files**: `-f file` (file exists), `-d dir` (directory exists).

---

## 🔄 4. Loops (`for` and `while`)

### A. `for` Loop (Iterating over lists/files)
Used when you know the number of iterations in advance (e.g., backing up multiple microservice logs).

```bash
#!/bin/bash

SERVICES=("cinera-auth" "cinera-video-player" "cinera-recommendation" "cinera-billing")

echo "=== Restarting CINERA Microservices ==="
for SERVICE in "${SERVICES[@]}"
do
    echo "🔄 Restarting $SERVICE..."
    # Simulate restart
    sleep 1
    echo "✅ $SERVICE is healthy."
done
```

---

### B. `while` Loop (Interactive Menu & Service Monitoring)
Runs continuously while a condition remains true.

#### Example: Interactive CINERA Admin Dashboard (from `while_loop.sh` lesson)

```bash
#!/bin/bash

while true; do
    echo "=========================================="
    echo "   🍿 CINERA AUTOMATION DASHBOARD"
    echo "=========================================="
    echo "1) View System & Process Info"
    echo "2) Check Disk Usage"
    echo "3) Generate Server Log Report"
    echo "q) Quit"
    echo "=========================================="
    read -p "Choose an option [1-3 or q]: " CHOICE

    if [[ $CHOICE == "q" ]]; then
        echo "Exiting CINERA Admin Panel. Goodbye!"
        break
    elif [[ $CHOICE == "1" ]]; then
        echo "--- Active CINERA Processes ---"
        ps aux | head -n 5
    elif [[ $CHOICE == "2" ]]; then
        echo "--- Storage Utilization ---"
        df -h
    elif [[ $CHOICE == "3" ]]; then
        echo "Generating report into process.log..."
        ps > process.log
        echo "✅ Log report generated!"
    else
        echo "❌ Invalid choice! Please enter 1, 2, 3, or q."
    fi
    echo ""
done
```

---

## 🧩 5. Functions in Shell Scripting

Functions encapsulate reusable code blocks. Position arguments (`$1`, `$2`) pass data into functions.

```bash
#!/bin/bash

# Function to log messages with timestamps
log_message() {
    local LOG_LEVEL=$1
    local MESSAGE=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LOG_LEVEL] - $MESSAGE"
}

# Function invocation
log_message "INFO" "CINERA database connection established."
log_message "WARNING" "High memory consumption on video streaming node."
log_message "ERROR" "Redis cache connection timeout!"
```

---

## 📄 6. I/O Redirection & Process Tracking (Task Assignments)

### A. Output Redirection Operators
* `>` : Overwrites destination file.
* `>>` : Appends to destination file.

```bash
# Overwrite process.log with current process snapshot
ps > process.log

# Append server uptime log
date >> server_uptime.log
```

---

## 🛠️ 7. Full Task Script Solution (`task.md` Implementation)

Here is the complete production script fulfilling all tasks required in `session3-shell-scripting/task.md`:

```bash
#!/bin/bash
# ==============================================================================
# CINERA System Monitoring & User Audit Script (Session 3 Assignment Solution)
# ==============================================================================

# 1. Print current date
CURRENT_DATE=$(date)
echo "📅 Current Date & Time: $CURRENT_DATE"

# 2. Print hostname and user info
HOST_NAME=$(hostname)
USER_NAME=$(whoami)
echo "🖥️ Hostname: $HOST_NAME"
echo "👤 Current User: $USER_NAME"
echo "👥 Active Users Logged In:"
w

# 3. Add process info inside process.log
echo "📝 Saving process snapshot to process.log..."
ps > process.log
echo "✅ Saved successfully!"

# 4. Take user input and display details
echo "------------------------------------------"
read -p "Enter your name: " NAME
read -p "Enter your roll number: " ROLL_NO
read -p "Enter your comment: " COMMENT

echo "------------------------------------------"
echo "My name is $NAME"
echo "My roll number is $ROLL_NO"
echo "My comment is: $COMMENT"
```

---

## 📋 Quick Command Cheat Sheet Summary

| Task | Command / Syntax | Example |
| :--- | :--- | :--- |
| **Make Executable** | `chmod +x script.sh` | `chmod +x deploy.sh` |
| **Store Command Result** | `VAR=$(command)` | `NOW=$(date)` |
| **Read User Input** | `read -p "prompt" VAR` | `read -p "Port: " PORT` |
| **Redirect & Overwrite** | `command > file` | `ps > process.log` |
| **Redirect & Append** | `command >> file` | `echo "done" >> log.txt` |
| **Numeric If Condition** | `if [ $A -eq $B ]` | `-eq`, `-ne`, `-gt`, `-lt` |
| **String If Condition** | `if [[ $A == "q" ]]` | `==`, `!=`, `-z` |
