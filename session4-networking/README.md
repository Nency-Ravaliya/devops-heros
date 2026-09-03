> **Submission for `session4-networking`** — Kartikey, Enrollment No. **10121** ([@Json604](https://github.com/Json604)).
>
> Every command shown was actually executed and the output is copied in verbatim.
> Full working code, scripts and raw transcripts: <https://github.com/Json604/devops-assignments/tree/main/assignment-03-networking>

# Assignment 3 — Networking

**Session:** `session4-networking` · **Author:** Kartikey (Json604) · **Enrollment No:** 10121

- **Task 1** — practice the commands and material from the `devops-heros` repo (`session4-networking/ip.md`,
  `session4-networking/resources.md`, and the `Linux Networking Cheat Sheet.pdf`).
- **Task 2** — a Markdown file containing the networking commands, their real output, and a short explanation
  of what I understood about each.

Every command below was executed on Ubuntu 24.04 (aarch64). Raw unedited transcript:
[`evidence/q3-networking-full.txt`](https://github.com/Json604/devops-assignments/blob/main/assignment-03-networking/evidence/q3-networking-full.txt).

**Host under test:** `172.17.0.2/16` on `eth0`, default gateway `172.17.0.1`, DNS `192.168.65.7`.

---

# Part 1 — IP addressing theory

Working through `session4-networking/ip.md`, checked against `ipcalc`.

## What an IP address is

A 32-bit number (IPv4) identifying a host **on a network**, written as four dotted decimal octets, so the
range is `0.0.0.0` – `255.255.255.255`. Every address splits into two parts: a **network part** and a
**host part**. The **subnet mask** is what decides where that split falls.

## Address classes

| Class | First octet | Default mask | Network / host bits | Usable hosts per network | Purpose |
|---|---|---|---|---|---|
| A | 1 – 126 | `255.0.0.0` (`/8`) | 8 / 24 | 2²⁴ − 2 = 16,777,214 | Very large networks |
| B | 128 – 191 | `255.255.0.0` (`/16`) | 16 / 16 | 2¹⁶ − 2 = 65,534 | Medium networks |
| C | 192 – 223 | `255.255.255.0` (`/24`) | 24 / 8 | 2⁸ − 2 = 254 | Small networks |
| D | 224 – 239 | — | — | — | **Multicast** |
| E | 240 – 255 | — | — | — | Experimental / reserved |

Two details worth being precise about, which the session notes gloss over:

- **`127.x.x.x` is not usable Class A** — the whole `127.0.0.0/8` block is reserved for **loopback**. That is
  why Class A is usable `1–126`, not `1–127`.
- **Why "− 2"?** Every network reserves two addresses: the all-zeros host part is the **network address**
  itself, and the all-ones host part is the **broadcast address**. Neither can be assigned to a machine.

## Private IP ranges (RFC 1918)

Not routable on the public internet — this is what NAT translates.

| Class | Range | CIDR |
|---|---|---|
| A | `10.0.0.0` – `10.255.255.255` | `10.0.0.0/8` |
| B | `172.16.0.0` – `172.31.255.255` | `172.16.0.0/12` |
| C | `192.168.0.0` – `192.168.255.255` | `192.168.0.0/16` |

This is directly visible in this exercise: the container's own address is **`172.17.0.2`**, inside Docker's
default `172.17.0.0/16` bridge — squarely in the private Class B range.

## Worked example — the one from `ip.md`

**`197.23.45.10` with mask `255.255.255.0`**

- First octet `197` → **Class C**, so 24 network bits and 8 host bits.
- Network address → `197.23.45.0`
- Broadcast address → `197.23.45.255`
- Usable host range → `197.23.45.1` – `197.23.45.254`
- Usable hosts → 2⁸ − 2 = **254**

**`120.27.1.0/8`**

- First octet `120` → **Class A**, 8 network bits, 24 host bits.
- Network → `120.0.0.0`, broadcast → `120.255.255.255`
- Usable hosts → 2²⁴ − 2 = **16,777,214**

> Note the `/8`: with only 8 network bits the `27.1` part is *host* bits, so `120.27.1.0/8` and `120.0.0.0/8`
> are the **same network**. `ipcalc` confirms this below — it reports the network as `120.0.0.0/8`.

### Verified with `ipcalc`

```console
$ ipcalc 197.23.45.10/24
Address:   197.23.45.10         11000101.00010111.00101101. 00001010
Netmask:   255.255.255.0 = 24   11111111.11111111.11111111. 00000000
Wildcard:  0.0.0.255            00000000.00000000.00000000. 11111111
=>
Network:   197.23.45.0/24       11000101.00010111.00101101. 00000000
HostMin:   197.23.45.1          11000101.00010111.00101101. 00000001
HostMax:   197.23.45.254        11000101.00010111.00101101. 11111110
Broadcast: 197.23.45.255        11000101.00010111.00101101. 11111111
Hosts/Net: 254                   Class C


$ ipcalc 120.27.1.0/8
Address:   120.27.1.0           01111000. 00011011.00000001.00000000
Netmask:   255.0.0.0 = 8        11111111. 00000000.00000000.00000000
Wildcard:  0.255.255.255        00000000. 11111111.11111111.11111111
=>
Network:   120.0.0.0/8          01111000. 00000000.00000000.00000000
HostMin:   120.0.0.1            01111000. 00000000.00000000.00000001
HostMax:   120.255.255.254      01111000. 11111111.11111111.11111110
Broadcast: 120.255.255.255      01111000. 11111111.11111111.11111111
Hosts/Net: 16777214              Class A


$ ipcalc 192.168.1.0/26
Address:   192.168.1.0          11000000.10101000.00000001.00 000000
Netmask:   255.255.255.192 = 26 11111111.11111111.11111111.11 000000
Wildcard:  0.0.0.63             00000000.00000000.00000000.00 111111
=>
Network:   192.168.1.0/26       11000000.10101000.00000001.00 000000
HostMin:   192.168.1.1          11000000.10101000.00000001.00 000001
HostMax:   192.168.1.62         11000000.10101000.00000001.00 111110
Broadcast: 192.168.1.63         11000000.10101000.00000001.00 111111
Hosts/Net: 62                    Class C, Private Internet


$ ipcalc 10.0.0.0/16
Address:   10.0.0.0             00001010.00000000. 00000000.00000000
Netmask:   255.255.0.0 = 16     11111111.11111111. 00000000.00000000
Wildcard:  0.0.255.255          00000000.00000000. 11111111.11111111
=>
Network:   10.0.0.0/16          00001010.00000000. 00000000.00000000
HostMin:   10.0.0.1             00001010.00000000. 00000000.00000001
HostMax:   10.0.255.254         00001010.00000000. 11111111.11111110
Broadcast: 10.0.255.255         00001010.00000000. 11111111.11111111
Hosts/Net: 65534                 Class A, Private Internet


```

Every hand calculation matches: `/24` → 254 hosts, `/8` → 16,777,214 hosts, and the `192.168.1.0/26` case shows
subnetting past the classful boundary — borrowing 2 host bits gives 4 subnets of **62** usable hosts each
(2⁶ − 2).

## Classful vs CIDR — the modern correction

Classes A/B/C are **historical**. Real networks use **CIDR** (Classless Inter-Domain Routing), where the prefix
length is explicit and can fall anywhere, not just on 8-bit boundaries. `192.168.1.0/26` above is not a "class"
at all. `ipcalc` still prints a class label because the first octet implies one, but the mask is what actually
governs routing. In practice you read `/26` and stop thinking about classes entirely.

**Quick mental math:** usable hosts = 2^(32 − prefix) − 2.
`/24`→254, `/25`→126, `/26`→62, `/27`→30, `/28`→14, `/29`→6, `/30`→2.

---

# Part 2 — Networking commands

## 1. Interface & IP configuration

| Command | What it does |
|---|---|
| `ip addr show` | Every interface with its IP addresses (the modern replacement for `ifconfig`) |
| `ip -brief addr` | The same, one tidy line per interface |
| `ip link show` | Layer-2 state only: MAC address, MTU, UP/DOWN |
| `ip -s link show eth0` | Adds RX/TX packet and **error/drop counters** |
| `ifconfig` | Legacy `net-tools` equivalent; often not installed by default any more |
| `hostname -I` | Just the IP addresses, ideal for scripts |
| `ethtool -i eth0` | Driver and NIC hardware details |

**What I understood:** `ip` comes from the `iproute2` package and has replaced the old `net-tools` commands
(`ifconfig`, `route`, `arp`, `netstat`). They still work if installed, but `ip` is the one that gets new
features. The output tells you three separate things: the **MAC address** (`link/ether`, layer 2), the
**IP address with its prefix** (`inet 172.17.0.2/16`, layer 3), and the **state flags** (`UP`, `LOWER_UP`).

`LOWER_UP` is the one people miss — `UP` means *the admin enabled the interface*, `LOWER_UP` means *the cable
is actually carrying a signal*. An interface that is `UP` but not `LOWER_UP` is an unplugged cable.

`ip -s link` is the first thing to check for a flaky connection: non-zero `errors` or `dropped` points at
hardware or MTU, not at your application.

```console
$ ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
3: gre0@NONE: <NOARP> mtu 1476 qdisc noop state DOWN group default qlen 1000
    link/gre 0.0.0.0 brd 0.0.0.0
4: gretap0@NONE: <BROADCAST,MULTICAST> mtu 1462 qdisc noop state DOWN group default qlen 1000
    link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
5: erspan0@NONE: <BROADCAST,MULTICAST> mtu 1450 qdisc noop state DOWN group default qlen 1000
    link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
6: ip_vti0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
7: ip6_vti0@NONE: <NOARP> mtu 1428 qdisc noop state DOWN group default qlen 1000
    link/tunnel6 :: brd :: permaddr 2a6c:8084:c02d::
8: sit0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/sit 0.0.0.0 brd 0.0.0.0
9: ip6tnl0@NONE: <NOARP> mtu 1452 qdisc noop state DOWN group default qlen 1000
    link/tunnel6 :: brd :: permaddr c209:efea:4891::
10: ip6gre0@NONE: <NOARP> mtu 1448 qdisc noop state DOWN group default qlen 1000
    link/gre6 :: brd :: permaddr 1ef1:e477:db66::
11: eth0@if2193: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc noqueue state UP group default 
    link/ether 02:e3:2a:30:fe:29 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever

$ ip -brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
tunl0@NONE       DOWN           
gre0@NONE        DOWN           
gretap0@NONE     DOWN           
erspan0@NONE     DOWN           
ip_vti0@NONE     DOWN           
ip6_vti0@NONE    DOWN           
sit0@NONE        DOWN           
ip6tnl0@NONE     DOWN           
ip6gre0@NONE     DOWN           
eth0@if2193      UP             172.17.0.2/16 

$ ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
3: gre0@NONE: <NOARP> mtu 1476 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/gre 0.0.0.0 brd 0.0.0.0
4: gretap0@NONE: <BROADCAST,MULTICAST> mtu 1462 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
5: erspan0@NONE: <BROADCAST,MULTICAST> mtu 1450 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
6: ip_vti0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
7: ip6_vti0@NONE: <NOARP> mtu 1428 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/tunnel6 :: brd :: permaddr 2a6c:8084:c02d::
8: sit0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/sit 0.0.0.0 brd 0.0.0.0
9: ip6tnl0@NONE: <NOARP> mtu 1452 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/tunnel6 :: brd :: permaddr c209:efea:4891::
10: ip6gre0@NONE: <NOARP> mtu 1448 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/gre6 :: brd :: permaddr 1ef1:e477:db66::
11: eth0@if2193: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc noqueue state UP mode DEFAULT group default 
    link/ether 02:e3:2a:30:fe:29 brd ff:ff:ff:ff:ff:ff link-netnsid 0

$ ip -s link show eth0
11: eth0@if2193: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc noqueue state UP mode DEFAULT group default 
    link/ether 02:e3:2a:30:fe:29 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    RX:  bytes packets errors dropped  missed   mcast           
      59340451    2925      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
        124030    1584      0       0       0       0 

$ ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 65535
        inet 172.17.0.2  netmask 255.255.0.0  broadcast 172.17.255.255
        ether 02:e3:2a:30:fe:29  txqueuelen 0  (Ethernet)
        RX packets 2925  bytes 59340451 (59.3 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1584  bytes 124030 (124.0 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 10  bytes 1670 (1.6 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 10  bytes 1670 (1.6 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0


$ hostname
9158f450b5b9

$ hostname -I
172.17.0.2 

$ ethtool -i eth0
driver: veth
version: 1.0
firmware-version: 
expansion-rom-version: 
bus-info: 
supports-statistics: yes
supports-test: no
supports-eeprom-access: no
supports-register-dump: no
supports-priv-flags: no

```

> The many `DOWN` interfaces (`tunl0`, `gre0`, `sit0`…) are kernel tunnel devices that exist by default and
> carry no traffic. The real interface here is **`eth0`** — `172.17.0.2/16`, MAC `02:e3:2a:30:fe:29`.
> `eth0@if2193` means it is one end of a **veth pair**, the virtual cable Docker uses to attach a container
> to the bridge; `if2193` is the peer's index on the host side.

## 2. Routing

| Command | What it does |
|---|---|
| `ip route show` | The kernel routing table |
| `ip route get <ip>` | **Which route would actually be used** for one destination |
| `route -n` / `netstat -rn` | Legacy views of the same table (`-n` = don't resolve names) |

**What I understood:** the routing table answers one question for every outgoing packet — *which interface,
and to which next hop?* The kernel picks the **most specific** matching prefix; `default` (`0.0.0.0/0`) is the
least specific, so it is the fallback when nothing else matches.

```console
$ ip route show
default via 172.17.0.1 dev eth0 
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2 

$ ip route get 8.8.8.8
8.8.8.8 via 172.17.0.1 dev eth0 src 172.17.0.2 uid 0 
    cache 

$ ip route get 172.17.0.5
172.17.0.5 dev eth0 src 172.17.0.2 uid 0 
    cache 

$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG    0      0        0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 eth0

$ netstat -rn
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG        0 0          0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 eth0

```

Reading the two rules here:

- `172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2` — a **directly connected** network. `scope
  link` means these hosts are reachable on the local segment with no router involved. The kernel added it
  automatically (`proto kernel`) when the address was configured.
- `default via 172.17.0.1 dev eth0` — everything else goes to the **gateway**.

`ip route get` is the command that settles arguments, because it asks the kernel to make the actual decision:

```
8.8.8.8   -> via 172.17.0.1 dev eth0 src 172.17.0.2    (external: goes via the gateway)
172.17.0.5 ->            dev eth0 src 172.17.0.2       (local: no "via", delivered directly)
```

The presence or absence of `via` is exactly the local-vs-remote distinction the subnet mask decides.

## 3. ARP / neighbour table (Layer 2)

| Command | What it does |
|---|---|
| `ip neigh show` | The ARP cache: IP → MAC mappings |
| `arp -n` | Legacy equivalent |
| `arping -I eth0 <ip>` | Send an ARP request directly, bypassing ICMP |

**What I understood:** IP addresses are layer 3, but actual delivery on an Ethernet segment happens by **MAC
address** at layer 2. ARP is the translation step: "who has 172.17.0.1? tell 172.17.0.2". The answer is cached
so it does not have to be asked per packet.

```console
$ ping -c 1 172.17.0.1 > /dev/null; ip neigh show
172.17.0.1 dev eth0 lladdr e6:db:4e:27:ea:d4 DELAY 

$ arp -n
Address                  HWtype  HWaddress           Flags Mask            Iface
172.17.0.1               ether   e6:db:4e:27:ea:d4   C                     eth0

$ arping -c 2 -I eth0 172.17.0.1
ARPING 172.17.0.1 from 172.17.0.2 eth0
Unicast reply from 172.17.0.1 [E6:DB:4E:27:EA:D4]  0.514ms
Unicast reply from 172.17.0.1 [E6:DB:4E:27:EA:D4]  0.607ms
Sent 2 probes (1 broadcast(s))
Received 2 response(s)

```

The ARP entry for the gateway `172.17.0.1 -> e6:db:4e:27:ea:d4` appeared **only after** pinging it — proof the
cache is populated on demand. `arping` is useful because it works at layer 2 even when ICMP is firewalled, and
`arping -D` detects duplicate IP addresses on a segment.

Entry states (`REACHABLE`, `STALE`, `DELAY`, `FAILED`) tell you how confident the kernel is; `FAILED` means
ARP got no answer, which is a layer-2 problem, not a routing one.

## 4. Connectivity testing — `ping`

| Flag | Meaning |
|---|---|
| `-c 4` | Stop after 4 packets (otherwise it runs forever) |
| `-W 2` | Wait at most 2 s for a reply |
| `-s 1000` | Payload size in bytes — for MTU testing |

**What I understood:** `ping` sends an ICMP echo request and times the reply. It proves **layer-3
reachability in both directions** — a reply means your packet arrived *and* the return path works.

```console
$ ping -c 4 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=63 time=204 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=63 time=38.5 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=63 time=44.7 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=63 time=42.4 ms

--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3019ms
rtt min/avg/max/mdev = 38.481/82.393/204.066/70.282 ms

$ ping -c 3 google.com
PING google.com (192.178.173.138) 56(84) bytes of data.
64 bytes from lcbome-in-f138.1e100.net (192.178.173.138): icmp_seq=1 ttl=63 time=30.4 ms
64 bytes from lcbome-in-f138.1e100.net (192.178.173.138): icmp_seq=2 ttl=63 time=48.6 ms
64 bytes from lcbome-in-f138.1e100.net (192.178.173.138): icmp_seq=3 ttl=63 time=27.7 ms

--- google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 4135ms
rtt min/avg/max/mdev = 27.667/35.564/48.636/9.309 ms

$ ping -c 2 -s 1000 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 1000(1028) bytes of data.
1008 bytes from 8.8.8.8: icmp_seq=1 ttl=63 time=29.5 ms
1008 bytes from 8.8.8.8: icmp_seq=2 ttl=63 time=98.1 ms

--- 8.8.8.8 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1008ms
rtt min/avg/max/mdev = 29.542/63.800/98.059/34.258 ms

--- unreachable host: note the 100% packet loss ---
$ ping -c 2 -W 2 10.255.255.1
PING 10.255.255.1 (10.255.255.1) 56(84) bytes of data.

--- 10.255.255.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1052ms


```

What the numbers mean:

- **`time=38.5 ms`** — round-trip time. Consistency matters more than the value; the `mdev` (mean deviation)
  of `70.282` here shows jitter, caused by the first packet paying for ARP/route setup.
- **`ttl=63`** — Time To Live, decremented by each router. Started at 64 and arrived as 63, so the packet
  crossed **one** router (the Docker gateway).
- **`0% packet loss`** — the headline number. Intermittent loss is worse than total loss, because it looks
  like random application slowness.
- **`ping google.com` resolved first** — it printed `PING google.com (192.178.173.138)`, so a successful ping
  by name proves DNS worked *and* the host is reachable. If ping by IP works but by name fails, the problem is
  DNS, not the network.
- **The unreachable case** (`10.255.255.1`) returned `100% packet loss` and no error — an unanswered ping is
  silence, which is why you must always pass `-c`/`-W` in scripts.

> A host that does not answer ping is not necessarily down: plenty of firewalls simply drop ICMP. That is why
> `nc -zv` (below) is the better reachability test for a specific service.

## 5. Path discovery — `traceroute` / `mtr`

**What I understood:** traceroute sends packets with **deliberately small TTLs** — TTL 1, then 2, then 3. Each
router that decrements a TTL to zero must return an ICMP "time exceeded" containing its own address, so the
path is revealed hop by hop.

```console
$ traceroute -m 12 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 12 hops max, 60 byte packets
 1  172.17.0.1 (172.17.0.1)  0.128 ms  0.008 ms  0.005 ms
 2  * * *
 3  * * *
 4  * * *
 5  * * *
 6  * * *
 7  * * *
 8  * * *
 9  * * *
10  * * *
11  * * *
12  * * *

$ traceroute -m 8 -T -p 443 github.com
traceroute to github.com (20.207.73.82), 8 hops max, 60 byte packets
 1  172.17.0.1 (172.17.0.1)  1.083 ms  5.803 ms  5.805 ms
 2  20.207.73.82 (20.207.73.82)  54.858 ms  54.684 ms *

$ mtr -r -c 3 8.8.8.8
Start: 2026-09-02T19:49:08+0000
HOST: 9158f450b5b9                Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 172.17.0.1                 0.0%     3    0.2   0.1   0.1   0.2   0.0
  2.|-- dns.google                 0.0%     3   33.3  43.4  13.5  83.6  36.1

```

This produced a genuinely instructive result:

- **`traceroute 8.8.8.8` shows hop 1 then `* * *` for the rest.** The `*` does **not** mean the host is
  unreachable — `ping 8.8.8.8` works fine, as shown above. It means intermediate routers are not returning
  ICMP time-exceeded messages. Here that is Docker Desktop's NAT layer on macOS, which does not forward them.
  Read `*` as "this hop declined to identify itself", never as "the path is broken".
- **`traceroute -T -p 443 github.com` worked**, because `-T` uses **TCP SYN to port 443** instead of UDP/ICMP.
  Firewalls that drop UDP and ICMP still have to allow TCP 443 for HTTPS to function. This is the practical
  lesson: when traceroute shows all stars, retry with `-T` against a port you know is open.
- **`mtr -r -c 3`** combines ping and traceroute — continuous sampling per hop, showing `Loss%` at each. It is
  the right tool for finding *which* hop is dropping packets, and it resolved `8.8.8.8` to `dns.google`.

## 6. DNS

| Command | What it does |
|---|---|
| `dig <name>` | Full DNS query with the complete response |
| `dig +short <name>` | Just the answer — for scripts |
| `dig MX/NS/AAAA <name>` | Query a specific record type |
| `dig -x <ip>` | **Reverse** lookup, IP → name |
| `dig @1.1.1.1 <name>` | Ask a **specific** resolver, bypassing `/etc/resolv.conf` |
| `nslookup` / `host` | Simpler, older front-ends |
| `/etc/resolv.conf` | Which resolver this machine uses |
| `/etc/hosts` | Static overrides, **checked before DNS** |

**What I understood:** DNS turns names into addresses, and it is the single most common cause of "the network
is broken". `dig` is the diagnostic tool because it shows the whole transaction, not just the result.

```console
$ cat /etc/resolv.conf
# Generated by Docker Engine.
# This file can be edited; Docker Engine will not make further changes once it
# has been modified.

nameserver 192.168.65.7

# Based on host file: '/etc/resolv.conf' (legacy)
# Overrides: []

$ cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::	ip6-localnet
ff00::	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.2	9158f450b5b9

$ dig github.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 42983
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;github.com.			IN	A

;; ANSWER SECTION:
github.com.		54	IN	A	20.207.73.82

;; Query time: 4 msec
;; SERVER: 192.168.65.7#53(192.168.65.7) (UDP)
;; WHEN: Wed Sep 02 19:49:16 UTC 2026
;; MSG SIZE  rcvd: 54


$ dig +short github.com
20.207.73.82

$ dig +short AAAA google.com

$ dig MX google.com +short
10 smtp.google.com.

$ dig NS github.com +short
ns-520.awsdns-01.net.
dns1.p08.nsone.net.
ns-1283.awsdns-32.org.
ns-1707.awsdns-21.co.uk.
ns-421.awsdns-52.com.
dns3.p08.nsone.net.
dns4.p08.nsone.net.
dns2.p08.nsone.net.

$ dig -x 8.8.8.8 +short
dns.google.

$ nslookup github.com
Server:		192.168.65.7
Address:	192.168.65.7#53

Non-authoritative answer:
Name:	github.com
Address: 20.207.73.82


$ host github.com
github.com has address 20.207.73.82
github.com mail is handled by 0 github-com.mail.protection.outlook.com.

--- query a specific DNS server directly (Cloudflare) ---
$ dig @1.1.1.1 +short example.com
;; communications error to 1.1.1.1#53: timed out
104.20.23.154
172.66.147.243

--- a name that does not exist: NXDOMAIN ---
$ dig +short this-name-does-not-exist-9z8x7.com; echo "status: $(dig this-name-does-not-exist-9z8x7.com | grep -o "status: [A-Z]*")"
status: status: NXDOMAIN

```

Reading the `dig github.com` response:

- **`status: NOERROR`** — the query succeeded. The other one you must recognise is **`NXDOMAIN`**, the name
  does not exist, which the deliberate bad-name query returned.
- **`ANSWER SECTION: github.com. 54 IN A 20.207.73.82`** — the `54` is the **TTL in seconds**: how long this
  answer may be cached. A low TTL is what makes a DNS-based failover switch quickly.
- **`flags: qr rd ra`** — `rd` = recursion desired, `ra` = recursion available. **`aa` is absent**, and
  `nslookup` spelled this out as *"Non-authoritative answer"* — the reply came from a cache, not from the
  domain's own nameservers.
- **`SERVER: 192.168.65.7#53`** — which resolver answered, matching `/etc/resolv.conf`. Port **53** is DNS.

Other results worth noting:

- **`dig +short AAAA google.com` returned nothing** — no IPv6 address was served to this host. An empty answer
  with `NOERROR` means "the name exists but has no record *of that type*", which is different from `NXDOMAIN`.
- **`dig -x 8.8.8.8` → `dns.google.`** — reverse DNS via the `in-addr.arpa` tree.
- **`dig @1.1.1.1 example.com` printed `communications error … timed out` and then still returned the
  answer.** Honest result: the first UDP packet to Cloudflare was lost, `dig` retried, and the retry
  succeeded. It is a good illustration that DNS over UDP is unreliable by design and clients must retry.
- **`/etc/hosts` is consulted before DNS** (per `/etc/nsswitch.conf`). It contains `172.17.0.2 9158f450b5b9`,
  which is how the container resolves its own hostname without any DNS server involved.

## 7. Ports, sockets & listening services

| Command | What it does |
|---|---|
| `ss -tulnp` | Listening sockets + owning process (**modern**) |
| `netstat -tulnp` | Same, legacy `net-tools` |
| `lsof -i :80` | Which process holds port 80 |
| `nc -zv host port` | Is a **remote** port open? |
| `nmap -sT -p 1-100 <host>` | Scan a range of ports |

`-tulnp` = **t**cp, **u**dp, **l**istening, **n**umeric, **p**rocess.

**What I understood:** an IP address gets you to the machine; the **port** gets you to the service. These
commands answer the two everyday questions — "what is listening on this box?" and "can I reach that service
from here?".

```console
$ ss -tulnp | cut -c1-95
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                         
tcp   LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=1000,fd=5),
tcp   LISTEN 0      511             [::]:80           [::]:*    users:(("nginx",pid=1000,fd=6),

$ netstat -tulnp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      990/nginx: master p 
tcp6       0      0 :::80                   :::*                    LISTEN      990/nginx: master p 

$ lsof -i :80 | head -6
COMMAND  PID     USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
nginx    990     root    5u  IPv4 1911768      0t0  TCP *:http (LISTEN)
nginx    990     root    6u  IPv6 1911769      0t0  TCP *:http (LISTEN)
nginx    991 www-data    5u  IPv4 1911768      0t0  TCP *:http (LISTEN)
nginx    991 www-data    6u  IPv6 1911769      0t0  TCP *:http (LISTEN)
nginx    992 www-data    5u  IPv4 1911768      0t0  TCP *:http (LISTEN)

--- is a remote port open? nc -zv = zero-IO scan, verbose ---
$ nc -zv github.com 443
Connection to github.com (20.207.73.82) 443 port [tcp/https] succeeded!

$ nc -zv github.com 22
Connection to github.com (20.207.73.82) 22 port [tcp/ssh] succeeded!

$ nc -zv -w 3 8.8.8.8 81
nc: connect to 8.8.8.8 port 81 (tcp) timed out: Operation now in progress

--- scan our own container (authorised: it is this machine) ---
$ nmap -sT -p 1-100 127.0.0.1
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-09-02 19:49 UTC
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000056s latency).
Not shown: 99 closed tcp ports (conn-refused)
PORT   STATE SERVICE
80/tcp open  http

Nmap done: 1 IP address (1 host up) scanned in 0.03 seconds

```

- **All three local tools agree**: nginx (master PID 990) is listening on port 80, on both `0.0.0.0` (all IPv4
  interfaces) and `[::]` (all IPv6). `0.0.0.0` matters — a service bound to `127.0.0.1` is reachable only from
  the machine itself, and that single detail is the cause of a large share of "why can't I connect" problems.
- **`nc -zv github.com 443` → `succeeded!`** — `-z` means "just check, send no data", `-v` prints the result.
  This is the correct reachability test for a service, because it completes a real **TCP handshake** rather
  than relying on ICMP.
- **`nc -zv 8.8.8.8 81` → `timed out`.** The distinction is worth learning: a **timeout** usually means a
  firewall silently dropped the packet, whereas **"connection refused"** means the host answered but nothing
  is listening on that port. Refused is a healthy host with no service; timeout is a wall.
- **`nmap -sT -p 1-100 127.0.0.1`** found `80/tcp open http` with the other 99 ports `closed (conn-refused)`.
  Only this machine was scanned — port-scanning hosts you do not own is not acceptable.

## 8. HTTP clients

| Command | What it does |
|---|---|
| `curl -I <url>` | Fetch **headers only** (HEAD request) |
| `curl -s -o /dev/null -w '...'` | Discard the body, print timing/status metrics |
| `wget -S -O /dev/null <url>` | Download, show server headers |

```console
$ curl -s -I https://github.com | head -14
HTTP/2 200 
date: Wed, 02 Sep 2026 19:50:00 GMT
content-type: text/html; charset=utf-8
content-language: en-US
vary: X-PJAX, X-PJAX-Container, Turbo-Visit, Turbo-Frame, X-Requested-With, X-GitHub-Client-Version, Accept-Language, Se
etag: W/"21350a3fb9f7e222c357b8202d88e506"
cache-control: max-age=0, private, must-revalidate
strict-transport-security: max-age=31536000; includeSubdomains; preload
x-frame-options: deny
x-content-type-options: nosniff
x-xss-protection: 0
referrer-policy: origin-when-cross-origin, strict-origin-when-cross-origin
content-security-policy: default-src 'none'; base-uri 'self'; child-src github.githubassets.com github.com/assets-cdn/wo

$ curl -s -o /dev/null -w "http_code=%{http_code} dns=%{time_namelookup}s connect=%{time_connect}s tls=%{time_appconnect}s total=%{time_total}s\n" https://github.com
http_code=200 dns=0.003805s connect=0.035625s tls=0.067971s total=0.418949s

$ curl -s http://localhost | head -8
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }

$ wget -S -q -O /dev/null https://example.com
  HTTP/1.1 200 OK
  Date: Wed, 02 Sep 2026 19:49:30 GMT
  Content-Type: text/html
  Transfer-Encoding: chunked
  Connection: keep-alive
  Server: cloudflare
  last-modified: Tue, 01 Sep 2026 23:48:12 GMT
  allow: GET, HEAD
  Accept-Ranges: bytes
  Age: 12506
  cf-cache-status: HIT
  CF-RAY: a34f09d06eb37eb6-MAA

```

**What I understood:** `curl -I` is the fastest way to check a web service is alive, because it asks for
headers only and skips the body entirely. `HTTP/2 200` confirms the protocol version *and* the status code in
one line.

The `-w` timing breakdown is the genuinely useful trick for diagnosing slowness — it splits one request into
its phases:

```
http_code=200  dns=0.003805s  connect=0.035625s  tls=0.067971s  total=0.418949s
```

DNS took 3.8 ms, the TCP handshake completed at 35 ms, TLS finished at 68 ms, and the whole request took
419 ms. Since each figure is cumulative, the server spent roughly **350 ms** generating the response — so this
is application latency, not a network problem. That is how you tell the two apart without guessing.

## 9. Packet capture — `tcpdump`

**What I understood:** every command above tells you the *result*; `tcpdump` shows the **actual packets**. It
is the final authority when tools disagree — if a packet is not in the capture, it was never sent.

```console
$ tcpdump -i eth0 -n icmp -c 4     # (ping running concurrently in another shell)
19:49:31.261851 IP 172.17.0.2 > 8.8.8.8: ICMP echo request, id 7, seq 1, length 64
19:49:31.275154 IP 8.8.8.8 > 172.17.0.2: ICMP echo reply, id 7, seq 1, length 64
19:49:32.268937 IP 172.17.0.2 > 8.8.8.8: ICMP echo request, id 7, seq 2, length 64
19:49:32.285575 IP 8.8.8.8 > 172.17.0.2: ICMP echo reply, id 7, seq 2, length 64

$ tcpdump -i eth0 -n -c 5 port 53   # DNS queries
19:49:35.380268 IP 172.17.0.2.53262 > 192.168.65.7.53: 49271+ [1au] A? github.com. (51)
19:49:35.384488 IP 192.168.65.7.53 > 172.17.0.2.53262: 49271 1/0/0 A 20.207.73.82 (54)
19:49:35.406013 IP 172.17.0.2.54900 > 192.168.65.7.53: 15315+ [1au] A? google.com. (51)
19:49:35.408757 IP 192.168.65.7.53 > 172.17.0.2.54900: 15315 6/0/0 A 192.178.173.138, A 192.178.173.101, A 192.178.173.113, A 192.178.173.100, A 192.178.173.139, A 192.178.173.102 (184)
19:49:35.429634 IP 172.17.0.2.36024 > 192.168.65.7.53: 41519+ [1au] A? example.com. (52)

```

- **The ICMP capture** shows the request/reply pairs of a concurrent `ping`, matched by `id 7, seq 1/2` —
  literally the packets `ping` reported.
- **The DNS capture** is the more instructive one. `A? github.com.` is the query and
  `1/0/0 A 20.207.73.82` is the response — 1 answer, 0 authority, 0 additional records. The `google.com`
  query came back `6/0/0` with six A records, which is DNS round-robin load balancing visible on the wire.
  The source ports (`53262`, `54900`, `36024`) are random per query — that randomisation is a security
  measure against cache-poisoning.

Useful filters: `tcpdump -i eth0 port 80`, `host 8.8.8.8`, `tcp and port 443`, `-n` (no name resolution),
`-c N` (stop after N packets), `-w file.pcap` (save for Wireshark).

## 10. `whois`

```console
$ whois 8.8.8.8 | head -14

#
# ARIN WHOIS data and services are subject to the Terms of Use
# available at: https://www.arin.net/resources/registry/whois/tou/
#
# If you see inaccuracies in the results, please report at
# https://www.arin.net/resources/registry/whois/inaccuracy_reporting/
#
# Copyright 1997-2026, American Registry for Internet Numbers, Ltd.
#


NetRange:       8.8.8.0 - 8.8.8.255
CIDR:           8.8.8.0/24

```

**What I understood:** `whois` queries the registry for ownership of an IP block or domain — `8.8.8.8` belongs
to `8.8.8.0/24`, registered with ARIN. Useful for identifying where unexpected traffic originates.

---

# Command summary

| Layer | Question | Command |
|---|---|---|
| L2 | What is my MAC / is the link up? | `ip link`, `ip -s link` |
| L2 | Which MAC owns this IP? | `ip neigh`, `arp -n`, `arping` |
| L3 | What is my IP? | `ip addr`, `hostname -I` |
| L3 | Where would this packet go? | `ip route`, `ip route get <ip>` |
| L3 | Can I reach that host? | `ping -c 4 <host>` |
| L3 | What is the path there? | `traceroute`, `traceroute -T -p 443`, `mtr` |
| App | Does the name resolve? | `dig`, `dig +short`, `nslookup`, `host` |
| L4 | What is listening here? | `ss -tulnp`, `netstat -tulnp`, `lsof -i :80` |
| L4 | Is that remote port open? | `nc -zv host port`, `nmap` |
| App | Is the web service healthy? | `curl -I`, `curl -w` timings |
| All | What is *actually* on the wire? | `tcpdump -i eth0 -n` |

## A troubleshooting order that works

Work up the stack — each step assumes the one before it passed:

1. `ip addr` — do I have an IP at all?
2. `ip route` — is there a default gateway?
3. `ping <gateway>` — is the local segment working?
4. `ping 8.8.8.8` — does the internet answer by **IP**?
5. `dig google.com` — does **DNS** work? (if 4 passes and 5 fails, it is DNS)
6. `nc -zv host port` — is the **specific service** reachable?
7. `curl -I` — is the **application** answering correctly?
8. `tcpdump` — when the answers above contradict each other.

## What I understood overall

- **`iproute2` replaced `net-tools`.** `ip addr` / `ip route` / `ip neigh` / `ss` supersede
  `ifconfig` / `route` / `arp` / `netstat`. Both were run above and agree, but only `ip` and `ss` are
  guaranteed to be present on a modern minimal image.
- **Layers narrow the problem.** ARP failing is layer 2; no route is layer 3; a refused port is layer 4; a
  500 response is the application. Working bottom-up stops you from debugging the wrong layer.
- **Timeout ≠ refused.** Refused means something answered "no". Timeout means nothing answered — usually a
  firewall. They point at completely different fixes.
- **`*` in traceroute is not failure.** It means that hop did not send ICMP back. `ping` succeeding to the same
  destination proves the path is fine.
- **The subnet mask is the whole game.** It decides local-vs-remote delivery, which decides whether ARP or the
  gateway is used. `ip route get` shows the kernel's actual decision.
- **DNS deserves its own step.** Half of "the network is down" is really a resolver problem, and `ping` by IP
  vs by name separates the two in one command.
