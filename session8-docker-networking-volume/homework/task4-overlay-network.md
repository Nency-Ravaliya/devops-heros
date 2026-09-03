# Task 4: Overlay Network (research)

**What it is:** an overlay network is a virtual network that spans **multiple
Docker hosts**, letting containers on different physical/virtual machines
communicate as if they were on the same local network. It's built on top of
the hosts' existing network (the "underlay") using VXLAN tunneling to
encapsulate container traffic.

**Use cases:**
- **Docker Swarm services** — by default, Swarm creates an overlay network
  (`ingress`) so replicas of a service spread across multiple nodes can talk
  to each other and be load-balanced.
- **Multi-host microservices** — services that must communicate directly
  (not just via published ports) when they're deployed across a cluster
  rather than a single machine.
- **Secure inter-host communication** — overlay networks can be encrypted
  (`--opt encrypted`), so traffic between hosts is protected even if it
  crosses an untrusted network.

**How it works across multiple hosts:**
1. A **key-value store** (or, in Swarm mode, the built-in Raft consensus
   store) keeps every host's Docker daemon in sync about which containers
   exist on which network and which host.
2. Each participating host runs a small VXLAN tunnel endpoint per overlay
   network.
3. When a container sends a packet to a container on another host, the
   sending host's daemon encapsulates it in a VXLAN packet addressed to the
   destination host's IP, using the underlay network to actually deliver it.
4. The receiving host decapsulates the packet and delivers it to the target
   container's virtual interface — from the containers' point of view, they
   are simply on the same subnet.

**Compare to a bridge network** (used in Task 1): a bridge network is
strictly local to a single Docker host — containers on different hosts on a
bridge network cannot see each other at all. Overlay networks exist
specifically to remove that single-host limitation.

Creating one (requires Swarm mode, or an external KV store for classic
multi-host networking):
```bash
docker swarm init
docker network create -d overlay my-overlay-net
docker service create --name web --network my-overlay-net --replicas 3 nginx:alpine
```

This task was research-only per the homework — no execution required.
