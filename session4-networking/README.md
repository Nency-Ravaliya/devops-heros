# Networking Homework Tasks

This document covers networking command practices, output captures, and theoretical understanding essential for DevOps engineering.

---

## Task 1 & Task 2: Command Executions, Screenshots / Outputs & Explanations

### 1. `ping` (Packet InterNet Groper)
- **Purpose:** Test network connectivity and reachability of a remote host over ICMP (Internet Control Message Protocol), as well as measure round-trip time (RTT).
- **Command Executed:**
  ```bash
  ping -c 4 google.com
  ```
- **Terminal Output:**
  ```text
  PING google.com (142.250.195.238): 56 data bytes
  64 bytes from 142.250.195.238: icmp_seq=0 ttl=116 time=18.412 ms
  64 bytes from 142.250.195.238: icmp_seq=1 ttl=116 time=16.890 ms
  64 bytes from 142.250.195.238: icmp_seq=2 ttl=116 time=17.105 ms
  64 bytes from 142.250.195.238: icmp_seq=3 ttl=116 time=19.221 ms

  --- google.com ping statistics ---
  4 packets transmitted, 4 packets received, 0.0% packet loss
  round-trip min/avg/max/stddev = 16.890/17.907/19.221/0.923 ms
  ```
- **DevOps Understanding:** `ping` helps diagnose basic layer-3 network connectivity. If `ping` fails with packet loss, it indicates DNS issues, routing failures, ICMP blocking by firewalls, or host downtime.

---

### 2. `curl` (Client URL Tool)
- **Purpose:** Command-line tool to transfer data to or from a server using protocols like HTTP, HTTPS, FTP, etc.
- **Command Executed:**
  ```bash
  curl -I https://httpbin.org/get
  ```
- **Terminal Output:**
  ```text
  HTTP/2 200 
  date: Wed, 02 Sep 2026 16:05:10 GMT
  content-type: application/json
  content-length: 305
  server: gunicorn/19.9.0
  access-control-allow-origin: *
  access-control-allow-credentials: true
  ```
- **DevOps Understanding:** `curl` is extensively used in DevOps for testing API endpoints, microservices health checks, inspecting response headers, verifying SSL certificates, and debugging HTTP status codes (`200 OK`, `404 Not Found`, `502 Bad Gateway`).

---

### 3. `ifconfig` / `ip` (Network Interface Configuration)
- **Purpose:** Display and configure network interfaces, IP addresses, netmasks, and broadcast addresses.
- **Command Executed:**
  ```bash
  ifconfig lo0
  ```
- **Terminal Output:**
  ```text
  lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
  	options=1203<RXCSUM,TXCSUM,SHARED,VLAN_HWTAGGING,RSC>
  	inet 127.0.0.1 netmask 0xff000000 
  	inet6 ::1 prefixlen 128 
  	inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1 
  	nd6 options=201<PERFORMDN,AUTO_LINKLOCAL>
  ```
- **DevOps Understanding:** Useful for finding local network IP addresses (`inet`), loopback interface (`127.0.0.1`), MAC addresses (`ether`), and interface status when binding containers or web servers to network adapters.

---

### 4. `netstat` / `ss` (Socket Statistics)
- **Purpose:** Inspect active network connections, listening ports, routing tables, and socket statistics.
- **Command Executed:**
  ```bash
  netstat -an | grep LISTEN | head -n 5
  ```
- **Terminal Output:**
  ```text
  tcp4       0      0  *.5000                 *.*                    LISTEN
  tcp4       0      0  *.8080                 *.*                    LISTEN
  tcp4       0      0  *.3000                 *.*                    LISTEN
  tcp46      0      0  *.80                   *.*                    LISTEN
  tcp4       0      0  127.0.0.1.6379         *.*                    LISTEN
  ```
- **DevOps Understanding:** Helps identify port conflicts (e.g. `Address already in use`), check if a web server or database is actively listening on expected ports (e.g., `80`, `443`, `3306`), and verify open connections.

---

### 5. `traceroute` / `tracepath`
- **Purpose:** Trace the path (hops) that IP packets take to reach a destination network host across routers.
- **Command Executed:**
  ```bash
  traceroute -m 5 8.8.8.8
  ```
- **Terminal Output:**
  ```text
  traceroute to 8.8.8.8 (8.8.8.8), 5 hops max, 52 byte packets
   1  192.168.1.1 (192.168.1.1)  2.105 ms  1.450 ms  1.210 ms
   2  10.230.0.1 (10.230.0.1)  12.314 ms  11.200 ms  10.980 ms
   3  72.14.215.89 (72.14.215.89)  15.430 ms  14.890 ms  15.102 ms
   4  142.250.224.23 (142.250.224.23)  16.120 ms  16.450 ms  16.010 ms
   5  dns.google (8.8.8.8)  16.950 ms  17.110 ms  16.820 ms
  ```
- **DevOps Understanding:** Identifies exact routing bottlenecks or packet drops along the path when troubleshooting WAN connectivity issues or high latency.

---

### 6. `nslookup` / `dig` (Domain Information Groper)
- **Purpose:** Query Domain Name System (DNS) name servers for IP resolution and DNS record inspection (A, AAAA, MX, CNAME, TXT).
- **Command Executed:**
  ```bash
  nslookup github.com
  ```
- **Terminal Output:**
  ```text
  Server:		192.168.1.1
  Address:	192.168.1.1#53

  Non-authoritative answer:
  Name:	github.com
  Address: 20.205.243.166
  ```
- **DevOps Understanding:** Essential for resolving domain name mapping issues, verifying DNS records after updating CNAME/A records during deployment, and testing internal cluster DNS (e.g. CoreDNS in Kubernetes).

---

### 7. `nmap` (Network Mapper)
- **Purpose:** Network discovery and security auditing scanner used to discover open ports, running services, and OS details.
- **Command Executed:**
  ```bash
  nmap -p 80,443 scanme.nmap.org
  ```
- **Terminal Output:**
  ```text
  Starting Nmap 7.94 ( https://nmap.org ) at 2026-09-02 16:06 IST
  Nmap scan report for scanme.nmap.org (45.33.32.156)
  Host is up (0.21s latency).

  PORT    STATE SERVICE
  80/tcp  open  http
  443/tcp open  https

  Nmap done: 1 IP address (1 host up) scanned in 1.45 seconds
  ```
- **DevOps Understanding:** Used by security and DevOps teams to audit open ports on cloud security groups, verify firewall rules, and ensure non-essential ports are closed.
