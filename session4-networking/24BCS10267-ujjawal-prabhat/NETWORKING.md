# Networking Commands — Practical Log

**Ujjawal Prabhat · 24BCS10267 · Session 04 — Networking**

## Setup

The command list comes from the course material: the `ip` command cheat sheet (*Linux Networking Cheat Sheet.pdf*), the net-tools vs iproute2 comparison, and the subnetting notes in `session4-networking/ip.md`. I added the usual troubleshooting tools: ping, traceroute, dig, nslookup, host, curl and nc.

- **Linux:** an Ubuntu 24.04 Docker container named `ujj-net`, started with `--cap-add NET_ADMIN --cap-add NET_RAW` so I could change interfaces, routes and ARP entries, and with `iproute2 net-tools dnsutils iputils-ping traceroute netcat-openbsd curl arping ethtool ipcalc whois mtr-tiny` installed.
- **macOS host:** used for a few commands where the container's view is limited (traceroute, default route).

To change settings without breaking the container's real network (`eth0`), I made a throw-away **dummy interface** (`dummy0`) and did all the add/delete/modify practice on it.

Every output below is real, copied from the terminal. Long outputs are cut and marked with `...`. In the container the commands were run with `docker exec ujj-net ...`, and the `$` prompt is added here to make it easier to read.

---

## 1. `ip addr` — IP addresses on interfaces

```console
$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
...
11: eth0@if119: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc noqueue state UP group default 
    link/ether de:73:f7:58:84:8c brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.4/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever

$ ip addr show dev eth0
11: eth0@if119: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc noqueue state UP group default 
    link/ether de:73:f7:58:84:8c brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.4/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever

$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
tunl0@NONE       DOWN           
...
eth0@if119       UP             172.17.0.4/16 
```

**What I understood:** `ip addr` (short form `ip a`) lists every interface along with its IPv4/IPv6 addresses. `lo` is the loopback interface (127.0.0.1), which a machine uses to talk to itself. `eth0` is the container's real NIC, IP `172.17.0.4/16`, on Docker's default bridge network. `/16` is the subnet mask written in CIDR form (255.255.0.0), and `brd` is the broadcast address. `-br` gives a short one-line-per-interface summary. The `tunl0`, `gre0` and similar entries are tunnel devices the kernel creates. They are DOWN and not used.

## 2. `ip link` — interface (layer 2) state

```console
$ ip link show dev eth0
11: eth0@if119: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc noqueue state UP mode DEFAULT group default 
    link/ether de:73:f7:58:84:8c brd ff:ff:ff:ff:ff:ff link-netnsid 0

$ ip -s link show dev eth0
11: eth0@if119: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc noqueue state UP mode DEFAULT group default 
    link/ether de:73:f7:58:84:8c brd ff:ff:ff:ff:ff:ff link-netnsid 0
    RX:  bytes packets errors dropped  missed   mcast           
       9705907    1615      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
         96201    1415      0       0       0       0 
```

**What I understood:** `ip link` works at the data-link layer. It shows the **MAC address** (`link/ether de:73:...`), the **MTU** (largest packet size), and whether the link is UP. `-s` adds RX (received) and TX (sent) counters. Rising `errors` or `dropped` numbers there are a sign of a faulty cable, NIC or driver.

## 3. `ip route` — routing table

```console
$ ip route
default via 172.17.0.1 dev eth0 
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.4 

$ ip route get 8.8.8.8
8.8.8.8 via 172.17.0.1 dev eth0 src 172.17.0.4 uid 0 
    cache 
```

**What I understood:** The routing table tells the kernel where to send each packet. `172.17.0.0/16` is directly connected, so it goes straight out of eth0. Everything else matches the `default` route and goes to the **gateway** `172.17.0.1`, which is the Docker bridge. `ip route get <ip>` answers "which route would a packet to this IP use?", which helps when debugging.

## 4. `ip neigh` / `arp` — ARP table (IP → MAC)

```console
$ ip neigh
172.17.0.1 dev eth0 lladdr d2:db:6f:1e:7d:b2 REACHABLE 

$ arp -a
? (172.17.0.1) at d2:db:6f:1e:7d:b2 [ether] on eth0

$ arp -n
Address                  HWtype  HWaddress           Flags Mask            Iface
172.17.0.1               ether   d2:db:6f:1e:7d:b2   C                     eth0
```

**What I understood:** Inside a LAN, frames are delivered by MAC address, not IP. **ARP** (Address Resolution Protocol) finds the MAC for a given IP and caches it. Here the container has learned the gateway's MAC. `ip neigh` is the modern command and `arp` is the old net-tools one. Both show the same data. `C` means a learned (complete) entry and `REACHABLE` means it was confirmed recently.

## 5. `ip maddr` — multicast addresses

```console
$ ip maddr show dev eth0
11:	eth0
	link  33:33:00:00:00:01
	link  01:00:5e:00:00:01
	inet  224.0.0.1
	inet6 ff02::1
	inet6 ff01::1
```

**What I understood:** These are the multicast groups the interface has joined. `224.0.0.1` is "all hosts on this subnet" for IPv4 and `ff02::1` is the IPv6 version. That fits the class notes: 224–239 is **Class D**, the multicast range.

## 6. Modifying interfaces, routes and ARP (on `dummy0`)

### Add an interface and an address, bring it up, change the MTU

```console
$ ip link add dummy0 type dummy
$ ip addr add 192.168.50.10/24 dev dummy0
$ ip link set dummy0 up
$ ip addr show dev dummy0
12: dummy0: <BROADCAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether da:9d:ac:cb:b2:29 brd ff:ff:ff:ff:ff:ff
    inet 192.168.50.10/24 scope global dummy0
       valid_lft forever preferred_lft forever
    inet6 fe80::d89d:acff:fecb:b229/64 scope link 
       valid_lft forever preferred_lft forever

$ ip link set dummy0 mtu 9000
$ ip link show dev dummy0
12: dummy0: <BROADCAST,NOARP,UP,LOWER_UP> mtu 9000 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether da:9d:ac:cb:b2:29 brd ff:ff:ff:ff:ff:ff

$ ip addr add 192.168.50.11/24 dev dummy0
$ ip -br addr show dev dummy0
dummy0           UNKNOWN        192.168.50.10/24 192.168.50.11/24 fe80::d89d:acff:fecb:b229/64 
```

**What I understood:** `ip addr add` puts an IP on an interface, and one interface can hold more than one IP. `ip link set ... up/down` turns the interface on or off. MTU 9000 is a "jumbo frame" size used in data centres. Once the interface came up, the kernel automatically gave it an IPv6 link-local address (`fe80::`). These changes are **not permanent** and disappear on reboot. On Ubuntu, permanent settings go in netplan.

### Routes: add, get, replace, delete

```console
$ ip route add 10.99.0.0/16 via 192.168.50.1 dev dummy0
$ ip route
default via 172.17.0.1 dev eth0 
10.99.0.0/16 via 192.168.50.1 dev dummy0 
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.4 
192.168.50.0/24 dev dummy0 proto kernel scope link src 192.168.50.10 

$ ip route get 10.99.1.5
10.99.1.5 via 192.168.50.1 dev dummy0 src 192.168.50.10 uid 0 
    cache 

$ ip route replace 10.99.0.0/16 dev dummy0
$ ip route show 10.99.0.0/16
10.99.0.0/16 dev dummy0 scope link 

$ ip route delete 10.99.0.0/16
```

**What I understood:** I added a static route so traffic for `10.99.0.0/16` goes through gateway `192.168.50.1`, and `ip route get` confirmed it. Adding the IP to dummy0 also created the `192.168.50.0/24` "connected" route automatically. `replace` changes a route in place (or adds it if it doesn't exist), and `delete` removes it.

### ARP entries: add, replace, delete

```console
$ ip neigh add 192.168.50.20 lladdr 1:2:3:4:5:6 dev dummy0
$ ip neigh show dev dummy0
192.168.50.20 lladdr 01:02:03:04:05:06 PERMANENT 

$ arp -n
Address                  HWtype  HWaddress           Flags Mask            Iface
172.17.0.1               ether   d2:db:6f:1e:7d:b2   C                     eth0
192.168.50.20            ether   01:02:03:04:05:06   CM                    dummy0

$ ip neigh replace 192.168.50.20 lladdr aa:bb:cc:dd:ee:ff dev dummy0
$ ip neigh show dev dummy0
192.168.50.20 lladdr aa:bb:cc:dd:ee:ff PERMANENT 

$ ip neigh del 192.168.50.20 dev dummy0
$ ip neigh show dev dummy0; echo "(empty)"
(empty)
```

**What I understood:** A manually added ARP entry is `PERMANENT`, and `arp -n` marks it `CM` (Complete, Manual). Static ARP entries are sometimes used to protect against ARP spoofing.

### Multicast, promiscuous mode, cleanup

```console
$ ip maddr add 33:33:00:00:00:01 dev dummy0
$ ip maddr show dev dummy0
12:	dummy0
	link  33:33:00:00:00:01 users 2 static
	link  01:00:5e:00:00:01
	inet  224.0.0.1
	inet6 ff02::1
	inet6 ff01::1
$ ip maddr del 33:33:00:00:00:01 dev dummy0

$ ip link set dummy0 promisc on
$ ip link show dummy0
12: dummy0: <BROADCAST,NOARP,PROMISC,UP,LOWER_UP> mtu 9000 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether da:9d:ac:cb:b2:29 brd ff:ff:ff:ff:ff:ff

$ ifconfig dummy0
dummy0: flags=451<UP,BROADCAST,RUNNING,NOARP,PROMISC>  mtu 9000
        inet 192.168.50.10  netmask 255.255.255.0  broadcast 0.0.0.0
        inet6 fe80::d89d:acff:fecb:b229  prefixlen 64  scopeid 0x20<link>
        ether da:9d:ac:cb:b2:29  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1  bytes 70 (70.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

$ ip addr del 192.168.50.11/24 dev dummy0
$ ip link set dummy0 down
$ ip -br link show dummy0
dummy0           DOWN           da:9d:ac:cb:b2:29 <BROADCAST,NOARP,PROMISC> 
$ ip link delete dummy0
$ ip -br link | grep dummy || echo "dummy0 removed"
dummy0 removed
```

**What I understood:** **Promiscuous mode** makes the NIC accept every frame it sees, even ones addressed to other MACs. Packet sniffers like tcpdump and Wireshark rely on it. After the practice I deleted everything and the container's network was back to how it started.

## 7. `ifconfig` / `route` / `netstat -rn` — the old net-tools commands

```console
$ ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 65535
        inet 172.17.0.4  netmask 255.255.0.0  broadcast 172.17.255.255
        ether de:73:f7:58:84:8c  txqueuelen 0  (Ethernet)
        RX packets 1615  bytes 9705907 (9.7 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1415  bytes 96201 (96.2 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG    0      0        0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 eth0

$ netstat -rn
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG        0 0          0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 eth0

$ netstat -i
Kernel Interface table
Iface             MTU    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
eth0            65535     1791      0      0 0          1637      0      0      0 BMRU
lo              65536       22      0      0 0            22      0      0      0 LRU
```

**What I understood:** These show the same information as `ip addr` and `ip route`, but in the older net-tools format. `ifconfig` shows the netmask in dotted form (`255.255.0.0`), which is the same as `/16`. In `route -n`, the flag `U` means up and `G` means the route uses a gateway. `0.0.0.0/0.0.0.0` is the default route. net-tools is deprecated: Ubuntu doesn't install it by default (I had to add `net-tools`), while `iproute2` is always there.

| net-tools (old) | iproute2 (new) |
|---|---|
| `ifconfig -a` | `ip addr` |
| `ifconfig eth0 up/down` | `ip link set eth0 up/down` |
| `ifconfig eth0 mtu 9000` | `ip link set eth0 mtu 9000` |
| `route` / `netstat -r` | `ip route` |
| `arp -a` | `ip neigh` |
| `netstat` | `ss` |
| `netstat -g` | `ip maddr` |

## 8. `ping` — is the host reachable?

```console
$ ping -c 4 google.com
PING google.com (74.125.68.100) 56(84) bytes of data.
64 bytes from sc-in-f100.1e100.net (74.125.68.100): icmp_seq=1 ttl=63 time=66.3 ms
64 bytes from sc-in-f100.1e100.net (74.125.68.100): icmp_seq=2 ttl=63 time=86.6 ms
64 bytes from sc-in-f100.1e100.net (74.125.68.100): icmp_seq=3 ttl=63 time=88.0 ms
64 bytes from sc-in-f100.1e100.net (74.125.68.100): icmp_seq=4 ttl=63 time=74.7 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 66.317/78.877/87.971/8.907 ms

$ ping -c 2 -W 2 10.255.255.1; echo "exit=$?"
PING 10.255.255.1 (10.255.255.1) 56(84) bytes of data.

--- 10.255.255.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1021ms

exit=1
```

**What I understood:** `ping` sends ICMP Echo Requests and waits for replies. It tells you whether a host is reachable, the round-trip time (`time=`), and the packet loss. It also showed that DNS works, since `google.com` resolved to `74.125.68.100`. `-c` sets the number of packets (on Linux, ping runs forever without it). The second ping went to an unreachable private IP: 100% loss and exit code 1, which a script can check. Keep in mind that some servers block ICMP, so a failed ping doesn't always mean the host is down.

## 9. `traceroute` / `mtr` — the path packets take

From the container:

```console
$ traceroute -n -m 15 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 15 hops max, 60 byte packets
 1  172.17.0.1  0.075 ms  0.015 ms  0.004 ms
 2  * * *
 3  * * *
...
15  * * *

$ traceroute -T -n -m 12 -q 1 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 12 hops max, 60 byte packets
 1  172.17.0.1  0.734 ms
 2  8.8.8.8  86.608 ms

$ mtr -n -r -c 3 8.8.8.8
Start: 2026-10-06T11:12:38+0000
HOST: ujj-net                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 172.17.0.1                 0.0%     3    0.1   0.1   0.1   0.2   0.0
  2.|-- 8.8.8.8                    0.0%     3   32.9  27.2  21.7  32.9   5.6
```

From the macOS host:

```console
$ traceroute -n -m 15 -q 1 -w 2 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 15 hops max, 40 byte packets
 1  172.20.10.1  18.737 ms
 2  *
 3  *
 4  8.8.8.8  170.219 ms
```

**What I understood:** traceroute sends packets with TTL = 1, 2, 3 and so on. Each router that drops a packet because its TTL ran out sends back an ICMP "time exceeded" message, which reveals that hop. `* * *` means the hop didn't reply, often because the router or a firewall blocks those messages. From the container, the default UDP probes got no replies after the Docker gateway, because Docker Desktop NATs traffic through its VM. With TCP probes (`-T`), the probe reached 8.8.8.8 at hop 2 because the NAT hides the routers in between. From the Mac (on a phone hotspot, `172.20.10.1`), hop 1 is the hotspot, hops 2–3 stay silent, and Google's DNS is hop 4. `mtr` combines ping and traceroute and gives loss and latency per hop.

## 10. DNS — `dig`, `nslookup`, `host`

```console
$ dig google.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 13960
;; flags: qr rd ra; QUERY: 1, ANSWER: 6, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;google.com.			IN	A

;; ANSWER SECTION:
google.com.		212	IN	A	74.125.68.100
google.com.		212	IN	A	74.125.68.138
google.com.		212	IN	A	74.125.68.139
google.com.		212	IN	A	74.125.68.102
google.com.		212	IN	A	74.125.68.101
google.com.		212	IN	A	74.125.68.113

;; Query time: 2 msec
;; SERVER: 192.168.65.7#53(192.168.65.7) (UDP)
;; WHEN: Tue Oct 06 11:12:04 UTC 2026
;; MSG SIZE  rcvd: 184

$ dig +short github.com
20.205.243.166

$ dig MX gmail.com +short
40 alt4.gmail-smtp-in.l.google.com.
20 alt2.gmail-smtp-in.l.google.com.
10 alt1.gmail-smtp-in.l.google.com.
5 gmail-smtp-in.l.google.com.
30 alt3.gmail-smtp-in.l.google.com.

$ dig -x 8.8.8.8 +short
dns.google.

$ dig @8.8.8.8 google.com +short
74.125.68.139
74.125.68.102
74.125.68.101
74.125.68.113
74.125.68.100
74.125.68.138
```

```console
$ nslookup example.com
Server:		192.168.65.7
Address:	192.168.65.7#53

Non-authoritative answer:
Name:	example.com
Address: 104.20.23.154
Name:	example.com
Address: 172.66.147.243
Name:	example.com
Address: 2606:4700:10::ac42:93f3
Name:	example.com
Address: 2606:4700:10::6814:179a

$ host github.com
github.com has address 20.205.243.166
github.com mail is handled by 0 github-com.mail.protection.outlook.com.

$ host -t mx gmail.com
gmail.com mail is handled by 40 alt4.gmail-smtp-in.l.google.com.
gmail.com mail is handled by 20 alt2.gmail-smtp-in.l.google.com.
gmail.com mail is handled by 10 alt1.gmail-smtp-in.l.google.com.
gmail.com mail is handled by 5 gmail-smtp-in.l.google.com.
gmail.com mail is handled by 30 alt3.gmail-smtp-in.l.google.com.
```

**What I understood:** DNS turns names into IPs. `dig` is the most detailed tool. It shows the record type (`A` = IPv4, `AAAA` = IPv6, `MX` = mail server, `PTR` = reverse lookup with `-x`), the **TTL** (212 seconds left in the cache), and which DNS server answered (`192.168.65.7`, Docker Desktop's DNS forwarder). `+short` prints only the answer, and `@8.8.8.8` asks a specific server. "Non-authoritative answer" in nslookup means the reply came from a resolver's cache, not from the domain's own name server. For MX records, a lower number means higher priority.

**Something I couldn't do:** `NS` and `TXT` queries timed out on the network I was using (a mobile hotspot). They failed from the container through Docker's DNS, straight to 8.8.8.8, over TCP, and from the macOS host, while `A`, `MX` and `PTR` queries worked:

```console
$ dig NS google.com +short
;; communications error to 192.168.65.7#53: timed out

$ dig @8.8.8.8 NS google.com +short
;; communications error to 8.8.8.8#53: timed out
;; communications error to 8.8.8.8#53: timed out
;; communications error to 8.8.8.8#53: timed out

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> @8.8.8.8 NS google.com +short
; (1 server found)
;; global options: +cmd
;; no servers could be reached
```

So I don't have NS-record output to show. This is itself a useful troubleshooting lesson: if some record types resolve and others time out, something on the network path (here probably the carrier's DNS filtering) is the cause, not the domain.

### DNS config files

```console
$ cat /etc/resolv.conf
# Generated by Docker Engine.
# This file can be edited; Docker Engine will not make further changes once it
# has been modified.

nameserver 192.168.65.7

# Based on host file: '/etc/resolv.conf' (legacy)
# Overrides: []

$ cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::	ip6-localnet
ff00::	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.4	ujj-net
```

**What I understood:** `/etc/resolv.conf` sets which DNS server the system asks. `/etc/hosts` is a local name → IP table that is checked **before** DNS, which is why the container's own hostname `ujj-net` resolves without any DNS query.

## 11. `curl` — talk HTTP

```console
$ curl -I https://www.google.com
...
HTTP/2 200 
content-type: text/html; charset=ISO-8859-1
...
date: Tue, 06 Oct 2026 11:12:20 GMT
server: gws
x-xss-protection: 0
x-frame-options: SAMEORIGIN
expires: Tue, 06 Oct 2026 11:12:20 GMT
cache-control: private
set-cookie: ... (cookie values trimmed)
alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000

$ curl -s -o /dev/null -w "HTTP %{http_code}, total time %{time_total}s, remote IP %{remote_ip}\n" https://github.com
HTTP 200, total time 0.508295s, remote IP 20.205.243.166
```

**What I understood:** `curl -I` sends a HEAD request and prints only the response **headers**: the status code (`200` = OK), the HTTP version (HTTP/2), the server type and the caching rules. `-w` prints timing and status details, which is handy in health-check scripts (e.g. "is the site returning 200, and how fast?"). (I removed the progress meter and the long cookie values from the first output.)

## 12. `ss` / `netstat` — sockets and ports

I started a TCP listener with `nc` on port 8080 to have something to look at:

```console
$ nc -lk -p 8080 >/tmp/nc_received.txt &

$ ss -tuln
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
tcp   LISTEN 0      1            0.0.0.0:8080      0.0.0.0:*          

$ ss -tlnp
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      1            0.0.0.0:8080      0.0.0.0:*    users:(("nc",pid=402,fd=3))

$ netstat -tulnp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      402/nc              

$ (sleep 3 | nc google.com 80 >/dev/null) &
$ sleep 1; ss -tnp state established
Recv-Q Send-Q Local Address:Port   Peer Address:PortProcess
0      0         172.17.0.4:33814 74.125.68.100:80   users:(("nc",pid=430,fd=3))

$ netstat -tnp | tail -2
tcp        0      0 127.0.0.1:58674         127.0.0.1:8080          TIME_WAIT   -                   
tcp        0      0 172.17.0.4:33814        74.125.68.100:80        ESTABLISHED 430/nc              

$ ss -s
Total: 3
TCP:   563 (estab 0, closed 562, orphaned 2, timewait 5)

Transport Total     IP        IPv6
RAW	  0         0         0        
UDP	  0         0         0        
TCP	  1         1         0        
INET	  1         1         0        
FRAG	  0         0         0        
```

**What I understood:** `ss` (the replacement for `netstat`) lists sockets. The flags: `-t` TCP, `-u` UDP, `-l` listening only, `-n` numeric (don't resolve names), `-p` show the owning process. `ss -tulnp` is the go-to command for "what is listening on which port?", and here it shows `nc` (pid 402) listening on `0.0.0.0:8080`, meaning all interfaces. `state established` shows live connections, like my nc connection from `172.17.0.4:33814` (a random **ephemeral port**) to Google's port 80. `TIME_WAIT` is a connection that just closed and is waiting out its timeout.

## 13. `nc` (netcat) — raw TCP/UDP tool

```console
$ echo "hello from 24BCS10267 via nc" | nc -q 1 localhost 8080
$ cat /tmp/nc_received.txt
hello from 24BCS10267 via nc

$ nc -zv localhost 8080
nc: connect to localhost (::1) port 8080 (tcp) failed: Connection refused
Connection to localhost (127.0.0.1) 8080 port [tcp/http-alt] succeeded!

$ nc -zv localhost 8081
nc: connect to localhost (::1) port 8081 (tcp) failed: Connection refused
nc: connect to localhost (127.0.0.1) port 8081 (tcp) failed: Connection refused

$ nc -zv -w 3 google.com 443
Connection to google.com (74.125.68.100) 443 port [tcp/https] succeeded!

$ kill %1; sleep 0.2; ss -tln
State Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
```

**What I understood:** netcat reads and writes raw data over TCP or UDP. I used it as a tiny server (`-l`) and sent it a message from a client. `-z` only checks whether a port is open, without sending data, and `-v` prints the result, which makes it a quick port checker ("is the DB port reachable from this server?"). On 8080, the IPv6 attempt (`::1`) was refused because my listener was IPv4-only, but IPv4 succeeded. Port 8081 had nothing listening, so both attempts were refused. Port 443 on Google is open. After `kill`, nothing is listening any more.

## 14. `arping` and `ethtool`

```console
$ arping -c 2 -I eth0 172.17.0.1
ARPING 172.17.0.1
42 bytes from d2:db:6f:1e:7d:b2 (172.17.0.1): index=0 time=10.000 usec
42 bytes from d2:db:6f:1e:7d:b2 (172.17.0.1): index=1 time=12.875 usec

--- 172.17.0.1 statistics ---
2 packets transmitted, 2 packets received,   0% unanswered (0 extra)
rtt min/avg/max/std-dev = 0.010/0.011/0.013/0.001 ms

$ ethtool -i eth0
driver: veth
version: 1.0
firmware-version: 
expansion-rom-version: 
bus-info: 
supports-statistics: yes
supports-test: no
supports-eeprom-access: no
supports-register-dump: no
supports-priv-flags: no

$ ethtool -S eth0
NIC statistics:
     peer_ifindex: 119
     rx_queue_0_xdp_packets: 0
     rx_queue_0_xdp_bytes: 0
     rx_queue_0_drops: 0
...
```

**What I understood:** `arping` works like ping but at layer 2, using ARP requests. It works even if a host blocks ICMP, as long as it's on the same LAN, and `-D` can detect duplicate IPs. `ethtool` shows driver and NIC details. Here the driver is `veth`, a virtual Ethernet pair, which is how Docker connects a container to the bridge. On a real server, `ethtool eth0` would also show link speed and duplex.

## 15. `whois`

```console
$ whois google.com | head -12
   Domain Name: GOOGLE.COM
   Registry Domain ID: 2138514_DOMAIN_COM-VRSN
   Registrar WHOIS Server: whois.markmonitor.com
   Registrar URL: http://www.markmonitor.com
   Updated Date: 2019-09-09T15:39:04Z
   Creation Date: 1997-09-15T04:00:00Z
   Registry Expiry Date: 2028-09-14T04:00:00Z
   Registrar: MarkMonitor Inc.
   Registrar IANA ID: 292
   Registrar Abuse Contact Email: abusecomplaints@markmonitor.com
   Registrar Abuse Contact Phone: +1.2086851750
   Domain Status: clientDeleteProhibited https://icann.org/epp#clientDeleteProhibited
```

**What I understood:** `whois` shows a domain's registration record: the registrar, when it was created and when it expires.

## 16. Subnetting with `ipcalc` (checking the class notes)

The class notes (`ip.md`) worked through `120.27.1.0/8` and `197.23.45.10` with mask 255.255.255.0. I checked them with `ipcalc`:

```console
$ ipcalc 120.27.1.0/8
Address:   120.27.1.0           01111000. 00011011.00000001.00000000
Netmask:   255.0.0.0 = 8        11111111. 00000000.00000000.00000000
Wildcard:  0.255.255.255        00000000. 11111111.11111111.11111111
=>
Network:   120.0.0.0/8          01111000. 00000000.00000000.00000000
HostMin:   120.0.0.1            01111000. 00000000.00000000.00000001
HostMax:   120.255.255.254      01111000. 11111111.11111111.11111110
Broadcast: 120.255.255.255      01111000. 11111111.11111111.11111111
Hosts/Net: 16777214              Class A

$ ipcalc 197.23.45.10/24
Address:   197.23.45.10         11000101.00010111.00101101. 00001010
Netmask:   255.255.255.0 = 24   11111111.11111111.11111111. 00000000
Wildcard:  0.0.0.255            00000000.00000000.00000000. 11111111
=>
Network:   197.23.45.0/24       11000101.00010111.00101101. 00000000
HostMin:   197.23.45.1          11000101.00010111.00101101. 00000001
HostMax:   197.23.45.254        11000101.00010111.00101101. 11111110
Broadcast: 197.23.45.255        11000101.00010111.00101101. 11111111
Hosts/Net: 254                   Class C

$ ipcalc 192.168.1.130/26
Address:   192.168.1.130        11000000.10101000.00000001.10 000010
Netmask:   255.255.255.192 = 26 11111111.11111111.11111111.11 000000
Wildcard:  0.0.0.63             00000000.00000000.00000000.00 111111
=>
Network:   192.168.1.128/26     11000000.10101000.00000001.10 000000
HostMin:   192.168.1.129        11000000.10101000.00000001.10 000001
HostMax:   192.168.1.190        11000000.10101000.00000001.10 111110
Broadcast: 192.168.1.191        11000000.10101000.00000001.10 111111
Hosts/Net: 62                    Class C, Private Internet
```

**What I understood:** The prefix (`/8`, `/24`, `/26`) is the number of **network bits**, and the rest are **host bits**. Usable hosts = 2^(host bits) − 2, because the first address is the network address and the last is the broadcast address.
- `/8` → 24 host bits → 2^24 − 2 = **16,777,214** hosts (Class A, matches the notes: "no. of usable hosts = 2^24 − 2").
- `/24` → 8 host bits → 2^8 − 2 = **254** hosts. 197.x is in the 192–223 range → **Class C**. The range is 197.23.45.0 – 197.23.45.255, matching the notes.
- `/26` splits a /24 into 4 blocks of 64. 192.168.1.130 is in the `.128–.191` block, leaving 62 usable hosts. 192.168.x.x is a **private** range, like the 10.0.0.0/8 range in the notes and 172.16.0.0/12.

The container's own `172.17.0.4/16` (Docker) and the Mac's `172.20.10.2` with netmask `0xfffffff0` = 255.255.255.240 = `/28` (a phone hotspot, 14 usable hosts) are also private addresses:

```console
$ ifconfig en0 | grep -E "flags|inet "        # macOS host
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500 constrained
	inet 172.20.10.2 netmask 0xfffffff0 broadcast 172.20.10.15

$ route -n get default                          # macOS host
   route to: default
destination: default
       mask: default
    gateway: 172.20.10.1
  interface: en0
      flags: <UP,GATEWAY,DONE,STATIC,PRCLONING,GLOBAL>
```

---

## Troubleshooting order I'll follow from now on

1. `ip a` / `ip link`: is the interface up, and does it have an IP?
2. `ip route`: is there a default gateway? `ping <gateway>`
3. `ping 8.8.8.8`: can I reach the internet by IP?
4. `dig google.com` / `cat /etc/resolv.conf`: does DNS work?
5. `traceroute` / `mtr`: where along the path does it break?
6. `ss -tulnp`: is my service actually listening, and on the right IP and port?
7. `nc -zv host port` / `curl -I`: can I reach the port, and does the app answer?
