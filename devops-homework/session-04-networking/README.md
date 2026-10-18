# Session 4: Networking

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

Commands practiced:

```bash
ip -brief address
ip route
ss -lnt
hostname
cat /etc/resolv.conf
getent hosts localhost
ping -c 2 127.0.0.1
curl -I --max-time 10 https://example.com
```

`evidence/network.txt` records output and failures from this environment. A blocked external request does not prove the remote server is down.

| Command | What I understood |
|---|---|
| ip -brief address | Shows interfaces and their assigned addresses |
| ip route | Shows route selection, including the default gateway |
| ss -lnt | Shows listening TCP sockets without resolving names |
| hostname | Shows the local machine name |
| cat /etc/resolv.conf | Shows resolver configuration |
| getent hosts localhost | Resolves through the system name-service configuration |
| ping -c 2 127.0.0.1 | Checks local IP loopback; does not test Internet connectivity |
| curl -I URL | Makes an HTTP HEAD request and displays response headers |
| dig example.com | Asks DNS for a name; needs dnsutils |
| traceroute example.com | Investigates hops; some routers do not reply |

TCP establishes a connection and provides an ordered byte stream. UDP sends datagrams
without those guarantees. DNS commonly uses UDP and also TCP on port 53; HTTP commonly
uses TCP 80 and HTTPS TCP 443 (HTTP/3 uses QUIC over UDP).

For `197.23.45.10/24`, the network is `197.23.45.0`, broadcast is `197.23.45.255`,
and there are 254 conventional usable host addresses. CIDR prefix length determines
the network boundary. Private IPv4 ranges are `10.0.0.0/8`, `172.16.0.0/12`, and
`192.168.0.0/16`. A subnet divides an address range; a gateway routes beyond it.

## Verification

Interface, route, socket, resolver and loopback commands ran.

External HTTP request timed out during DNS resolution.

Command output: [evidence/](evidence/).
