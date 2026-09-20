# Session 4 — Networking

**Name:** Sourabh Srivastva 
**Enrollment Number:** 24BCS10157

---

## Task 1: Practice Networking Commands

### `ip addr` - Show Network Interfaces and IP Addresses

```bash
ip addr
```

```text
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet 10.255.255.254/32 brd 10.255.255.254 scope global lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host proto kernel_lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1280 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:f0:f9:42 brd ff:ff:ff:ff:ff:ff
    altname enx00155df0f942
    inet 172.21.8.107/20 brd 172.21.15.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::215:5dff:fef0:f942/64 scope link proto kernel_ll
       valid_lft forever preferred_lft forever
```

**What I understood:** `ip addr` shows all network interfaces with their IP addresses. `lo` is the loopback interface (127.0.0.1). `eth0` is the main Ethernet interface showing the machine's IP `172.21.8.107` in the `/20` subnet.

---

### `ip route` - View the Routing Table

```bash
ip route
```

```text
default via 172.21.0.1 dev eth0 proto kernel
172.21.0.0/20 dev eth0 proto kernel scope link src 172.21.8.107
```

**What I understood:** The routing table tells the kernel where to send packets. `default via 172.21.0.1` means all traffic that doesn't match a specific route goes to the gateway `172.21.0.1 `. The second line says traffic for the local `172.21.0.0/20` subnet goes directly through `eth0`.

---

### `ping` - Test Connectivity

```bash
ping -c 4 google.com
```

```text
PING google.com (142.250.183.174) 56(84) bytes of data.
64 bytes from bom07s32-in-f14.1e100.net (142.250.183.174): icmp_seq=1 ttl=116 time=12.5 ms
64 bytes from bom07s32-in-f14.1e100.net (142.250.183.174): icmp_seq=2 ttl=116 time=25.9 ms
64 bytes from bom07s32-in-f14.1e100.net (142.250.183.174): icmp_seq=3 ttl=116 time=12.9 ms
64 bytes from bom07s32-in-f14.1e100.net (142.250.183.174): icmp_seq=4 ttl=116 time=12.1 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 12.090/15.854/25.933/5.826 ms
```

**What I understood:** `ping` sends ICMP echo-request packets and measures round-trip time (RTT). `0% packet loss` confirms the host is reachable. TTL (Time To Live) indicates how many router hops the packet has left.

---

### `traceroute` - Trace the Path to a Host

```bash
traceroute google.com
```

```text
traceroute to google.com (142.250.183.174), 30 hops max, 60 byte packets
 1  DESKTOP-E0F3569.mshome.net (172.21.0.1)  0.509 ms  0.486 ms  0.468 ms
 2  192.168.1.1 (192.168.1.1)  5.667 ms  5.642 ms  5.621 ms
 3  * * *
 4  * 202.88.156.197 (202.88.156.197)  5.538 ms *
 5  * * *
 6  10.240.254.120 (10.240.254.120)  7.493 ms  4.658 ms  4.645 ms
 7  10.240.254.1 (10.240.254.1)  7.721 ms * *
 8  10.241.1.1 (10.241.1.1)  5.791 ms  5.777 ms  8.846 ms
 9  * * *
10  142.250.172.12 (142.250.172.12)  14.720 ms  14.703 ms  13.625 ms
11  192.178.121.39 (192.178.121.39)  18.295 ms  15.059 ms 192.178.120.187 (192.178.120.187)  13.191 ms
12  142.251.55.67 (142.251.55.67)  15.742 ms  12.745 ms 142.251.55.65 (142.251.55.65)  12.611 ms
```

**What I understood:** `traceroute` reveals every router hop between your machine and the destination. `* * *` on hop 4 means that router did not respond (ICMP blocked). Useful for diagnosing where network slowdowns or failures occur.

---

### `netstat` / `ss` - Active Connections and Open Ports

```bash
ss -tuln
```

```text
Netid  State   Recv-Q  Send-Q  Local Address:Port   Peer Address:Port  Process
udp    UNCONN  0       0       0.0.0.0:68            0.0.0.0:*
tcp    LISTEN  0       128     0.0.0.0:22            0.0.0.0:*
tcp    LISTEN  0       128     [::]:22               [::]:*
```

**What I understood:** `ss -tuln` shows TCP (`t`), UDP (`u`) sockets, listening (`l`) only, in numeric (`n`) form. Port 22 is SSH listening on all interfaces. Port 68 is DHCP client.

---

### `curl` - HTTP Requests

```bash
curl -I https://www.google.com
```

```text
HTTP/2 200
content-type: text/html; charset=ISO-8859-1
date: Wed, 03 Sep 2026 11:45:00 GMT
server: gws
x-xss-protection: 0
x-frame-options: SAMEORIGIN
cache-control: private, max-age=0
```

**What I understood:** `curl -I` sends an HTTP HEAD request and shows only response headers. The `200` status means success. Headers tell us the server type (`gws` = Google Web Server), content type, and cache policy.

---

### `nslookup` / `dig` - DNS Lookup

```bash
nslookup google.com
```

```text
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   google.com
Address: 142.250.195.78
Name:   google.com
Address: 2404:6800:4009:80c::200e
```

```bash
dig google.com +short
```

```text
142.250.195.78
```

**What I understood:** DNS translates domain names to IP addresses. `nslookup` and `dig` query the DNS server. The DNS server `8.8.8.8` is Google's public resolver. `+short` in dig gives just the IP.

---

### `wget` - Download Files

```bash
wget -q https://example.com/index.html -O /tmp/page.html
echo "Download done. File size: $(wc -c < /tmp/page.html) bytes"
```

```text
Download done. File size: 1256 bytes
```

**What I understood:** `wget` downloads files from the internet. `-q` is quiet mode. `-O` specifies output filename. Useful for downloading files or testing HTTP connectivity without a browser.

---

### `hostname` - Machine Name & DNS

```bash
hostname
hostname -I
hostname -f
```

```text
DESKTOP-E0F3569
172.21.8.107
DESKTOP-E0F3569.localdomain
```

**What I understood:** `hostname` shows the machine name. `-I` shows all IP addresses assigned to the machine. `-f` shows the fully qualified domain name (FQDN).

---

### `ifconfig` - Legacy Interface Config

```bash
ifconfig eth0
```

```text
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1280
        inet 172.21.8.107  netmask 255.255.240.0  broadcast 172.21.15.255
        inet6 fe80::215:5dff:fef0:f942  prefixlen 64  scopeid 0x20<link>
        ether 00:15:5d:f0:f9:42  txqueuelen 1000  (Ethernet)
        RX packets 1728  bytes 6136258 (6.1 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1115  bytes 130831 (130.8 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

**What I understood:** `ifconfig` is the older way to view and configure network interfaces. Shows MAC address, IP, netmask, and packet statistics. Superseded by `ip addr` but still widely used.

---

## Task 2: Networking Commands Summary

| Command | Purpose |
|---|---|
| `ip addr` | Show network interfaces and IPs |
| `ip route` | Show routing table |
| `ping` | Test ICMP connectivity |
| `traceroute` | Trace route to a host hop by hop |
| `ss -tuln` | Show open TCP/UDP ports |
| `curl` | Make HTTP/HTTPS requests |
| `wget` | Download files from URLs |
| `nslookup` / `dig` | DNS resolution |
| `hostname` | Show/query machine name |
| `ifconfig` | Legacy interface config |
| `iptables` | Firewall rules (kernel netfilter) |
| `ufw` | Simplified firewall (Ubuntu) |