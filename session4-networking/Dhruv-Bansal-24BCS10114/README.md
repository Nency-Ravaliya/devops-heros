# Session 4 - Networking

Dhruv Bansal - 24BCS10114

I used these commands to check the local network, DNS, routes, open ports, and HTTP connectivity.

## Commands practised

### `ip addr`

Shows interfaces, MAC addresses, and assigned IPv4/IPv6 addresses.

```bash
ip addr
```

### `ip route`

Shows the routing table, including the default gateway.

```bash
ip route
```

### `ping`

Tests whether a host responds to ICMP echo requests.

```bash
ping -c 4 example.com
```

### `traceroute`

Shows the hops between this machine and a destination.

```bash
traceroute example.com
```

### `ss`

Lists listening TCP sockets.

```bash
ss -lnt
```

### `curl`

Makes an HTTP request; `-I` requests headers only.

```bash
curl -I https://example.com
```

### `nslookup`

Queries DNS for a domain name.

```bash
nslookup example.com
```

### `wget`

Downloads a file or page from a URL.

```bash
wget https://example.com
```

### `hostname`

Prints the current machine name.

```bash
hostname
```

### `ifconfig`

Legacy interface inspection command; `ip addr` is preferred on modern Linux distributions.

```bash
ifconfig
```

## Basic troubleshooting order

When a website is not opening, I would check it in this order:

```bash
ip addr
ip route
ping -c 4 8.8.8.8
nslookup example.com
curl -I https://example.com
traceroute example.com
```

This helps separate a local interface problem, a missing route, a DNS problem, and an application-level HTTP problem.
