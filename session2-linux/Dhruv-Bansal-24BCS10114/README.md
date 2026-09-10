# Session 2 - Linux fundamentals

**Dhruv Bansal - 24BCS10114**

This submission uses a disposable directory for the link exercise, so it does not alter files outside the lab.

## Link behaviour

`links-lab.sh` creates one file, a hard link, and a symbolic link. It checks that the first two share an inode, removes the original name, and then confirms that the hard link still contains the data while the symbolic link is dangling.

Run it from a Linux shell:

```bash
bash links-lab.sh --verify
```

## User-management note

On Debian and Ubuntu, `adduser` is the interactive, policy-aware helper that is suitable for a one-off administrator task. `useradd` is the lower-level command and is better for repeatable scripts when every option is specified deliberately. A safe practice account can be created with `sudo adduser labuser` and removed afterwards with `sudo deluser --remove-home labuser`.

## Journal inspection

Useful commands are `journalctl -b` for the current boot, `journalctl -u ssh --since today` for a service, and `journalctl -p warning..alert -b` to focus on high-severity records. Availability of individual units varies by host, so commands should be run against a service that exists locally.

## Command practice

`pwd`, `ls -lah`, `find`, `grep`, `df -h`, `free -h`, and `ps aux` answer different operational questions. I would start with read-only commands before changing ownership, permissions, users, or processes.
