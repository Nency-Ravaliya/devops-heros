# Task 3 – `journalctl`

## What it is

`journalctl` reads the **systemd journal**: a binary, indexed log store written by `systemd-journald`. Everything that goes through systemd ends up there: kernel messages, boot messages, stdout/stderr of every service, `syslog()` calls, and audit/auth events. Because it is indexed you can filter by unit, priority, time, boot, PID, or any metadata field, which is much nicer than `grep`-ing `/var/log/syslog`.

## Setup for this exercise

macOS has no systemd and a normal Docker container does not run it either, so I built a small Ubuntu 24.04 image with `systemd` as PID 1 ([`transcripts/systemd-lab.Dockerfile`](transcripts/systemd-lab.Dockerfile)) and ran it privileged. `systemctl is-system-running` reported `running`, so the journal was live. Full output: [`transcripts/task3-journalctl.txt`](transcripts/task3-journalctl.txt).

## The commands I practised

| Command | What it shows |
|---|---|
| `journalctl` | whole journal, oldest first, paged with `less` |
| `journalctl -n 15` | last 15 lines (`--no-pager` to print straight to the terminal) |
| `journalctl -f` | follow, like `tail -f` |
| `journalctl -b` | only the current boot; `-b -1` = previous boot; `--list-boots` |
| `journalctl -u ssh` | one service (unit). `-u ssh -u cron` for several |
| `journalctl -p err -b` | priority `err` and worse (`emerg alert crit err warning notice info debug`) |
| `journalctl --since "2 minutes ago"`, `--since 09:00 --until 09:30` | time window |
| `journalctl -k` | kernel messages only (`dmesg` equivalent) |
| `journalctl _PID=1234`, `_UID=1000` | filter by any journal field |
| `journalctl -o json-pretty`, `-o short-iso`, `-o cat` | change output format |
| `journalctl --disk-usage`, `--vacuum-time=2weeks` | how much space the journal takes, and trim it |

## Checking the logs of a specific service

I started `ssh` and `cron`, then asked for the ssh unit only:

```text
$ systemctl start ssh cron
$ journalctl -u ssh --no-pager
Sep 03 15:44:06 1e16d79ee3d9 systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Sep 03 15:44:06 1e16d79ee3d9 sshd[115]: Server listening on 0.0.0.0 port 22.
Sep 03 15:44:06 1e16d79ee3d9 sshd[115]: Server listening on :: port 22.
Sep 03 15:44:06 1e16d79ee3d9 systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
```

Restarting the service produced new lines straight away:

```text
$ systemctl restart ssh
$ journalctl -u ssh -n 6 --no-pager
Sep 03 15:44:06 1e16d79ee3d9 systemd[1]: ssh.service: Deactivated successfully.
Sep 03 15:44:06 1e16d79ee3d9 systemd[1]: Stopped ssh.service - OpenBSD Secure Shell server.
Sep 03 15:44:06 1e16d79ee3d9 systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Sep 03 15:44:06 1e16d79ee3d9 sshd[127]: Server listening on 0.0.0.0 port 22.
Sep 03 15:44:06 1e16d79ee3d9 sshd[127]: Server listening on :: port 22.
Sep 03 15:44:06 1e16d79ee3d9 systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
```

Note the PID changed from 115 to 127: the old daemon was stopped and a new one started. `journalctl -b | head` also showed the kernel boot lines, and `journalctl -o json-pretty` exposed the metadata fields (`_SYSTEMD_UNIT`, `_PID`, `PRIORITY`, `MESSAGE` ...) that the filters above work on.

## Troubleshooting recipe I will remember

```bash
systemctl status nginx            # is it up, and the last few log lines
journalctl -u nginx -b -p warning # everything worrying since boot
journalctl -u nginx -f            # watch while reproducing the problem
journalctl -b -1 -p err           # why did the machine crash last time?
```
