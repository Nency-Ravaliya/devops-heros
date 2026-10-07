## Difference B/W Soft Link And Hard Link
- soft links point to the filename/path of the target object while hard links point to their inodes
- soft links break if the original object is deleted while hard links retain original data

**soft link :** ln -s target linkName

**hard link :** ln target linkName

## adduser vs useradd

useradd is a native, low-level binary tool built directly into the system core. It operates instantly without asking questions, doing only the bare minimum required to create an entry for an account. By default, it will not create a home directory or prompt you for a password, meaning you must manually pass specific command flags or run secondary commands to make the account fully usable.

In contrast, adduser is a high-level, interactive script that serves as a user-friendly wrapper around the raw useradd command. When executed, it launches a step-by-step wizard right in your terminal, automatically generating a home directory, assigning a standard command shell, and prompting you to set a password immediately. Because of this automation, adduser is heavily preferred on Ubuntu and Linux for manual account creation. It eliminates human error by enforcing safe system defaults, such as setting up secure permissions and copying profile configurations, without requiring complex, multi-flag command strings.

Ultimately, use useradd for automation or shell scripts where you need precise, non-interactive control over configuration flags. Turn to adduser for manual, everyday management when you want a complete, fully functioning user profile set up safely in seconds.


## journalctl

journalctl is the central command used to view system and application logs in modern Linux. Instead of checking many different files, Linux collects all background messages, errors, and system events into one secure database. journalctl is the tool you use to search through that database to find out why a program crashed or what the system is doing.

View all logs : journalctl

Watch logs live : journalctl -f

Check a specific service : journalctl -u service

Current user journal : journalctl --user	