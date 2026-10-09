#!/bin/bash
# Task 4: Linux command cheat sheet -- practice run
# Run: bash task4-cheatsheet.sh
# Screenshot: whichever sections you want to show; the script is safe to run
# end-to-end (no interactive commands, no writes outside a temp dir).

set -u

WORKDIR="$(mktemp -d)"
cd "$WORKDIR" || exit 1

hr() { echo; echo "=============== $1 ==============="; }

# ---- File and directory commands ----------------------------------------
hr "FILES & DIRECTORIES"
pwd                                  # print working directory
ls -l                                # long listing
mkdir -p devops_logs                 # create dir (-p: no error if it exists)
touch index.html                     # create empty file / bump mtime
cp index.html devops_logs/           # copy
mv index.html backup_index.html      # rename / move
ls -lR                               # recursive listing
rm backup_index.html                 # delete file
rmdir devops_logs 2>/dev/null || rm -rf devops_logs   # delete dir

# ---- File viewing and search --------------------------------------------
hr "VIEW & SEARCH"
cat /etc/os-release                  # whole file
head -n 5 /etc/os-release            # first N lines
tail -n 5 /etc/os-release            # last N lines
grep -i 'ubuntu\|debian\|centos' /etc/os-release   # pattern match
wc -l /etc/os-release                # line count
find /etc -maxdepth 1 -name '*.conf' | head -5     # find by name

# NOTE: /var/log/syslog does NOT exist on Ubuntu 22.04+ / 24.04 -- rsyslog was
# dropped in favour of journald. Read logs through journalctl instead.
hr "LOGS (journald, not /var/log/syslog)"
if command -v journalctl >/dev/null 2>&1; then
    journalctl -n 10 --no-pager
    journalctl -p 3 -n 10 --no-pager     # errors only
else
    echo "no journalctl here; falling back to /var/log"
    ls -l /var/log | head -10
fi

# ---- Networking ---------------------------------------------------------
hr "NETWORKING"
ping -c 4 google.com                 # -c 4 or it never stops
ip a                                 # interfaces + addresses (replaces ifconfig)
ip route                             # routing table
curl -s -o /dev/null -w 'github api HTTP %{http_code}\n' https://api.github.com
ss -tuln | head -10                  # listening sockets (replaces netstat)
nslookup google.com 2>/dev/null | head -6 || dig +short google.com

# ---- Permissions and ownership ------------------------------------------
hr "PERMISSIONS & OWNERSHIP"
touch script.sh
ls -l script.sh                      # before
chmod 755 script.sh                  # rwx r-x r-x
ls -l script.sh                      # after
# chown user:group script.sh         # needs sudo; commented so the script stays safe
umask                                # default permission mask

# ---- Disk and storage ---------------------------------------------------
hr "DISK & STORAGE"
df -h                                # filesystem usage, human readable
du -sh /etc 2>/dev/null              # size of one dir
free -h                              # memory usage
lsblk 2>/dev/null | head -10         # block devices

# ---- User management ----------------------------------------------------
hr "USERS & GROUPS"
whoami                               # current user
id                                   # uid, gid, groups
groups                               # group memberships
who                                  # who is logged in
last -n 5 2>/dev/null                # recent logins

# ---- System information -------------------------------------------------
hr "SYSTEM INFO"
uname -a                             # kernel + arch
hostname                             # host name
uptime                               # load average + how long up
date                                 # current date/time
lscpu 2>/dev/null | head -8          # CPU details

# ---- Processes and services ---------------------------------------------
hr "PROCESSES & SERVICES"
ps aux | head -10                    # snapshot of processes
top -b -n 1 | head -15               # -b -n 1 = batch mode, one pass, then exit
                                     # (plain `top` is interactive and blocks)
if command -v systemctl >/dev/null 2>&1; then
    systemctl list-units --type=service --state=running --no-pager | head -10
fi

# ---- Archiving and packages ---------------------------------------------
hr "ARCHIVES & PACKAGES"
tar -czf demo.tar.gz script.sh       # create gzip tarball
tar -tzf demo.tar.gz                 # list contents
rm -f demo.tar.gz script.sh
apt list --installed 2>/dev/null | head -5 || echo "not a Debian/Ubuntu box"

# ---- Cleanup ------------------------------------------------------------
cd / && rm -rf "$WORKDIR"
hr "DONE"
