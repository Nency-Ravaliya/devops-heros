#!/bin/bash
b(){ echo; echo "=====[$1]====="; }
b "T1-setup"
mkdir -p /root/linklab && cd /root/linklab
echo "Hello from the original file" > original.txt
ln -s original.txt soft_link.txt
ln original.txt hard_link.txt
ls -li
b "T1-inode-compare"
stat -c '%n -> inode %i, links %h, size %s, type %F' original.txt hard_link.txt soft_link.txt
b "T1-content"
cat soft_link.txt; cat hard_link.txt
b "T1-append-then-read"
echo "Second line added via hard link" >> hard_link.txt
cat original.txt
b "T1-delete-original"
rm original.txt
ls -li
echo "--- reading soft link after deleting original ---"
cat soft_link.txt 2>&1
echo "--- reading hard link after deleting original ---"
cat hard_link.txt
b "T1-dangling-check"
ls -l soft_link.txt; test -e soft_link.txt && echo "soft link target EXISTS" || echo "soft link is DANGLING (broken)"
b "T1-hardlink-to-dir"
ln /tmp /root/dirlink 2>&1 || true
ln -s /tmp /root/dirsoftlink && ls -ld /root/dirsoftlink
