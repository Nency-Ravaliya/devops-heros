#!/usr/bin/env bash
#
# Task 2 — adduser vs useradd, and creating a test user.
# On Debian/Ubuntu the recommended command is `adduser` (friendly wrapper).
# On Arch/Omarchy (this machine) only `useradd` (shadow) exists, so we use it
# and reproduce exactly what adduser does for us.
#
set -u
PW='2169'
if [ "$(id -u)" -eq 0 ]; then
  SUDO() { "$@"; }
else
  SUDO() { echo "$PW" | sudo -S "$@"; }
fi

hr() { printf '%.0s-' {1..60}; echo; }

echo "os: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2)"
hr

echo ">>> 1) Is the Debian-style 'adduser' available here?"
if command -v adduser >/dev/null 2>&1; then
  echo "adduser -> $(command -v adduser)"
else
  echo "adduser: NOT INSTALLED  (Debian/Ubuntu perl wrapper, not shipped in Arch shadow)"
fi
echo "useradd -> $(command -v useradd)"
hr

echo ">>> 2) useradd is low-level: no prompts, every option explicit"
useradd --help 2>&1 | sed -n '1,6p'
hr

echo ">>> 3) Create a test user (adduser-style: home dir + bash shell + comment)"
SUDO useradd -m -s /bin/bash -c "Homework Test User" testuser && echo "created testuser"
echo 'testuser:TestPass123' | SUDO chpasswd
echo "password set (chpasswd, non-interactive)"
hr

echo ">>> 4) Verify the account"
id testuser
getent passwd testuser
hr

echo ">>> 5) -m created the home dir + skeleton files (adduser does this automatically)"
SUDO ls -ld /home/testuser
SUDO ls -A /home/testuser | head -3
echo "groups: $(groups testuser)"
hr

echo ">>> 6) Password is stored HASHED (not plaintext) in /etc/shadow"
echo "   (real hash redacted below for security)"
SUDO getent shadow testuser | cut -d: -f1,2 | sed -E 's/^(testuser:)[^:]*$/\1$6$...hash.../'
hr

echo ">>> 7) useradd WITHOUT -m creates no home (the key adduser convenience)"
SUDO useradd -M -s /usr/bin/nologin tmpuser 2>/dev/null && echo "created tmpuser (no home)"
ls -ld /home/tmpuser 2>&1 | sed 's/^/   /'
echo "removing throwaway user (userdel -r) ..."
SUDO userdel -r tmpuser && echo "   tmpuser removed"
id tmpuser 2>&1 | sed 's/^/   /'
hr

echo ">>> 8) Test user left in place for the lab:"
getent passwd testuser
hr

echo "### HW-T2-DONE ###"
