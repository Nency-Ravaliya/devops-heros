
TASK I:
A link is a way to access a file through another filename.

| Feature                  | Soft Link (Symbolic) | Hard Link                  |
| ------------------------ | -------------------- | -------------------------- |
| Command                  | `ln -s`              | `ln`                       |
| Points to                | File path/name       | Same inode                 |
| Can link directories?    | Yes                  | Generally no               |
| Can cross filesystems?   | Yes                  | No                         |
| If original file deleted | Link breaks          | Data still accessible      |
| Inode                    | Different inode      | Same inode                 |
| Looks like               | Shortcut             | Another name for same file |

A soft link is a separate file containing a path to another file, while a hard link is another directory entry pointing to the same inode and therefore the same underlying data. Soft links can cross filesystems and can point to directories, while hard links generally cannot.

PRACTICE:
amitabh@LAPTOP-3KF17VR3:~$ mkdir ~/link-practice
cd ~/link-practice

echo "Hello Linux" > original.txt
amitabh@LAPTOP-3KF17VR3:~/link-practice$ ln -s original.txt softlink.txt
amitabh@LAPTOP-3KF17VR3:~/link-practice$ ls -l
total 4
-rw-r--r-- 1 amitabh amitabh 12 Sep  3 12:27 original.txt
lrwxrwxrwx 1 amitabh amitabh 12 Sep  3 12:27 softlink.txt -> original.txt
amitabh@LAPTOP-3KF17VR3:~/link-practice$ cat softlink.txt
Hello Linux
amitabh@LAPTOP-3KF17VR3:~/link-practice$ ln original.txt hardlink.txt
amitabh@LAPTOP-3KF17VR3:~/link-practice$ ls -li
total 8
42032 -rw-r--r-- 2 amitabh amitabh 12 Sep  3 12:27 hardlink.txt
42032 -rw-r--r-- 2 amitabh amitabh 12 Sep  3 12:27 original.txt
42040 lrwxrwxrwx 1 amitabh amitabh 12 Sep  3 12:27 softlink.txt -> original.txt

amitabh@LAPTOP-3KF17VR3:~/link-practice$ rm original.txt
amitabh@LAPTOP-3KF17VR3:~/link-practice$ cat hardlink.txt
Hello Linux
amitabh@LAPTOP-3KF17VR3:~/link-practice$ cat softlink.txt
cat: softlink.txt: No such file or directory

TASK II:
'useradd' is the lower-level Linux utility.Depending on options/configuration, you may need to explicitly create the home directory and set a shell.
On Ubuntu/Debian, adduser is a higher-level, friendlier Perl script that uses useradd underneath.It interactively asks for:

Password
Full name
Room number
Phone information
etc.

PRACTICE:
amitabh@LAPTOP-3KF17VR3:~/link-practice$ sudo useradd -m -s /bin/bash amitabh
[sudo: authenticate] Password:
useradd: user 'amitabh' already exists
amitabh@LAPTOP-3KF17VR3:~/link-practice$ sudo useradd -m -s /bin/bash testuser
amitabh@LAPTOP-3KF17VR3:~/link-practice$ sudo passwd testuser
New password:
Retype new password:
passwd: password updated successfully
amitabh@LAPTOP-3KF17VR3:~/link-practice$ sudo adduser testuser2
New password:
Retype new password:
passwd: password updated successfully
Changing the user information for testuser2
Enter the new value, or press ENTER for the default
        Full Name []: Amitabh_Panda
        Room Number []: 347
        Work Phone []: 6206808722
        Home Phone []: 7631122898
        Other []:
Is the information correct? [Y/n] Y

TASK III:
journalctl is used to view logs collected by systemd's journal.

PRACTICE:
amitabh@LAPTOP-3KF17VR3:~/link-practice$ journalctl -r
Sep 03 12:56:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:55:52 LAPTOP-3KF17VR3 systemd[853]: Failed to start ubuntu-insights-upload.service - "Upload collected and ma>
Sep 03 12:55:52 LAPTOP-3KF17VR3 systemd[853]: ubuntu-insights-upload.service: Failed with result 'exit-code'.
Sep 03 12:55:52 LAPTOP-3KF17VR3 systemd[853]: ubuntu-insights-upload.service: Main process exited, code=exited, status=>
Sep 03 12:55:52 LAPTOP-3KF17VR3 (ubuntu-insights)[1125]: ubuntu-insights-upload.service: Failed at step NAMESPACE spawn>
Sep 03 12:55:52 LAPTOP-3KF17VR3 (ubuntu-insights)[1125]: ubuntu-insights-upload.service: Failed to set up mount namespa>
Sep 03 12:55:52 LAPTOP-3KF17VR3 systemd[853]: Starting ubuntu-insights-upload.service - "Upload collected and matured p>
Sep 03 12:55:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:54:52 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:54:36 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:54:28 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:54:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:54:22 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:54:21 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:54:20 LAPTOP-3KF17VR3 systemd[1]: Started wsl-pro.service - Bridge to Ubuntu Pro agent on Windows.
Sep 03 12:54:20 LAPTOP-3KF17VR3 wsl-pro-service[1096]: INFO Starting WSL Pro Service version wsl-pro-service/0.1.19
Sep 03 12:54:20 LAPTOP-3KF17VR3 systemd[1]: Starting wsl-pro.service - Bridge to Ubuntu Pro agent on Windows...
Sep 03 12:54:20 LAPTOP-3KF17VR3 systemd[1]: wsl-pro.service: Scheduled restart job, restart counter is at 1.
Sep 03 12:52:52 LAPTOP-3KF17VR3 systemd[853]: Failed to start ubuntu-insights-collect.service - "Collect platform repor>
Sep 03 12:52:52 LAPTOP-3KF17VR3 systemd[853]: ubuntu-insights-collect.service: Failed with result 'exit-code'.
Sep 03 12:52:52 LAPTOP-3KF17VR3 systemd[853]: ubuntu-insights-collect.service: Main process exited, code=exited, status>
Sep 03 12:52:52 LAPTOP-3KF17VR3 (ubuntu-insights)[1091]: ubuntu-insights-collect.service: Failed at step NAMESPACE spaw>
Sep 03 12:52:52 LAPTOP-3KF17VR3 (ubuntu-insights)[1091]: ubuntu-insights-collect.service: Failed to set up mount namesp>
Sep 03 12:52:52 LAPTOP-3KF17VR3 systemd[853]: Starting ubuntu-insights-collect.service - "Collect platform report using>
Sep 03 12:52:52 LAPTOP-3KF17VR3 systemd[853]: ubuntu-insights-collect.service: restrict-interfaces: Couldn't find index>
Sep 03 12:52:52 LAPTOP-3KF17VR3 systemd[853]: launchpadlib-cache-clean.service - Clean up old files in the Launchpadlib>
Sep 03 12:51:06 LAPTOP-3KF17VR3 sudo[1049]: pam_unix(sudo:session): session closed for user root
Sep 03 12:51:06 LAPTOP-3KF17VR3 gpasswd[1083]: members of group users set by root to amitabh,testuser2
Sep 03 12:51:06 LAPTOP-3KF17VR3 adduser[1052]: Adding user `testuser2' to group `users' ...

amitabh@LAPTOP-3KF17VR3:~/link-practice$ journalctl -n 20
Sep 03 12:54:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:54:28 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:54:36 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:54:52 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:55:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:55:52 LAPTOP-3KF17VR3 systemd[853]: Starting ubuntu-insights-upload.service - "Upload collected and matured p>
Sep 03 12:55:52 LAPTOP-3KF17VR3 (ubuntu-insights)[1125]: ubuntu-insights-upload.service: Failed to set up mount namespa>
Sep 03 12:55:52 LAPTOP-3KF17VR3 (ubuntu-insights)[1125]: ubuntu-insights-upload.service: Failed at step NAMESPACE spawn>
Sep 03 12:55:52 LAPTOP-3KF17VR3 systemd[853]: ubuntu-insights-upload.service: Main process exited, code=exited, status=>
Sep 03 12:55:52 LAPTOP-3KF17VR3 systemd[853]: ubuntu-insights-upload.service: Failed with result 'exit-code'.
Sep 03 12:55:52 LAPTOP-3KF17VR3 systemd[853]: Failed to start ubuntu-insights-upload.service - "Upload collected and ma>
Sep 03 12:56:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:57:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:58:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 12:59:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 13:00:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 13:01:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 13:02:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 13:03:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>
Sep 03 13:04:25 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not ge>

amitabh@LAPTOP-3KF17VR3:~/link-practice$ journalctl -f
Sep 03 12:55:52 LAPTOP-3KF17VR3 systemd[853]: Failed to start ubuntu-insights-upload.service - "Upload collected and matured platform reports using Ubuntu Insights while respecting consent".
Sep 03 12:56:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/USER/.ubuntupro/.address": open /mnt/c/Users/USER/.ubuntupro/.address: no such file or directory
Sep 03 12:57:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/USER/.ubuntupro/.address": open /mnt/c/Users/USER/.ubuntupro/.address: no such file or directory
Sep 03 12:58:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/USER/.ubuntupro/.address": open /mnt/c/Users/USER/.ubuntupro/.address: no such file or directory
Sep 03 12:59:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/USER/.ubuntupro/.address": open /mnt/c/Users/USER/.ubuntupro/.address: no such file or directory
Sep 03 13:00:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/USER/.ubuntupro/.address": open /mnt/c/Users/USER/.ubuntupro/.address: no such file or directory
Sep 03 13:01:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/USER/.ubuntupro/.address": open /mnt/c/Users/USER/.ubuntupro/.address: no such file or directory
Sep 03 13:02:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/USER/.ubuntupro/.address": open /mnt/c/Users/USER/.ubuntupro/.address: no such file or directory
Sep 03 13:03:24 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/USER/.ubuntupro/.address": open /mnt/c/Users/USER/.ubuntupro/.address: no such file or directory
Sep 03 13:04:25 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/USER/.ubuntupro/.address": open /mnt/c/Users/USER/.ubuntupro/.address: no such file or directory
Sep 03 13:05:25 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/USER/.ubuntupro/.address": open /mnt/c/Users/USER/.ubuntupro/.address: no such file or directory
Sep 03 13:05:25 LAPTOP-3KF17VR3 wsl-pro-service[1096]: WARNING Exiting after <nil>: check if the Windows agent is installed and running.
Sep 03 13:05:25 LAPTOP-3KF17VR3 systemd[1]: wsl-pro.service: Deactivated successfully.
^Camitabh@LAPTOP-3KF17VR3:~/link-practice$ journalctl -u <service>
-bash: syntax error near unexpected token `newline'

TEST IV:
| Command                    | What to remember                                        |
| -------------------------- | ------------------------------------------------------- |
| `ip addr`                  | Show IP addresses                                       |
| `ip link`                  | Show network interfaces/status                          |
| `ip -s link`               | Show interface statistics                               |
| `ip route`                 | Show routing table                                      |
| `ip route get <IP>`        | See which route an IP will take                         |
| `ip neigh`                 | Show ARP/neighbour table                                |
| `ip link set <iface> up`   | Bring interface up                                      |
| `ip link set <iface> down` | Bring interface down                                    |
| `ss -a`                    | Show all sockets                                        |
| `ss -n`                    | Don't resolve names; show numeric addresses/ports       |
| `ss -p`                    | Show process using socket                               |
| `ss -tulpn`                | **Very important:** TCP/UDP listening ports + processes |
| `arping`                   | Send ARP request                                        |
| `ethtool`                  | Inspect/control network interface/driver                |

PRACTICE:
amitabh@LAPTOP-3KF17VR3:~$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet 10.255.255.254/32 brd 10.255.255.254 scope global lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host proto kernel_lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:51:3d:5c brd ff:ff:ff:ff:ff:ff
    altname enx00155d513d5c
    inet 172.27.36.164/20 brd 172.27.47.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::215:5dff:fe51:3d5c/64 scope link proto kernel_ll
       valid_lft forever preferred_lft forever
amitabh@LAPTOP-3KF17VR3:~$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether 00:15:5d:51:3d:5c brd ff:ff:ff:ff:ff:ff
    altname enx00155d513d5c
amitabh@LAPTOP-3KF17VR3:~$ ip -s link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    RX:  bytes packets errors dropped  missed   mcast
          9510      68      0       0       0       0
    TX:  bytes packets errors dropped carrier collsns
          9510      68      0       0       0       0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether 00:15:5d:51:3d:5c brd ff:ff:ff:ff:ff:ff
    RX:  bytes packets errors dropped  missed   mcast
        111451     488      0       0       0     231
    TX:  bytes packets errors dropped carrier collsns
         63830     350      0       0       0       0
    altname enx00155d513d5c
amitabh@LAPTOP-3KF17VR3:~$ ip route
default via 172.27.32.1 dev eth0 proto kernel
172.27.32.0/20 dev eth0 proto kernel scope link src 172.27.36.164

amitabh@LAPTOP-3KF17VR3:~$ ip route get 8.8.8.8
8.8.8.8 via 172.27.32.1 dev eth0 src 172.27.36.164 uid 1000
    cache
amitabh@LAPTOP-3KF17VR3:~$ ip neigh
172.27.32.1 dev eth0 lladdr 00:15:5d:6c:9d:31 STALE
amitabh@LAPTOP-3KF17VR3:~$ ip link set eth0 down
RTNETLINK answers: Operation not permitted
amitabh@LAPTOP-3KF17VR3:~$ ip link set eth0 up
RTNETLINK answers: Operation not permitted
amitabh@LAPTOP-3KF17VR3:~$ ss -a
RTNETLINK answers: Invalid argument
Netid  State    Recv-Q  Send-Q                                          Local Address:Port                 Peer Address:Port
nl     UNCONN   0       0                                                        rtnl:165                              *
nl     UNCONN   0       0                                                        rtnl:kernel                           *
nl     UNCONN   0       0                                                        rtnl:-1089214714                      *
nl     UNCONN   0       0                                                        rtnl:systemd-resolve/86               *
nl     UNCONN   0       0                                                        rtnl:-1139325659                      *
nl     UNCONN   0       0                                                        rtnl:-62937089                        *
nl     UNCONN   0       0                                                        rtnl:-1958921668                      *
nl     UNCONN   0       0                                                        rtnl:systemd-resolve/86               *
nl     UNCONN   4352    0                                                     tcpdiag:ss/1272                          *
nl     UNCONN   960     0                                                     tcpdiag:kernel                           *
nl     UNCONN   0       0                                                     tcpdiag:169                              *
nl     UNCONN   0       0                                                     selinux:kernel                           *
nl     UNCONN   0       0                                                       iscsi:kernel                           *
nl     UNCONN   0       0                                                       audit:kernel                           *
nl     UNCONN   0       0                                                       audit:systemd/1                        *
nl     UNCONN   0       0                                                   fiblookup:kernel                           *
nl     UNCONN   0       0                                                   connector:kernel                           *
nl     UNCONN   0       0                                                   connector:171                              *
nl     UNCONN   0       0                                                   connector:171                              *
nl     UNCONN   0       0                                                         nft:systemd/1                        *
nl     UNCONN   0       0                                                         nft:kernel                           *
nl     UNCONN   0       0                                                      uevent:-1108407529                      *
nl     UNCONN   0       0                                                      uevent:systemd/853                      *
nl     UNCONN   0       0                                                      uevent:20                               *
nl     UNCONN   0       0                                                      uevent:systemd/1                        *
nl     UNCONN   0       0                                                      uevent:systemd-logind/174               *
nl     UNCONN   0       0                                                      uevent:systemd/405                      *
nl     UNCONN   0       0                                                      uevent:-1199368914                      *
nl     UNCONN   0       0                                                      uevent:-1327239749                      *
nl     UNCONN   0       0                                                      uevent:kernel                           *
nl     UNCONN   0       0                                                      uevent:-1851801749                      *
nl     UNCONN   0       0                                                      uevent:-885179200                       *
nl     UNCONN   0       0                                                      uevent:systemd/853                      *
nl     UNCONN   0       0                                                      uevent:systemd/405                      *
nl     UNCONN   0       0                                                      uevent:-1199368914                      *
nl     UNCONN   0       0                                                      uevent:-1327239749                      *
nl     UNCONN   0       0                                                      uevent:-885179200                       *
nl     UNCONN   0       0                                                      uevent:-1108407529                      *
nl     UNCONN   0       0                                                      uevent:systemd-logind/174               *
nl     UNCONN   0       0                                                      uevent:-1851801749                      *
nl     UNCONN   0       0                                                      uevent:systemd/1                        *
nl     UNCONN   0       0                                                      uevent:20                               *
nl     UNCONN   0       0                                                        genl:kernel                           *
nl     UNCONN   0       0                                                  scsi-trans:kernel                           *
u_str  ESTAB    0       0                                                           * 12390                           * 12391
u_str  ESTAB    0       0                                 /run/dbus/system_bus_socket 5751                            * 5750
u_str  ESTAB    0       0                                                           * 9236                            * 9235
u_str  LISTEN   0       4096                                       /run/WSL/2_interop 7190                            * 0
u_str  LISTEN   0       4096                                       /run/WSL/1_interop 8230                            * 0
u_dgr  ESTAB    0       0                                                           * 8260                            * 8261
u_seq  LISTEN   0       1                                /mnt/wslg/weston-notify.sock 10256                           * 0
u_str  LISTEN   0       4096                              /run/dbus/system_bus_socket 3897                            * 0
u_str  ESTAB    0       0                                                           * 7183                            * 7184
u_dgr  ESTAB    0       0                                                           * 7605                            * 7604
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 8520                            * 2495
u_str  LISTEN   0       128                           /mnt/wslg/runtime-dir/wayland-0 9230                            * 0
u_str  LISTEN   0       1                                           /tmp/.X11-unix/X0 9233                            * 0
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 9367                            * 8501
u_str  LISTEN   0       5                          /mnt/wslg/runtime-dir/pulse/native 2262                            * 0
u_str  LISTEN   0       100                             /mnt/wslg/PulseAudioRDPSource 9252                            * 0
u_str  LISTEN   0       100                               /mnt/wslg/PulseAudioRDPSink 1171                            * 0
u_dgr  UNCONN   0       0                               /run/user/1000/systemd/notify 1509                            * 0
u_dgr  UNCONN   0       0                                  /run/user/0/systemd/notify 7601                            * 0
u_dgr  ESTAB    0       0                                                           * 7590                            * 8277
u_str  LISTEN   0       4096                           /run/user/1000/systemd/private 1516                            * 0
u_dgr  UNCONN   0       0                                /var/run/chrony/chronyd.sock 63                              * 0
u_str  LISTEN   0       4096                              /run/user/0/systemd/private 7608                            * 0
u_str  LISTEN   0       4096                /run/user/1000/systemd/io.systemd.Manager 1518                            * 0
u_str  LISTEN   0       5                                       /mnt/wslg/PulseServer 2717                            * 0
u_str  LISTEN   0       4096                   /run/user/0/systemd/io.systemd.Manager 7610                            * 0
u_str  LISTEN   0       4096                                       /run/user/1000/bus 1527                            * 0
u_str  ESTAB    0       0                                                           * 6171                            * 0
u_str  LISTEN   0       4096                                          /run/user/0/bus 7619                            * 0
u_str  ESTAB    0       0                                 /run/dbus/system_bus_socket 254                             * 1408
u_str  LISTEN   0       4096                           /run/user/1000/gnupg/S.dirmngr 1528                            * 0
u_str  LISTEN   0       4096                              /run/user/0/gnupg/S.dirmngr 7620                            * 0
u_str  LISTEN   0       4096                 /run/user/1000/gnupg/S.gpg-agent.browser 1529                            * 0
u_str  LISTEN   0       4096                    /run/user/0/gnupg/S.gpg-agent.browser 7621                            * 0
u_dgr  ESTAB    0       0                                                           * 7584                            * 8276
u_str  LISTEN   0       4096                   /run/user/1000/gnupg/S.gpg-agent.extra 1530                            * 0
u_str  LISTEN   0       4096                      /run/user/0/gnupg/S.gpg-agent.extra 7622                            * 0
u_str  LISTEN   0       4096                     /run/user/1000/gnupg/S.gpg-agent.ssh 1531                            * 0
u_str  ESTAB    0       0                                                           * 2718                            * 12395
u_str  LISTEN   0       4096                        /run/user/0/gnupg/S.gpg-agent.ssh 7623                            * 0
u_str  LISTEN   0       4096                         /run/user/1000/gnupg/S.gpg-agent 1532                            * 0
u_str  LISTEN   0       4096                            /run/user/0/gnupg/S.gpg-agent 10792                           * 0
u_str  LISTEN   0       4096                           /run/user/1000/gnupg/S.keyboxd 1533                            * 0
u_str  LISTEN   0       4096                              /run/user/0/gnupg/S.keyboxd 10793                           * 0
u_str  LISTEN   0       4096                         /run/user/1000/pk-debconf-socket 1534                            * 0
u_str  LISTEN   0       4096                            /run/user/0/pk-debconf-socket 10794                           * 0
u_str  LISTEN   0       4096                /run/user/1000/snapd-session-agent.socket 1535                            * 0
u_str  LISTEN   0       4096                   /run/user/0/snapd-session-agent.socket 10795                           * 0
u_str  LISTEN   0       4096                             /run/user/1000/openssh_agent 1536                            * 0
u_str  LISTEN   0       4096                                /run/user/0/openssh_agent 10796                           * 0
u_str  LISTEN   0       4096            /run/user/1000/systemd/io.systemd.AskPassword 1537                            * 0
u_str  ESTAB    0       0                                 /run/dbus/system_bus_socket 4733                            * 237
u_str  LISTEN   0       4096               /run/user/0/systemd/io.systemd.AskPassword 10797                           * 0
u_dgr  UNCONN   0       0                                    /run/chrony/chronyd.sock 8603                            * 0
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 6627                            * 1489
u_dgr  ESTAB    0       0                                                           * 8259                            * 8258
u_dgr  ESTAB    0       0                                                           * 1510                            * 1511
u_str  LISTEN   0       4096                                     /tmp/dbus-5bQXsYvhmm 6165                            * 0
u_dgr  ESTAB    0       0                                                           * 6465                            * 8277
u_dgr  ESTAB    0       0                                                           * 1515                            * 1514
u_str  ESTAB    0       0                                                           * 6490                            * 8330
u_dgr  ESTAB    0       0                                                           * 8258                            * 8259
u_str  ESTAB    0       0                                                           * 3903                            * 3904
u_dgr  ESTAB    0       0                                         /run/systemd/notify 8255                            * 0
u_str  LISTEN   0       4096                                     /run/systemd/private 8262                            * 0
u_str  LISTEN   0       4096               /run/systemd/userdb/io.systemd.DynamicUser 8263                            * 0
u_str  LISTEN   0       4096                       /run/systemd/io.systemd.ManagedOOM 8264                            * 0
u_dgr  ESTAB    0       0                                                           * 8257                            * 8256
u_str  LISTEN   0       4096                          /run/systemd/io.systemd.Manager 8265                            * 0
u_str  ESTAB    0       0                                                           * 1354                            * 1355
u_dgr  ESTAB    0       0                                                           * 1514                            * 1515
u_str  ESTAB    0       0                                                           * 11344                           * 6270
u_dgr  ESTAB    0       0                                                           * 8261                            * 8260
u_dgr  UNCONN   0       0                                 /run/systemd/journal/syslog 8272                            * 0
u_str  LISTEN   0       4096                      /run/systemd/io.systemd.AskPassword 8273                            * 0
u_str  LISTEN   0       4096                      /run/systemd/io.systemd.Credentials 8274                            * 0
u_str  LISTEN   0       4096                     /run/systemd/io.systemd.FactoryReset 8275                            * 0
u_dgr  ESTAB    0       0                                /run/systemd/journal/dev-log 8276                            * 0
u_dgr  ESTAB    0       0                                 /run/systemd/journal/socket 8277                            * 0
u_str  LISTEN   0       4096                              /run/systemd/journal/stdout 8278                            * 0
u_dgr  ESTAB    0       0                                                           * 10547                           * 8276
u_str  LISTEN   0       4096                      /run/systemd/io.systemd.MuteConsole 8279                            * 0
u_str  LISTEN   0       4096          /run/systemd/resolve/io.systemd.Resolve.Monitor 8280                            * 0
u_str  LISTEN   0       4096                  /run/systemd/resolve/io.systemd.Resolve 8281                            * 0
u_str  ESTAB    0       0                                                           * 1489                            * 6627
u_dgr  ESTAB    0       0                                                           * 7602                            * 7603
u_seq  LISTEN   0       4096                                        /run/udev/control 8282                            * 0
u_str  LISTEN   0       4096                                /run/udev/io.systemd.Udev 8284                            * 0
u_str  ESTAB    0       0                                                           * 7573                            * 12731
u_seq  ESTAB    0       0                                                           * 8605                            * 8604
u_str  LISTEN   0       4096                                     /run/WSL/339_interop 4770                            * 0
u_str  LISTEN   0       4096                  /run/systemd/journal/io.systemd.journal 4607                            * 0
u_str  ESTAB    0       0                                           /tmp/.X11-unix/X0 10584                           * 2265
u_dgr  ESTAB    0       0                                                           * 7607                            * 7606
u_str  ESTAB    0       0                                                           * 3899                            * 3900
u_dgr  ESTAB    0       0                                                           * 7604                            * 7605
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 11500                           * 12379
u_str  ESTAB    0       0                                                           * 9237                            * 9238
u_str  ESTAB    0       0                                                           * 1408                            * 254
u_dgr  ESTAB    0       0                                                           * 7252                            * 8277
u_dgr  ESTAB    0       0                                                           * 8308                            * 8277
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 4639                            * 10336
u_str  LISTEN   0       4096                           /run/systemd/io.systemd.sysext 1166                            * 0
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 6270                            * 11344
u_str  ESTAB    0       0                                                           * 5660                            * 6348
u_str  ESTAB    0       0                                                           * 6235                            * 10314
u_dgr  ESTAB    0       0                                                           * 1498                            * 8277
u_dgr  ESTAB    0       0                                                           * 4612                            * 8255
u_str  ESTAB    0       0                                                           * 1355                            * 1354
u_str  ESTAB    0       0                                                           * 8569                            * 8570
u_str  ESTAB    0       0                                 /run/dbus/system_bus_socket 1357                            * 155
u_str  ESTAB    0       0                                                           * 12379                           * 11500
u_dgr  ESTAB    0       0                                                           * 4717                            * 8276
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 12731                           * 7573
u_dgr  ESTAB    0       0                                                           * 1513                            * 1512
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 10314                           * 6235
u_str  ESTAB    0       0                                                           * 9238                            * 9237
u_dgr  ESTAB    0       0                                                           * 8256                            * 8257
u_str  ESTAB    0       0                                                           * 3900                            * 3899
u_str  ESTAB    0       0                                                           * 2495                            * 8520
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 8570                            * 8569
u_str  LISTEN   0       5                                          /run/apport.socket 1198                            * 0
u_str  LISTEN   0       4096                              /run/dbus/system_bus_socket 1199                            * 0
u_str  LISTEN   0       4096                          /run/polkit/agent-helper.socket 1200                            * 0
u_str  LISTEN   0       4096                                        /run/snapd.socket 1201                            * 0
u_str  LISTEN   0       4096                                   /run/snapd-snap.socket 1202                            * 0
u_str  LISTEN   0       4096                         /run/systemd/io.systemd.Hostname 1203                            * 0
u_str  ESTAB    0       0                                                           * 240                             * 239
u_str  LISTEN   0       4096                            /run/systemd/io.systemd.Login 1204                            * 0
u_str  ESTAB    0       0                                                           * 12391                           * 12390
u_str  ESTAB    0       0                                                           * 8501                            * 9367
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 8521                            * 2500
u_dgr  ESTAB    0       0                                                           * 1512                            * 1513
u_str  ESTAB    0       0                                 /mnt/wslg/PulseAudioRDPSink 8330                            * 6490
u_str  ESTAB    0       0                                                           * 3904                            * 3903
u_str  ESTAB    0       0                                                           * 237                             * 4733
u_seq  ESTAB    0       0                                                           * 8604                            * 8605
u_dgr  ESTAB    0       0                                                           * 7603                            * 7602
u_str  ESTAB    0       0                                 /run/dbus/system_bus_socket 8618                            * 6478
u_dgr  ESTAB    0       0                                                           * 1511                            * 1510
u_str  ESTAB    0       0                                                           * 239                             * 240
u_str  ESTAB    0       0                                 /run/dbus/system_bus_socket 2741                            * 1517
u_dgr  ESTAB    0       0                                                           * 8596                            * 8276
u_dgr  ESTAB    0       0                                                           * 11346                           * 8276
u_str  ESTAB    0       0                                        /tmp/dbus-5bQXsYvhmm 12395                           * 2718
u_str  ESTAB    0       0                                                           * 9235                            * 9236
u_str  ESTAB    0       0                                                           * 2500                            * 8521
u_dgr  ESTAB    0       0                                                           * 299                             * 8276
u_str  ESTAB    0       0                                                           * 2265                            * 10584
u_str  ESTAB    0       0                                 /run/dbus/system_bus_socket 7040                            * 7609
u_dgr  ESTAB    0       0                                                           * 138                             * 8277
u_dgr  ESTAB    0       0                                                           * 7606                            * 7607
u_str  ESTAB    0       0                                 /run/systemd/journal/stdout 6348                            * 5660
u_str  ESTAB    0       0                                                           * 7184                            * 7183
u_str  ESTAB    0       0                                                           * 10336                           * 4639
u_str  ESTAB    0       0                    @d490366f2279b533/bus/systemd/bus-system 7609                            * 7040
u_str  ESTAB    0       0                 @3797ad06a751e816/bus/systemd-logind/system 6478                            * 8618
u_str  ESTAB    0       0                    @d1db3ee1a72526b4/bus/systemd/bus-system 1517                            * 2741
u_str  ESTAB    0       0        @c9c410374d1df70/bus/systemd-resolve/bus-api-resolve 155                             * 1357
u_str  ESTAB    0       0                @d743379147c23c0c/bus/systemd/bus-api-system 5750                            * 5751
u_dgr  UNCONN   0       0                                       @11079370719182248386 7257                            * 0
udp    UNCONN   0       0                                                   127.0.0.1:323                       0.0.0.0:*
udp    UNCONN   0       0                                                   127.0.0.1:323                       0.0.0.0:*
udp    UNCONN   0       0                                                  127.0.0.54:domain                    0.0.0.0:*
udp    UNCONN   0       0                                               127.0.0.53%lo:domain                    0.0.0.0:*
udp    UNCONN   0       0                                              10.255.255.254:domain                    0.0.0.0:*
udp    UNCONN   0       0                                                       [::1]:323                          [::]:*
udp    UNCONN   0       0                                                       [::1]:323                          [::]:*
tcp    LISTEN   0       4096                                            127.0.0.53%lo:domain                    0.0.0.0:*
tcp    LISTEN   0       1000                                           10.255.255.254:domain                    0.0.0.0:*
tcp    LISTEN   0       4096                                               127.0.0.54:domain                    0.0.0.0:*
v_str  LISTEN   0       0                                                           *:1                               *:*
v_str  ESTAB    0       0                                                           *:3639976910                      2:50000
v_str  ESTAB    0       0                                                           *:3639976911                      2:50000
v_str  ESTAB    0       0                                                           *:3639976912                      2:50000
v_str  ESTAB    0       0                                                           *:3639976913                      2:50000
v_str  ESTAB    0       0                                                           *:3639976914                      2:50000
v_str  LISTEN   0       0                                                           *:3639976915                      *:*
v_str  ESTAB    0       0                                                           *:3639976916                      2:50001
v_str  ESTAB    0       0                                                           *:3639976917                      2:50001
v_str  ESTAB    0       0                                                           *:3639976918                      2:50001
v_str  LISTEN   0       0                                                           *:3639976919                      *:*
v_str  ESTAB    0       0                                                           *:3639976920                      2:50000
v_str  ESTAB    0       0                                                           *:3639976921                      2:50000
v_str  ESTAB    0       0                                                           *:3639976922                      2:50002
v_str  ESTAB    0       0                                                           *:3639976923                      2:50002
v_str  ESTAB    0       0                                                           *:3639976926                      2:50002
v_str  ESTAB    0       0                                                           *:3639976927                      2:50002
v_str  LISTEN   0       0                                                           *:3639976928                      *:*
v_str  LISTEN   0       0                                                           *:3639976931                      *:*
v_str  ESTAB    0       0                                                           *:3639976933                      2:50003
v_str  ESTAB    0       0                                                           *:3639976934                      2:50003
v_str  ESTAB    0       0                                                           *:1                               2:1182111266
v_str  ESTAB    0       0                                                           *:3639976919                      2:1182111245
v_str  ESTAB    0       0                                                           *:3639976924                      2:1182111252
v_str  ESTAB    0       0                                                           *:3639976925                      2:1182111259
v_str  ESTAB    0       0                                                           *:3639976925                      2:1182111258
v_str  ESTAB    0       0                                                           *:3639976925                      2:1182111257
v_str  CLOSING  0       0                                                           *:3639976925                      2:1182111256
v_str  ESTAB    0       0                                                           *:3639976931                      2:1182111273
v_str  ESTAB    0       0                                                           *:3639976929                      2:1182111261
v_str  ESTAB    0       0                                                           *:3639976932                      2:1182111278
v_str  ESTAB    0       0                                                           *:3639976932                      2:1182111277
v_str  ESTAB    0       0                                                           *:3639976932                      2:1182111276
v_str  ESTAB    0       0                                                           *:3639976932                      2:1182111275
v_str  ESTAB    0       0                                                           *:3639976932                      2:1182111274
amitabh@LAPTOP-3KF17VR3:~$ ss -n
RTNETLINK answers: Invalid argument
Netid State   Recv-Q Send-Q                                          Local Address:Port         Peer Address:Port
u_str ESTAB   0      0                                                           * 12390                   * 12391
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 5751                    * 5750
u_str ESTAB   0      0                                                           * 9236                    * 9235
u_dgr ESTAB   0      0                                                           * 8260                    * 8261
u_str ESTAB   0      0                                                           * 7183                    * 7184
u_dgr ESTAB   0      0                                                           * 7605                    * 7604
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 8520                    * 2495
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 9367                    * 8501
u_dgr ESTAB   0      0                                                           * 7590                    * 8277
u_str ESTAB   0      0                                                           * 6171                    * 0
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 254                     * 1408
u_dgr ESTAB   0      0                                                           * 7584                    * 8276
u_str ESTAB   0      0                                                           * 2718                    * 12395
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 4733                    * 237
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 6627                    * 1489
u_dgr ESTAB   0      0                                                           * 8259                    * 8258
u_dgr ESTAB   0      0                                                           * 1510                    * 1511
u_dgr ESTAB   0      0                                                           * 6465                    * 8277
u_dgr ESTAB   0      0                                                           * 1515                    * 1514
u_str ESTAB   0      0                                                           * 6490                    * 8330
u_dgr ESTAB   0      0                                                           * 8258                    * 8259
u_str ESTAB   0      0                                                           * 3903                    * 3904
u_dgr ESTAB   0      0                                         /run/systemd/notify 8255                    * 0
u_dgr ESTAB   0      0                                                           * 8257                    * 8256
u_str ESTAB   0      0                                                           * 1354                    * 1355
u_dgr ESTAB   0      0                                                           * 1514                    * 1515
u_str ESTAB   0      0                                                           * 11344                   * 6270
u_dgr ESTAB   0      0                                                           * 8261                    * 8260
u_dgr ESTAB   0      0                                /run/systemd/journal/dev-log 8276                    * 0
u_dgr ESTAB   0      0                                 /run/systemd/journal/socket 8277                    * 0
u_dgr ESTAB   0      0                                                           * 10547                   * 8276
u_str ESTAB   0      0                                                           * 1489                    * 6627
u_dgr ESTAB   0      0                                                           * 7602                    * 7603
u_str ESTAB   0      0                                                           * 7573                    * 12731
u_seq ESTAB   0      0                                                           * 8605                    * 8604
u_str ESTAB   0      0                                           /tmp/.X11-unix/X0 10584                   * 2265
u_dgr ESTAB   0      0                                                           * 7607                    * 7606
u_str ESTAB   0      0                                                           * 3899                    * 3900
u_dgr ESTAB   0      0                                                           * 7604                    * 7605
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 11500                   * 12379
u_str ESTAB   0      0                                                           * 9237                    * 9238
u_str ESTAB   0      0                                                           * 1408                    * 254
u_dgr ESTAB   0      0                                                           * 7252                    * 8277
u_dgr ESTAB   0      0                                                           * 8308                    * 8277
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 4639                    * 10336
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 6270                    * 11344
u_str ESTAB   0      0                                                           * 5660                    * 6348
u_str ESTAB   0      0                                                           * 6235                    * 10314
u_dgr ESTAB   0      0                                                           * 1498                    * 8277
u_dgr ESTAB   0      0                                                           * 4612                    * 8255
u_str ESTAB   0      0                                                           * 1355                    * 1354
u_str ESTAB   0      0                                                           * 8569                    * 8570
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 1357                    * 155
u_str ESTAB   0      0                                                           * 12379                   * 11500
u_dgr ESTAB   0      0                                                           * 4717                    * 8276
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 12731                   * 7573
u_dgr ESTAB   0      0                                                           * 1513                    * 1512
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 10314                   * 6235
u_str ESTAB   0      0                                                           * 9238                    * 9237
u_dgr ESTAB   0      0                                                           * 8256                    * 8257
u_str ESTAB   0      0                                                           * 3900                    * 3899
u_str ESTAB   0      0                                                           * 2495                    * 8520
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 8570                    * 8569
u_str ESTAB   0      0                                                           * 240                     * 239
u_str ESTAB   0      0                                                           * 12391                   * 12390
u_str ESTAB   0      0                                                           * 8501                    * 9367
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 8521                    * 2500
u_dgr ESTAB   0      0                                                           * 1512                    * 1513
u_str ESTAB   0      0                                 /mnt/wslg/PulseAudioRDPSink 8330                    * 6490
u_str ESTAB   0      0                                                           * 3904                    * 3903
u_str ESTAB   0      0                                                           * 237                     * 4733
u_seq ESTAB   0      0                                                           * 8604                    * 8605
u_dgr ESTAB   0      0                                                           * 7603                    * 7602
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 8618                    * 6478
u_dgr ESTAB   0      0                                                           * 1511                    * 1510
u_str ESTAB   0      0                                                           * 239                     * 240
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 2741                    * 1517
u_dgr ESTAB   0      0                                                           * 8596                    * 8276
u_dgr ESTAB   0      0                                                           * 11346                   * 8276
u_str ESTAB   0      0                                        /tmp/dbus-5bQXsYvhmm 12395                   * 2718
u_str ESTAB   0      0                                                           * 9235                    * 9236
u_str ESTAB   0      0                                                           * 2500                    * 8521
u_dgr ESTAB   0      0                                                           * 299                     * 8276
u_str ESTAB   0      0                                                           * 2265                    * 10584
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 7040                    * 7609
u_dgr ESTAB   0      0                                                           * 138                     * 8277
u_dgr ESTAB   0      0                                                           * 7606                    * 7607
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 6348                    * 5660
u_str ESTAB   0      0                                                           * 7184                    * 7183
u_str ESTAB   0      0                                                           * 10336                   * 4639
u_str ESTAB   0      0                    @d490366f2279b533/bus/systemd/bus-system 7609                    * 7040
u_str ESTAB   0      0                 @3797ad06a751e816/bus/systemd-logind/system 6478                    * 8618
u_str ESTAB   0      0                    @d1db3ee1a72526b4/bus/systemd/bus-system 1517                    * 2741
u_str ESTAB   0      0        @c9c410374d1df70/bus/systemd-resolve/bus-api-resolve 155                     * 1357
u_str ESTAB   0      0                @d743379147c23c0c/bus/systemd/bus-api-system 5750                    * 5751
v_str ESTAB   0      0                                                           *:3639976910              2:50000
v_str ESTAB   0      0                                                           *:3639976911              2:50000
v_str ESTAB   0      0                                                           *:3639976912              2:50000
v_str ESTAB   0      0                                                           *:3639976913              2:50000
v_str ESTAB   0      0                                                           *:3639976914              2:50000
v_str ESTAB   0      0                                                           *:3639976916              2:50001
v_str ESTAB   0      0                                                           *:3639976917              2:50001
v_str ESTAB   0      0                                                           *:3639976918              2:50001
v_str ESTAB   0      0                                                           *:3639976920              2:50000
v_str ESTAB   0      0                                                           *:3639976921              2:50000
v_str ESTAB   0      0                                                           *:3639976922              2:50002
v_str ESTAB   0      0                                                           *:3639976923              2:50002
v_str ESTAB   0      0                                                           *:3639976926              2:50002
v_str ESTAB   0      0                                                           *:3639976927              2:50002
v_str ESTAB   0      0                                                           *:3639976933              2:50003
v_str ESTAB   0      0                                                           *:3639976934              2:50003
v_str ESTAB   0      0                                                           *:1                       2:1182111266
v_str ESTAB   0      0                                                           *:3639976919              2:1182111245
v_str ESTAB   0      0                                                           *:3639976924              2:1182111252
v_str ESTAB   0      0                                                           *:3639976925              2:1182111259
v_str ESTAB   0      0                                                           *:3639976925              2:1182111258
v_str ESTAB   0      0                                                           *:3639976925              2:1182111257
v_str CLOSING 0      0                                                           *:3639976925              2:1182111256
v_str ESTAB   0      0                                                           *:3639976931              2:1182111273
v_str ESTAB   0      0                                                           *:3639976929              2:1182111261
v_str ESTAB   0      0                                                           *:3639976932              2:1182111278
v_str ESTAB   0      0                                                           *:3639976932              2:1182111277
v_str ESTAB   0      0                                                           *:3639976932              2:1182111276
v_str ESTAB   0      0                                                           *:3639976932              2:1182111275
v_str ESTAB   0      0                                                           *:3639976932              2:1182111274
amitabh@LAPTOP-3KF17VR3:~$ ss -p
RTNETLINK answers: Invalid argument
Netid State   Recv-Q Send-Q                                          Local Address:Port         Peer Address:Port       Process
u_str ESTAB   0      0                                                           * 12390                   * 12391      
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 5751                    * 5750       
u_str ESTAB   0      0                                                           * 9236                    * 9235       
u_dgr ESTAB   0      0                                                           * 8260                    * 8261       
u_str ESTAB   0      0                                                           * 7183                    * 7184       
u_dgr ESTAB   0      0                                                           * 7605                    * 7604       
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 8520                    * 2495       
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 9367                    * 8501       
u_dgr ESTAB   0      0                                                           * 7590                    * 8277       
u_str ESTAB   0      0                                                           * 6171                    * 0          
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 254                     * 1408       
u_dgr ESTAB   0      0                                                           * 7584                    * 8276       
u_str ESTAB   0      0                                                           * 2718                    * 12395      
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 4733                    * 237        
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 6627                    * 1489       
u_dgr ESTAB   0      0                                                           * 8259                    * 8258       
u_dgr ESTAB   0      0                                                           * 1510                    * 1511       
u_dgr ESTAB   0      0                                                           * 6465                    * 8277       
u_dgr ESTAB   0      0                                                           * 1515                    * 1514       
u_str ESTAB   0      0                                                           * 6490                    * 8330       
u_dgr ESTAB   0      0                                                           * 8258                    * 8259       
u_str ESTAB   0      0                                                           * 3903                    * 3904       
u_dgr ESTAB   0      0                                         /run/systemd/notify 8255                    * 0          
u_dgr ESTAB   0      0                                                           * 8257                    * 8256       
u_str ESTAB   0      0                                                           * 1354                    * 1355       
u_dgr ESTAB   0      0                                                           * 1514                    * 1515       
u_str ESTAB   0      0                                                           * 11344                   * 6270       
u_dgr ESTAB   0      0                                                           * 8261                    * 8260       
u_dgr ESTAB   0      0                                /run/systemd/journal/dev-log 8276                    * 0          
u_dgr ESTAB   0      0                                 /run/systemd/journal/socket 8277                    * 0          
u_dgr ESTAB   0      0                                                           * 10547                   * 8276       
u_str ESTAB   0      0                                                           * 1489                    * 6627       
u_dgr ESTAB   0      0                                                           * 7602                    * 7603       
u_str ESTAB   0      0                                                           * 7573                    * 12731      
u_seq ESTAB   0      0                                                           * 8605                    * 8604       
u_str ESTAB   0      0                                           /tmp/.X11-unix/X0 10584                   * 2265       
u_dgr ESTAB   0      0                                                           * 7607                    * 7606       
u_str ESTAB   0      0                                                           * 3899                    * 3900       
u_dgr ESTAB   0      0                                                           * 7604                    * 7605       
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 11500                   * 12379      
u_str ESTAB   0      0                                                           * 9237                    * 9238       
u_str ESTAB   0      0                                                           * 1408                    * 254        
u_dgr ESTAB   0      0                                                           * 7252                    * 8277       
u_dgr ESTAB   0      0                                                           * 8308                    * 8277       
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 4639                    * 10336      
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 6270                    * 11344      
u_str ESTAB   0      0                                                           * 5660                    * 6348       
u_str ESTAB   0      0                                                           * 6235                    * 10314      
u_dgr ESTAB   0      0                                                           * 1498                    * 8277       
u_dgr ESTAB   0      0                                                           * 4612                    * 8255       
u_str ESTAB   0      0                                                           * 1355                    * 1354       
u_str ESTAB   0      0                                                           * 8569                    * 8570       
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 1357                    * 155        
u_str ESTAB   0      0                                                           * 12379                   * 11500      
u_dgr ESTAB   0      0                                                           * 4717                    * 8276       
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 12731                   * 7573       
u_dgr ESTAB   0      0                                                           * 1513                    * 1512       
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 10314                   * 6235       
u_str ESTAB   0      0                                                           * 9238                    * 9237       
u_dgr ESTAB   0      0                                                           * 8256                    * 8257       
u_str ESTAB   0      0                                                           * 3900                    * 3899       
u_str ESTAB   0      0                                                           * 2495                    * 8520       
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 8570                    * 8569       
u_str ESTAB   0      0                                                           * 240                     * 239        
u_str ESTAB   0      0                                                           * 12391                   * 12390      
u_str ESTAB   0      0                                                           * 8501                    * 9367       
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 8521                    * 2500       
u_dgr ESTAB   0      0                                                           * 1512                    * 1513       
u_str ESTAB   0      0                                 /mnt/wslg/PulseAudioRDPSink 8330                    * 6490       
u_str ESTAB   0      0                                                           * 3904                    * 3903       
u_str ESTAB   0      0                                                           * 237                     * 4733       
u_seq ESTAB   0      0                                                           * 8604                    * 8605       
u_dgr ESTAB   0      0                                                           * 7603                    * 7602       
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 8618                    * 6478       
u_dgr ESTAB   0      0                                                           * 1511                    * 1510       
u_str ESTAB   0      0                                                           * 239                     * 240        
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 2741                    * 1517       
u_dgr ESTAB   0      0                                                           * 8596                    * 8276       
u_dgr ESTAB   0      0                                                           * 11346                   * 8276       
u_str ESTAB   0      0                                        /tmp/dbus-5bQXsYvhmm 12395                   * 2718       
u_str ESTAB   0      0                                                           * 9235                    * 9236       
u_str ESTAB   0      0                                                           * 2500                    * 8521       
u_dgr ESTAB   0      0                                                           * 299                     * 8276       
u_str ESTAB   0      0                                                           * 2265                    * 10584      
u_str ESTAB   0      0                                 /run/dbus/system_bus_socket 7040                    * 7609       
u_dgr ESTAB   0      0                                                           * 138                     * 8277       
u_dgr ESTAB   0      0                                                           * 7606                    * 7607       
u_str ESTAB   0      0                                 /run/systemd/journal/stdout 6348                    * 5660       
u_str ESTAB   0      0                                                           * 7184                    * 7183       
u_str ESTAB   0      0                                                           * 10336                   * 4639       
u_str ESTAB   0      0                    @d490366f2279b533/bus/systemd/bus-system 7609                    * 7040       
u_str ESTAB   0      0                 @3797ad06a751e816/bus/systemd-logind/system 6478                    * 8618       
u_str ESTAB   0      0                    @d1db3ee1a72526b4/bus/systemd/bus-system 1517                    * 2741       
u_str ESTAB   0      0        @c9c410374d1df70/bus/systemd-resolve/bus-api-resolve 155                     * 1357       
u_str ESTAB   0      0                @d743379147c23c0c/bus/systemd/bus-api-system 5750                    * 5751       
v_str ESTAB   0      0                                                           *:3639976910              2:50000      
v_str ESTAB   0      0                                                           *:3639976911              2:50000      
v_str ESTAB   0      0                                                           *:3639976912              2:50000      
v_str ESTAB   0      0                                                           *:3639976913              2:50000      
v_str ESTAB   0      0                                                           *:3639976914              2:50000      
v_str ESTAB   0      0                                                           *:3639976916              2:50001      
v_str ESTAB   0      0                                                           *:3639976917              2:50001      
v_str ESTAB   0      0                                                           *:3639976918              2:50001      
v_str ESTAB   0      0                                                           *:3639976920              2:50000      
v_str ESTAB   0      0                                                           *:3639976921              2:50000      
v_str ESTAB   0      0                                                           *:3639976922              2:50002      
v_str ESTAB   0      0                                                           *:3639976923              2:50002      
v_str ESTAB   0      0                                                           *:3639976926              2:50002      
v_str ESTAB   0      0                                                           *:3639976927              2:50002      
v_str ESTAB   0      0                                                           *:3639976933              2:50003      
v_str ESTAB   0      0                                                           *:3639976934              2:50003      
v_str ESTAB   0      0                                                           *:1                       2:1182111266 
v_str ESTAB   0      0                                                           *:3639976919              2:1182111245 
v_str ESTAB   0      0                                                           *:3639976924              2:1182111252 
v_str ESTAB   0      0                                                           *:3639976925              2:1182111259 
v_str ESTAB   0      0                                                           *:3639976925              2:1182111258 
v_str ESTAB   0      0                                                           *:3639976925              2:1182111257 
v_str CLOSING 0      0                                                           *:3639976925              2:1182111256 
v_str ESTAB   0      0                                                           *:3639976931              2:1182111273 
v_str ESTAB   0      0                                                           *:3639976929              2:1182111261 
v_str ESTAB   0      0                                                           *:3639976932              2:1182111278 
v_str ESTAB   0      0                                                           *:3639976932              2:1182111277 
v_str ESTAB   0      0                                                           *:3639976932              2:1182111276 
v_str ESTAB   0      0                                                           *:3639976932              2:1182111275 
v_str ESTAB   0      0                                                           *:3639976932              2:1182111274 
amitabh@LAPTOP-3KF17VR3:~$ ss -tulpn
Netid      State       Recv-Q      Send-Q            Local Address:Port             Peer Address:Port      Process
udp        UNCONN      0           0                     127.0.0.1:323                   0.0.0.0:*
udp        UNCONN      0           0                     127.0.0.1:323                   0.0.0.0:*
udp        UNCONN      0           0                    127.0.0.54:53                    0.0.0.0:*
udp        UNCONN      0           0                 127.0.0.53%lo:53                    0.0.0.0:*
udp        UNCONN      0           0                10.255.255.254:53                    0.0.0.0:*
udp        UNCONN      0           0                         [::1]:323                      [::]:*
udp        UNCONN      0           0                         [::1]:323                      [::]:*
tcp        LISTEN      0           4096              127.0.0.53%lo:53                    0.0.0.0:*
tcp        LISTEN      0           1000             10.255.255.254:53                    0.0.0.0:*
tcp        LISTEN      0           4096                 127.0.0.54:53                    0.0.0.0:*

amitabh@LAPTOP-3KF17VR3:~$ arping

Usage:
  arping [options] <destination>

Options:
  -f            quit on first reply
  -q            be quiet
  -b            keep on broadcasting, do not unicast
  -D            duplicate address detection mode
  -U            unsolicited ARP mode, update your neighbours
  -A            ARP answer mode, update your neighbours
  -V            print version and exit
  -c <count>    how many packets to send
  -w <timeout>  how long to wait for a reply
  -i <interval> set interval between packets (default: 1 second)
  -I <device>   which ethernet device to use
  -s <source>   source IP address
  <destination> DNS name or IP address

For more details see arping(8).