# Session 4 — Commands Homework

Commands covered: `ping`, `sum`, and special linking (soft link / hard link).

---

## 1. `ping`

**What it does:** Checks whether another machine on the network is reachable, and how long a round trip takes. It sends ICMP "echo request" packets and waits for "echo reply" packets to come back.

**Command:**

```bash
ping -c 4 google.com
```

**Output:**

```
PING google.com (142.250.77.142): 56 data bytes
64 bytes from 142.250.77.142: icmp_seq=0 ttl=118 time=12.664 ms
64 bytes from 142.250.77.142: icmp_seq=1 ttl=118 time=14.472 ms
64 bytes from 142.250.77.142: icmp_seq=2 ttl=118 time=14.062 ms
64 bytes from 142.250.77.142: icmp_seq=3 ttl=118 time=20.929 ms

--- google.com ping statistics ---
4 packets transmitted, 4 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 12.664/15.532/20.929/3.187 ms
```

**Reading the output:**

| Field | Meaning |
|---|---|
| `142.250.77.142` | The IP address that `google.com` resolved to — so DNS worked before any packet was even sent |
| `icmp_seq` | Packet sequence number. A missing number means that packet was lost |
| `ttl=118` | Time To Live — the hop budget left. Each router decreases it by 1. Started at 128, so the reply crossed roughly 10 routers |
| `time=12.664 ms` | Round-trip time for that one packet |
| `0.0% packet loss` | Every packet came back — a healthy, stable link |
| `min/avg/max/stddev` | Summary of all 4 round trips. Low stddev (3.187 ms) means consistent latency, not a jittery connection |

**What I understood:**

`ping` is the first tool to reach for when "the network is down." It actually tests three separate things at once, which is why it is so useful for narrowing a problem:

1. **DNS** — if the hostname could not be resolved, it fails immediately with `cannot resolve google.com` and no packets are sent at all.
2. **Reachability** — whether packets can get to the destination and back.
3. **Quality** — latency and packet loss, not just up/down.

So the failure mode tells you where the problem is. If `ping google.com` fails but `ping 8.8.8.8` succeeds, the network is fine and DNS is broken. If both fail, it is connectivity or the gateway. If packets return but with high loss or a large stddev, the link is up but unreliable — often worse to debug than a clean outage.

The `-c 4` flag limits it to 4 packets. Without it, `ping` runs forever until stopped with `Ctrl+C`.

One caveat: a failed ping does not always mean a host is down. Many servers and firewalls deliberately block ICMP, so they stay silent while still serving traffic normally on ports 80/443.

---

## 2. `sum`

**What it does:** Prints a checksum and block count for a file. The checksum is a short number calculated from the file's contents, used to verify that a file has not changed or been corrupted.

**Command:**

```bash
sum original.txt
cksum original.txt
wc -c original.txt
```

**Output:**

```
### sum
35893 1 original.txt
### cksum
3844424620 55 original.txt
### wc -c
      55 original.txt
```

The `sum` output is two values: `35893` is the checksum, `1` is the size in 1K blocks.

**Proving it detects change** — append a single character and re-run:

```bash
printf 'x' >> original.txt
sum original.txt
cksum original.txt
```

```
### sum again
50834 1 original.txt
### cksum again
1210282005 56 original.txt
```

**What I understood:**

One added character changed the checksum from `35893` to `50834` — completely, not slightly. That is the whole point: you cannot tell from a checksum *what* changed, only that *something* did. This is what makes it useful for integrity checking. Download a file, compare its checksum against the one the publisher posted, and if they match the file arrived intact.

The block count is also worth noting. `sum` reported `1` block both times, because a 55-byte and a 56-byte file both round up to one 1K block — so the block count is far too coarse to detect a change on its own. `cksum` is more informative here: it reported the exact byte count (55, then 56) alongside its checksum, which matches what `wc -c` said.

`sum` is an old utility with a weak 16-bit checksum, so different collisions are possible and it is not suitable for security. In real DevOps work the modern replacements are used instead:

| Command | Use |
|---|---|
| `sum` | Legacy, 16-bit — quick corruption check only |
| `cksum` | CRC-32 plus exact byte count |
| `md5sum` / `md5` | 128-bit, common for download verification, but broken for security |
| `sha256sum` / `shasum -a 256` | The current standard for verifying releases and container images |

The practical lesson is the distinction between *integrity* and *security*. A checksum catches accidental corruption — a truncated download, a bad disk. It does not stop a deliberate attacker, who could alter a file and simply publish a matching checksum. That is why signed checksums (GPG) are used for real software releases.

---

## 3. Special linking — soft links and hard links

**What it does:** `ln` creates a second name that points to an existing file, so the same data can be reached from more than one path without duplicating it.

- `ln -s target linkname` → **soft link** (symbolic link / symlink) — a small separate file that stores the *path* of the target, like a shortcut.
- `ln target linkname` → **hard link** — a second directory entry pointing at the *same inode*, so both names are equally real.

**Commands:**

```bash
printf 'Hello DevOps Heroes\nLearning about links.\n' > original.txt
ln -s original.txt soft-link.txt
ln original.txt hard-link.txt
ls -li
```

**Output:**

```
total 16
64838572 -rw-r--r--@ 2 vanditabyaadwivedi  wheel  42 Aug 31 13:16 hard-link.txt
64838572 -rw-r--r--@ 2 vanditabyaadwivedi  wheel  42 Aug 31 13:16 original.txt
64838573 lrwxr-xr-x@ 1 vanditabyaadwivedi  wheel  12 Aug 31 13:16 soft-link.txt -> original.txt
```

The `-i` flag shows the **inode number** — the filesystem's internal ID for the actual data. Three things stand out:

- `original.txt` and `hard-link.txt` share inode **64838572**. They are two names for one piece of data.
- `soft-link.txt` has its own inode **64838573**, and its own type flag `l` (instead of `-`) at the start of the permissions. It is a genuinely different file.
- The link count column (after the permissions) reads `2` for the hard-linked pair and `1` for the symlink. That count is how many names point to the inode.
- The symlink's size is **12 bytes** — exactly the length of the string `original.txt`. That is literally all it contains: the path.

Both read the same content:

```bash
cat soft-link.txt
cat hard-link.txt
```

```
Hello DevOps Heroes
Learning about links.
```

**The deletion test** — this is where the two behave completely differently:

```bash
rm original.txt
ls -li
cat hard-link.txt
cat soft-link.txt
```

```
total 8
64838572 -rw-r--r--@ 1 vanditabyaadwivedi  wheel  42 Aug 31 13:16 hard-link.txt
64838573 lrwxr-xr-x@ 1 vanditabyaadwivedi  wheel  12 Aug 31 13:16 soft-link.txt -> original.txt

### cat hard-link.txt (still works)
Hello DevOps Heroes
Learning about links.

### cat soft-link.txt (broken)
cat: soft-link.txt: No such file or directory
```

**What I understood:**

Deleting `original.txt` did **not** delete the data. The hard link still prints the file contents perfectly, and its link count simply dropped from `2` to `1`.

This clarified what `rm` actually does. `rm` does not erase file contents — it removes *one name* and decrements the inode's link count. The data is only freed when that count reaches zero. Since `hard-link.txt` still pointed at inode 64838572, the count went to 1, not 0, and the data survived.

The soft link broke instead, because it never held the data — only the text `original.txt`. Once nothing answered to that name, the link became a **dangling symlink**: still present in `ls`, still looking valid, but pointing at nothing. Note that `ls` happily lists it while `cat` fails, which is a realistic way this bites you in practice.

**Comparison:**

| | Soft link (`ln -s`) | Hard link (`ln`) |
|---|---|---|
| Inode | Own, separate inode | Same inode as target |
| Stores | The target's *path* | Nothing — it *is* the file |
| Size | Length of the path string (12 bytes here) | Same as the file (42 bytes) |
| Delete the original | Link breaks | Data survives |
| Across filesystems / disks | Works | Not allowed |
| On directories | Allowed | Not allowed (would create loops) |
| `ls -l` type flag | `l` | `-` |

Hard links are restricted to a single filesystem because an inode number is only meaningful within its own filesystem — number 64838572 on one disk has nothing to do with 64838572 on another. A symlink is just a stored string, so it can point anywhere, including across disks or at a path that does not exist yet.

**Where this shows up in DevOps:** symlinks are used constantly for release management — `/app/current -> /app/releases/v1.2.3`, where deploying is just repointing the symlink and rolling back is repointing it again. `nginx` uses the same idea with `sites-enabled/` holding symlinks into `sites-available/`. Hard links are what make backup tools like `rsync --link-dest` efficient: unchanged files across snapshots are hard-linked, so ten daily backups of the same file consume the space of one.

---

## Summary

| Command | Purpose | Key takeaway |
|---|---|---|
| `ping` | Test reachability and latency | Tests DNS, connectivity, and quality at once — the failure mode tells you which one broke |
| `sum` | Checksum a file | Any change flips the checksum entirely; catches corruption, not tampering |
| `ln -s` | Soft link | Stores a path — breaks if the target is removed |
| `ln` | Hard link | Shares the inode — data survives deletion of the original name |
