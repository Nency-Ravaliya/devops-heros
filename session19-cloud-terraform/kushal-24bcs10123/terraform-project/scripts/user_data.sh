#!/bin/bash
# Runs once at first boot (cloud-init). Installs nginx and serves a page that names the instance.
set -eux
dnf install -y nginx
TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 300')
IID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
cat > /usr/share/nginx/html/index.html <<HTML
<h1>Session 19 - Terraform built this</h1>
<p>instance: ${IID} in ${AZ}</p>
<p>kushal-24bcs10123</p>
HTML
systemctl enable --now nginx
