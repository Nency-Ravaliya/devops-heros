#!/usr/bin/env bash
# Networking Homework Task 2 (part 3/3) — path, HTTP, TCP port checks
set -u
hline() { printf '=%.0s' {1..60}; echo; }

hline; echo "PATH TO HOST        ->  tracepath -m 5 8.8.8.8"; hline
tracepath -m 5 8.8.8.8 2>&1 | sed -n '1,7p'
echo
hline; echo "HTTP HEADERS        ->  curl -sI https://example.com"; hline
curl -sI --max-time 8 https://example.com | sed -n '1,6p'
echo
hline; echo "HTTP BODY           ->  curl -s https://api.github.com | head"; hline
curl -s --max-time 8 https://api.github.com | head -n 5
echo
hline; echo "TCP PORT CHECK      ->  nc -zv -w 3 1.1.1.1 443"; hline
nc -zv -w 3 1.1.1.1 443 2>&1
echo
hline; echo "TLS CERTIFICATE     ->  openssl s_client (subject/issuer)"; hline
echo | timeout 8 openssl s_client -connect example.com:443 -servername example.com 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates 2>/dev/null
echo
echo "### NET-C-DONE ###"
