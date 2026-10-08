## Difference B/W Soft Link And Hard Link

* **Soft links** store the filename/path of the target object, whereas **hard links** directly reference the target object's inode.
* **Soft links** become invalid when the original object is deleted, while **hard links** continue to access the original data even after the original filename is removed.

**soft link :** `ln -s target linkName`

**hard link :** `ln target linkName`

## adduser vs useradd

`useradd` is a native, low-level Linux command used to create user accounts. It performs only the basic account creation tasks and does not usually provide an interactive setup. By default, it does not create a home directory or ask for a password, so additional options or commands may be required to configure the account completely.

On the other hand, `adduser` is a higher-level, interactive script that works as a more user-friendly interface for creating users. It guides you through the setup process, automatically creates a home directory, assigns a standard shell, and asks you to set a password.

Because it handles many configuration steps automatically, `adduser` is generally more convenient for manually creating users on Ubuntu and other Linux distributions. It also applies sensible defaults for permissions and user profile configuration.

In short, use `useradd` when you need precise, non-interactive control, especially in scripts or automation. Use `adduser` when creating users manually and you want a simpler, guided setup.

## journalctl

`journalctl` is the primary command for accessing system and application logs on modern Linux systems. Instead of manually checking multiple log files, Linux's `systemd` journal stores messages, errors, and system events in a centralized log system. `journalctl` allows you to search and inspect these logs to troubleshoot issues such as service failures or application crashes.

**View all logs :** `journalctl`

**Watch logs live :** `journalctl -f`

**Check a specific service :** `journalctl -u service`

**Current user journal :** `journalctl --user`
