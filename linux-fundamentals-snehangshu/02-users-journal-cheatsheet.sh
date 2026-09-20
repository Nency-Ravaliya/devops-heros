#!/bin/bash
b(){ echo; echo "=====[$1]====="; }
export DEBIAN_FRONTEND=noninteractive
b "T2-which"
which useradd adduser; file $(which adduser) | cut -d: -f2
b "T2-useradd-lowlevel"
useradd testuser_low
grep '^testuser_low' /etc/passwd
ls -ld /home/testuser_low 2>&1
b "T2-adduser-recommended"
adduser --disabled-password --gecos "" testuser_hw 2>&1
b "T2-verify-adduser"
grep '^testuser_hw' /etc/passwd
ls -ld /home/testuser_hw
ls -A /home/testuser_hw
id testuser_hw
b "T2-compare"
echo "useradd  : $(grep '^testuser_low' /etc/passwd)"
echo "adduser  : $(grep '^testuser_hw'  /etc/passwd)"
b "T3-journal-boot"
journalctl --no-pager -b -n 5
b "T3-journal-unit"
systemctl start cron 2>/dev/null; sleep 1
journalctl --no-pager -u cron -n 5
b "T3-journal-priority"
journalctl --no-pager -p err -b -n 5; echo "(exit $?)"
b "T3-journal-since"
journalctl --no-pager --since "10 minutes ago" -n 5
b "T3-journal-diskusage"
journalctl --disk-usage
b "T3-journal-kernel-json"
journalctl --no-pager -n 1 -o json-pretty | head -15
b "T4-cheatsheet"
echo "-- whoami --"; whoami
echo "-- uname -a --"; uname -a
echo "-- pwd --"; pwd
echo "-- df -h --"; df -h | head -5
echo "-- free -h --"; free -h
echo "-- ps aux (top 5) --"; ps aux | head -5
echo "-- top -bn1 (head) --"; top -bn1 | head -5
echo "-- uptime --"; uptime
echo "-- du -sh /etc --"; du -sh /etc
echo "-- grep -rn 'root' /etc/passwd --"; grep -n 'root' /etc/passwd | head -3
echo "-- find /etc -name '*.conf' (5) --"; find /etc -name '*.conf' | head -5
echo "-- chmod/chown demo --"; touch /root/perm.txt; chmod 754 /root/perm.txt; chown testuser_hw:testuser_hw /root/perm.txt; ls -l /root/perm.txt
echo "-- tar --"; tar -czf /root/etcsample.tar.gz /etc/hostname /etc/hosts 2>/dev/null; ls -lh /root/etcsample.tar.gz; tar -tzf /root/etcsample.tar.gz
echo "-- head/tail --"; head -3 /etc/passwd; echo "..."; tail -3 /etc/passwd
echo "-- wc -l /etc/passwd --"; wc -l /etc/passwd
echo "-- sort/uniq --"; cut -d: -f7 /etc/passwd | sort | uniq -c | sort -rn
echo "-- awk --"; awk -F: '$3>=1000 {print $1, $3}' /etc/passwd
echo "-- sed --"; echo "devops heros" | sed 's/heros/heroes/'
echo "-- env | head -5 --"; env | sort | head -5
echo "-- history/alias --"; alias ll='ls -l'; alias | head -3
