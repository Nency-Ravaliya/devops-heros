#!/bin/bash
# Task 1: Soft link vs hard link
# Run: bash task1-links.sh
# Screenshot: the "ls -li" inode table, and the cat results after deleting the original.

set -u

WORKDIR="$(mktemp -d)"
cd "$WORKDIR" || exit 1
echo "Working in: $WORKDIR"
echo

# ---- Create the original file -------------------------------------------
echo "Hello Linux" > original.txt

# ---- Create a soft (symbolic) link --------------------------------------
ln -s original.txt soft_link.txt

# ---- Create a hard link -------------------------------------------------
ln original.txt hard_link.txt

# ---- Inode numbers and link counts --------------------------------------
# original.txt and hard_link.txt share ONE inode and show link count 2.
# soft_link.txt has its own inode and is typed "l" (a path stored as data).
echo "--- ls -li BEFORE deleting the original ---"
ls -li original.txt soft_link.txt hard_link.txt
echo

echo "--- readlink: what the soft link actually stores ---"
readlink soft_link.txt
echo

echo "--- stat: link count on the shared inode ---"
stat -c '%n  inode=%i  links=%h  size=%s' original.txt hard_link.txt soft_link.txt
echo

# ---- Delete the original ------------------------------------------------
echo "--- Deleting original.txt ---"
rm original.txt
echo

echo "--- ls -li AFTER deleting the original ---"
# soft_link.txt is now dangling (often shown in red / blinking).
ls -li soft_link.txt hard_link.txt
echo

# ---- Soft link is now broken -------------------------------------------
echo "--- cat soft_link.txt (expected to FAIL: No such file or directory) ---"
cat soft_link.txt || echo ">> soft link is dangling, as expected"
echo

# ---- Hard link still works ---------------------------------------------
echo "--- cat hard_link.txt (expected to WORK: same inode, data still referenced) ---"
cat hard_link.txt
echo

# ---- Cleanup ------------------------------------------------------------
rm -f soft_link.txt hard_link.txt
cd / && rm -rf "$WORKDIR"
echo "Cleaned up $WORKDIR"
