# Task 1 – Soft links vs hard links

## The one-line mental model

* A **hard link** is *another name for the same inode*. Two directory entries, one piece of data.
* A **soft (symbolic) link** is *a tiny separate file whose content is a path*. It is resolved every time you open it.

```text
 hard.txt ─┐                      soft.txt ──(contains the text "original.txt")──▶ original.txt ─┐
           ├──▶ inode 278152 ──▶ data                                                              ├──▶ inode 278152
 original.txt ┘                                                                                    ┘
```

## Commands

```bash
ln  original.txt hard.txt     # hard link  (no flag)
ln -s original.txt soft.txt   # soft link  (-s = symbolic)
ls -li                        # -i shows inode numbers
readlink soft.txt             # where does the symlink point?
stat -c '%n inode=%i links=%h' original.txt hard.txt soft.txt
rm hard.txt soft.txt          # deleting a link never touches the data of the other names
find . -xtype l               # find dangling symlinks
```

## What I observed (from the transcript)

```text
$ ls -li
278152 -rw-r--r-- 2 root root 29 Sep  3 15:35 hard.txt
278152 -rw-r--r-- 2 root root 29 Sep  3 15:35 original.txt
278153 lrwxrwxrwx 1 root root 12 Sep  3 15:35 soft.txt -> original.txt
```

* `hard.txt` and `original.txt` share inode **278152** and the link count is **2**.
* `soft.txt` has its own inode, type `l`, and its size is 12 bytes = `len("original.txt")`.

Then I renamed the original:

```text
$ mv original.txt renamed.txt
$ cat soft.txt
cat: soft.txt: No such file or directory      <- dangling, it still says "original.txt"
$ cat hard.txt
hello from the original file                  <- unaffected, it never cared about the name
appended via hard link
```

And deleted the last "original" name:

```text
$ rm renamed.txt
$ ls -li
278152 -rw-r--r-- 1 root root 52 hard.txt    <- link count dropped 2 -> 1, data still there
278153 lrwxrwxrwx 1 root root 12 soft.txt -> original.txt
```

Directories:

```text
$ ln -s /root/links linkdir      # fine
$ ln /root/links hard_dir
ln: /root/links: hard link not allowed for directory
```

## Comparison table

| | Hard link | Soft link |
|---|---|---|
| Command | `ln target name` | `ln -s target name` |
| Points to | inode (the data) | a path string |
| Same inode number? | yes | no |
| Survives `rm`/`mv` of the original? | yes, data lives until link count hits 0 | no, becomes dangling |
| Can link a directory? | no (only `.` and `..` are hard links to dirs) | yes |
| Can cross filesystems / partitions? | no, inodes are per-filesystem | yes |
| Shown by `ls -l` as | a normal file | `lrwxrwxrwx ... name -> target` |
| Size | same as the file | length of the target path |
| Permissions | shared with the file | always `777`, target's perms apply |

## Interview answer (30 seconds)

> A hard link is a second directory entry for the same inode, so both names are equal owners of the data and the file is only removed when the last hard link is deleted; hard links cannot span filesystems or point to directories. A symbolic link is a separate small file that stores a path; it can point anywhere, including directories and other filesystems, but it breaks if the target is moved or removed. `ls -li` shows hard links sharing an inode number and symlinks with an `l` type and an arrow.

Follow-up questions I prepared for:

* *Why does a fresh empty directory have link count 2?* Its own entry plus `.` inside it; every subdirectory adds one more via `..`.
* *How do package managers use symlinks?* Alternatives such as `/usr/bin/python3 -> python3.12`, and version switching in tools like `nvm`.
* *How do backup tools use hard links?* `rsync --link-dest` and Time Machine style snapshots share unchanged files between snapshots at zero extra cost.
