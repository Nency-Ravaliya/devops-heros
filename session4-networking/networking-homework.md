# Assignment 3 - Networking Homework

## Name

Shivansh Singh

## Operating System

Windows

---

# Task 1 - Networking Commands

I practiced the basic networking commands from the DevOps networking resources. Since I am using Windows, I used Windows equivalents for some Linux commands.

---

## 1. ping

### Command

```powershell
ping google.com
```

### Output

```text
Pinging google.com [192.178.173.139] with 32 bytes of data:
Reply from 192.178.173.139: bytes=32 time=19ms TTL=116
Reply from 192.178.173.139: bytes=32 time=17ms TTL=116
Reply from 192.178.173.139: bytes=32 time=18ms TTL=116
Reply from 192.178.173.139: bytes=32 time=18ms TTL=116

Ping statistics for 192.178.173.139:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
    Minimum = 17ms, Maximum = 19ms, Average = 18ms
```

### What I understood

The `ping` command is used to check whether a device or server is reachable over a network. It also shows the response time. In my test, all 4 packets were received successfully with 0% packet loss.

---

## 2. tracert

### Command

```powershell
tracert google.com
```

### Output

```text
Tracing route to google.com [192.178.173.139]
over a maximum of 30 hops:

1     4 ms     5 ms     6 ms  wifi.height8tech.com [100.128.160.1]
2    20 ms    17 ms    20 ms  114.79.130.29.dvois.com [114.79.130.29]
3    19 ms    17 ms    17 ms  72.14.208.165
4    23 ms    19 ms    18 ms  192.178.110.123
5    19 ms    18 ms    18 ms  142.251.250.2
6     *        *        *     Request timed out.
```

### What I understood

`tracert` shows the path taken by network packets from my computer to the destination. Each hop represents a router or network device on the way. It can help find where a network connection is slowing down or failing.

---

## 3. netstat

### Command

```powershell
netstat -ano
```

### Output

```text
Active Connections

Proto  Local Address          Foreign Address        State           PID
TCP    0.0.0.0:135            0.0.0.0:0              LISTENING       1968
TCP    0.0.0.0:445            0.0.0.0:0              LISTENING       4
TCP    0.0.0.0:3306           0.0.0.0:0              LISTENING       8020
TCP    0.0.0.0:5432           0.0.0.0:0              LISTENING       8120
TCP    100.128.166.110:49216  48.218.104.163:443     ESTABLISHED     3172
TCP    100.128.166.110:49416  4.213.25.240:443       ESTABLISHED     6688
TCP    100.128.166.110:49676  35.208.249.213:443     ESTABLISHED     27680
```

### What I understood

`netstat` shows active network connections, listening ports, protocols and process IDs. The `-a` option shows active connections and listening ports, `-n` shows addresses numerically, and `-o` shows the process ID.

---

## 4. Test-NetConnection

### Command

```powershell
Test-NetConnection google.com -Port 80
```

### Output

```text
ComputerName     : google.com
RemoteAddress    : 192.178.173.138
RemotePort       : 80
InterfaceAlias   : Wi-Fi
SourceAddress    : 100.128.166.110
TcpTestSucceeded : True
```

### What I understood

`Test-NetConnection` is a Windows networking command used to test connectivity to another computer and a specific port. Here, port 80 was reachable and the TCP connection succeeded.

---

## 5. nslookup

### Command

```powershell
nslookup google.com
```

### Output

```text
Server:  wifi.height8tech.com
Address:  100.128.160.1

Non-authoritative answer:
Name:    google.com
Addresses:
2404:6800:4000:101d::65
2404:6800:4000:101d::71
2404:6800:4000:101d::8b
2404:6800:4000:101d::64
192.178.173.100
192.178.173.102
192.178.173.138
192.178.173.113
192.178.173.139
192.178.173.101
```

### What I understood

`nslookup` is used to check DNS information. DNS converts domain names such as `google.com` into IP addresses. The command showed both IPv4 and IPv6 addresses.

---

## 6. curl

### Command

```powershell
curl.exe -I https://www.google.com
```

### Output

```text
HTTP/1.1 200 OK
Content-Type: text/html; charset=ISO-8859-1
Server: gws
Cache-Control: private
```

### What I understood

`curl` is used to communicate with web servers and APIs. The `-I` option requests only the HTTP headers. The `200 OK` response means that the web server successfully responded to the request.

---

## 7. arp

### Command

```powershell
arp -a
```

### Output

```text
Interface: 100.128.166.110

Internet Address      Physical Address      Type
100.128.160.1         d0-ea-11-32-00-19     dynamic
100.128.160.16        9c-c7-d3-2d-61-14     dynamic
100.128.160.72        e0-e2-58-41-88-31     dynamic
100.128.160.89        78-af-08-6b-ce-1b     dynamic
100.128.161.61        c0-35-32-dd-a1-cf     dynamic
```

### What I understood

`arp` shows the ARP table of the computer. It maps IP addresses to MAC addresses for devices on the local network.

---

## 8. Network Services

### Command

```powershell
Get-Service | Where-Object {$_.Name -match "Network|DNS"}
```

### Output

```text
Status   Name               DisplayName
------   ----               -----------
Running  Dnscache           DNS Client
Running  HPNetworkCap       HP Network HSA Service
Stopped  WMPNetworkSvc      Windows Media Player Network Sharing...
```

### What I understood

This command shows Windows services related to networking and DNS. It also shows whether a service is currently running or stopped.

The Linux command `systemctl` is commonly used for managing services on Linux, so on Windows I used `Get-Service` instead.

---

# Task 2 - IP Addressing

I also studied the IP addressing and subnetting concepts provided in the networking session.

## IPv4

An IPv4 address is a 32-bit address used to identify a device on a network.

The IPv4 address range is:

```text
0.0.0.0 - 255.255.255.255
```

## IP Classes

```text
Class A: 1 - 127
Class B: 128 - 191
Class C: 192 - 223
Class D: 224 - 239
```

## Common Subnet Masks

```text
Class A: 255.0.0.0
Class B: 255.255.0.0
Class C: 255.255.255.0
```

## Private IP Address Range

One important private IP range is:

```text
10.0.0.0 - 10.255.255.255
```

## Example

For:

```text
120.27.1.0/8
```

The first 8 bits are network bits and the remaining 24 bits are host bits.

```text
Network bits = 8
Host bits    = 24
Total hosts  = 2^24
Usable hosts = 2^24 - 2
```

The subnet mask for `/8` is:

```text
255.0.0.0
```

---

# What I Learned

From this networking practice, I understood the basic purpose of different networking commands.

* `ping` checks network reachability.
* `tracert` shows the path taken by packets.
* `netstat` shows network connections and ports.
* `Test-NetConnection` tests connectivity to a specific port.
* `nslookup` checks DNS information.
* `curl` communicates with web servers.
* `arp` shows IP-to-MAC address mappings.
* `Get-Service` helps check Windows network-related services.
* IP addresses identify devices on a network.
* Subnet masks divide an IP address into network and host parts.

Since I am using Windows, I used Windows equivalents for commands that are normally used on Linux.
