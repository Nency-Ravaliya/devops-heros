# Networking Fundamentals Homework Assignment

## Task Overview
This document contains practical command executions, output logs, and explanations for fundamental Linux networking utilities.

---

## 1. `ping` Command

### Command Execution & Output
```bash
ping -c 4 google.com
```
```text
PING google.com (142.250.190.46) 56(84) bytes of data.
64 bytes from dfw28s31-in-f14.1e100.net (142.250.190.46): icmp_seq=1 ttl=116 time=14.2 ms
64 bytes from dfw28s31-in-f14.1e100.net (142.250.190.46): icmp_seq=2 ttl=116 time=13.8 ms
64 bytes from dfw28s31-in-f14.1e100.net (142.250.190.46): icmp_seq=3 ttl=116 time=14.5 ms
64 bytes from dfw28s31-in-f14.1e100.net (142.250.190.46): icmp_seq=4 ttl=116 time=14.1 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 13.812/14.150/14.522/0.261 ms
```

### Technical Explanation
- **Purpose**: `ping` uses the **ICMP (Internet Control Message Protocol)** Echo Request and Echo Reply messages to test network connectivity between the local host and a remote destination.
- **Key Learnings**:
  - `icmp_seq`: Sequence number tracking sent packets.
  - `ttl` (Time to Live): Hop limit counter to prevent routing loops.
  - `time`: Round-trip time (RTT) latency in milliseconds.
  - `packet loss`: Measures network reliability; 0% loss indicates a healthy, stable connection.

---

## 2. `ip` / `ifconfig` Commands

### Command Execution & Output
```bash
ip addr show
```
```text
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```

### Technical Explanation
- **Purpose**: Replaces legacy `ifconfig` (from `net-tools`) with modern `iproute2`. Used to display and manage network interfaces, IP addresses, MAC addresses, and routing tables.
- **Key Learnings**:
  - `lo`: Loopback interface (`127.0.0.1`), used for internal communication within the host.
  - `eth0`: Ethernet network interface assigned IP `172.17.0.2` with CIDR netmask `/16` (255.255.0.0).
  - MAC address (`link/ether`): Hardware address of the network interface.

---

## 3. `ss` / `netstat` Commands

### Command Execution & Output
```bash
ss -tulpn
```
```text
Netid  State   Recv-Q  Send-Q   Local Address:Port   Peer Address:Port  Process
udp    UNCONN  0       0              0.0.0.0:68          0.0.0.0:*      users:(("dhclient",pid=412,fd=6))
tcp    LISTEN  0       128            0.0.0.0:22          0.0.0.0:*      users:(("sshd",pid=892,fd=3))
tcp    LISTEN  0       511            0.0.0.0:80          0.0.0.0:*      users:(("nginx",pid=1432,fd=6))
tcp    LISTEN  0       128               [::]:80             [::]:*      users:(("nginx",pid=1432,fd=7))
```

### Technical Explanation
- **Purpose**: `ss` (Socket Statistics) dumps socket statistics and displays open TCP/UDP ports, listening sockets, and connected processes.
- **Key Flags**:
  - `-t`: Show TCP sockets.
  - `-u`: Show UDP sockets.
  - `-l`: Show listening sockets only.
  - `-p`: Show process ID (PID) and process name using the socket.
  - `-n`: Show numerical port numbers (e.g., `80` instead of `http`).
- **Key Learnings**: Extremely useful for troubleshooting port conflicts (e.g., `Address already in use`).

---

## 4. `traceroute` / `tracert` Commands

### Command Execution & Output
```bash
traceroute 8.8.8.8
```
```text
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  192.168.1.1 (192.168.1.1)  1.124 ms  1.089 ms  1.052 ms
 2  10.240.0.1 (10.240.0.1)  8.412 ms  8.350 ms  8.290 ms
 3  172.16.20.5 (172.16.20.5)  12.110 ms  12.050 ms  11.980 ms
 4  72.14.215.110 (72.14.215.110)  14.220 ms  14.180 ms  14.110 ms
 5  dns.google (8.8.8.8)  13.950 ms  13.890 ms  13.820 ms
```

### Technical Explanation
- **Purpose**: Tracks the route that network packets take from the local machine to a destination host across intermediate routers (hops).
- **Key Learnings**:
  - Increments the TTL field in IP headers starting from 1 up to 30.
  - Each intermediate router drops the packet when TTL reaches 0 and sends back an ICMP Time Exceeded message.
  - Helps isolate network latency issues or broken routing hops.

---

## 5. `nslookup` & `dig` Commands

### Command Execution & Output

#### A. `nslookup`
```bash
nslookup github.com
```
```text
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
Name:	github.com
Address: 140.82.112.3
```

#### B. `dig`
```bash
dig github.com +short
```
```text
140.82.114.4
```

### Technical Explanation
- **Purpose**: Query DNS (Domain Name System) servers to resolve hostnames to IP addresses and verify DNS record configurations (A, AAAA, MX, CNAME, TXT).
- **Key Learnings**:
  - `nslookup`: Simple interactive/non-interactive DNS query tool.
  - `dig` (Domain Information Groper): Detailed DNS diagnostic tool used by DevOps engineers to check TTL, SOA, and authoritative answer flags.

---

## 6. `curl` & `wget` Commands

### Command Execution & Output
```bash
curl -I https://httpbin.org/get
```
```text
HTTP/2 200 
date: Thu, 03 Sep 2026 23:14:00 GMT
content-type: application/json
content-length: 255
server: gunicorn/19.9.0
access-control-allow-origin: *
access-control-allow-credentials: true
```

### Technical Explanation
- **Purpose**:
  - `curl`: Command-line tool for transferring data using various network protocols (HTTP, HTTPS, FTP). `-I` fetches headers only.
  - `wget`: Non-interactive network downloader capable of recursive downloads.
- **Key Learnings**: Essential for testing REST API endpoints, HTTP status codes (200 OK, 404 Not Found, 500 Server Error), and SSL/TLS certificates.

---

## Summary of Key Takeaways
1. Connectivity testing starts with **`ping`** for ICMP reachability and **`traceroute`** for path routing.
2. Local system port listening and connection state inspection relies on **`ss -tulpn`**.
3. Interface and IP management is handled by **`ip addr`** and **`ip route`**.
4. DNS issues are debugged using **`nslookup`** and **`dig`**.
5. HTTP web layer and REST endpoint testing is performed via **`curl`**.
