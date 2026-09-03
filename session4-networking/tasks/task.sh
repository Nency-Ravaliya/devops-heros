#!/bin/bash

# Show IP and network configuration
ip a

# Test network connectivity
ping -c 4 google.com

# Show the route taken to reach a host
traceroute google.com

# Show network connections and listening ports
netstat -tulnp

# Fetch data from a URL
curl https://api.github.com