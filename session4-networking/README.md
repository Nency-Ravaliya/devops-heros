# Network Troubleshooting & Verification Commands

### 1. Host Identity and Local Network Interfaces

* `hostname`  
  * Displays the unique name assigned to your computer on the local network.

![Screenshot 1](Screenshot%202026-09-02%20141157.png)

* `ip a`  
  * Shows all network adapters, their assigned IPv4/IPv6 addresses, and interface states.

![Screenshot 2](Screenshot%202026-09-02%20141215.png)

* `ifconfig`  
  * An older tool that displays network card configurations, IP details, and data transfer stats.

  ![Screenshot 3](Screenshot%202026-09-02%20141244.png)

---

### 2. Local Socket Statistics and Active Ports

* `ss -tuln`  
  * Quick and modern tool that shows which local ports are open and listening for TCP/UDP connections.

  ![Screenshot 4](Screenshot%202026-09-02%20141437.png)


* `netstat -tuln`  
  * Classic networking tool that lists all active listening ports and their associated protocols.

![Screenshot 5](Screenshot%202026-09-02%20141443.png)

---

### 3. ARP Cache

* `arp -a`  
  * Lists the local mapping between IP addresses and the physical MAC addresses of nearby devices.

  ![Screenshot 6](Screenshot%202026-09-02%20141520.png)

---

### 4. Routing Tables

* `route -n`  
  * Shows the system's routing table using numbers to show how traffic finds the default gateway.

  ![Screenshot 7](Screenshot%202026-09-02%20141613.png)


* `ip route`  
  * Modern command that reveals the exact paths and gateway your system uses to direct network traffic.

  ![Screenshot 8](Screenshot%202026-09-02%20141626.png)

---

### 5. DNS Resolution

* `nslookup google.com`  
  * Queries a DNS server to quickly check if a website name successfully translates into an IP address.

  ![Screenshot 9](Screenshot%202026-09-02%20141713.png)


* `dig google.com`  
  * Performs an in-depth DNS lookup that outputs detailed technical query records and response times.

  ![Screenshot 10](Screenshot%202026-09-02%20141731.png)

---

### 6. ICMP Reachability and Path Tracing

* `ping -c 4 google.com`  
  * Sends 4 test signals to measure response time and check if the destination is reachable.

  ![Screenshot 11](Screenshot%202026-09-02%20141822.png)


* `traceroute google.com`  
  * Maps every intermediate router (hop) your traffic passes through on its way to the destination.

  ![Screenshot 12](Screenshot%202026-09-02%20141905.png)

---

### 7. Layer 4 TCP Port Connectivity

* `timeout 3 telnet google.com 80`  
  * Tests if a specific port (HTTP port 80) is reachable and stops automatically after 3 seconds.

  ![Screenshot 14](Screenshot%202026-09-02%20142216.png)

---

### 8. Layer 7 HTTP/HTTPS Verification

* `curl -I https://www.google.com`  
  * Fetches only the website header data over HTTPS to verify the web server is responding properly (like HTTP 200).

  ![Screenshot 13](Screenshot%202026-09-02%20142027.png)

---

### 9. Packet Inspection

* `sudo tcpdump -i any -n -c 5 host google.com`  
  * Captures 5 live network packets traveling between your machine and Google across all interfaces.

  ![Screenshot 15](Screenshot%202026-09-02%20142541.png)































