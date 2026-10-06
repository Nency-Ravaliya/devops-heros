# Session 3 — System information script

Student: Viraj Bhanage, roll 24BCS10274  
Enrollment number: `24BCS10274`

Script: [system_info.sh](system_info.sh)

It prints the date, hostname, username, and disk usage. It reads a name, enrollment number, and comment with `read -p`. It creates `student-output/`, touches `processes.log`, and redirects `ps aux` into that file.

## Command output

Captured on 6 Oct 2026:

```text
Current date: Tue Oct  6 19:51:01 WITA 2026
Hostname: Virajs-MacBook-Pro-3.local
Username: bhanageviraj

Disk usage:
/dev/disk3s1s1   926Gi   13Gi   221Gi    6%   /

My name is Viraj Bhanage
My enrollment number is 24BCS10274
My comment is: Session 3 lab for Viraj Bhanage.
```

The full `df` listing from that run is in [script-output.txt](script-output.txt). The process log is generated locally and is gitignored, because a full process list from a laptop does not belong in a public repository. Run the script again and the file is recreated:

```bash
chmod +x system_info.sh
./system_info.sh
wc -l student-output/processes.log
```
