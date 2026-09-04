#!/bin/bash
# Task 2: adduser vs useradd
# Run: bash task2-users.sh
# Screenshot: the which/help output, the adduser run, and the id/getent verification.
# NOTE: needs sudo. `adduser` prompts for a password and GECOS fields interactively.

set -u

USER_NAME="linux_test_user"

# ---- Where each command lives -------------------------------------------
echo "--- which adduser / useradd ---"
which adduser
which useradd
echo

# ---- What each one actually is ------------------------------------------
# adduser: a high-level Perl/shell wrapper (Debian/Ubuntu policy tool).
# useradd: the low-level binary from the shadow-utils package.
echo "--- file: wrapper vs binary ---"
file "$(which adduser)"
file "$(which useradd)"
echo

echo "--- adduser --help (first 15 lines) ---"
adduser --help 2>&1 | head -15
echo

echo "--- useradd --help (first 15 lines) ---"
useradd --help 2>&1 | head -15
echo

# ---- Create the test user with the recommended command ------------------
# adduser is the recommended one on Ubuntu/Debian: it creates the home
# directory, copies /etc/skel, creates the matching group, and prompts for a
# password -- all in one step.
if id "$USER_NAME" >/dev/null 2>&1; then
    echo ">> $USER_NAME already exists, skipping creation"
else
    echo "--- Creating $USER_NAME with adduser (interactive) ---"
    sudo adduser "$USER_NAME"
fi
echo

# ---- Verify -------------------------------------------------------------
echo "--- id ---"
id "$USER_NAME"
echo

echo "--- getent passwd ---"
getent passwd "$USER_NAME"
echo

echo "--- home directory created + /etc/skel copied ---"
sudo ls -la "/home/$USER_NAME"
echo

# ---- Cleanup (uncomment to remove the test user) ------------------------
# sudo deluser --remove-home "$USER_NAME"
