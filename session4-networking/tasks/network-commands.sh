#!/bin/bash
# Session 4 - Networking Fundamentals
# Runs the 14 networking commands from the course material and prints the output.
#
# Run: bash network-commands.sh
#
# Four of these need packages that Ubuntu does not ship by default:
#   sudo apt update && sudo apt install -y traceroute iputils-tracepath inetutils-telnet dnsutils
# The script checks for them and says so rather than failing.

set -u

hr() { echo; echo "=============== $1 ==============="; }

# ---- 1. hostname ---------------------------------------------------------
hr "1. hostname"
hostname

# ---- 2. whoami -----------------------------------------------------------
hr "2. whoami"
whoami

# ---- 3. ip a -------------------------------------------------------------
hr "3. ip a"
ip a

# ---- 4. hostname -I ------------------------------------------------------
hr "4. hostname -I"
hostname -I

# ---- 5. ip route ---------------------------------------------------------
hr "5. ip route"
ip route

# ---- 6. ping -------------------------------------------------------------
# -c 4 stops after four packets. Without it ping runs until interrupted.
hr "6. ping -c 4 8.8.8.8"
ping -c 4 8.8.8.8

# ---- 7. nslookup ---------------------------------------------------------
hr "7. nslookup google.com"
if command -v nslookup >/dev/null 2>&1; then
    nslookup google.com
else
    echo "nslookup not installed - run: sudo apt install -y dnsutils"
fi

# ---- 8. curl -------------------------------------------------------------
hr "8. curl https://api.github.com"
curl -s https://api.github.com | head -n 12

# ---- 9. curl -I ----------------------------------------------------------
# -I sends a HEAD request: response headers only, no body.
hr "9. curl -I https://www.google.com"
curl -sI https://www.google.com

# ---- 10. ss --------------------------------------------------------------
# -t TCP, -u UDP, -l listening only, -n numeric ports (no /etc/services lookup)
hr "10. ss -tuln"
ss -tuln

# ---- 11. /etc/hosts ------------------------------------------------------
hr "11. cat /etc/hosts"
cat /etc/hosts

# ---- 12. tracepath -------------------------------------------------------
# -m 10 caps the hop count so the script does not stall on a long path.
hr "12. tracepath -m 10 google.com"
if command -v tracepath >/dev/null 2>&1; then
    tracepath -m 10 google.com
else
    echo "tracepath not installed - run: sudo apt install -y iputils-tracepath"
fi

# ---- 13. traceroute ------------------------------------------------------
hr "13. traceroute -m 10 google.com"
if command -v traceroute >/dev/null 2>&1; then
    traceroute -m 10 google.com
else
    echo "traceroute not installed - run: sudo apt install -y traceroute"
fi

# ---- 14. telnet ----------------------------------------------------------
# telnet is interactive, so </dev/null closes the session immediately after the
# connection is made, and timeout is a backstop. Port 80 on a web server is the
# classic "is this port open" test.
hr "14. telnet google.com 80"
if command -v telnet >/dev/null 2>&1; then
    timeout 5 telnet google.com 80 </dev/null
    echo "(connection closed by the script - telnet is interactive)"
else
    echo "telnet not installed - run: sudo apt install -y inetutils-telnet"
fi

hr "DONE"
