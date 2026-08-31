# NAT — Network Address Translation

**Vedanshu Nishad** — 24BCS10285 — Batch B

## 1. What does NAT stand for?

**NAT = Network Address Translation.**

In one line: our router rewrites the "from" address on the traffic we send out,
so that all the devices in our home or office can share **one** public IP address.

The way I picture it: imagine an office with a single phone number. Fifty people
work there, but the outside world only ever sees that one number. The
receptionist keeps a note of who made which call, so when a reply comes back it
reaches the right desk. **Our router is that receptionist.**

## 2. Why do we need NAT?

Every device on the internet needs an IP address. The older addressing system
(IPv4) gives us about **4.3 billion** of them. That felt like plenty in the
1980s. Then we all got a phone, a laptop, a TV  — and we
ran out.

We solved it in two halves.

**Half one — private addresses.** Some ranges were set aside for us to use
freely inside our own networks. They are not allowed on the public internet, so
all of us can reuse the same ones without clashing:

| Range                             | Where We usually see it       |
| --------------------------------- | ----------------------------- |
| `10.0.0.0` – `10.255.255.255`     | large company networks, cloud |
| `172.16.0.0` – `172.31.255.255`   | Docker, mid-size networks     |
| `192.168.0.0` – `192.168.255.255` | home WiFi routers             |

My laptop's `192.168.1.5` exists in millions of other homes at the same moment.
That is fine, because it never leaves my house.

**Half two — NAT.** Since a private address cannot travel on the internet,
something has to swap it for a real public one on the way out, and swap it back
on the way in. That something is NAT.

## 3. Where do we use NAT?

| Where                          | What it is doing for us                                      |
| ------------------------------ | ------------------------------------------------------------ |
| **Home / college WiFi router** | My phone, laptop and TV all share the one public IP our ISP gave us. |
| **Mobile networks (4G/5G)**    | Carriers don't have enough IPs for every subscriber, so thousands of us share a pool. This is called **CGNAT** (Carrier-Grade NAT). |
| **Cloud (AWS / Azure / GCP)**  | Private servers with no public IP still need to download updates. A "NAT Gateway" lets them reach out without being reachable from outside. |
| **Docker containers**          | Each container gets a private IP on a virtual network, and Docker NATs their traffic out through the host. |
| **Company offices**            | Hundreds of employees working behind a handful of public IPs. |

2. Two reasons we rely on it everywhere:
   
   1. **It saves addresses** — hundreds of devices, one public IP.
   2. **It hides our internal network** — from outside, all anyone sees is the
      router. Nobody can reach my laptop directly. I'd call that a useful side
      effect rather than real security, but it does help.

## 4. How it actually works

Say my laptop `192.168.1.5` wants to load `example.com`.

1. My laptop builds a packet: **from** `192.168.1.5:51000` → **to** `93.184.216.34:443`.
2. The packet reaches our router. The router knows `192.168.1.5` cannot go out
   on the internet, so it **rewrites the "from" address** to its own public IP
   and picks a spare port: **from** `103.21.44.7:62001`.
3. Before sending it on, the router writes a line in its **NAT table** so it
   remembers who asked.
4. The website replies to `103.21.44.7:62001`. It has no idea my laptop exists.
5. The router looks up port `62001` in its table, sees the entry belongs to
   `192.168.1.5:51000`, rewrites the "to" address back, and hands me the reply.

That NAT table is the whole trick. It is just a lookup list:

| Inside (private)    | Outside (public)    | Destination         |
| ------------------- | ------------------- | ------------------- |
| `192.168.1.5:51000` | `103.21.44.7:62001` | `93.184.216.34:443` |
| `192.168.1.9:48122` | `103.21.44.7:62002` | `93.184.216.34:443` |

Look at rows 1 and 2: **two different devices talking to the same website**. The
private IPs differ and the public **ports** differ, so the router can always tell
the two replies apart.

## 5. The three names I come across

- **SNAT (Source NAT)** — changing the *sender's* address. This is the normal
  outgoing case I described above.
- **DNAT (Destination NAT)** — changing the *receiver's* address. We use it for
  **port forwarding**: "anything arriving at our public IP on port 25565, send it
  to the game server at `192.168.1.50`." This is how we let the outside world
  reach something inside our network.
- **PAT / NAPT (Port Address Translation)** — SNAT *plus* port rewriting, so many
  devices fit behind one IP. Technically this is what our home routers do, even
  though we all just say "NAT".
