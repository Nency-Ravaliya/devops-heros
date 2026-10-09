# Session 4 - Networking Homework

## Task 1: Practice commands from shared networking repos

Reference repos:
- https://github.com/Nency-Ravaliya/Networking
- https://github.com/Nency-Ravaliya/Network-Troubleshooting
- https://github.com/Nency-Ravaliya/Subnetting

## Task 2: Networking command practice with understanding

> Run these commands and paste your real output/screenshots below each section.

### 1) `ip a`
- **Purpose**: shows interfaces and IP addresses.
- **What I understood**: helps identify active NICs and assigned IPv4/IPv6 addresses.

```bash
ip a
```

### 2) `ip route`
- **Purpose**: shows routing table and default gateway.
- **What I understood**: confirms where packets are sent outside local subnet.

```bash
ip route
```

### 3) `ping`
- **Purpose**: checks reachability and latency.
- **What I understood**: if ping fails, there may be DNS/routing/firewall issues.

```bash
ping -c 4 8.8.8.8
ping -c 4 google.com
```

### 4) `nslookup`
- **Purpose**: resolves domain name to IP.
- **What I understood**: verifies DNS resolution separately from raw connectivity.

```bash
nslookup github.com
```

### 5) `traceroute`
- **Purpose**: shows hop-by-hop network path.
- **What I understood**: useful to locate where packets are delayed or dropped.

```bash
traceroute github.com
```

### 6) `netstat` / `ss`
- **Purpose**: lists listening ports and socket status.
- **What I understood**: identifies which process is serving on which port.

```bash
ss -tulnp
```

### 7) `curl`
- **Purpose**: tests HTTP/HTTPS endpoint response.
- **What I understood**: quickly verifies app/API health.

```bash
curl -I https://github.com
```
