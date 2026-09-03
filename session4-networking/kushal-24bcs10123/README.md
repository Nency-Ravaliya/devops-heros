# Session 4 – Networking Fundamentals

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123  
**Machine:** MacBook Pro (Apple Silicon), macOS, Wi-Fi interface `en0`. Commands are the BSD/macOS versions; the Linux equivalent is noted where it differs. Raw output of every command is in [`outputs/`](outputs) (my LAN IP, MAC addresses and public IP are masked).

## Task 1 – practising the course repos

I went through the networking repos linked in `session4-networking/resources.md` (Network-Troubleshooting, OSI-Network-devices, Subnetting, IP-quest, How-DHCP-Works) and used their command lists as the checklist for Task 2. Subnetting practice from `ip.md`:

| Question | Working | Answer |
|---|---|---|
| Class and mask of `120.27.1.0` | first octet 1–127 → Class A | mask `255.0.0.0` (/8), 2^24 − 2 = 16,777,214 usable hosts |
| Broadcast of `197.23.45.10/24` | Class C, host bits all 1 | `197.23.45.255` |
| My own Wi-Fi: `.../20` (mask `0xfffff000` in `ifconfig`) | 32 − 20 = 12 host bits | 2^12 − 2 = 4,094 usable hosts, broadcast `100.129.175.255` |
| Is `100.129.160.x` private? | not in 10/8, 172.16/12 or 192.168/16, but it **is** in `100.64.0.0/10` | Carrier-grade NAT range (RFC 6598), the ISP is NATing me |

## Task 2 – commands, output and what I understood

### 1. `hostname` → [outputs/01-hostname.txt](outputs/01-hostname.txt)

```text
$ hostname
Kushals-MacBook-Pro.local
```

The name this machine calls itself. The `.local` suffix is mDNS/Bonjour, so other devices on the LAN can resolve it without a DNS server. On Linux `hostnamectl` shows and sets it.

### 2. `ifconfig en0` / `ip addr` → [02-ifconfig.txt](outputs/02-ifconfig.txt), [03-ip-addr.txt](outputs/03-ip-addr.txt)

```text
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 66:48:3c:xx:xx:xx
	inet <redacted-lan-ip> netmask 0xfffff000 broadcast 100.129.175.255
	status: active
```

Layer 2 (MAC `ether`) and layer 3 (`inet` IPv4 + `inet6`) addresses of my interface, the MTU (1500 = standard Ethernet) and the netmask in hex. `ipconfig getoption en0 router` showed the default gateway `100.129.160.1`, which is also my DNS server (the Wi-Fi router). Linux: `ip -brief addr`, `ip route`.

### 3. `ping` → [04-ping.txt](outputs/04-ping.txt)

```text
$ ping -c 4 google.com
64 bytes from 142.250.207.174: icmp_seq=0 ttl=117 time=67.827 ms
...
4 packets transmitted, 4 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 26.598/38.249/67.827/17.183 ms
```

ICMP echo request/reply. It proves DNS works (name → IP), the path is up, and gives latency. `ttl=117` means the reply crossed about 11 routers (Google starts at 128). 0 % loss is what you want; growing loss or jitter points at Wi-Fi or ISP trouble. `-c 4` limits the count (on Linux too).

### 4. `traceroute` → [05-traceroute.txt](outputs/05-traceroute.txt)

```text
 1  wifi.height8tech.com (100.129.160.1)   13.5 ms   <- my router
 2  202.131.133.5.convergentindia.com        9.0 ms   <- ISP
 3  115.117.125.189.static-mumbai.vsnl.net.in 17.5 ms <- Tata (VSNL) backbone, Mumbai
 4  *                                                  <- router that does not answer ICMP
 5  115.112.15.114.static-chennai.vsnl.net.in 19.8 ms
 7  216.239.43.234                          138.1 ms  <- Google network
12  142.250.214.111                          48.3 ms
```

Sends packets with TTL 1, 2, 3 … and records who sends back "TTL exceeded", so I see every hop. A `*` is a hop that drops ICMP; it is not necessarily a problem. Useful for seeing *where* latency appears. `-m 12 -w 1 -q 1` = max 12 hops, 1 s wait, 1 probe per hop. Linux: `traceroute`, `mtr` (live version).

### 5. DNS: `nslookup`, `dig`, `host` → [06](outputs/06-nslookup.txt), [07](outputs/07-dig.txt), [08](outputs/08-host.txt)

```text
$ nslookup github.com
Server:   1.1.1.1
Address:  1.1.1.1#53
Name:     github.com
Address:  20.207.73.82

$ dig github.com +noall +answer +stats
github.com.   1   IN  A  20.207.73.82
;; Query time: 12 msec   ;; SERVER: 8.8.8.8#53(8.8.8.8)

$ dig google.com MX +short
10 smtp.google.com.
$ dig -x 8.8.8.8 +short
dns.google.

$ host scaler.com
scaler.com has address 18.172.78.47      (4 A records – AWS CloudFront)
scaler.com mail is handled by 1 aspmx.l.google.com.   (Google Workspace)
```

Three tools for the same job. `nslookup` is the simple one, `dig` gives full detail (record type, TTL, which server answered, query time) and is the one to use when debugging; `host` is a terse summary. I tried an `A` record, `MX` (mail) and a reverse (`-x`, IP → name) lookup. My resolver was Cloudflare `1.1.1.1` and `dig` defaulted to Google `8.8.8.8`; the TTL of 1 s on github.com means their load balancer wants clients to re-resolve constantly.

### 6. Routing table: `netstat -rn` / `ip route` → [09-routes.txt](outputs/09-routes.txt)

```text
Destination        Gateway            Flags    Netif
default            100.129.160.1      UGScg    en0        <- everything else goes to the router
100.129.160/20     link#17            UCS      en0        <- my subnet is directly attached
100.129.160.1      f4:1e:57:xx:xx:xx  UHLWIir  en0        <- gateway's MAC (ARP resolved)
```

The kernel's map of "to reach X, send via Y". `default` is the route of last resort. `U`=up, `G`=gateway, `H`=host route, `L`=link-layer address present.

### 7. Listening ports: `lsof -iTCP -sTCP:LISTEN` / `ss -ltnp` → [10-listening.txt](outputs/10-listening.txt)

```text
COMMAND    PID  USER   TYPE  NAME
Spotify    646  ...    IPv4  TCP 127.0.0.1:7768 (LISTEN)
Code\x20H 1931  ...    IPv4  TCP 127.0.0.1:16430 (LISTEN)
Raycast   2079  ...    IPv4  TCP 127.0.0.1:7265 (LISTEN)
```

Which programs are waiting for incoming connections and on which port. `127.0.0.1:port` = only reachable from this machine; `*:port` = exposed on all interfaces (worth checking for security). Linux equivalent: `ss -ltnp` (or old `netstat -tulpn`).

### 8. Active connections: `netstat -an -p tcp` → [11-connections.txt](outputs/11-connections.txt), [18-ss-equivalent.txt](outputs/18-ss-equivalent.txt)

```text
55 ESTABLISHED
tcp4  0  0  <lan-ip>.54343   3.33.235.18.443   ESTABLISHED
...
  40 ESTABLISHED   16 LISTEN   3 TIME_WAIT   1 FIN_WAIT_1   1 CLOSE_WAIT
```

Every TCP socket and its state. Almost all are to port 443 (HTTPS). The `sort | uniq -c` summary of states is a quick health check: piles of `TIME_WAIT`/`CLOSE_WAIT` suggest connection leaks.

### 9. ARP cache: `arp -a` / `ip neigh` → [12-arp.txt](outputs/12-arp.txt)

```text
wifi.height8tech.com (100.129.160.1) at f4:1e:57:xx:xx:xx on en0 ifscope [ethernet]
? (100.129.160.21) at 8a:e6:76:xx:xx:xx on en0 ifscope [ethernet]
```

IP → MAC mappings the kernel has learned on the local segment. This is how a packet for the gateway actually gets an Ethernet destination address. Entries appear when I talk to a device and expire after a while.

### 10. HTTP with `curl` → [13-curl.txt](outputs/13-curl.txt), [14-curl-verbose.txt](outputs/14-curl-verbose.txt)

```text
$ curl -sI https://github.com
HTTP/2 200
content-type: text/html; charset=utf-8
strict-transport-security: max-age=31536000; includeSubdomains; preload
x-frame-options: deny

$ curl -s -o /dev/null -w "dns=%{time_namelookup}s connect=%{time_connect}s tls=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s http=%{http_code}" https://www.google.com
dns=0.070s connect=0.111s tls=0.161s ttfb=0.286s total=0.343s http=200
```

`-I` fetches only headers: status code, server, security headers, HTTP/2. The `-w` timing breakdown separates DNS, TCP handshake, TLS handshake and server think-time, which tells you *which layer* is slow.

### 11. Port check with `nc` (netcat) → [15-nc-port.txt](outputs/15-nc-port.txt)

```text
Connection to github.com port 443 [tcp/https] succeeded!
Connection to github.com port 22 [tcp/ssh] succeeded!
nc: connectx to github.com port 8080 (tcp) failed: Operation timed out
```

`nc -zv host port` just tries the TCP handshake. Succeeded = something is listening and no firewall in the way; timed out = filtered/dropped (a "refused" would mean reachable but closed). Handy for "is the DB port open from this box?" without installing anything. (`-G 3` = 3 s connect timeout on macOS; Linux uses `-w 3`.)

### 12. `whois` → [16-whois.txt](outputs/16-whois.txt)

```text
Creation Date: 2007-10-09T18:20:50Z
Registrar: MarkMonitor Inc.
Name Server: DNS1.P08.NSONE.NET
Name Server: NS-1283.AWSDNS-32.ORG
```

Registration data for a domain: registrar, dates, authoritative name servers (GitHub uses NS1 and AWS Route 53). Also works on IPs to find which organisation owns a block.

### 13. Public IP → [17-public-ip.txt](outputs/17-public-ip.txt)

`curl https://api.ipify.org` returned `202.131.xxx.xxx`, different from my `100.129.x.x` interface address: the ISP's NAT (see the CGNAT note above) rewrites my address on the way out. `traceroute` hop 2 sits in the same `202.131.133.x` block.

## Summary of what the commands are for

| Layer / question | Command(s) |
|---|---|
| Who am I on the network | `hostname`, `ifconfig` / `ip addr` |
| Can I reach X, how far, how slow | `ping`, `traceroute` / `mtr` |
| Does the name resolve, to what, by whom | `nslookup`, `dig`, `host` |
| Where do packets go | `netstat -rn` / `ip route`, `arp -a` / `ip neigh` |
| What is listening / connected on this host | `lsof -i` / `ss -ltnp`, `netstat -an` |
| Is a remote port open | `nc -zv`, `curl -I`, `telnet` |
| Is the web service healthy and fast | `curl -I`, `curl -w` timings |
| Who owns this domain / IP | `whois` |
