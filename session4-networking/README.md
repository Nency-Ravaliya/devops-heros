1. Ping Command
Command Executed:

ping -c 4 google.com
Output:

PING google.com (142.250.207.174) 56(84) bytes of data.
64 bytes from pnbomb-bl-in-f14.1e100.net (142.250.207.174): icmp_seq=1 ttl=116 time=122 ms
64 bytes from pnbomb-bl-in-f14.1e100.net (142.250.207.174): icmp_seq=2 ttl=116 time=24.6 ms
64 bytes from pnbomb-bl-in-f14.1e100.net (142.250.207.174): icmp_seq=3 ttl=116 time=38.4 ms
64 bytes from pnbomb-bl-in-f14.1e100.net (142.250.207.174): icmp_seq=4 ttl=116 time=27.8 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 24.600/53.241/122.116/40.093 ms

Explanation: The ping command is a fundamental diagnostic tool used to test the reachability of a host on an IP network. It works by sending ICMP (Internet Control Message Protocol) Echo Request packets to the target and waiting for an ICMP Echo Reply. The output shows whether the packets successfully reached the destination, if any packets were lost (packet loss), and how long it took for the round trip (latency/time).

2. Curl Command
Command Executed:

curl -I https://example.com
(Using -I fetches only the HTTP headers for a cleaner output)

Output:

HTTP/2 200
date: Thu, 03 Sep 2026 14:19:16 GMT
content-type: text/html
server: cloudflare
last-modified: Wed, 02 Sep 2026 22:14:26 GMT
allow: GET, HEAD
accept-ranges: bytes
age: 7088
cf-cache-status: HIT
cf-ray: a3556371cbcb914f-MAA

Explanation: curl (Client URL) is a command-line tool used for transferring data to or from a server using various protocols (HTTP, HTTPS, FTP, etc.). It is heavily used in DevOps to test REST APIs, download files, or check if a web server is responding correctly. In this output, we successfully received a 200 OK HTTP status code, confirming the web server is up and serving content.

3. Traceroute Command
Command Executed:

traceroute google.com
Output:

traceroute to google.com (142.250.207.174), 30 hops max, 60 byte packets
 1  LAPTOP-3KF17VR3.mshome.net (172.27.32.1)  0.242 ms  0.209 ms  0.254 ms
 2  wifi.height8tech.com (100.129.160.1)  87.878 ms  87.854 ms  87.849 ms
 3  202.131.133.5.convergentindia.com (202.131.133.5)  87.834 ms  87.812 ms  87.807 ms
 4  115.117.125.189.static-mumbai.vsnl.net.in (115.117.125.189)  84.457 ms  84.453 ms  84.449 ms
 5  * * *
 6  115.112.15.114.static-chennai.vsnl.net.in (115.112.15.114)  84.230 ms  81.958 ms  81.947 ms
 7  * * *
 8  216.239.56.62 (216.239.56.62)  18.709 ms 142.251.55.244 (142.251.55.244)  26.313 ms 142.251.55.216 (142.251.55.216)  28.172 ms
 9  172.253.71.2 (172.253.71.2)  20.466 ms 172.253.70.166 (172.253.70.166)  63.222 ms  63.208 ms
10  * * *
11  192.178.254.216 (192.178.254.216)  64.332 ms  64.302 ms 172.253.70.180 (172.253.70.180)  62.269 ms
12  172.253.177.31 (172.253.177.31)  62.264 ms  62.260 ms 172.253.177.91 (172.253.177.91)  104.458 ms
13  142.250.214.113 (142.250.214.113)  104.443 ms  104.439 ms 142.250.214.111 (142.250.214.111)  103.638 ms
14  pnbomb-bl-in-f14.1e100.net (142.250.207.174)  103.977 ms  102.855 ms  102.847 ms

Explanation: While ping tells you if a server is reachable, traceroute tells you how your traffic gets there. It maps the exact path (or routing hops) that a packet takes from your local machine to the destination server. It does this by gradually increasing the "Time to Live" (TTL) of packets. This is extremely useful for finding out exactly where a connection is failing or lagging across the internet.

4. Nslookup Command
Command Executed:

nslookup scaler.com
Output:

Server:         10.255.255.254
Address:        10.255.255.254#53

Non-authoritative answer:
Name:   scaler.com
Address: 18.172.78.107
Name:   scaler.com
Address: 18.172.78.47
Name:   scaler.com
Address: 18.172.78.67
Name:   scaler.com
Address: 18.172.78.88

Explanation: nslookup (Name Server Lookup) is a tool used to query the Domain Name System (DNS). It translates human-readable domain names into the IP addresses that computers use to communicate. The output shows the DNS server used to resolve the query and the resulting IP addresses for the requested domain.

5. Ifconfig Command
Command Executed:

ifconfig
Output:

eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.27.36.164  netmask 255.255.240.0  broadcast 172.27.47.255
        inet6 fe80::215:5dff:fe0a:b6be  prefixlen 64  scopeid 0x20<link>
        ether 00:15:5d:0a:b6:be  txqueuelen 1000  (Ethernet)
        RX packets 8378  bytes 36753416 (36.7 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 4116  bytes 384859 (384.8 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 180  bytes 24989 (24.9 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 180  bytes 24989 (24.9 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

Explanation: ifconfig (Interface Configuration) displays the current network configuration of your system's network interfaces (like Wi-Fi or Ethernet cards). It shows crucial details such as the assigned local IP address, subnet mask, MAC address (ether), and statistics on transmitted/received packets.

6. Netstat Command
Command Executed:

netstat -tuln
Output:

Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.54:53           0.0.0.0:*               LISTEN
tcp        0      0 10.255.255.254:53       0.0.0.0:*               LISTEN
udp        0      0 127.0.0.54:53           0.0.0.0:*
udp        0      0 127.0.0.53:53           0.0.0.0:*
udp        0      0 10.255.255.254:53       0.0.0.0:*
udp        0      0 127.0.0.1:323           0.0.0.0:*
udp        0      0 127.0.0.1:323           0.0.0.0:*
udp6       0      0 ::1:323                 :::*
udp6       0      0 ::1:323                 :::*

Explanation: netstat (Network Statistics) provides detailed information about active network connections, routing tables, and listening ports. The flags -tuln are commonly used to show only listening (l) TCP (t) and UDP (u) ports in numerical (n) form. This is highly useful for verifying if a service (like a web server on port 80 or SSH on port 22) is actively running and accepting connections.

7. Route Command
Command Executed:

route -n
Output:

Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.27.32.1     0.0.0.0         UG    0      0        0 eth0
172.27.32.0     0.0.0.0         255.255.240.0   U     0      0        0 eth0

Explanation: The route command allows you to view and manipulate the IP routing table of your operating system. The routing table determines where network traffic is directed based on its destination IP. In the output, the 0.0.0.0 destination represents the "default gateway" (192.168.1.1), which means any traffic not destined for the local network is sent to the router to be forwarded to the internet.

8. Hostname Command
Command Executed:

hostname
Output:

LAPTOP-3KF17VR3

Explanation: The hostname command simply displays (or sets) the network name of the current machine. This name is used to identify the device on a local network and is often utilized in logs, command prompts, and internal DNS resolution.

9. Dig Command
Command Executed:

dig scaler.com +short
Output:
18.172.78.88
18.172.78.107
18.172.78.67
18.172.78.47

Explanation: dig (Domain Information Groper) is a powerful, flexible command-line tool for interrogating DNS name servers. It performs DNS lookups and displays the answers returned from the queried name servers. While similar to nslookup, dig provides much more detailed output by default and is widely preferred by Linux system administrators for DNS troubleshooting. Using the +short flag strips the verbose metadata and returns only the resolved IP addresses.