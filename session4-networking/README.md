# Network Troubleshooting & Verification Commands

### 1. Host Information and Network Interfaces

* `hostname`

  * Displays the name assigned to the system, which identifies the computer on the network.

![Screenshot 1](./Screenshot%202026-09-04%20at%2011.21.05 PM.png)

* `ifconfig`

  * A traditional networking command used to view network interface configuration, IP addresses, and transmission statistics.

![Screenshot 2](./Screenshot%202026-09-04%20at%2011.22.07 PM.png)

---

### 2. Socket and Port Information


* `netstat -tuln`

  * A commonly used legacy command for viewing listening TCP/UDP ports and their associated network information.

![Screenshot 5](./Screenshot%202026-09-04%20at%2011.27.56 PM.png)

---

### 3. ARP Cache

* `arp -a`

  * Shows the ARP table, which contains mappings between local IP addresses and the corresponding MAC addresses of devices on the network.

![Screenshot 6](./Screenshot%202026-09-04%20at%2011.28.49 PM.png)


### 4. DNS Resolution

* `nslookup google.com`

  * Sends a DNS query to find the IP address associated with `google.com`, helping verify that DNS resolution is working correctly.

![Screenshot 9](./Screenshot%202026-09-04%20at%2011.32.43 PM.png)

* `dig google.com`

  * Provides detailed DNS query and response information, making it useful for deeper DNS troubleshooting and analysis.

![Screenshot 10](./Screenshot%202026-09-04%20at%2011.33.07 PM.png)

---

### 5. Connectivity and Network Path Testing

* `ping -c 4 google.com`

  * Sends four ICMP packets to Google to check whether the destination is reachable and measure the response time.

![Screenshot 11](./Screenshot%202026-09-04%20at%2011.33.46 PM.png)

* `traceroute google.com`

  * Displays the sequence of network hops between the local system and Google, helping identify where delays or connectivity problems may occur.

![Screenshot 12](./Screenshot%202026-09-04%20at%2011.34.03 PM.png)

---

### 6. TCP Port Connectivity

* `timeout 3 telnet google.com 80`

  * Attempts to establish a connection to Google's HTTP port (80) and automatically terminates the test after 3 seconds.

![Screenshot 14](./Screenshot%202026-09-04%20at%2011.38.13 PM.png)

---

### 7. HTTP/HTTPS Connectivity Verification

* `curl -I https://www.google.com`

  * Retrieves only the HTTP response headers from Google over HTTPS, allowing you to verify whether the web server is responding successfully.

![Screenshot 13](./Screenshot%202026-09-04%20at%2011.38.36 PM.png)

---

### 9. Network Packet Capture

* `sudo tcpdump -i any -n -c 5 host google.com`

  * Captures five network packets related to communication with Google across all available network interfaces, providing a quick look at network traffic.

![Screenshot 15](./d3b5f5b1-8f86-4f61-b15a-0334a62c3607.png)

### 10. Routing Information

* `ip route`

  * A modern command for viewing the routing table and determining how the system forwards network traffic through gateways and interfaces.

![Screenshot 8](./Screenshot%202026-09-04%20at%2011.37.37 PM.png)

---
