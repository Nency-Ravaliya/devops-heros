# Session 4: Networking

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

## What this file contains

- **Task 1:** I practised the commands from the shared repos (*Network-Troubleshooting*, *Networking*) and from the Linux `ip` cheat sheet given in the course.
- **Task 2:** this Markdown file. Every command was executed, the real output is pasted under it, and each command has a short note on what I understood.

**Environment:** Part A runs natively on my Ubuntu 26.04 (WSL2) machine. A few tools (`traceroute`, `telnet`, `tcpdump`) are not installed there and need root to install, so Part B runs them as root in a disposable `ubuntu:24.04` Docker container (its network path therefore starts at the Docker bridge instead of my laptop).

### Big picture (from the networking notes)

```
Laptop --(Wi-Fi/Ethernet, MAC addresses, L2)--> Router/Gateway --(IP routing, L3)--> ISP --> Internet --> google.com
         DHCP gives the laptop IP + gateway + DNS      DNS turns google.com into an IP      TCP (L4) opens port 443, HTTP/TLS (L7) fetches the page
```

Troubleshooting order I follow: **interface/IP -> gateway -> internet by IP -> DNS name -> port -> application (HTTP)**.

---

# Part A: Commands run on my machine (WSL Ubuntu)

## 1. Interface, IP and routes (`ip`, `ifconfig`)

_hostname and the IP addresses assigned to this host._

```console
$ hostname; hostname -I
Yashg-Laptop
172.28.10.180 
```

_ip addr shows the IP address(es), netmask (/20 = 255.255.240.0), MAC and state (UP) of one interface. This replaces the older ifconfig._

```console
$ ip addr show eth0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:b5:b4:a9 brd ff:ff:ff:ff:ff:ff
    altname enx00155db5b4a9
    inet 172.28.10.180/20 brd 172.28.15.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::215:5dff:feb5:b4a9/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
```

_ip link shows the layer-2 state of each interface (UP/DOWN, MAC address) in short form._

```console
$ ip -brief link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0             UP             00:15:5d:b5:b4:a9 <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

_The older net-tools way of showing the same information._

```console
$ ifconfig eth0 | head -4
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.28.10.180  netmask 255.255.240.0  broadcast 172.28.15.255
        inet6 fe80::215:5dff:feb5:b4a9  prefixlen 64  scopeid 0x20<link>
        ether 00:15:5d:b5:b4:a9  txqueuelen 1000  (Ethernet)
```

_The routing table. The "default via ..." line is my gateway: everything not on the local subnet is sent there._

```console
$ ip route
default via 172.28.0.1 dev eth0 proto kernel 
172.28.0.0/20 dev eth0 proto kernel scope link src 172.28.10.180 
```

_Which route and source address would be used to reach 8.8.8.8._

```console
$ ip route get 8.8.8.8
8.8.8.8 via 172.28.0.1 dev eth0 src 172.28.10.180 uid 1000 
    cache 
```

_The neighbour (ARP) table: IP address -> MAC address of devices on my local network._

```console
$ ip neigh
172.28.0.1 dev eth0 lladdr 00:15:5d:88:10:74 REACHABLE 
```

_The same ARP information using the classic arp command._

```console
$ arp -n
Address                  HWtype  HWaddress           Flags Mask            Iface
172.28.0.1               ether   00:15:5d:88:10:74   C                     eth0
```

## 2. Reachability (`ping`)

_ping sends ICMP echo requests. Replies mean the network path works; time= is the round-trip latency. Pinging an IP first proves connectivity without involving DNS._

```console
$ ping -c 4 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=115 time=16.0 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=115 time=13.1 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=115 time=13.8 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=115 time=17.0 ms

--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 13.148/14.976/16.987/1.564 ms
```

_Pinging a name also tests DNS resolution (the name is turned into an IP first). 0% packet loss = healthy._

```console
$ ping -c 4 google.com
PING google.com (142.250.143.101) 56(84) bytes of data.
64 bytes from pt-in-f101.1e100.net (142.250.143.101): icmp_seq=1 ttl=112 time=30.7 ms
64 bytes from pt-in-f101.1e100.net (142.250.143.101): icmp_seq=2 ttl=112 time=27.8 ms
64 bytes from pt-in-f101.1e100.net (142.250.143.101): icmp_seq=3 ttl=112 time=48.0 ms
64 bytes from pt-in-f101.1e100.net (142.250.143.101): icmp_seq=4 ttl=112 time=48.4 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 27.801/38.721/48.357/9.521 ms
```

## 3. Open ports and connections (`netstat`, `ss`, `nc`)

_netstat lists listening (-l) TCP (-t) and UDP (-u) sockets with numeric (-n) addresses: what services are exposed on this machine._

```console
$ netstat -tuln
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN     
tcp        0      0 127.0.0.54:53           0.0.0.0:*               LISTEN     
tcp        0      0 10.255.255.254:53       0.0.0.0:*               LISTEN     
udp        0      0 127.0.0.54:53           0.0.0.0:*                          
udp        0      0 127.0.0.53:53           0.0.0.0:*                          
udp        0      0 10.255.255.254:53       0.0.0.0:*                          
udp        0      0 127.0.0.1:323           0.0.0.0:*                          
udp        0      0 127.0.0.1:323           0.0.0.0:*                          
udp6       0      0 ::1:323                 :::*                               
udp6       0      0 ::1:323                 :::*                               
```

_ss does the same job faster and is the modern replacement for netstat._

```console
$ ss -tuln
Netid        State         Recv-Q        Send-Q                Local Address:Port               Peer Address:Port       
udp          UNCONN        0             0                        127.0.0.54:53                      0.0.0.0:*          
udp          UNCONN        0             0                     127.0.0.53%lo:53                      0.0.0.0:*          
udp          UNCONN        0             0                    10.255.255.254:53                      0.0.0.0:*          
udp          UNCONN        0             0                         127.0.0.1:323                     0.0.0.0:*          
udp          UNCONN        0             0                         127.0.0.1:323                     0.0.0.0:*          
udp          UNCONN        0             0                             [::1]:323                        [::]:*          
udp          UNCONN        0             0                             [::1]:323                        [::]:*          
tcp          LISTEN        0             4096                  127.0.0.53%lo:53                      0.0.0.0:*          
tcp          LISTEN        0             4096                     127.0.0.54:53                      0.0.0.0:*          
tcp          LISTEN        0             1000                 10.255.255.254:53                      0.0.0.0:*          
```

_Socket statistics summary (counts of TCP/UDP sockets by state)._

```console
$ ss -s
Total: 318
TCP:   30 (estab 2, closed 25, orphaned 0, timewait 0)

Transport Total     IP        IPv6
RAW	  0         0         0        
UDP	  7         5         2        
TCP	  5         5         0        
INET	  12        10        2        
FRAG	  0         0         0        

```

_nc (netcat) -z only checks whether a port is open without sending data. This is the quick way to test "is the port reachable?" (the job telnet does in Part B)._

```console
$ nc -zv -w 3 example.com 80 443
Connection to example.com (172.66.147.243) 80 port [tcp/http] succeeded!
Connection to example.com (104.20.23.154) 443 port [tcp/https] succeeded!
```

## 4. DNS (`nslookup`, `dig`, `host`)

_Which DNS server this machine asks._

```console
$ grep -v "^#" /etc/resolv.conf
nameserver 10.255.255.254
```

_nslookup asks the DNS server for the IP of a name. It shows which server answered and the A/AAAA records._

```console
$ nslookup google.com
Server:		10.255.255.254
Address:	10.255.255.254#53

Non-authoritative answer:
Name:	google.com
Address: 142.250.143.138
Name:	google.com
Address: 142.250.143.100
Name:	google.com
Address: 142.250.143.113
Name:	google.com
Address: 142.250.143.102
Name:	google.com
Address: 142.250.143.139
Name:	google.com
Address: 142.250.143.101
Name:	google.com
Address: 2404:6800:4000:100c::8b
Name:	google.com
Address: 2404:6800:4000:100c::65
Name:	google.com
Address: 2404:6800:4000:100c::71
Name:	google.com
Address: 2404:6800:4000:100c::66

```

_dig gives a detailed view of a DNS query: the answer section, the TTL (second column, how long the answer may be cached) and the query time._

```console
$ dig google.com +noall +answer +stats
google.com.		19	IN	A	142.250.143.100
google.com.		19	IN	A	142.250.143.113
google.com.		19	IN	A	142.250.143.102
google.com.		19	IN	A	142.250.143.139
google.com.		19	IN	A	142.250.143.101
google.com.		19	IN	A	142.250.143.138
;; Query time: 20 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Sun Oct 18 12:21:51 UTC 2026
;; MSG SIZE  rcvd: 260

```

_Look up a different record type: MX = mail servers._

```console
$ dig MX gmail.com +short
20 alt2.gmail-smtp-in.l.google.com.
30 alt3.gmail-smtp-in.l.google.com.
40 alt4.gmail-smtp-in.l.google.com.
5 gmail-smtp-in.l.google.com.
10 alt1.gmail-smtp-in.l.google.com.
```

_Reverse lookup: IP address -> name._

```console
$ dig -x 8.8.8.8 +short
dns.google.
```

_host is the simplest lookup tool._

```console
$ host github.com
github.com has address 20.207.73.82
github.com mail is handled by 0 github-com.mail.protection.outlook.com.
```

## 5. HTTP (`curl`)

_curl -I fetches only the response headers. 200 means the server is up and answering HTTP; this tests the whole stack (DNS + TCP + TLS + HTTP)._

```console
$ curl -sI https://example.com
HTTP/2 200 
date: Sun, 18 Oct 2026 12:21:50 GMT
content-type: text/html; charset=utf-8
server: cloudflare
last-modified: Tue, 13 Oct 2026 20:08:28 GMT
allow: GET, HEAD
accept-ranges: bytes
age: 7924
cf-cache-status: HIT
cf-ray: a4c7814d1faffaad-MAA
alt-svc: h3=":443"; ma=86400

```

_curl -w prints timings, which show where the time is spent (DNS, TCP connect, TLS handshake, total)._

```console
$ curl -s -o /dev/null -w "code=%{http_code} dns=%{time_namelookup}s connect=%{time_connect}s tls=%{time_appconnect}s total=%{time_total}s\n" https://example.com
code=200 dns=0.078043s connect=0.092330s tls=0.127994s total=0.149451s
```

_curl -v shows the connection steps: the IP tried, the TCP connect, the TLS version and the HTTP request/response lines._

```console
$ curl -sv https://example.com -o /dev/null 2>&1 | grep -E "^(\*   Trying|\* Connected|\* SSL connection|> GET|> Host|< HTTP)"
*   Trying [2606:4700:10::ac42:93f3]:443...
*   Trying 172.66.147.243:443...
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519MLKEM768 / id-ecPublicKey
> GET / HTTP/2
> Host: example.com
< HTTP/2 200 
```

## 6. Network services (`systemctl`)

_Is the DNS resolver / network service running? (NetworkManager is not installed on this WSL image, so it reports inactive.)_

```console
$ systemctl is-active systemd-resolved systemd-networkd NetworkManager
active
inactive
inactive
```

_Detail for the resolver service that handles DNS on this machine._

```console
$ systemctl status systemd-resolved --no-pager | head -6
● systemd-resolved.service - Network Name Resolution
     Loaded: loaded (/usr/lib/systemd/system/systemd-resolved.service; enabled; preset: enabled)
     Active: active (running) since Sun 2026-10-18 12:11:42 UTC; 10min ago
 Invocation: 7a54ec583d904c4fb6fb5aeab2c7d1f8
TriggeredBy: ● systemd-resolved-monitor.socket
             ● systemd-resolved-varlink.socket
```

## 7. IP addressing and subnet maths (from the class notes)

The notes have worked examples (classes A/B/C, subnet masks, host counts). I checked them with Python's `ipaddress` module.

_Netmask, network address, broadcast address and usable hosts (2^host_bits - 2) for the examples from the notes. 197.23.45.10/24 has broadcast 197.23.45.255, as in the notes._

```console
$ python3 - <<PY
import ipaddress as ip
for cidr in ["197.23.45.10/24", "120.27.1.0/8", "10.0.0.0/16", "192.168.1.0/26"]:
    n = ip.ip_interface(cidr).network
    hosts = n.num_addresses - 2
    print(f"{cidr:18} netmask={n.netmask}  network={n.network_address}  broadcast={n.broadcast_address}  usable_hosts={hosts}")
print("is 10.1.2.3 private?", ip.ip_address("10.1.2.3").is_private, "| is 8.8.8.8 private?", ip.ip_address("8.8.8.8").is_private)
PY
197.23.45.10/24    netmask=255.255.255.0  network=197.23.45.0  broadcast=197.23.45.255  usable_hosts=254
120.27.1.0/8       netmask=255.0.0.0  network=120.0.0.0  broadcast=120.255.255.255  usable_hosts=16777214
10.0.0.0/16        netmask=255.255.0.0  network=10.0.0.0  broadcast=10.0.255.255  usable_hosts=65534
192.168.1.0/26     netmask=255.255.255.192  network=192.168.1.0  broadcast=192.168.1.63  usable_hosts=62
is 10.1.2.3 private? True | is 8.8.8.8 private? False
```

---

# Part B: Tools that need root (disposable Ubuntu container)

The container is deleted after the run. I first installed the tools it needs:

_Install the tools._

```console
$ apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq traceroute tcpdump telnet iputils-ping curl ca-certificates iproute2 >/dev/null 2>&1 && echo "traceroute, tcpdump, telnet, ping, curl, ip installed"
traceroute, tcpdump, telnet, ping, curl, ip installed
```

## 8. `traceroute`

_traceroute lists every router (hop) between me and the destination with 3 timings per hop. A "* * *" line is a hop that does not answer probes (very common, not necessarily a problem); a sudden jump in latency shows where the slow link is. I used -I (ICMP mode) because the default UDP probes are dropped by Docker NAT. NAT also hides the routers beyond this machine, so the container only shows 2 hops (the Docker bridge gateway, then the destination); Part C shows the full path from the Windows host._

```console
$ traceroute -I -n -m 10 -w 2 google.com
traceroute to google.com (172.217.160.206), 10 hops max, 60 byte packets
 1  172.17.0.1  0.616 ms  0.578 ms  0.574 ms
 2  172.217.160.206  37.667 ms  37.679 ms  40.581 ms
```

## 9. `telnet`

_telnet opens a raw TCP connection to host:port. "Connected to ..." proves the port is reachable (the same check nc -z did in Part A). A refused or timed-out connection points to a firewall or a stopped service._

```console
$ timeout 5 telnet example.com 80 </dev/null
Trying 172.66.147.243...
Connected to example.com.
Escape character is '^]'.
Connection closed by foreign host.
```

_A port that is not open: the connection never completes (it hangs until the timeout), the typical symptom of a firewall DROP._

```console
$ timeout 3 telnet example.com 81 </dev/null; echo "exit code: $?"
exit code: 124
```

## 10. `tcpdump`

_The interface that will be sniffed._

```console
$ ip -o -4 addr show eth0 | awk "{print \$2, \$4}"
eth0 172.17.0.2/16
```

_tcpdump captures live packets. Here I filter for ICMP (ping) while a ping runs in the background: you can see the echo request going out and the echo reply coming back with the same id/seq._

```console
$ (sleep 1; ping -c 2 -W 1 8.8.8.8 >/dev/null) & timeout 20 tcpdump -Z root -n -i eth0 -c 4 icmp 2>&1
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
12:28:04.832806 IP 172.17.0.2 > 8.8.8.8: ICMP echo request, id 13, seq 1, length 64
12:28:04.850904 IP 8.8.8.8 > 172.17.0.2: ICMP echo reply, id 13, seq 1, length 64
12:28:05.834688 IP 172.17.0.2 > 8.8.8.8: ICMP echo request, id 13, seq 2, length 64
12:28:05.847377 IP 8.8.8.8 > 172.17.0.2: ICMP echo reply, id 13, seq 2, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

_Filter by TCP port 80 while curl fetches a page: the first three lines are the TCP three-way handshake (Flags [S], [S.], [.]), then the HTTP request/response follows._

```console
$ (sleep 1; curl -s -o /dev/null http://example.com) & timeout 20 tcpdump -Z root -n -i eth0 -c 8 "tcp port 80" 2>&1
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
12:28:06.931681 IP 172.17.0.2.49420 > 172.66.147.243.80: Flags [S], seq 2677566482, win 64240, options [mss 1460,sackOK,TS val 639963605 ecr 0,nop,wscale 7], length 0
12:28:06.953064 IP 172.66.147.243.80 > 172.17.0.2.49420: Flags [S.], seq 2306274473, ack 2677566483, win 29184, options [mss 1460,sackOK,TS val 3022468570 ecr 639963605,nop,wscale 7], length 0
12:28:06.953162 IP 172.17.0.2.49420 > 172.66.147.243.80: Flags [.], ack 1, win 502, options [nop,nop,TS val 639963627 ecr 3022468570], length 0
12:28:06.953309 IP 172.17.0.2.49420 > 172.66.147.243.80: Flags [P.], seq 1:75, ack 1, win 502, options [nop,nop,TS val 639963627 ecr 3022468570], length 74: HTTP: GET / HTTP/1.1
12:28:06.954369 IP 172.66.147.243.80 > 172.17.0.2.49420: Flags [.], ack 75, win 227, options [nop,nop,TS val 3022468572 ecr 639963627], length 0
12:28:06.982192 IP 172.66.147.243.80 > 172.17.0.2.49420: Flags [P.], seq 1:937, ack 75, win 4096, options [nop,nop,TS val 3022468599 ecr 639963627], length 936: HTTP: HTTP/1.1 200 OK
12:28:06.982261 IP 172.17.0.2.49420 > 172.66.147.243.80: Flags [.], ack 937, win 525, options [nop,nop,TS val 639963656 ecr 3022468599], length 0
12:28:06.982559 IP 172.17.0.2.49420 > 172.66.147.243.80: Flags [F.], seq 75, ack 937, win 525, options [nop,nop,TS val 639963656 ecr 3022468599], length 0
8 packets captured
11 packets received by filter
0 packets dropped by kernel
```

---

# Part C: The same idea on the Windows host (`tracert`)

Windows calls it `tracert`. Run directly on my laptop (PowerShell), it shows the whole path to Google because there is no Docker NAT in between.

_`-d` skips reverse DNS lookups (faster), `-h 8` limits it to 8 hops._

```console
PS> tracert -d -h 8 -w 1500 google.com
Tracing route to google.com [172.217.160.206]
over a maximum of 8 hops:

  1    11 ms     4 ms     4 ms  100.129.160.1
  2     5 ms     4 ms     4 ms  202.131.133.5
  3    11 ms     9 ms     6 ms  115.117.125.189
  4     *       60 ms     *     172.28.117.90
  5    14 ms    11 ms    20 ms  115.112.15.114
  6    31 ms    54 ms    31 ms  172.217.160.206

Trace complete.
```

How to read it: hop 1 is my router/gateway (a carrier-grade NAT address in the `100.64.0.0/10` range), hops 2-5 are routers inside my ISP and its upstream network, hop 6 is Google. Hop 4 shows `*` for two of its three probes: that router rate-limits ICMP replies, which is normal and not a fault because the later hops still answer.

---

# Command summary

| Goal | Command |
|---|---|
| My IP, interfaces, MAC | `ip addr`, `ip link`, `ifconfig`, `hostname -I` |
| Gateway and routes | `ip route`, `ip route get <ip>` |
| Local neighbours | `ip neigh`, `arp -n` |
| Is the host reachable? | `ping` |
| Path to the host | `traceroute` / `tracert` |
| Which ports are listening here? | `ss -tuln`, `netstat -tuln` |
| Is a remote port open? | `nc -zv host port`, `telnet host port` |
| DNS resolution | `nslookup`, `dig`, `host` |
| HTTP check and timing | `curl -I`, `curl -w`, `curl -v` |
| Watch packets | `tcpdump` |
| Is the network service running? | `systemctl status` |
