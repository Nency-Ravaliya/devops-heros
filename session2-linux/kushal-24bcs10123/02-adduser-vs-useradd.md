# Task 2 – `adduser` vs `useradd`

## What they are

| | `useradd` | `adduser` |
|---|---|---|
| What is it | compiled binary from the `passwd`/shadow-utils package (`file` says *ELF 64-bit executable*) | Perl script from the Debian `adduser` package (`head -1` shows `#! /usr/bin/perl`) |
| Available on | every Linux distribution | Debian, Ubuntu and derivatives (Fedora/RHEL just alias it to `useradd`) |
| Style | low level, non-interactive, does exactly what the flags say | high level, interactive, applies sane defaults from `/etc/adduser.conf` |
| Home directory | **not** created unless you pass `-m` | created and populated from `/etc/skel` |
| Login shell | `/bin/sh` unless `-s /bin/bash` | `/bin/bash` (DSHELL) |
| Password | not set, run `passwd` afterwards | prompts for it (`--disabled-password` to skip) |
| Per-user group | depends on `USERGROUPS_ENAB` | always creates one |
| Adds to `users` group | no | yes |
| Good for | scripts, Dockerfiles, Ansible, cloud-init | humans typing at a terminal |

## What happened when I ran them (Ubuntu 24.04)

```text
$ useradd rawuser
$ grep rawuser /etc/passwd
rawuser:x:1001:1001::/home/rawuser:/bin/sh
$ ls -ld /home/rawuser
ls: cannot access '/home/rawuser': No such file or directory     <- no home, /bin/sh shell
```

To get a usable account from `useradd` you have to spell everything out:

```text
$ useradd -m -s /bin/bash -c 'Raw User 2' rawuser2
$ ls -la /home/rawuser2
-rw-r--r-- 1 rawuser2 rawuser2  220 .bash_logout
-rw-r--r-- 1 rawuser2 rawuser2 3771 .bashrc
-rw-r--r-- 1 rawuser2 rawuser2  807 .profile
```

`adduser` does all of that by itself and tells you what it is doing:

```text
$ adduser --disabled-password --gecos 'Kushal Test User,,,' testuser
info: Adding user `testuser' ...
info: Selecting UID/GID from range 1000 to 59999 ...
info: Adding new group `testuser' (1003) ...
info: Adding new user `testuser' (1003) with group `testuser (1003)' ...
info: Creating home directory `/home/testuser' ...
info: Copying files from `/etc/skel' ...
info: Adding new user `testuser' to supplemental / extra groups `users' ...
info: Adding user `testuser' to group `users' ...

$ id testuser
uid=1003(testuser) gid=1003(testuser) groups=1003(testuser),100(users)
```

(Interactively, without `--disabled-password --gecos`, it would also prompt for the password and the full name / room / phone fields.)

Clean-up counterpart is `deluser --remove-home testuser` (or `userdel -r`).

> Side note I learned the hard way: the minimal `ubuntu:24.04` Docker image ships `useradd` but **not** `adduser` – I had to `apt-get install adduser` first. On a normal Ubuntu install both are present.

## Which one should you use on Ubuntu, and why?

* **On the command line: `adduser`.** Ubuntu's own documentation recommends it because it is the friendly front end: it picks the next free UID, creates the group, the home directory, copies the skeleton dotfiles, sets bash as the shell and asks for a password, so you cannot forget a step. `useradd` with no flags produces a half-configured account (as `rawuser` shows).
* **In scripts and Dockerfiles: `useradd`.** It is non-interactive, has the same flags on every distro, and gives you full control (`-m -s /bin/bash -G sudo -u 1500 ...`).

## Commands I would use in practice

```bash
sudo adduser alice                       # normal interactive creation on Ubuntu
sudo usermod -aG sudo alice              # give sudo rights afterwards
sudo useradd -m -s /bin/bash -G docker bob && sudo passwd bob   # scripted equivalent
getent passwd alice; id alice; ls -la /home/alice               # verify
sudo deluser --remove-home alice         # remove
```
