# Linux Fundamentals

**Name:** Shivansh Singh  
**Enrollment Number:** 24BCS10050

## 1. Basic Linux Commands

| Command | Purpose |
|---|---|
| `ls` | List files and directories |
| `cd` | Change directory |
| `pwd` | Show current directory |
| `mkdir` | Create directory |
| `rm` | Remove files/directories |
| `touch` | Create a file |
| `cp` | Copy files |
| `mv` | Move or rename files |
| `cat` | View file contents |
| `grep` | Search inside files |

## 2. Process and Service Management

```bash
ps aux
top
htop
kill -9 PID
systemctl status nginx
systemctl restart nginx

These commands are used to monitor processes, stop processes, and manage services.

3. Networking
ping google.com
ip a
netstat -tulnp
curl https://api.github.com
wget https://example.com/file.zip

These commands are used for connectivity, IP configuration, network connections, downloading and fetching data.

4. Permissions
chmod 755 script.sh
chown user:group file.txt
umask

chmod changes permissions and chown changes ownership.

5. Package Management
Ubuntu/Debian
apt update
apt install nginx -y
RHEL/CentOS
yum install nginx -y
6. Disk and Storage
df -h
du -sh /var/log
lsblk
mount
umount

These commands are used to check disk usage, file sizes, block devices and mounted filesystems.

7. User Management
adduser devops
useradd -m -s /bin/bash devuser
usermod -aG sudo devops
passwd devops
id devops
groups devops
deluser devops
who
w
last
adduser vs useradd

adduser is more interactive and user-friendly.

useradd is a lower-level command commonly used for automated user creation.

8. Soft Links and Hard Links
Soft Link

A soft link points to another file or directory.

ln -s original.txt softlink.txt
Hard Link

A hard link points to the same underlying file data.

ln original.txt hardlink.txt
Difference
Soft Link	Hard Link
Points to a path	Points to the same file data
Can link to directories	Normally used for files
Can become broken	Remains valid while a hard link exists
ln -s	ln
9. journalctl

journalctl is used to view system logs managed by systemd.

journalctl
journalctl -xe
journalctl -u nginx
journalctl -f

journalctl -xe is useful for checking important logs during troubleshooting.

10. Advanced Linux Commands
Monitoring
top
htop
vmstat 1
iostat -xz 1
uptime
free -h
Networking
ss -tulwn
nmap IP
curl -I URL
traceroute host
File Management
rsync -avz src/ dest/
find / -type f -name "file.txt"
locate file
Logs and Debugging
journalctl -xe
tail -f /var/log/syslog
dmesg
strace -p PID
lsof -i :80
11. Scheduling and Background Jobs
crontab -e
nohup python3 app.py &

Example cron job:

0 2 * * * /home/user/backup.sh
12. System Information
uname -a
hostname
uptime
whoami
history
date
clear
13. Useful Shortcuts
Shortcut	Purpose
!!	Run last command again
!n	Run nth command from history
Ctrl+C	Cancel running command
Ctrl+L	Clear terminal
Conclusion

Linux fundamentals are important in DevOps for managing files, users, processes, services, networking, permissions, storage and system logs.