1 ip a: Displays network interfaces active IP addresses, and hardware MAC addresses.

2 ping -c 4 google.com : sends ICMP echo requests to test latency and connectivity to Google.

3 tracepath google.com: Maps out all router haps between your laptop and Google's server.

4 ss -tuln: Displays all active listening TCP/UDP ports on your machine.

5 ns lookup google.com dig google.com: Queries DNS servers to resolve domain names into IP addresses.

6 curl -I https://google.com: Fetches HTTP response headers and status codes from web severs.

Terminal outputs

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
4: br-78b6fc3b675c: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether b2:f1:22:f3:7c:7a brd ff:ff:ff:ff:ff:ff
    inet 172.19.0.1/16 brd 172.19.255.255 scope global br-78b6fc3b675c
       valid_lft forever preferred_lft forever
5: br-b1ce458180cb: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether ce:57:55:78:86:1b brd ff:ff:ff:ff:ff:ff
    inet 172.18.0.1/16 brd 172.18.255.255 scope global br-b1ce458180cb
       valid_lft forever preferred_lft forever
6: br-b21e205a5c17: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 6a:d6:0b:1e:8e:b1 brd ff:ff:ff:ff:ff:ff
    inet 172.20.0.1/16 brd 172.20.255.255 scope global br-b21e205a5c17
       valid_lft forever preferred_lft forever
    inet6 fe80::68d6:bff:fe1e:8eb1/64 scope link 
       valid_lft forever preferred_lft forever
7: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 12:bb:0e:d0:63:e3 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
8: veth5bbe204@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-b21e205a5c17 state UP group default 
    link/ether ba:c7:35:6c:2a:7e brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::b8c7:35ff:fe6c:2a7e/64 scope link 
       valid_lft forever preferred_lft forever
9: vethd227f99@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-b21e205a5c17 state UP group default 
    link/ether a6:75:52:92:94:21 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::a475:52ff:fe92:9421/64 scope link 
       valid_lft forever preferred_lft forever
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ ping -c 4 google.com
PING google.com (142.250.206.110) 56(84) bytes of data.
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=1 ttl=120 time=15.5 ms
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=2 ttl=120 time=14.4 ms
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=3 ttl=120 time=14.1 ms
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=4 ttl=120 time=15.7 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 14.111/14.918/15.693/0.669 ms
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ ping -c 10 google.com
PING google.com (142.250.206.110) 56(84) bytes of data.
64 bytes from del11s20-in-f14.1e100.net (142.250.206.110): icmp_seq=1 ttl=120 time=14.9 ms
64 bytes from del11s20-in-f14.1e100.net (142.250.206.110): icmp_seq=2 ttl=120 time=13.9 ms
64 bytes from del11s20-in-f14.1e100.net (142.250.206.110): icmp_seq=3 ttl=120 time=14.4 ms
64 bytes from del11s20-in-f14.1e100.net (142.250.206.110): icmp_seq=4 ttl=120 time=14.0 ms
64 bytes from del11s20-in-f14.1e100.net (142.250.206.110): icmp_seq=5 ttl=120 time=14.1 ms
64 bytes from del11s20-in-f14.1e100.net (142.250.206.110): icmp_seq=6 ttl=120 time=14.0 ms
64 bytes from del11s20-in-f14.1e100.net (142.250.206.110): icmp_seq=7 ttl=120 time=14.0 ms
64 bytes from del11s20-in-f14.1e100.net (142.250.206.110): icmp_seq=8 ttl=120 time=14.2 ms
64 bytes from del11s20-in-f14.1e100.net (142.250.206.110): icmp_seq=9 ttl=120 time=14.2 ms
64 bytes from del11s20-in-f14.1e100.net (142.250.206.110): icmp_seq=10 ttl=120 time=19.1 ms

--- google.com ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9010ms
rtt min/avg/max/mdev = 13.907/14.660/19.060/1.491 ms
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ tracpath google.com
Command 'tracpath' not found, did you mean:
  command 'tracepath' from deb iputils-tracepath (3:20240117-1ubuntu0.1)
Try: sudo apt install <deb name>
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ tracepath.google.com
tracepath.google.com: command not found
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ tracepath google.com
 1?: [LOCALHOST]                      pmtu 1500
 1:  wifi.height8tech.com                                  9.188ms 
 1:  wifi.height8tech.com                                  5.102ms 
 2:  114.79.130.29.dvois.com                              16.291ms 
 3:  72.14.208.165                                        21.397ms 
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
^C
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ ss -tuln
Netid          State           Recv-Q          Send-Q                    Local Address:Port                      Peer Address:Port          Process          
udp            UNCONN          0               0                           224.0.0.251:5353                           0.0.0.0:*                              
udp            UNCONN          0               0                           224.0.0.251:5353                           0.0.0.0:*                              
udp            UNCONN          0               0                           224.0.0.251:5353                           0.0.0.0:*                              
udp            UNCONN          0               0                           224.0.0.251:5353                           0.0.0.0:*                              
udp            UNCONN          0               0                           224.0.0.251:5353                           0.0.0.0:*                              
udp            UNCONN          0               0                           224.0.0.251:5353                           0.0.0.0:*                              
udp            UNCONN          0               0                           224.0.0.251:5353                           0.0.0.0:*                              
udp            UNCONN          0               0                           224.0.0.251:5353                           0.0.0.0:*                              
udp            UNCONN          0               0                               0.0.0.0:5353                           0.0.0.0:*                              
udp            UNCONN          0               0                               0.0.0.0:59395                          0.0.0.0:*                              
udp            UNCONN          0               0                                  [::]:5353                              [::]:*                              
udp            UNCONN          0               0                                  [::]:40553                             [::]:*                              
tcp            LISTEN          0               4096                          127.0.0.1:43023                          0.0.0.0:*                              
tcp            LISTEN          0               4096                          127.0.0.1:27017                          0.0.0.0:*                              
tcp            LISTEN          0               4096                            0.0.0.0:5000                           0.0.0.0:*                              
tcp            LISTEN          0               4096                          127.0.0.1:39387                          0.0.0.0:*                              
tcp            LISTEN          0               511                           127.0.0.1:40243                          0.0.0.0:*                              
tcp            LISTEN          0               4096                          127.0.0.1:631                            0.0.0.0:*                              
tcp            LISTEN          0               511                           127.0.0.1:37807                          0.0.0.0:*                              
tcp            LISTEN          0               4096                          127.0.0.1:41191                          0.0.0.0:*                              
tcp            LISTEN          0               4096                          127.0.0.1:34437                          0.0.0.0:*                              
tcp            LISTEN          0               511                           127.0.0.1:42031                          0.0.0.0:*                              
tcp            LISTEN          0               4096                            0.0.0.0:8080                           0.0.0.0:*                              
tcp            LISTEN          0               4096                          127.0.0.1:34243                          0.0.0.0:*                              
tcp            LISTEN          0               4096                              [::1]:631                               [::]:*                              
tcp            LISTEN          0               4096                               [::]:5000                              [::]:*                              
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ nslookup google.com
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   google.com
Address: 142.250.206.110
Name:   google.com
Address: 2404:6800:4009:81f::200e

durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ dig google.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 21041
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 4, ADDITIONAL: 4

;; QUESTION SECTION:
;google.com.                    IN      A

;; ANSWER SECTION:
google.com.             134     IN      A       142.250.206.110

;; AUTHORITY SECTION:
google.com.             151152  IN      NS      ns3.google.com.
google.com.             151152  IN      NS      ns1.google.com.
google.com.             151152  IN      NS      ns2.google.com.
google.com.             151152  IN      NS      ns4.google.com.

;; ADDITIONAL SECTION:
ns3.google.com.         166137  IN      A       216.239.36.10
ns1.google.com.         173424  IN      A       216.239.32.10
ns2.google.com.         163085  IN      A       216.239.34.10
ns4.google.com.         280807  IN      A       216.239.38.10

;; Query time: 12 msec
;; SERVER: 8.8.8.8#53(8.8.8.8) (UDP)
;; WHEN: Wed Sep 02 18:31:04 IST 2026
;; MSG SIZE  rcvd: 180

durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ curl -I https://google.com
HTTP/2 301 
location: https://www.google.com/
content-type: text/html; charset=UTF-8
content-security-policy-report-only: object-src 'none';base-uri 'self';script-src 'nonce-07dFR3BTOazssgJfdRrllQ' 'strict-dynamic' 'report-sample' 'unsafe-eval' 'unsafe-inline' https: http:;report-uri https://csp.withgoogle.com/csp/gws/other-hp
date: Wed, 02 Sep 2026 13:01:37 GMT
expires: Fri, 02 Oct 2026 13:01:37 GMT
cache-control: public, max-age=2592000
server: gws
content-length: 220
x-xss-protection: 0
x-frame-options: SAMEORIGIN
alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000

durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ nano networking_tasks.md
durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session4-networking$ 