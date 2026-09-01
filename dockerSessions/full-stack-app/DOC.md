### Network connecting backend and database
```bash
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/full-stack-app$ docker network inspect monastery360-server
[
    {
        "Name": "monastery360-server",
        "Id": "72beb2003c2a5a8675c02c4a3097423d92b0e8505433f20e9d0d0a148b31940f",
        "Created": "2026-08-31T23:30:54.48869496+05:30",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.19.0.0/16",
                    "Gateway": "172.19.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Options": {},
        "Labels": {},
        "Containers": {
            "1fc577ffbb7449b63bab152513d64961761fe05e69dfe870ceb20f91f7447070": {
                "Name": "monastery360-backend",
                "EndpointID": "90b7ea3b5da56befc4285026cadb1b9be9dacab5a5efa91620f354e37bc4ec4c",
                "MacAddress": "76:50:f4:9b:3c:ce",
                "IPv4Address": "172.19.0.3/16",
                "IPv6Address": ""
            },
            "899faee657679dc0bd8cc1d8cee2c8fb1d11e435e34a5e684260484a4762fb24": {
                "Name": "mongodb-db",
                "EndpointID": "208e4975d8fa108bba4af6c9b40a79abecb4b936e389f8cdfb6e54477ddc572d",
                "MacAddress": "92:c1:2d:4d:94:3e",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.19.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]
```
----------------
### Network connecting frontend and backend
```bash
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/full-stack-app$ docker network inspect monastery360-client
[
    {
        "Name": "monastery360-client",
        "Id": "c706d8d7c7f9614f5c65e7b6485998f201f745bd0fc7c2ca404cd6531b9a55e6",
        "Created": "2026-08-31T23:44:52.160979578+05:30",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Options": {},
        "Labels": {},
        "Containers": {
            "1fc577ffbb7449b63bab152513d64961761fe05e69dfe870ceb20f91f7447070": {
                "Name": "monastery360-backend",
                "EndpointID": "b329df97bd7b65df915cd3a78809a9f860c90ea13cc66e022641f5fb74db978a",
                "MacAddress": "56:08:0c:a4:0d:3a",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            },
            "68443b97adf218826bb9e01f5d22777da77ffeeafeaf1f9df385f5f5895c55ee": {
                "Name": "monastery360-frontend",
                "EndpointID": "882c7310935bbb4ea729ee06ec2083507f8f07d9ef600233849afa3a33bb2520",
                "MacAddress": "86:d8:e7:c2:49:17",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.18.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]
```
------------
### Containers' health
```bash
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/full-stack-app$ docker ps
CONTAINER ID   IMAGE                   COMMAND                  CREATED          STATUS          PORTS                                             NAMES
1fc577ffbb74   monastery360:backend    "docker-entrypoint.s…"   2 minutes ago    Up 2 minutes    0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp       monastery360-backend
899faee65767   mongo:latest            "docker-entrypoint.s…"   3 minutes ago    Up 3 minutes    0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp   mongodb-db
68443b97adf2   monastery360:frontend   "/docker-entrypoint.…"   10 minutes ago   Up 10 minutes   0.0.0.0:5173->80/tcp, [::]:5173->80/tcp           monastery360-frontend
```
------------
### Browser Screenshot
![browser_ss](./assets/Screenshot%20from%202026-08-31%2023-49-31.png)
-------------
### Database docker command
```bash
docker run -it -d -p 27017:27017 --name mongodb-db mongo:latest
```