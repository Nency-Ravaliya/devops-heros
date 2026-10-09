# Task 4: Overlay Network

## What is an Overlay Network?

An overlay network in Docker is used to connect containers that are running on **different Docker hosts**. It creates a virtual network on top of the existing host networks.

Unlike a normal bridge network, which is mainly used for containers on the same Docker host, an overlay network can allow containers on different Docker hosts to communicate.

## Use Cases

Overlay networks are mainly useful for:

* Docker Swarm applications
* Microservices running on multiple Docker hosts
* Applications where different services are running on different servers
* Communication between containers across multiple machines

## How it works across multiple Docker Hosts

For an overlay network, the Docker hosts need to be part of the same **Docker Swarm**. An overlay network can then be created on the Swarm, and containers or services on different hosts can connect to it. Docker handles the networking and routing between the containers.

For example:

```bash
docker swarm init
```

Then an overlay network can be created:

```bash
docker network create --driver overlay --attachable my-overlay
```

Containers connected to `my-overlay` can communicate even if they are running on different Docker hosts.

For multiple hosts, Docker uses ports such as `2377`, `7946`, and `4789` for Swarm and overlay networking communication.

## What I Understood

I understood that an overlay network is useful when Docker containers are running on **different machines**. It connects the Docker hosts together and allows containers on those hosts to communicate as if they were on the same Docker network.

It is commonly used with Docker Swarm and is useful for distributed and microservice applications.
