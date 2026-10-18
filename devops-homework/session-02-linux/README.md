# Session 2: Linux

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

Link exercise (run in an empty practice directory):

```bash
echo 'Linux practice' > original.txt
ln original.txt hard.txt
ln -s original.txt soft.txt
ls -li original.txt hard.txt soft.txt
unlink original.txt
cat hard.txt
cat soft.txt  # Fails because its target was removed.
unlink soft.txt
unlink hard.txt
```

Output is in `evidence/links.txt`.

| Soft link | Hard link |
|---|---|
| Stores a path to a target | Another directory entry for the same inode |
| Has its own inode | Shares inode and file data |
| Can cross filesystems and link directories | Normally cannot cross filesystems or link directories |
| Becomes dangling if target is removed | Data remains until the final link and open reference are gone |

`ln file hard` creates a hard link; `ln -s file soft` creates a soft link.
Removing a link with `unlink` removes that name. It does not automatically remove the other names.

On Ubuntu, `adduser` is a friendly high-level command which normally creates a home
directory and asks for account details. `useradd` is a lower-level command useful
in scripts; options such as `-m` must be supplied deliberately. Defaults vary by distribution.
Practice on Ubuntu (the recorded run used a disposable Debian container):

```bash
adduser --disabled-password --gecos '' learner
id learner
ls -ld /home/learner
deluser --remove-home learner
```

`journalctl` reads the systemd journal. Examples on a systemd Ubuntu host:

```bash
journalctl -b --no-pager -n 20
journalctl -u ssh.service --since '1 hour ago' --no-pager
journalctl -p err -b --no-pager
journalctl -f
```

Containers usually do not run systemd, so an empty journal there is not proof that
the host has no errors. Service names and journal permissions also differ.

| Command | Purpose and small example |
|---|---|
| pwd / ls | Current directory / list files: `ls -la` |
| mkdir / touch | Create directory / empty file: `mkdir lab; touch lab/a` |
| cp / mv | Copy / rename: `cp lab/a lab/b` |
| cat / tail | Read file / last lines: `tail -n 5 file.log` |
| find / grep | Find names / matching text: `grep error file.log` |
| chmod | Change permissions: `chmod u+x script.sh` |
| df / du | Filesystem space / directory usage: `df -h; du -sh .` |
| ps / top | Process snapshot / interactive view: `ps -ef` |
| whoami / id | Username / UID and groups |
| man | Read the manual: `man ln` |

## Verification

Link creation/deletion, user creation/deletion and the command exercises ran in disposable containers. Service journal output was captured from the host.

Local Linux exercises are verified; see the recorded command output.

Command output: [evidence/](evidence/).
