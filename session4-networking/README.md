> **Submission for `session4-networking`** — Piyush Bansal.
>
> Every command below was actually executed live and the output is copied in verbatim.

# Session 4 — Networking Fundamentals Homework

**Environment:** Ubuntu 24.04 (aarch64 container, systemd as PID 1) — same
[`session2-linux`](../session2-linux/README.md) container, with `iproute2`, `iputils-ping`, `dnsutils`,
`netcat-openbsd`, and `traceroute` installed.

## Contents

- [Task 1](#task-1)
- [Task 2 — Networking commands, output, and explanation of each](#task-2--networking-commands-output-and-explanation-of-each)

## Task 1

Practiced the commands and material from the devops-hero GitHub repo (this repo) — covered in the command
walkthrough below.

## Task 2 — Networking commands, output, and explanation of each

Run inside the same Ubuntu 24.04 + systemd container used for [`session2-linux`](../session2-linux/README.md),
so `ip`, `ping`, `dig`, `nslookup`, `ss`, `traceroute`, and `nc` are all genuine Linux networking tools, not
macOS equivalents.

| Command | What it does |
|---|---|
| `ip a` | Lists every network interface and its assigned IP address(es) |
| `ip route` | Shows the routing table — which gateway/interface traffic for a destination goes through |
| `hostname` / `hostname -I` | This machine's name / its IP address(es) |
| `ping` | Sends ICMP echo requests to test basic reachability and measure latency |
| `nslookup` | Resolves a hostname to an IP via DNS (simple form) |
| `dig` | Resolves a hostname to an IP via DNS (detailed form — shows the full DNS response) |
| `curl -I` | Fetches just the HTTP response headers — tests whether a web service is actually serving |
| `ss -tulnp` | Lists listening TCP/UDP sockets and the process bound to each |
| `traceroute` | Shows the hop-by-hop path packets take to reach a destination |
| `nc -zv` | "Zero-I/O" scan — checks whether a specific TCP port on a host is open, without sending data |
| `ip neigh` | The ARP/neighbor table — IP-to-MAC mappings the kernel has learned on the local network |

## Full transcript

```console
########## 1. ip a - list network interfaces and IPs ##########
$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
11: eth0@if22: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc noqueue state UP group default
    link/ether 6a:93:df:05:5b:1d brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```
**Understanding:** `lo` is the loopback interface (127.0.0.1, always present). `eth0` is the container's real
interface with IP `172.17.0.2/16` — the `/16` means a 255.255.0.0 netmask, so this container shares a
`172.17.0.0/16` subnet with every other container on this Docker bridge network.

```console
########## 2. ip route - routing table ##########
$ ip route
default via 172.17.0.1 dev eth0
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2
```
**Understanding:** Two rules. The second says "anything in `172.17.0.0/16` is reachable directly on `eth0`, no
gateway needed" (it's local). The `default` rule says "everything else goes via `172.17.0.1`" — that's
Docker's bridge gateway, which then routes out to the real network.

```console
########## 3. hostname / hostname -I ##########
$ hostname
9d1f6248d53e
$ hostname -I
172.17.0.2
```
**Understanding:** `hostname` alone prints the machine's name (here, the container ID Docker assigned).
`hostname -I` prints its actual IP address(es) — useful for scripts that need the IP without parsing `ip a`.

```console
########## 4. ping - test reachability ##########
$ ping -c 3 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=63 time=14.7 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=63 time=14.5 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=63 time=14.1 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2010ms
rtt min/avg/max/mdev = 14.099/14.435/14.730/0.259 ms
```
**Understanding:** `-c 3` sends exactly 3 ICMP echo requests, then stops (without `-c`, ping runs forever).
`0% packet loss` and consistent `~14ms` round-trip time confirm this container has real, healthy outbound
connectivity to the internet.

```console
########## 5. ping a hostname (tests DNS + reachability together) ##########
$ ping -c 3 google.com
PING google.com (142.250.205.206) 56(84) bytes of data.
64 bytes from lcboma-ba-in-f14.1e100.net (142.250.205.206): icmp_seq=1 ttl=63 time=30.6 ms
64 bytes from lcboma-ba-in-f14.1e100.net (142.250.205.206): icmp_seq=2 ttl=63 time=28.2 ms
64 bytes from lcboma-ba-in-f14.1e100.net (142.250.205.206): icmp_seq=3 ttl=63 time=28.0 ms

--- google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2009ms
```
**Understanding:** Pinging a hostname (instead of an IP) exercises DNS resolution first, then ICMP. The line
`PING google.com (142.250.205.206)` shows the resolved IP — proof DNS worked before any packet was sent.

```console
########## 6. nslookup - DNS lookup ##########
$ nslookup google.com
Server:		192.168.65.7
Address:	192.168.65.7#53

Non-authoritative answer:
Name:	google.com
Address: 142.250.205.206
```
**Understanding:** `nslookup` asks the configured resolver (`192.168.65.7`, Docker Desktop's internal DNS
proxy on the Mac host) to translate `google.com` into an IP. "Non-authoritative" means the answer came from a
resolver's cache, not directly from google.com's own authoritative nameserver.

```console
########## 7. dig - detailed DNS lookup ##########
$ dig google.com +short
142.250.205.206

$ dig google.com
;; ANSWER SECTION:
google.com.		368	IN	A	142.250.205.206

;; Query time: 2 msec
;; SERVER: 192.168.65.7#53(192.168.65.7) (UDP)
```
**Understanding:** `dig` gives the same answer as `nslookup` but with far more detail — record type (`A` =
IPv4 address), TTL (`368` seconds this record can be cached), and query timing. `+short` strips all of that
down to just the IP, useful in scripts.

```console
########## 8. curl -I - check HTTP headers / connectivity to a service ##########
$ curl -I https://www.google.com
HTTP/2 200
content-type: text/html; charset=ISO-8859-1
date: Thu, 03 Sep 2026 08:27:30 GMT
server: gws
...
```
**Understanding:** `-I` (capital i) sends a `HEAD` request — fetches only headers, not the page body. `HTTP/2
200` confirms the server is up, reachable, and responding successfully, without downloading the full page.

```console
########## 9. ss -tulnp - listening ports ##########
$ ss -tulnp
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:Port Process
tcp   LISTEN 0      511    0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=812,...))
tcp   LISTEN 0      511       [::]:80           [::]:*    users:(("nginx",pid=812,...))
```
**Understanding:** `-t` = TCP, `-u` = UDP, `-l` = listening sockets only, `-n` = numeric (no DNS lookups,
faster), `-p` = show the owning process. This shows nginx (installed in session 2/3) listening on port 80,
both IPv4 (`0.0.0.0`) and IPv6 (`[::]`).

```console
########## 10. traceroute - path to a host ##########
$ traceroute -m 10 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 10 hops max, 60 byte packets
 1  172.17.0.1 (172.17.0.1)  2.368 ms  1.103 ms  1.052 ms
 2  * * *
 3  * * *
 ...
```
**Understanding:** Each line is one router hop, found by sending packets with increasing TTL and catching the
"TTL exceeded" replies. Hop 1 is the Docker bridge gateway. The `* * *` after that means those routers didn't
reply to traceroute's probes (very common — many networks rate-limit or block this deliberately), even though
the ping test above proved the path to 8.8.8.8 itself works fine.

```console
########## 11. netcat - test if a port is open ##########
$ nc -zv google.com 443
Connection to google.com (142.250.205.206) 443 port [tcp/https] succeeded!
```
**Understanding:** `-z` = scan without sending data (just check if the port accepts a connection), `-v` =
verbose. Confirms port 443 (HTTPS) on google.com is open and accepting TCP connections — this is the check
you'd run before debugging "why can't my app reach this service" further up the stack.

```console
########## 12. arp / ip neigh - MAC address table ##########
$ ip neigh
172.17.0.1 dev eth0 lladdr ea:fe:33:c7:e1:c6 REACHABLE
```
**Understanding:** The kernel's ARP cache — which IP addresses on the local network segment map to which MAC
addresses, learned automatically as traffic flows. Only the gateway (`172.17.0.1`) shows up here because it's
the only local-network peer this container has talked to directly.

---

# Files in this folder

| File | Purpose |
|---|---|
| `README.md` | This file — all networking commands, output, and explanations |
