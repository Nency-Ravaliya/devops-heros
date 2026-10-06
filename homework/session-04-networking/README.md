# Session 4 — Networking commands

Student: Viraj Bhanage, roll 24BCS10274

Practice repos from the session notes:

- https://github.com/Nency-Ravaliya/Network-Troubleshooting
- https://github.com/Nency-Ravaliya/OSI-Network-devices
- https://github.com/Nency-Ravaliya/Networking
- https://github.com/Nency-Ravaliya/Subnetting
- https://github.com/Nency-Ravaliya/IP-quest

Raw output from this machine: [command-output.txt](command-output.txt)

## What each command showed

**`hostname` / `whoami` / `uname -a`**  
This host is `Virajs-MacBook-Pro-3.local`, user `bhanageviraj`, Darwin arm64. These identify the machine before any network test.

**`ping -c 3 8.8.8.8`**  
Three ICMP echo requests to Google DNS all came back. Packet loss was 0%. Ping checks that an IP path exists. It does not prove that HTTP or DNS works.

**`nslookup github.com`**  
The DNS server was the LAN gateway `192.168.24.1`. It returned `20.205.243.166` for `github.com`. The answer is non-authoritative because the resolver is not the owner of the `github.com` zone. It asked other servers and cached the reply.

**`curl -sI https://example.com`**  
The server answered `HTTP/2 200` from Cloudflare. `-I` asks for headers only, so this checks the web path without downloading the page.

**`route get 1.1.1.1`**  
Traffic for that address uses the default route via `192.168.24.1` on `en0`. The default gateway is the next hop for anything that is not on the local subnet.

## IP notes from the session

An IPv4 address is 32 bits. The subnet mask splits the network bits from the host bits. Class A `255.0.0.0` leaves 24 host bits (`2^24 - 2` usable hosts). Private ranges used in labs are `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16`. This laptop is on `192.168.24.0/23`, which is inside the private Class C space.
