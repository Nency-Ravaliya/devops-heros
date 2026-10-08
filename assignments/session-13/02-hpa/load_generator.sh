#!/bin/bash
# HPA Load Generator Script
echo "Starting HPA load generator using busybox pod..."
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://php-apache; done"
