#!/bin/bash
# Task 3: journalctl
# Run: bash task3-journalctl.sh
# Screenshot: the system log tail and the per-service log output.
# NOTE: journalctl needs systemd. On WSL without systemd it will fail --
# use a VM or an EC2/Ubuntu box for this task.

set -u

# ---- Is systemd/journald even running here? -----------------------------
if ! command -v journalctl >/dev/null 2>&1; then
    echo "journalctl not found -- this box has no systemd. Use a VM/cloud Ubuntu."
    exit 1
fi

# ---- Last 20 system log lines -------------------------------------------
echo "--- journalctl -n 20 : newest 20 entries from the whole journal ---"
journalctl -n 20 --no-pager
echo

# ---- Only errors and worse ----------------------------------------------
# -p 3 = priority err. Handy first move when debugging a broken box.
echo "--- journalctl -p 3 -n 20 : errors only ---"
journalctl -p 3 -n 20 --no-pager
echo

# ---- Logs since boot ----------------------------------------------------
echo "--- journalctl -b -n 20 : current boot only ---"
journalctl -b -n 20 --no-pager
echo

# ---- Logs for one specific service --------------------------------------
# The ssh unit is named "ssh" on Ubuntu/Debian and "sshd" on RHEL/Amazon Linux.
# Detect it instead of hardcoding.
SVC=""
for candidate in ssh sshd; do
    if systemctl list-unit-files --type=service 2>/dev/null | grep -q "^${candidate}\.service"; then
        SVC="$candidate"
        break
    fi
done

if [ -n "$SVC" ]; then
    echo "--- journalctl -u $SVC -n 20 : logs for one service ---"
    journalctl -u "$SVC" -n 20 --no-pager
else
    echo ">> no ssh/sshd unit found; showing systemd-journald's own logs instead"
    journalctl -u systemd-journald -n 20 --no-pager
fi
echo

# ---- Time filtering -----------------------------------------------------
echo "--- journalctl --since '1 hour ago' -n 20 ---"
journalctl --since "1 hour ago" -n 20 --no-pager
echo

# ---- Follow mode (commented: it blocks forever) -------------------------
# journalctl -u "$SVC" -f      # live tail, Ctrl-C to quit

# ---- How much disk the journal eats -------------------------------------
echo "--- journalctl --disk-usage ---"
journalctl --disk-usage
