# Networking Homework

Name: Durga Prasad
Enrollment: 10012

## Task 1

Practiced commands from the devops-hero github repo.

## Task 2

Ran networking commands and added the output below with a short explanation of what I understood.

---

### ip a

Shows all network interfaces, their IP addresses and MAC addresses.

```
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp2s0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN group default qlen 1000
    link/ether 14:16:9e:82:f0:7a brd ff:ff:ff:ff:ff:ff
3: wlp0s20f3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 80:38:fb:28:30:e8 brd ff:ff:ff:ff:ff:ff
    inet 100.128.164.219/20 brd 100.128.175.255 scope global dynamic noprefixroute wlp0s20f3
       valid_lft 84815sec preferred_lft 84815sec
    inet6 fe80::b1be:4a63:b29b:ddb7/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

---

### ping -c 4 google.com

Sends 4 packets to google.com to test if the network is working and to check the latency.

```
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ ping -c 4 google.com
PING google.com (142.250.206.110) 56(84) bytes of data.
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=1 ttl=120 time=15.5 ms
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=2 ttl=120 time=14.4 ms
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=3 ttl=120 time=14.1 ms
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=4 ttl=120 time=15.2 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 14.119/14.823/15.501/0.591 ms
```

---

### tracepath google.com

Shows all the hops (routers) between my machine and google.com.

```
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ tracepath google.com
 1?: [LOCALHOST]                      pmtu 1500
 1:  100.128.160.1                                         1.980ms
 2:  10.10.196.1                                           4.251ms
 3:  172.19.55.2                                           4.837ms
 4:  no reply
 5:  no reply
 6:  216.239.41.77                                        14.891ms
 7:  142.250.206.110                                      15.234ms
     Resume: pmtu 1500
```

---

### ss -tuln

Shows all open/listening ports on my machine. -t is for TCP, -u is for UDP, -l is for listening, -n means do not resolve hostnames.

```
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ ss -tuln
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:Port
tcp   LISTEN 0      4096       127.0.0.1:631        0.0.0.0:*
tcp   LISTEN 0      4096       127.0.0.1:45201      0.0.0.0:*
udp   UNCONN 0      0            0.0.0.0:5353       0.0.0.0:*
udp   UNCONN 0      0            0.0.0.0:34566      0.0.0.0:*
```

---

### nslookup google.com

Resolves the domain name google.com to an IP address using DNS.

```
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ nslookup google.com
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   google.com
Address: 142.250.206.110
Name:   google.com
Address: 2404:6800:4007:80d::200e
```

---

### dig google.com

More detailed DNS lookup. Shows the query time and TTL as well.

```
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ dig google.com

; <<>> DiG 9.18.12 <<>> google.com
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345

;; ANSWER SECTION:
google.com.             299     IN      A       142.250.206.110

;; Query time: 21 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
```

---

### curl -I https://google.com

Fetches only the HTTP headers from google.com without downloading the page body. Useful to check the response status code and server info.

```
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ curl -I https://google.com
HTTP/2 301
location: https://www.google.com/
content-type: text/html; charset=UTF-8
date: Wed, 07 Oct 2026 16:40:03 GMT
server: gws
```

301 means google.com redirects to www.google.com.

---

More detailed outputs are in networking_tasks.md
