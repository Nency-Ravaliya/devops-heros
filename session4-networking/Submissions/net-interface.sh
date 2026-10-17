#!/usr/bin/env bash
# Networking Homework Task 2 (part 1/3) — interfaces, routes, neighbours, sockets
set -u
hline() { printf '=%.0s' {1..60}; echo; }

hline; echo "ADDRESSES          ->  ip -brief addr"; hline
ip -brief addr
echo
hline; echo "ROUTING TABLE      ->  ip route"; hline
ip route
echo
hline; echo "NEIGHBOURS (ARP)   ->  ip neigh"; hline
ip neigh
echo
hline; echo "LISTENING PORTS    ->  ss -tuln"; hline
ss -tuln | head -n 12
echo
hline; echo "DNS SERVERS        ->  cat /etc/resolv.conf"; hline
grep -v '^#' /etc/resolv.conf | sed '/^$/d'
echo
echo "### NET-A-DONE ###"
