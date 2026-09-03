# Session 4 - Networking Fundamentals Assignment

## Task 1: Practice commands from the devops-hero networking repositories

Reference: [`resources.md`](resources.md) lists the instructor's networking repos, in particular
[`Network-Troubleshooting`](https://github.com/Nency-Ravaliya/Network-Troubleshooting), which walks through
a standard diagnostic toolkit: `ping`, `traceroute`, `netstat`, `telnet`, `tcpdump`, `nslookup`, `dig`,
`curl`, `arp`, `systemctl`. Each of these was actually run on this machine (see Task 2) to practice the
full troubleshooting sequence: reachability → routing → local ports → DNS → app-layer → link layer.

Subnetting/IP-addressing notes from the session are in [`ip.md`](ip.md) (classful ranges, subnet masks,
network/host bit split, usable host count, private IP ranges).

## Task 2: Command outputs + explanations

Raw output files are under [`command-outputs/`](command-outputs/). Summary and explanation below.

### `ping` - reachability + latency
```
PING google.com (172.217.160.142): 56 data bytes
64 bytes from 172.217.160.142: icmp_seq=0 ttl=117 time=24.076 ms
64 bytes from 172.217.160.142: icmp_seq=1 ttl=117 time=49.905 ms
64 bytes from 172.217.160.142: icmp_seq=2 ttl=117 time=101.607 ms
64 bytes from 172.217.160.142: icmp_seq=3 ttl=117 time=23.217 ms

--- google.com ping statistics ---
4 packets transmitted, 4 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 23.217/49.701/101.607/31.829 ms
```
`google.com` is reachable, 0% packet loss, round-trip latency ~24-100ms. This is the first, most basic
check: "is the remote host up and responding at all?"

### `traceroute` - path/hop-by-hop routing
```
 1  wifi.height8tech.com (10.114.0.1)        <- local gateway
 2  202.131.133.17.convergentindia.com       <- ISP edge
 3  115.117.125.189.static-mumbai.vsnl.net.in
 6  * * *                                    <- hop didn't reply (common, often ICMP-rate-limited)
 7-10 216.239.x.x / 142.251.x.x / 192.178.x.x  <- Google's own network (peering)
```
Shows every router hop between this machine and Google, with round-trip time per hop. Useful for spotting
*where* latency/packet loss is introduced - e.g. if hop 3 is slow but every hop after is fast, the ISP
segment is the bottleneck, not Google's network. Full output: `command-outputs/01-ping-traceroute.txt`.

### `netstat` - local listening ports
```
tcp4  127.0.0.1.20697   *.*   LISTEN
tcp6  *.5000            *.*   LISTEN
tcp6  *.7000            *.*   LISTEN
...
```
Lists sockets in `LISTEN` state on this machine - i.e. which local services/ports are open and could be
involved in a connectivity problem (port conflicts, a service not actually listening where expected, etc).
Full output: `command-outputs/02-netstat-arp.txt`.

### `arp` - IP → MAC address table
```
wifi.height8tech.com (10.114.0.1) at f4:1e:57:3d:ae:df on en0 ifscope [ethernet]
? (10.114.0.2) at f2:c8:3a:35:98:14 on en0 ifscope [ethernet]
...
```
Shows the local link-layer mapping of IP addresses to MAC addresses that this machine has already resolved
on the LAN - useful for spotting IP conflicts or confirming a device is actually on the local segment.
> Only a handful of sample rows are included here (see `command-outputs/02-netstat-arp.txt`) - the real
> table had 180+ entries since this is a shared office network, and publishing every device's MAC/IP
> wasn't appropriate for a public repo.

### `nslookup` / `dig` - DNS resolution
```
$ nslookup google.com
Server:    10.114.0.1
Non-authoritative answer:
Name:  google.com
Address: 172.217.160.142
```
```
$ dig google.com +noall +answer
google.com.  169  IN  A  172.217.160.142
```
Both resolve `google.com` → `172.217.160.142` via the local DNS resolver (`10.114.0.1`). `dig` additionally
shows the authoritative name servers (`ns1-ns4.google.com`) and their IPs in the AUTHORITY/ADDITIONAL
sections - useful when a `ping`/`curl` fails and you need to know if it's a DNS problem vs a routing
problem. Full output: `command-outputs/03-dns.txt`.

### `curl` - application-layer (HTTP/HTTPS) connectivity
```
$ curl -Is https://google.com
HTTP/2 301
location: https://www.google.com/
server: gws
```
Confirms the web server is not just reachable at the network layer but actually answering HTTP requests -
here a `301` redirect to `www.google.com`, which is normal/expected Google behavior.

### `telnet` / `nc` - raw TCP port connectivity
```
$ nc -G 3 -zv google.com 443
Connection to google.com port 443 [tcp/https] succeeded!
$ nc -G 3 -zv google.com 80
Connection to google.com port 80 [tcp/http] succeeded!
```
(`nc -zv` used here in place of interactive `telnet <host> <port>`, since it performs the exact same TCP
connect-test non-interactively - `telnet google.com 443` and Ctrl-] to quit does the identical check.)
Confirms ports 443 and 80 are open and accepting TCP connections on the target - narrows a failure down to
"below the port" (firewall/routing) vs "above the port" (the application itself).

### `tcpdump` - packet capture
```
$ tcpdump -c 1
tcpdump: ioctl(SIOCIFCREATE): Operation not permitted
```
`tcpdump` needs raw-socket access, which requires root/sudo (or `CAP_NET_RAW` on Linux). Run as
`sudo tcpdump -c 5 -i en0 host google.com` on a real box to capture and inspect the actual packets of a
request to `google.com` at the wire level - the deepest layer of the troubleshooting sequence.

### `systemctl` - service status
Not applicable on this machine (macOS has no systemd). On a systemd-based Linux host, e.g.
`systemctl status nginx` / `systemctl is-active docker` confirms whether the *networked service itself* is
even running, before blaming the network - see [`session2-linux/README.md`](../session2-linux/README.md)
for the related `journalctl` notes.

### Diagnostic sequence, tied together

`ping` (is it up?) → `traceroute` (where's the path breaking/slow?) → `netstat`/`arp` (is this machine's
local networking OK?) → `nslookup`/`dig` (does the name even resolve?) → `curl`/`telnet`/`nc` (is the
port/app answering?) → `tcpdump` (what's actually on the wire?) → `systemctl` (is the local service even
running?). Each tool isolates one layer, so together they narrow a "can't connect" problem down to a
specific cause.
