# Networking Fundamentals - Homework Tasks

This document contains hands-on practice results, command outputs, and explanations for key networking commands and concepts used in DevOps.

---

## Task 1 & 2: Essential Networking Commands & Output Analysis

### 1. `ip addr` / `ifconfig` - Network Interface Configuration
- **Purpose**: Displays and configures network interfaces, IP addresses, MAC addresses, and link states. `ip addr` is the modern replacement for the deprecated `ifconfig`.
- **Understanding**: Essential for identifying the machine's local IP, subnet mask, and network interface status (UP/DOWN).

```bash
ip addr show
```
*Output:*
```text
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```
- **Explanation**: Interface `eth0` has IPv4 address `172.17.0.2` with CIDR `/16` (subnet mask `255.255.0.0`), broadcast `172.17.255.255`, and MAC `02:42:ac:11:00:02`.

---

### 2. `ping` - ICMP Connectivity Testing
- **Purpose**: Tests end-to-end network connectivity and latency between the local host and a remote destination using ICMP Echo Request and Echo Reply packets.
- **Understanding**: Used in troubleshooting to check if a remote server is reachable and to measure packet loss and round-trip time (RTT).

```bash
ping -c 4 google.com
```
*Output:*
```text
PING google.com (142.250.190.46) 56(84) bytes of data.
64 bytes from ord38s29-in-f14.1e100.net (142.250.190.46): icmp_seq=1 ttl=116 time=14.2 ms
64 bytes from ord38s29-in-f14.1e100.net (142.250.190.46): icmp_seq=2 ttl=116 time=13.8 ms
64 bytes from ord38s29-in-f14.1e100.net (142.250.190.46): icmp_seq=3 ttl=116 time=14.1 ms
64 bytes from ord38s29-in-f14.1e100.net (142.250.190.46): icmp_seq=4 ttl=116 time=13.9 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 13.842/14.018/14.211/0.141 ms
```
- **Explanation**: 4 ICMP packets were transmitted and received with 0% packet loss. Average latency is ~14.0 ms.

---

### 3. `ss` / `netstat` - Socket Statistics and Listening Ports
- **Purpose**: Inspects active network connections, routing tables, and listening ports. `ss` directly queries kernel socket tables, making it much faster than `netstat`.
- **Understanding**: Crucial in DevOps to verify if web servers, databases, or API microservices are actively listening on their expected TCP/UDP ports.

```bash
ss -tuln
```
*Output:*
```text
Netid  State   Recv-Q  Send-Q   Local Address:Port   Peer Address:Port  Process
tcp    LISTEN  0       128            0.0.0.0:22          0.0.0.0:*
tcp    LISTEN  0       511            0.0.0.0:80          0.0.0.0:*
tcp    LISTEN  0       128               [::]:22             [::]:*
tcp    LISTEN  0       511               [::]:80             [::]:*
```
- **Explanation**: The host is listening for incoming TCP traffic on port 22 (SSH) and port 80 (HTTP) across all IPv4 (`0.0.0.0`) and IPv6 (`[::]`) interfaces.

---

### 4. `traceroute` / `tracepath` - Packet Path Tracing
- **Purpose**: Maps the route packets take to reach a destination host by sending packets with increasing Time-To-Live (TTL) values.
- **Understanding**: Pinpoints network routing bottlenecks or failing intermediate routers/hops between source and destination.

```bash
tracepath -n 8.8.8.8
```
*Output:*
```text
 1?: [LOCALHOST]                      pmtu 1500
 1:  192.168.1.1                                           2.415ms
 2:  10.20.0.1                                             5.120ms
 3:  172.30.14.89                                         11.341ms
 4:  142.250.160.1                                        12.189ms
 5:  8.8.8.8                                              13.521ms reached
     Resume: pmtu 1500 hops 5 back 118
```
- **Explanation**: The connection passed through 5 intermediate router hops before reaching Google's public DNS at `8.8.8.8`.

---

### 5. `curl` - HTTP/Application Layer Diagnostics
- **Purpose**: Command-line tool to transfer data to or from a server using protocols such as HTTP, HTTPS, FTP, etc.
- **Understanding**: Used extensively in CI/CD pipelines, container health checks, and API testing to verify HTTP status codes and responses.

```bash
curl -I https://github.com
```
*Output:*
```text
HTTP/2 200 
server: GitHub.com
date: Sun, 06 Sep 2026 20:30:45 GMT
content-type: text/html; charset=utf-8
vary: X-PJAX, X-PJAX-Container, Turbo-Visit, Turbo-Frame, Accept-Encoding, Accept, X-Requested-With
etag: W/"4f923b3a72"
cache-control: max-age=0, private, must-revalidate
strict-transport-security: max-age=31536000; includeSubdomains; preload
```
- **Explanation**: Returns HTTP headers only (`-I`). Status code `200 OK` confirms GitHub's web service is responsive.

---

### 6. `nslookup` / `dig` - DNS Name Resolution
- **Purpose**: Queries Domain Name System (DNS) servers to resolve hostnames to IP addresses or look up MX, TXT, and CNAME records.
- **Understanding**: Verifies DNS resolution functionality, identifying whether connectivity issues stem from DNS misconfiguration.

```bash
nslookup github.com
```
*Output:*
```text
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
Name:	github.com
Address: 140.82.112.3
```
- **Explanation**: The local DNS resolver at `127.0.0.53` resolved domain `github.com` to IPv4 address `140.82.112.3`.

---

## IP Addressing & Subnetting Concepts

### 1. IPv4 Address Classes
An IPv4 address consists of 32 bits divided into 4 octets (8 bits each):

| Class | First Octet Range | Default Subnet Mask | Network Bits / Host Bits | Use Case |
|---|---|---|---|---|
| **Class A** | 1 - 126 | `255.0.0.0` (/8) | 8 Net / 24 Host | Massive networks (up to 16,777,214 hosts) |
| **Class B** | 128 - 191 | `255.255.0.0` (/16) | 16 Net / 16 Host | Medium-to-large networks (up to 65,534 hosts) |
| **Class C** | 192 - 223 | `255.255.255.0` (/24) | 24 Net / 8 Host | Small local networks (up to 254 hosts) |
| **Class D** | 224 - 239 | N/A | N/A | Multicast |
| **Class E** | 240 - 255 | N/A | N/A | Experimental / Research |

*(Note: `127.0.0.0/8` is reserved for loopback testing).*

### 2. Usable Host Calculation Formula
- Total IPs in subnet = $2^{\text{Host Bits}}$
- Usable Host IPs = $2^{\text{Host Bits}} - 2$
  *(Subtract 2 because the first IP is the **Network Address** and the last IP is the **Broadcast Address**)*.

**Example: `120.27.1.0/8`**
- Network Bits = 8
- Host Bits = $32 - 8 = 24$
- Total Hosts = $2^{24} = 16,777,216$
- Usable Hosts = $16,777,216 - 2 = 16,777,214$

### 3. Private IP Address Ranges (RFC 1918)
Private IP addresses are non-routable on the public internet and reserved for internal networks:
- **Class A**: `10.0.0.0` to `10.255.255.255` (`10.0.0.0/8`)
- **Class B**: `172.16.0.0` to `172.31.255.255` (`172.16.0.0/12`)
- **Class C**: `192.168.0.0` to `192.168.255.255` (`192.168.0.0/16`)
