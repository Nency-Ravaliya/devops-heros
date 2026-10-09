#!/bin/bash
b(){ echo; echo "=====[$1]====="; }
b "ip-a";        ip -4 addr show
b "ip-route";    ip route
b "ifconfig";    ifconfig 2>/dev/null | head -12
b "hostname";    hostname; hostname -i
b "ping";        ping -c 4 google.com
b "ping-ip";     ping -c 3 8.8.8.8
b "traceroute";  traceroute -m 10 -w 2 google.com 2>&1 | head -14
b "nslookup";    nslookup github.com
b "dig";         dig github.com +noall +answer
b "dig-mx";      dig google.com MX +short
b "dig-trace";   dig github.com +trace +noall +answer 2>&1 | head -12
b "host";        host github.com
b "curl-headers";curl -sI https://github.com | head -12
b "curl-timing"; curl -s -o /dev/null -w "dns:%{time_namelookup}s connect:%{time_connect}s tls:%{time_appconnect}s ttfb:%{time_starttransfer}s total:%{time_total}s code:%{http_code} ip:%{remote_ip}\n" https://example.com
b "wget";        wget -q -O /dev/null -S https://example.com 2>&1 | head -8
b "ss-listen";   ss -tulpn 2>/dev/null | head -10
b "netstat";     netstat -tulpn 2>/dev/null | head -10
b "netstat-r";   netstat -rn
b "arp";         ip neigh
b "nc-port";     nc -zv -w 3 github.com 443 2>&1; nc -zv -w 3 github.com 8123 2>&1
b "telnet";      (echo quit | timeout 5 telnet google.com 80) 2>&1 | head -6
b "resolv";      cat /etc/resolv.conf
b "hosts";       cat /etc/hosts
b "tcpdump";     (timeout 6 tcpdump -i any -c 5 -n icmp & sleep 1; ping -c 3 8.8.8.8 >/dev/null; wait) 2>&1 | head -14
b "mtr";         mtr -r -c 3 8.8.8.8 2>&1 | head -10
b "ss-summary";  ss -s
