#!/bin/bash
b(){ echo; echo "=====[$1]====="; }
b "OS-IDENTITY"
cat /etc/os-release | grep -E "^NAME|^VERSION="
echo "--- uname -srm ---"; uname -srm
echo "--- arch ---"; arch
b "JOURNAL-REAL-SERVICE"
systemctl start cron 2>/dev/null; systemctl status cron --no-pager 2>&1 | head -6
b "JOURNAL-UNIT-CRON"
journalctl --no-pager -u cron -n 5
b "JOURNAL-GENERATE-AND-READ"
logger -p user.notice -t deploy-script "starting deployment of devops-heros build 42"
logger -p user.err    -t deploy-script "failed to reach database on port 3306"
logger -p user.info   -t deploy-script "deployment finished"
sleep 1
echo "--- journalctl -t deploy-script ---"
journalctl --no-pager -t deploy-script -n 10
b "JOURNAL-PRIORITY-ERR"
journalctl --no-pager -p err -n 5 -t deploy-script
b "JOURNAL-SINCE"
journalctl --no-pager --since "5 minutes ago" -t deploy-script
b "JOURNAL-USER-CREATION"
journalctl --no-pager -n 5 -t useradd -t groupadd -t chfn 2>/dev/null | head -8
b "JOURNAL-DISK-USAGE"
journalctl --disk-usage
b "JOURNAL-JSON"
journalctl --no-pager -n 1 -t deploy-script -o json-pretty | head -14
b "SYSTEMCTL-LIST"
systemctl list-units --type=service --no-pager 2>&1 | head -8
