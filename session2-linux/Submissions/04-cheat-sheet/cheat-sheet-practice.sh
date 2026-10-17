#!/usr/bin/env bash
#
# Task 4 — practice a selection of the cheat-sheet commands on THIS machine.
# Each command is run for real so the screenshot shows genuine output.
#
set -u

hr() { printf '%.0s-' {1..60}; echo; }

echo "Cheat-sheet practice on $(hostname) — real output"
hr

echo ">>> uname -a        (kernel & system info)"
uname -a
hr

echo ">>> hostname / whoami / date / uptime"
echo "hostname : $(hostname)"
echo "whoami   : $(whoami)"
echo "date     : $(date)"
echo "uptime   :$(uptime -p)  (load:$(cut -d' ' -f1-3 /proc/loadavg))"
hr

echo ">>> df -h           (disk usage)"
df -h / /home 2>/dev/null | head -5
hr

echo ">>> du -sh          (folder size)"
du -sh /var/log 2>/dev/null
hr

echo ">>> ip a            (network config, first interface)"
ip -brief a | head -5
hr

echo ">>> ps aux | head   (processes)"
ps aux --sort=-%mem | head -5
hr

echo ">>> grep inside a file"
grep -E '^(NAME|PRETTY_NAME)=' /etc/os-release
hr

echo ">>> ls -l /etc/os-release  + stat"
ls -l /etc/os-release
stat -c 'perms=%A owner=%U:%G size=%s bytes' /etc/os-release
hr

echo ">>> history        (last 5 commands in this shell)"
history 2>/dev/null | tail -5 || echo "(history not enabled in non-interactive script)"
hr

echo "### HW-T4-DONE ###"
