#!/bin/bash
# Prints all Task 4 overlay-network evidence on one screen, for screenshotting.
echo "=============== TASK 4: OVERLAY NETWORK ==============="
echo
echo "--- 1. Overlay requires swarm mode (SCOPE column) ---"
docker network ls | grep -E "NETWORK|overlay|frontend-net|bridge  "
echo
echo "--- 2. Replicated service running on the overlay ---"
docker service ls
echo
echo "--- 3. Service discovery: name -> virtual IP (VIP) ---"
echo -n "web-svc resolves to:  "; docker exec overlay-client getent hosts web-svc
echo -n "tasks.web-svc:        "; docker exec overlay-client getent hosts tasks.web-svc
echo
echo "--- 4. HTTP through the VIP, load-balanced across 3 replicas ---"
docker exec overlay-client wget -qO- --timeout=5 http://web-svc | grep -i "<title>"
echo
echo "--- 5. Overlay network details ---"
docker network inspect app-overlay --format 'Driver:     {{.Driver}}
Scope:      {{.Scope}}
Attachable: {{.Attachable}}
Subnet:     {{range .IPAM.Config}}{{.Subnet}}{{end}}'
echo "======================================================="
