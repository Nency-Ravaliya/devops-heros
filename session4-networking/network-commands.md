# Session 4 — Networking Homework

## Task 1: devops-hero repo commands
Practiced the networking commands from the shared `devops-hero` GitHub repo and the resources listed in [`resources.md`](resources.md) (subnetting, DHCP, OSI devices, etc. — see linked repos there).

## Task 2: Networking commands — output + explanation

Full raw transcript: [`command-outputs.txt`](command-outputs.txt) (MAC addresses redacted before publishing, since this is a public repo — everything else is the real output from this machine).

| Command | What it does | What I observed |
|---|---|---|
| `ifconfig en0` | Shows the configuration of network interface `en0` (Wi-Fi) — IP address, netmask, MAC address, link status. | Interface is `UP` and `RUNNING`; it has an IPv4 address in the `100.64.0.0/10` range, which is a **CGNAT (Carrier-Grade NAT)** address, not a public IP — meaning the ISP is doing NAT before the traffic even reaches a "normal" router. |
| `ping -c 4 google.com` | Sends 4 ICMP echo requests to test reachability and measure round-trip latency. | All 4 packets got a reply (`0.0% packet loss`), average round-trip time ~18.7ms — confirms DNS resolution + basic connectivity are working. |
| `traceroute -m 10 google.com` | Shows every router (hop) the packet passes through on its way to the destination, up to 10 hops. | Traffic left through the local Wi-Fi gateway, then the ISP's network, then Google's network (`1e100.net`, Google's own domain for its infrastructure), reaching the destination in 6 hops. |
| `nslookup google.com` | Queries DNS to resolve a hostname to an IP address. | Resolved `google.com` to `142.250.207.174` using the local router (`100.128.160.1`) as the DNS server. |
| `netstat -rn` | Displays the OS's routing table — which gateway/interface is used for which destination network. | The `default` route (used for anything not matched more specifically) goes out via `en0` through the gateway `100.128.160.1`. Other rows are ARP-cache-style entries (`UHLWI` = host route learned via link-layer) for devices on the same local subnet. |
| `whois -h whois.iana.org google.com` | Looks up domain registration info from a WHOIS server — here, IANA, the top-level registry authority. | Confirms `.com` is delegated to VeriSign, the registry operator for the `.com` TLD (for the actual registrant of `google.com` specifically you'd query `whois.verisign-grs.com`, which the IANA response points to via `refer:`). |

**What I understood, in short:** DNS turns names into IPs (`nslookup`); `ping`/`traceroute` tell you whether a path exists and how it gets there hop by hop; `netstat -rn` and `ifconfig` show how *this* machine decides where to send traffic; `whois` tells you who owns/administers a domain at the registry level.
