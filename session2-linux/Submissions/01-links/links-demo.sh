#!/usr/bin/env bash
#
# Task 1 — Soft (symbolic) links vs Hard links
# Demonstrates creation, inode identity, and deletion behaviour.
#
set -u

WORK="/tmp/hw-links-demo"
rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"

hr() { printf '%.0s-' {1..60}; echo; }

echo "Working directory: $(pwd)"
hr

echo ">>> 1) Create an original file"
echo "This is the original file" > original.txt
ls -li original.txt
hr

echo ">>> 2) Create a HARD link (ln) and a SOFT link (ln -s)"
ln    original.txt hardlink.txt
ln -s original.txt softlink.txt
ls -li original.txt hardlink.txt softlink.txt
echo
echo "Inode numbers: original.txt + hardlink.txt SHARE the same inode (same data)."
echo "softlink.txt has its OWN inode and just points at the path."
hr

echo ">>> 3) stat: count the hard links to the inode"
stat -c '%n -> inode=%i  links=%h  type=%F' original.txt hardlink.txt softlink.txt
hr

echo ">>> 4) Delete the ORIGINAL file"
rm original.txt
ls -li
echo
echo -n "hardlink.txt still readable?  "; cat hardlink.txt
echo -n "softlink.txt still readable?  "; cat softlink.txt 2>&1
hr

echo ">>> 5) Recreate the original -> the soft link works again"
echo "This is the original file" > original.txt
echo -n "softlink.txt now:             "; cat softlink.txt
hr

echo ">>> 6) Delete the links (rm removes links, not the target)"
run_rm() { rm "$1" && echo "   removed $1"; }
run_rm softlink.txt
run_rm hardlink.txt
ls -li
hr

echo ">>> 7) A hard link cannot span filesystems; a soft link can"
ln /etc/hostname "$WORK/etc-hostname-hard" 2>&1 || true
ln -s /etc/hostname     "$WORK/etc-hostname-soft"
ls -l "$WORK/etc-hostname-soft"; cat "$WORK/etc-hostname-soft"
hr

echo "### HW-T1-DONE ###"
