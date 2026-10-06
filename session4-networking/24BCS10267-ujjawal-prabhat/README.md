# Session 04 — Networking

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 04 — Networking |

## Task checklist

- [x] Run the networking commands from the course material (the `ip` cheat sheet, net-tools vs iproute2, the subnetting notes in `ip.md`)
- [x] `ip addr`, `ip link`, `ip route`, `ip neigh`, `ip maddr` (query **and** modify on a dummy interface)
- [x] `ifconfig`, `route`, `arp`, `netstat` (old net-tools) compared with iproute2
- [x] `ping`, `traceroute`, `mtr`
- [x] `dig`, `nslookup`, `host`, `/etc/resolv.conf`, `/etc/hosts`
- [x] `curl -I`, `ss`, `netstat`, `nc`, `arping`, `ethtool`, `whois`
- [x] Subnetting checks with `ipcalc` (class A/C, CIDR, usable hosts)
- [x] A short "what I understood" for every command

## Deliverable

**[NETWORKING.md](./NETWORKING.md)** has every command with its real output and my explanation.

## Environment

- Ubuntu 24.04 container (`ujj-net`) on Docker Desktop with `NET_ADMIN`/`NET_RAW` capabilities, so interface, route and ARP changes were allowed. The changes were made on a temporary `dummy0` interface, which was deleted at the end.
- macOS host for traceroute and the default route, since the container's view of the path is hidden by Docker's NAT.

## What I couldn't do

- **`dig NS` / `dig TXT`**: these queries timed out on my network (a mobile hotspot), both from the container and from the macOS host, even when sent straight to 8.8.8.8 or over TCP. `A`, `MX` and `PTR` lookups worked. The failed attempts are recorded in NETWORKING.md, and there is no NS-record output.
- **Hop-by-hop traceroute from the container**: Docker Desktop NATs container traffic, so UDP traceroute shows `* * *` after the Docker gateway. I added a TCP traceroute and an `mtr`, plus a traceroute from the Mac host.
- **`ethtool` link speed / `-g` ring buffer**: the container's NIC is a virtual `veth`, so there is no physical link info. Only `ethtool -i` and `-S` give meaningful output.
