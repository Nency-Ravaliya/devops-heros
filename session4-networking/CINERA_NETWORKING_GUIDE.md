# 🍿 CINERA (Netflix Clone) - Complete Computer Networking & Subnetting Guide & Notes

Welcome to the **Complete Computer Networking Guide** built around a real-world production infrastructure: **CINERA** (a scalable Netflix clone).

This guide walks you through every core networking concept, IP addressing principle, subnetting calculation, and network troubleshooting command taught in DevOps Session 4, using **CINERA** as our hands-on example.

---

## 🌐 1. CINERA Cloud Network Architecture

In production, CINERA runs inside an isolated **Virtual Private Cloud (VPC)** divided into secure subnets:

```text
                                [ INTERNET ]
                                     |
                                     v (Public IP: 198.51.100.42)
                        +--------------------------+
                        |   Nginx Load Balancer    |
                        |   Public Subnet          |
                        |   (10.0.1.0/24)          |
                        +--------------------------+
                                     |
                                     v (Private Network Routing)
             +-----------------------+-----------------------+
             |                                               |
             v                                               v
+--------------------------+                   +--------------------------+
|  Express API Servers     |                   |  Database & Redis Cache  |
|  Private App Subnet      |                   |  Private DB Subnet       |
|  (10.0.2.0/24)           |                   |  (10.0.3.0/24)           |
+--------------------------+                   +--------------------------+
```

---

## 🔢 2. IP Addressing & CIDR Notation Fundamentals

An **IP (Internet Protocol) Address** is a unique 32-bit binary number represented in 4 decimal octets separated by dots (e.g., `192.168.1.1`).

### A. IP Classes Breakdown

| Class | First Octet Range | Default Subnet Mask | Default CIDR | Use Case in CINERA |
| :--- | :--- | :--- | :--- | :--- |
| **Class A** | `1.0.0.0` to `127.255.255.255` | `255.0.0.0` | `/8` | Large Enterprise Internal Networks |
| **Class B** | `128.0.0.0` to `191.255.255.255` | `255.255.0.0` | `/16` | Medium to Large Enterprise VPCs |
| **Class C** | `192.168.0.0` to `223.255.255.255` | `255.255.255.0` | `/24` | Small Office / Home / Subnet Networks |
| **Class D** | `224.0.0.0` to `239.255.255.255` | Multicast | N/A | Video Multicasting & Streaming protocols |

---

### B. Public vs. Private IP Ranges

* **Public IP Addresses**: Globally unique and routable on the open Internet (e.g., CINERA's public domain `cinera.com` resolves to `198.51.100.42`).
* **Private IP Ranges (RFC 1918)**: Used strictly inside local networks and cloud VPCs; NOT routable directly over the public Internet.

#### Private IP Address Ranges:
* **Class A**: `10.0.0.0` – `10.255.255.255` (Used by AWS VPC for CINERA)
* **Class B**: `172.16.0.0` – `172.31.255.255` (Used default by Docker bridges)
* **Class C**: `192.168.0.0` – `192.168.255.255` (Home Wi-Fi routers)

---

## 📐 3. Subnetting & Host Calculation Formula for CINERA

Subnetting divides a larger network into smaller, isolated networks to improve security and prevent broadcast traffic congestion.

### A. Subnet Mask & Network vs. Host Bits

An IP address has two parts:
1. **Network Part**: Identifies the network.
2. **Host Part**: Identifies the specific device/server on that network.

The **Subnet Mask** uses consecutive `1`s for Network bits and `0`s for Host bits.

#### Example: CINERA App Subnet `10.0.2.0/24`
* **CIDR `/24`** means **24 bits** are reserved for Network, and **8 bits** for Hosts ($32 - 24 = 8$).
* **Subnet Mask**: `255.255.255.0` (`11111111.11111111.11111111.00000000`).

### B. Usable Hosts Formula

$$\text{Total Hosts} = 2^{(\text{Host Bits})}$$
$$\text{Usable Hosts} = 2^{(\text{Host Bits})} - 2$$

*(Subtract 2 because the 1st address is Network ID and the last address is Broadcast ID).*

#### Calculation for CINERA `/24` Subnet:
* **Host bits** = $32 - 24 = 8$
* **Total IPs** = $2^8 = 256$
* **Usable IPs** = $256 - 2 = 254$ usable server IPs.
* **Network ID**: `10.0.2.0`
* **Broadcast ID**: `10.0.2.255`
* **Usable IP Range**: `10.0.2.1` to `10.0.2.254`

---

## 🔄 4. Network Address Translation (NAT)

How do CINERA private database servers (IP `10.0.3.45`) download software security updates without a public IP?

Through **NAT (Network Address Translation)**:
1. **SNAT (Source NAT)**: Replaces the private IP `10.0.3.45` with a NAT Gateway's public IP before sending outgoing requests to the internet.
2. **DNAT (Destination NAT) / Port Forwarding**: Translates external traffic targeting a public IP/port (e.g. `198.51.100.42:8080`) to an internal server IP (`10.0.1.15:80`).

---

## 🛠️ 5. Network Troubleshooting Commands (DevOps Toolkit)

When CINERA's Express backend cannot reach MongoDB or users experience video playback buffering, DevOps engineers use these key commands:

### A. Testing Connectivity & DNS

* **Ping (ICMP Reachability)**:
  ```bash
  ping -c 4 cinera.com
  ```
  * Checks if destination server is online and measures round-trip packet latency.

* **DNS Name Resolution (`nslookup` & `dig`)**:
  ```bash
  nslookup cinera.com
  dig cinera.com +short
  ```
  * Resolves domain names to IP addresses via DNS server.

---

### B. Inspecting Open Ports & Active Connections

* **`ss` (Socket Statistics - Modern replacement for `netstat`)**:
  ```bash
  ss -tulpn
  ```
  * `-t`: TCP ports
  * `-u`: UDP ports
  * `-l`: Listening sockets
  * `-p`: Show process PID/name
  * `-n`: Show numeric IP/ports instead of domain names

* **Check if CINERA Express server is listening on port 5000**:
  ```bash
  ss -tulpn | grep 5000
  ```

---

### C. Testing HTTP Services & Route Tracing

* **`curl` (Test HTTP Endpoints)**:
  ```bash
  curl -I http://10.0.2.15:5000/api/v1/health
  ```
  * `-I`: Fetch response headers only (HTTP status code `200 OK`).

* **`traceroute` / `tracepath` (Network Path & Hop Analysis)**:
  ```bash
  traceroute cinera.com
  ```
  * Shows every router/hop packets travel through to reach CINERA.

---

## 📋 Quick Cheat Sheet Summary

| Task | Command | Purpose |
| :--- | :--- | :--- |
| **Check Interface IP** | `ip addr show` / `ifconfig` | Displays network interfaces & local IPs |
| **Test Port Connectivity** | `nc -zv 10.0.2.15 5000` | Netcat test if port 5000 is open |
| **Check Active Ports** | `ss -tulpn` | Shows all listening services & PIDs |
| **Inspect Routing Table** | `ip route` | Displays kernel routing rules |
| **Capture Packets** | `tcpdump -i eth0 port 80` | Sniffs live network traffic on port 80 |
