#!/bin/bash
echo "Starting load generation on backend service..."
while true; do
  curl -s http://backend-service:8080/ > /dev/null
done
