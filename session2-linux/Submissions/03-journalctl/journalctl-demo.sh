#!/usr/bin/env bash
#
# Task 3 — journalctl: reading the systemd journal (logs).
# journalctl talks to systemd-journald. The journal is a structured,
# indexed binary log; journalctl is the reader.
#
set -u
JC="journalctl --no-pager"

hr() { printf '%.0s-' {1..60}; echo; }

echo "journald: $(systemctl show -p Version --value systemd-journald 2>/dev/null) | systemd: $(systemctl --version | head -1)"
hr

echo ">>> 1) How much disk is the journal using?  (journalctl --disk-usage)"
$JC --disk-usage
hr

echo ">>> 2) Logs from the CURRENT boot only  (-b)"
$JC -b -n 6
hr

echo ">>> 3) Logs for one service  (-u NetworkManager.service)"
$JC -u NetworkManager.service -n 6
hr

echo ">>> 4) Only errors from this boot  (-p err -b)"
$JC -p err -b -n 6
hr

echo ">>> 5) Time-bounded query  (--since '30 min ago')"
$JC --since "30 min ago" -n 5
hr

echo ">>> 6) Between two times / relative ranges"
$JC --since "today" --until "now" -n 4
hr

echo ">>> 7) List recorded boots"
$JC --list-boots | tail -4
hr

echo ">>> 8) A useful combo: follow is -f, filter by unit + priority"
echo "   (skipped -f, it never returns)  example: journalctl -u sshd -p err -b -f"
$JC -u systemd-resolved.service -p warning -n 5
hr

echo "### HW-T3-DONE ###"
