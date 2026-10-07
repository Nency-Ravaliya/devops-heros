# Session 2 – Linux Fundamentals

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Environment:** Ubuntu 24.04 containers on Docker Desktop (macOS host). Task 3 uses a container booted with `systemd` as PID 1 so `journalctl` has a real journal to read.

Every command in these notes was actually run; the raw terminal output lives in [`transcripts/`](transcripts).

| Task | Notes | Raw output |
|---|---|---|
| 1. Soft link vs hard link | [01-soft-vs-hard-links.md](01-soft-vs-hard-links.md) | [task1-links-task2-users.txt](transcripts/task1-links-task2-users.txt) |
| 2. `adduser` vs `useradd` | [02-adduser-vs-useradd.md](02-adduser-vs-useradd.md) | same file, second half |
| 3. `journalctl` | [03-journalctl.md](03-journalctl.md) | [task3-journalctl.txt](transcripts/task3-journalctl.txt) |
| 4. Command cheat sheet | [04-command-cheatsheet.md](04-command-cheatsheet.md) | – |

## How I reproduced a "real" Linux box on a Mac

```bash
# Tasks 1 & 2 – throwaway Ubuntu container, script mounted read-only
docker run --rm -v "$PWD/links-users.sh:/x.sh:ro" ubuntu:24.04 bash /x.sh

# Task 3 – Ubuntu with systemd as init (see transcripts/systemd-lab.Dockerfile)
docker build -t ubuntu-systemd -f transcripts/systemd-lab.Dockerfile .
docker run -d --name sysd --privileged --tmpfs /run --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw ubuntu-systemd
docker exec -it sysd bash
```
