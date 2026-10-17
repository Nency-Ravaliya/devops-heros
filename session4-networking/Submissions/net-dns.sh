#!/usr/bin/env bash
# Networking Homework Task 2 (part 2/3) — reachability & DNS
set -u
hline() { printf '=%.0s' {1..60}; echo; }

hline; echo "ICMP REACHABILITY   ->  ping -c 3 8.8.8.8"; hline
ping -c 3 -W 2 8.8.8.8
echo
hline; echo "DNS LOOKUP          ->  dig +short google.com"; hline
dig +short google.com
echo
hline; echo "DNS RECORD DETAIL   ->  dig google.com A +noall +answer"; hline
dig google.com A +noall +answer
echo
hline; echo "DNS (nslookup)      ->  nslookup google.com"; hline
nslookup google.com | sed -n '1,5p'
echo
hline; echo "DNS (host)          ->  host example.com"; hline
host example.com
echo
echo "### NET-B-DONE ###"
