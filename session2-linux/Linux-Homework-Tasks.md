# Linux Homework Tasks

This repository contains my notes and hands-on practice for basic Linux concepts and commands.

## 📚 Tasks Covered

* Soft Links & Hard Links
* `adduser` vs `useradd`
* `journalctl`
* Linux Command Cheat Sheet

---

# Task 1: Soft Link & Hard Link

## Soft Link (Symbolic Link)

A **soft link** is a file that points to another file or directory. It stores the **path** of the target.

### Create a Soft Link

```bash
ln -s original.txt softlink.txt
```

### Check the Link

```bash
ls -l
```

The output will show something like:

```text
softlink.txt -> original.txt
```

### Delete a Soft Link

```bash
rm softlink.txt
```

Deleting the soft link does **not** delete the original file.

---

## Hard Link

A **hard link** is another name for the same underlying file/inode.

### Create a Hard Link

```bash
ln original.txt hardlink.txt
```

### Check Inodes

```bash
ls -li
```

The original file and hard link will have the **same inode number**.

### Delete a Hard Link

```bash
rm hardlink.txt
```

Deleting one hard link does not delete the actual data as long as another hard link still exists.

### Soft Link vs Hard Link

| Feature                      | Soft Link | Hard Link    |
| ---------------------------- | --------- | ------------ |
| Points to                    | File path | Inode        |
| Can link directories         | Yes       | Generally no |
| Can cross filesystems        | Yes       | No           |
| Same inode as original       | No        | Yes          |
| Works if original is deleted | No        | Yes          |
| Command                      | `ln -s`   | `ln`         |

### Interview Question

**Q: What is the difference between a soft link and a hard link?**

A soft link is a separate file that stores the path to another file, while a hard link is another directory entry pointing to the same inode and data. A soft link becomes broken if the original file is deleted or moved, whereas a hard link continues to work as long as at least one hard link to the inode exists.

---

# Task 2: `adduser` vs `useradd`

Both commands are used to create users, but they work differently.

## `useradd`

`useradd` is a **low-level Linux utility** for creating users.

Example:

```bash
sudo useradd testuser
```

It generally requires additional configuration if you want to create a home directory, set a password, or configure other user properties.

For example:

```bash
sudo useradd -m testuser
sudo passwd testuser
```

`-m` creates the user's home directory.

---

## `adduser`

`adduser` is a **higher-level, more user-friendly utility**, commonly available on Debian/Ubuntu systems.

```bash
sudo adduser testuser
```

It interactively:

* Creates the user
* Creates the home directory
* Prompts for a password
* Creates the appropriate user/group configuration
* Asks for optional user information

---

## Which One Is Preferred on Ubuntu?

On Ubuntu, **`adduser` is generally preferred for interactive/manual user creation** because it provides a simpler and safer interface around the lower-level `useradd` functionality.

For scripting and automation, `useradd` is often preferred because it is more predictable and provides command-line options suitable for automation.

### Comparison

| Feature             | `adduser`                     | `useradd`                     |
| ------------------- | ----------------------------- | ----------------------------- |
| Type                | High-level Perl utility       | Low-level system utility      |
| Ease of use         | Easier                        | More manual                   |
| Interactive         | Yes                           | No                            |
| Home directory      | Usually created automatically | Use `-m`                      |
| Password setup      | Prompted automatically        | Use `passwd` separately       |
| Common Ubuntu usage | Preferred for manual creation | Useful for scripts/automation |

### Practice

Create a test user:

```bash
sudo adduser testuser
```

Verify the user:

```bash
id testuser
```

Check the user's home directory:

```bash
ls /home
```

---

# Task 3: `journalctl`

`journalctl` is a command used to view and query logs collected by **systemd's journal**.

It is useful for troubleshooting:

* System problems
* Service failures
* Boot issues
* Application/service logs
* Authentication and system events

## View All Logs

```bash
journalctl
```

Because logs can be very large, you can use:

```bash
journalctl -n 50
```

This displays the latest 50 log entries.

## View Logs in Real Time

```bash
journalctl -f
```

`-f` follows the log and displays new entries as they are generated.

## View Logs for a Specific Service

Use the `-u` option:

```bash
journalctl -u <service-name>
```

For example:

```bash
journalctl -u ssh
```

On some Ubuntu versions, the service may be named `ssh.service`:

```bash
journalctl -u ssh.service
```

## View Recent Service Logs

```bash
journalctl -u ssh -n 50
```

## View Logs Since the Current Boot

```bash
journalctl -b
```

## View Logs for the Previous Boot

```bash
journalctl -b -1
```

## View Logs Within a Time Range

```bash
journalctl --since "1 hour ago"
```

or:

```bash
journalctl --since "2026-09-02 20:00:00"
```

### Useful Options

| Command                           | Purpose                   |
| --------------------------------- | ------------------------- |
| `journalctl`                      | View all journal logs     |
| `journalctl -n 50`                | Show latest 50 entries    |
| `journalctl -f`                   | Follow logs in real time  |
| `journalctl -u service`           | View logs for a service   |
| `journalctl -b`                   | Logs from current boot    |
| `journalctl -b -1`                | Logs from previous boot   |
| `journalctl --since "1 hour ago"` | Logs from a specific time |

### Practice

Check the logs for a service:

```bash
journalctl -u ssh
```

Then check the most recent entries:

```bash
journalctl -u ssh -n 20
```

---

# Task 4: Linux Command Cheat Sheet

## 📁 File & Directory Commands

### `pwd`

Shows the current working directory.

```bash
pwd
```

### `ls`

Lists files and directories.

```bash
ls
ls -l
ls -la
```

### `cd`

Changes the current directory.

```bash
cd /home
cd ..
cd ~
```

### `mkdir`

Creates a directory.

```bash
mkdir test
```

### `touch`

Creates an empty file.

```bash
touch file.txt
```

### `cp`

Copies files or directories.

```bash
cp file.txt backup.txt
cp -r folder1 folder2
```

### `mv`

Moves or renames files/directories.

```bash
mv file.txt newfile.txt
mv file.txt /tmp/
```

### `rm`

Removes files.

```bash
rm file.txt
rm -r folder
```

---

## 📄 Viewing Files

### `cat`

Displays the contents of a file.

```bash
cat file.txt
```

### `less`

Views a file page by page.

```bash
less file.txt
```

### `head`

Shows the beginning of a file.

```bash
head file.txt
```

### `tail`

Shows the end of a file.

```bash
tail file.txt
```

Follow a changing file:

```bash
tail -f file.log
```

---

## 🔍 Searching

### `grep`

Searches for text inside files.

```bash
grep "error" file.log
```

Recursive search:

```bash
grep -r "error" .
```

### `find`

Searches for files and directories.

```bash
find . -name "file.txt"
```

---

## 🔐 Permissions

### `chmod`

Changes file permissions.

```bash
chmod 755 script.sh
```

### `chown`

Changes file ownership.

```bash
sudo chown user:user file.txt
```

### `sudo`

Runs a command with elevated privileges.

```bash
sudo command
```

---

## 👤 User Commands

### `whoami`

Shows the current user.

```bash
whoami
```

### `id`

Shows user and group information.

```bash
id
```

### `passwd`

Changes a user's password.

```bash
passwd
```

### `who`

Shows currently logged-in users.

```bash
who
```

---

## 💻 Processes

### `ps`

Displays running processes.

```bash
ps
ps aux
```

### `top`

Displays processes and system resource usage.

```bash
top
```

### `kill`

Terminates a process using its PID.

```bash
kill <PID>
```

---

## 💾 Disk & System Information

### `df`

Shows filesystem disk usage.

```bash
df -h
```

### `du`

Shows directory/file space usage.

```bash
du -sh folder
```

### `free`

Shows memory usage.

```bash
free -h
```

### `uname`

Displays system information.

```bash
uname -a
```

---

## 🌐 Networking

### `ping`

Tests network connectivity.

```bash
ping google.com
```

### `ip`

Displays network interface and IP information.

```bash
ip addr
```

### `curl`

Makes HTTP requests.

```bash
curl https://example.com
```

---

# 🧠 Key Takeaways

* **Soft links** point to a file path, while **hard links** point to the same inode.
* `ln -s` creates a soft link and `ln` creates a hard link.
* On Ubuntu, `adduser` is generally easier and preferred for interactive user creation.
* `useradd` is a lower-level utility that is useful for automation and scripting.
* `journalctl` is used to inspect logs managed by `systemd`.
* `journalctl -u <service>` is useful for troubleshooting a specific service.
* Linux commands can be combined with options and pipes to perform more powerful operations.

---

# 🛠️ Practice

```bash
# Links
ln original.txt hardlink.txt
ln -s original.txt softlink.txt
ls -li
rm hardlink.txt
rm softlink.txt

# Users
sudo adduser testuser
id testuser

# Logs
journalctl
journalctl -n 50
journalctl -u ssh
journalctl -f

# Basic commands
pwd
ls -la
cd
mkdir
touch
cp
mv
rm
cat
grep
find
chmod
ps
df -h
free -h
```
