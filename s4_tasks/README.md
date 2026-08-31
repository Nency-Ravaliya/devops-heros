### Session 4: Networking Tasks

## hostname and whoami

```
boot.dev/git-and-github on  main [!] on ☁️  (us-east-1)
󰂄 9% ❯ hostname
razor

[to get the ip of host ]
boot.dev/git-and-github on  main [!] on ☁️  (us-east-1)
󰂄 10% ❯ hostname -i
100.128.163.113

boot.dev/git-and-github on  main [!] on ☁️  (us-east-1)
󰂄 9% ❯ whoami
razor

```

## ip a

```
boot.dev/git-and-github on  main [!] on ☁️  (us-east-1)
❯ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: enp8s0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN group default qlen 1000
    link/ether 5c:b9:01:02:65:f8 brd ff:ff:ff:ff:ff:ff
    altname enx5cb9010265f8
3: wlo1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether ac:d1:b8:93:de:03 brd ff:ff:ff:ff:ff:ff
    altname wlp9s0
    altname wlxacd1b893de03
    inet 100.128.163.113/20 brd 100.128.175.255 scope global dynamic noprefixroute wlo1
       valid_lft 86137sec preferred_lft 86137sec
    inet6 fe80::3796:779f:9cda:6a3/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

Explanation:
```
Here lo -> loopback
     enp8s0 -> it the ethernet connection device
     wlo1 -> is the wifi chip
```


Q. If ip = 197.23.45.10
=> Class C
subnet mask = 255.255.255.0
broadcast address = 197.23.45.255
network bits = 24
host bits = 8
no of hosts = 2^8
no of usable hosts = 2^8 - 2

## Network Commands used in class:

## ip route

```
~ on ☁️  (us-east-1)
❯ ip route
default via 100.128.160.1 dev wlo1 proto dhcp src 100.128.163.113 metric 600
100.128.160.0/20 dev wlo1 proto kernel scope link src 100.128.163.113 metric 600
```
## nslookup google.com

```
~ on ☁️  (us-east-1)
❯ nslookup amazon.com
Server:		100.128.160.1
Address:	100.128.160.1#53

Non-authoritative answer:
Name:	amazon.com
Address: 98.87.170.74
Name:	amazon.com
Address: 98.82.161.185
Name:	amazon.com
Address: 98.87.170.71
```
## curl

```
~ on ☁️  (us-east-1)
❯ curl linux.org
<html>
<head><title>301 Moved Permanently</title></head>
<body>
<center><h1>301 Moved Permanently</h1></center>
<hr><center>cloudflare</center>
</body>
</html>

~ on ☁️  (us-east-1)
❯ curl -i linux.org
HTTP/1.1 301 Moved Permanently
Date: Mon, 24 Aug 2026 13:56:52 GMT
Content-Type: text/html; charset=UTF-8
Transfer-Encoding: chunked
Connection: keep-alive
Location: https://linux.org/
Speculation-Rules: "/cdn-cgi/speculation"
Report-To: {"group":"cf-nel","max_age":604800,"endpoints":[{"url":"https://a.nel.cloudflare.com/report/v4?s=8jUI6N7IZvRaWTW8x0%2Bxp85itx6BAVyldzrzhTRe3MRMuw2KrToQb7cOVMArsiPunfc7RBiBeliGWFsOryxyLxBzsXrWyh5l88oBKOOdqereUO7rj9YWB05raQ%3D%3D"}]}
Nel: {"report_to":"cf-nel","success_fraction":0.0,"max_age":604800}
Server: cloudflare
CF-RAY: a302dce5be1c85e8-BOM
alt-svc: h3=":443"; ma=86400

<html>
<head><title>301 Moved Permanently</title></head>
<body>
<center><h1>301 Moved Permanently</h1></center>
<hr><center>cloudflare</center>
</body>
</html>
```

## ss -tuln

```
~ on ☁️  (us-east-1)
❯ ss -tuln
Netid  State   Recv-Q   Send-Q            Local Address:Port      Peer Address:Port
udp    UNCONN  0        0          100.128.163.113%wlo1:29895          0.0.0.0:*
udp    UNCONN  0        0                   224.0.0.251:5353           0.0.0.0:*
udp    UNCONN  0        0          100.128.163.113%wlo1:54654          0.0.0.0:*
udp    UNCONN  0        0          100.128.163.113%wlo1:9993           0.0.0.0:*
tcp    LISTEN  0        5                       0.0.0.0:9993           0.0.0.0:*
tcp    LISTEN  0        5                             *:9993                 *:*
tcp    LISTEN  0        5                             *:6600                 *:*
```

## traceroute (used tracepath: same utility but required no superuser previliges)

```
~ on ☁️  (us-east-1)
❯ tracepath scaler.com
 1?: [LOCALHOST]                      pmtu 1500
 1:  _gateway                                             18.427ms
 1:  _gateway                                             33.893ms
 2:  114.79.130.29.dvois.com                              23.789ms
 3:  no reply
 4:  no reply
 5:  no reply
 6:  no reply
 7:  no reply
 8:  no reply
 9:  no reply
10:  no reply
11:  no reply
12:  no reply
13:  no reply
14:  no reply
15:  no reply
16:  no reply
17:  no reply
18:  no reply
19:  no reply
20:  no reply
21:  no reply
22:  no reply
23:  no reply
24:  no reply
25:  no reply
26:  no reply
27:  no reply
28:  no reply
29:  no reply
^C
```

## NAT(What, Why and How)

# How my laptop gets it ip address?
```
Initialy my laptop has no ip address. But it is connected to a router via wifi, so its know the router exists. Now my laptop will send a
DHCP request to check if there is any DHCP server(the router we are connected to) to give it an ip address. This communication happens as
DHCP Discover Offer Request and ACK requests. Then the router assigns me an ip address and also my laptop now know the
```

# NAT (Network Address Translation):
```
Basically our router acts a translator between my machine, the laptop and the internet. My internet sees the ip of the router not my own ip.
As the router ip is unique on the internet, not neccesarily my own ip.

Now every single packet going from my laptop ahs SOURCE and DESTINATION ip. Initialy when i search for google.com, the recursive recolver give me its
ip address, so i get SOURCE: <my laptop ip> DESTINATION: <googles ip> then this packets goes to NAT, now NAT updates the source to its own ip as
SOURCE: <nats ip>. Then the requests goes to the internet. Same protocol is followed when the request comes back.

Now i question arrises since NAT updated the SOURCE ip before sending the request, how would it know which device in its network to respond
back to, that is where NAT tables comes in, which stores this realtionship.
```




















