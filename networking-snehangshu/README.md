# Session 4 — Networking Fundamentals

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Topic:** Networking commands — execution, output and explanation

Every command below was executed on a real Linux host with full network tooling
(`iproute2`, `bind-utils`, `curl`, `tcpdump`, `mtr`, `netcat`). All output blocks are the
actual terminal output, not examples.

---

## Task 1 — Practise the networking commands

## Task 2 — Command outputs with explanations

---

### 1. `ip addr` — show interface addresses

```bash
ip -4 addr show
```

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0@if12: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default  link-netnsid 0
    inet 172.17.0.3/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```

**What I understood:** `ip addr` lists every network interface and the IP addresses bound
to it. `lo` is the loopback interface — `127.0.0.1` never leaves the machine and is how a
process talks to itself. `eth0` is the real interface with address `172.17.0.3/16`; the
`/16` is the subnet mask, meaning the first 16 bits (`172.17.`) identify the network and
the rest identify the host, so this network can hold ~65 534 addresses. `mtu 1500` is the
largest frame the link will carry, and `state UP` means the link is live. This is the
modern replacement for `ifconfig`.

---

### 2. `ifconfig` — the legacy equivalent

```bash
ifconfig
```

```
eth0      Link encap:Ethernet  HWaddr 9A:DB:DA:9B:98:DF
          inet addr:172.17.0.3  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:3 errors:0 dropped:0 overruns:0 frame:0
          TX packets:1 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:238 (238.0 B)  TX bytes:42 (42.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
```

**What I understood:** `ifconfig` shows the same information plus per-interface counters.
`HWaddr` is the **MAC address** — the layer-2 hardware identifier, unique per NIC, used to
deliver frames inside the local segment (IP is layer 3 and routes *between* segments).
The `errors`/`dropped`/`collisions` counters are the first thing to check when a link is
flaky. `ifconfig` is deprecated in favour of `ip`, but still very common on older systems.

---

### 3. `hostname` — machine name and IP

```bash
hostname
hostname -i
```

```
233e79f6a710
172.17.0.3
```

**What I understood:** `hostname` prints the system's name; `-i` resolves it to an IP by
looking it up (usually via `/etc/hosts`). Useful for confirming which box you are actually
logged into before running something destructive.

---

### 4. `ping` — is the host reachable, and how far away is it?

```bash
ping -c 4 google.com
```

```
PING google.com (192.178.173.100) 56(84) bytes of data.
64 bytes from 192.178.173.100: icmp_seq=1 ttl=63 time=43.2 ms
64 bytes from 192.178.173.100: icmp_seq=2 ttl=63 time=176 ms
64 bytes from 192.178.173.100: icmp_seq=3 ttl=63 time=40.1 ms
64 bytes from 192.178.173.100: icmp_seq=4 ttl=63 time=30.8 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 30.764/72.450/175.713/59.795 ms
```

```bash
ping -c 3 8.8.8.8
```

```
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=63 time=30.7 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=63 time=124 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=63 time=28.9 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 28.901/61.140/123.824/44.330 ms
```

**What I understood:** `ping` sends **ICMP echo request** packets and times the replies.
Three things to read here:

- `0% packet loss` — the path is healthy. Loss is what you actually care about; a slow but
  lossless path is usually fine, a lossy one is not.
- `time=...` is the **round-trip time**. The `mdev` (jitter) of ~60 ms shows the latency is
  inconsistent — this was a home/WiFi link, not a datacentre.
- `ttl=63` — Time To Live. It starts at 64 and each router decrements it by one, so a
  returning TTL of 63 means the reply crossed **one** routing hop. TTL also prevents
  packets looping forever.

Pinging the name first resolved `google.com` to an IP — so a successful `ping <hostname>`
proves **both** DNS and connectivity, while `ping 8.8.8.8` isolates pure connectivity. If
the IP pings but the name does not, the problem is DNS.

---

### 5. `traceroute` — what path do packets take?

```bash
traceroute -m 10 -w 2 google.com
```

```
traceroute to google.com (192.178.173.100), 10 hops max, 46 byte packets
 1  172.17.0.1 (172.17.0.1)  0.005 ms  0.004 ms  0.003 ms
 2  *  *  *
 3  *  *  *
 4  *  *  *
 5  *  *  *
 ...
```

**What I understood:** `traceroute` maps the route hop by hop by sending packets with
TTL=1, 2, 3 … — each router that discards an expired packet replies with "time exceeded",
revealing its address. Hop 1 is my default gateway `172.17.0.1`, answering in 0.005 ms
because it is on the same host. The `* * *` on later hops does **not** mean the route is
broken — connectivity clearly worked in the `ping` above. It means those routers are
configured not to reply to the probes (very common, and ISPs often rate-limit ICMP).
`mtr` below gets around this by using a different probe method.

---

### 6. `mtr` — traceroute + ping combined

```bash
mtr -r -c 3 8.8.8.8
```

```
Start: 2026-09-17T20:33:42+0000
HOST: 233e79f6a710                Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 172.17.0.1                 0.0%     3    0.1   0.1   0.1   0.2   0.0
  2.|-- 8.8.8.8                    0.0%     3   49.0  63.5  18.9 122.8  53.4
```

**What I understood:** `mtr` continuously probes every hop and gives per-hop loss and
latency statistics. This is the tool for answering "*where* is the connection breaking?" —
the first hop showing sustained loss is where the problem starts. Here both hops show 0%
loss, so the path is clean; the high `StDev` at hop 2 again shows jitter, not loss.

---

### 7. `nslookup` — DNS lookup

```bash
nslookup github.com
```

```
Server:		192.168.65.7
Address:	192.168.65.7#53

Non-authoritative answer:
Name:	github.com
Address: 20.207.73.82
```

**What I understood:** `nslookup` asks a DNS resolver to turn a name into an IP. `Server:`
is the resolver that answered, on the standard DNS port **53**. *"Non-authoritative"* means
this resolver is serving a cached copy rather than being the zone's own authoritative name
server — which is normal and is what makes DNS fast.

---

### 8. `dig` — the detailed DNS tool

```bash
dig github.com +noall +answer
```

```
github.com.		55	IN	A	20.207.73.82
```

```bash
dig google.com MX +short
```

```
10 smtp.google.com.
```

**What I understood:** `dig` is the DNS debugging tool of choice because it shows the raw
record. Reading the answer line: name `github.com.` (the trailing dot = the DNS root),
**TTL 55 seconds** (how much longer this answer may be cached — a low TTL is what lets you
fail over quickly), class `IN` (Internet), type **`A`** (IPv4 address), then the value.

Common record types:

| Type | Meaning |
|---|---|
| `A` / `AAAA` | IPv4 / IPv6 address |
| `CNAME` | Alias to another name |
| `MX` | Mail exchanger (the `10` above is its priority — lower wins) |
| `NS` | Authoritative name servers for the zone |
| `TXT` | Free text — used for SPF, domain verification |

---

### 9. `host` — the quick lookup

```bash
host github.com
```

```
github.com has address 20.207.73.82
github.com mail is handled by 0 github-com.mail.protection.outlook.com.
```

**What I understood:** `host` is the one-line, human-readable version of `dig`. Note it
returns both the A record and the MX record — and the MX points at Outlook, which tells you
GitHub outsources its mail. That is the kind of thing DNS quietly reveals.

---

### 10. `/etc/resolv.conf` and `/etc/hosts` — how names get resolved

```bash
cat /etc/resolv.conf
```

```
# Generated by Docker Engine.
nameserver 192.168.65.7
```

```bash
cat /etc/hosts
```

```
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::	ip6-localnet
ff00::	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.3	233e79f6a710
```

**What I understood:** `/etc/hosts` is a **static** name→IP table consulted *before* DNS,
so an entry here overrides the whole internet — which is exactly why it is the first file
to check when a name resolves to something unexpected. `/etc/resolv.conf` names the DNS
servers used when `/etc/hosts` has no answer. The last line of `/etc/hosts` maps this
machine's own hostname to its IP, which is what made `hostname -i` work earlier.

---

### 11. `ip route` / `netstat -rn` — the routing table

```bash
ip route
```

```
default via 172.17.0.1 dev eth0
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.3
```

```bash
netstat -rn
```

```
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG        0 0          0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 eth0
```

**What I understood:** The routing table decides where every outgoing packet goes. Read it
most-specific-first:

- `172.17.0.0/16 dev eth0` — anything inside my own subnet is delivered **directly** over
  `eth0`, no router involved.
- `default via 172.17.0.1` — everything else is handed to the **default gateway**. In
  `netstat` form the same rule appears as destination `0.0.0.0` with flags `UG`
  (**U**p, **G**ateway).

"No route to host" errors and containers that cannot reach the internet are almost always a
missing default route.

---

### 12. `ip neigh` (ARP) — IP to MAC mapping

```bash
ip neigh
```

```
172.17.0.1 dev eth0 lladdr ce:3f:58:6c:30:2c REACHABLE
```

**What I understood:** This is the **ARP cache**. To actually put a packet on the wire the
kernel needs the destination's MAC address, so ARP broadcasts "who has 172.17.0.1?" and
caches the answer. `REACHABLE` means the entry was confirmed recently. ARP works only
inside a broadcast domain — which is precisely why anything off-subnet must go via the
gateway from the routing table above.

---

### 13. `ss` / `netstat` — sockets and listening ports

```bash
ss -tulpn
```

```
Netid State Recv-Q Send-Q Local Address:Port Peer Address:Port Process
```

```bash
ss -s
```

```
Total: 1
TCP:   44 (estab 0, closed 44, orphaned 0, timewait 3)

Transport Total     IP        IPv6
RAW	  0         0         0
UDP	  0         0         0
TCP	  0         0         0
INET	  0         0         0
FRAG	  0         0         0
```

**What I understood:** `ss -tulpn` = **t**cp, **u**dp, **l**istening, **p**rocess,
**n**umeric — the standard "what is listening on this box, and which process owns it?"
command, and the first thing to run for a "port already in use" or "connection refused"
error. The empty table here is correct: this host was running only diagnostic tools, so
nothing was listening. `ss -s` summarises socket state — the 3 sockets in `timewait` are
the closed connections from the `curl`/`nc` tests, held briefly by TCP so late packets do
not confuse a new connection.

---

### 14. `nc` (netcat) — is a TCP port open?

```bash
nc -zv -w 3 github.com 443
nc -zv -w 3 github.com 8123
```

```
Connection to github.com (20.207.73.82) 443 port [tcp/https] succeeded!
nc: connect to github.com (20.207.73.82) port 8123 (tcp) timed out: Operation in progress
```

**What I understood:** `-z` scans without sending data, `-v` is verbose, `-w 3` sets a
timeout. Port 443 (HTTPS) accepted the connection; port 8123 timed out. The *kind* of
failure is diagnostic:

- **timed out** → a firewall is silently dropping the packets,
- **connection refused** → the packet reached the host but nothing is listening.

`ping` only tells you the *host* is up; `nc` tells you the *service* is up, which is the
question that actually matters.

---

### 15. `telnet` — raw TCP, by hand

```bash
telnet google.com 80
```

```
Connected to google.com
HTTP/1.0 400 Bad Request
Content-Type: text/html; charset=UTF-8
Referrer-Policy: no-referrer
Content-Length: 1555
Date: Thu, 17 Sep 2026 20:33:37 GMT
```

**What I understood:** `telnet host port` opens a raw TCP connection, so it doubles as a
port tester. `Connected to google.com` proves the TCP handshake succeeded. I then sent
`quit`, which is not valid HTTP, so the server answered `400 Bad Request` — and that is
still a *success* for this test: it proves a real HTTP server is listening and talking.

---

### 16. `curl` — HTTP client

```bash
curl -sI https://github.com
```

```
HTTP/2 200
date: Thu, 17 Sep 2026 20:33:32 GMT
content-type: text/html; charset=utf-8
content-language: en-US
etag: W/"5bc1397598ce20b4ac141a59026d5d94"
cache-control: max-age=0, private, must-revalidate
strict-transport-security: max-age=31536000; includeSubdomains; preload
x-frame-options: deny
x-content-type-options: nosniff
x-xss-protection: 0
referrer-policy: origin-when-cross-origin, strict-origin-when-cross-origin
```

**What I understood:** `-I` fetches only the headers, `-s` silences the progress meter.
`HTTP/2 200` = success over HTTP/2. The headers are worth reading:
`strict-transport-security` forces HTTPS for a year, `x-frame-options: deny` blocks
clickjacking, `x-content-type-options: nosniff` stops MIME sniffing, and `etag` +
`cache-control` drive caching.

### `curl` with timing breakdown

```bash
curl -s -o /dev/null -w "dns:%{time_namelookup}s connect:%{time_connect}s tls:%{time_appconnect}s ttfb:%{time_starttransfer}s total:%{time_total}s code:%{http_code} ip:%{remote_ip}\n" https://example.com
```

```
dns:0.050005s connect:0.096709s tls:0.136777s ttfb:0.160462s total:0.160595s code:200 ip:172.66.147.243
```

**What I understood:** This single command splits a request into its phases, which is how
you tell *what* is slow rather than just *that* it is slow:

| Phase | Time | Meaning |
|---|---|---|
| DNS | 50 ms | name → IP |
| Connect | 97 ms (≈47 ms more) | TCP three-way handshake |
| TLS | 137 ms (≈40 ms more) | certificate exchange + key agreement |
| TTFB | 160 ms (≈24 ms more) | server thought about it and started replying |
| Total | 161 ms | body transferred in under a millisecond |

So ~85% of this request was **connection setup**, not the server. That is exactly why
keep-alive, connection pooling and HTTP/2 matter so much.

---

### 17. `wget` — download / inspect headers

```bash
wget -q -O /dev/null -S https://example.com
```

```
  HTTP/1.1 200 OK
  Date: Thu, 17 Sep 2026 20:33:34 GMT
  Content-Type: text/html
  Transfer-Encoding: chunked
  Connection: close
  Server: cloudflare
  last-modified: Tue, 15 Sep 2026 23:41:26 GMT
  allow: GET, HEAD
```

**What I understood:** `wget` is the downloader (`-S` shows server headers). `Server:
cloudflare` shows the site sits behind a CDN, and `Transfer-Encoding: chunked` means the
body is streamed in pieces with no `Content-Length` known up front. Rule of thumb:
`curl` for talking to APIs, `wget` for fetching files (it has recursion and resume).

---

### 18. `tcpdump` — watch actual packets

```bash
tcpdump -i any -c 5 -n icmp      # (while a ping ran in parallel)
```

```
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
20:33:40.336656 eth0  Out IP 172.17.0.3 > 8.8.8.8: ICMP echo request, id 3, seq 1, length 64
20:33:40.386396 eth0  In  IP 8.8.8.8 > 172.17.0.3: ICMP echo reply,   id 3, seq 1, length 64
20:33:41.338564 eth0  Out IP 172.17.0.3 > 8.8.8.8: ICMP echo request, id 3, seq 2, length 64
20:33:41.354651 eth0  In  IP 8.8.8.8 > 172.17.0.3: ICMP echo reply,   id 3, seq 2, length 64
20:33:42.339788 eth0  Out IP 172.17.0.3 > 8.8.8.8: ICMP echo request, id 3, seq 3, length 64
5 packets captured
6 packets received by filter
0 packets dropped by kernel
```

**What I understood:** `tcpdump` is the ground truth — it shows the packets themselves.
Here you can literally watch the ping working: an `echo request` **Out** to 8.8.8.8, then
an `echo reply` **In** 50 ms later, matched by `id`/`seq`. Because it shows direction, it
settles the classic argument of whether a request left the box at all versus whether the
reply never came back. `-n` skips name resolution (so the capture does not generate its own
DNS traffic) and `-c 5` stops after 5 packets.

Useful filters: `tcpdump -i eth0 port 80`, `tcpdump host 8.8.8.8`, `tcpdump tcp port 443
-w capture.pcap` (then open in Wireshark).

---

## Command reference

| Command | Layer | Use it when |
|---|---|---|
| `ip addr` / `ifconfig` | L2/L3 | What is my IP / MAC / MTU? |
| `ip route` / `netstat -rn` | L3 | Where do my packets go? |
| `ip neigh` (ARP) | L2 | IP→MAC on the local segment |
| `ping` | L3 (ICMP) | Is the host reachable? Any loss? |
| `traceroute` / `mtr` | L3 | Which hop is broken or slow? |
| `nslookup` / `dig` / `host` | L7 (DNS) | Does the name resolve, and to what? |
| `ss` / `netstat -tulpn` | L4 | What is listening locally? |
| `nc -zv` / `telnet` | L4 | Is that remote port actually open? |
| `curl` / `wget` | L7 (HTTP) | Does the service respond? Which phase is slow? |
| `tcpdump` | all | What is *really* on the wire? |

## A debugging order that works

1. `ip addr` — do I even have an IP?
2. `ip route` — do I have a default gateway?
3. `ping <gateway>` — is the local network fine?
4. `ping 8.8.8.8` — is the internet reachable at all?
5. `dig <name>` — does DNS work? *(if 4 passes but 5 fails, it is DNS)*
6. `nc -zv <host> <port>` — is the specific service reachable?
7. `curl -v` — is the application itself answering correctly?
8. `tcpdump` — when the answers above disagree with each other.

---

## Summary

| Task | Status |
|---|---|
| Task 1 — Practised the networking commands from the devops-heros repo | Done |
| Task 2 — Markdown file created with each command's real output plus an explanation of what I understood | Done |
