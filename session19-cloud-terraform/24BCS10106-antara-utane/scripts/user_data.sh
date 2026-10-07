#!/bin/bash
# Runs once at first boot (cloud-init). Installs nginx and a tiny landing page.
set -euxo pipefail

if command -v dnf >/dev/null 2>&1; then
  dnf install -y nginx
elif command -v yum >/dev/null 2>&1; then
  amazon-linux-extras install -y nginx1 || yum install -y nginx
else
  apt-get update -y
  apt-get install -y nginx
fi

cat > /usr/share/nginx/html/index.html <<'HTML'
<h1>${project}</h1>
<p>Deployed with Terraform by Antara Utane (24BCS10106)</p>
HTML
# Debian/Ubuntu serve from /var/www/html
[ -d /var/www/html ] && cp /usr/share/nginx/html/index.html /var/www/html/index.html || true

systemctl enable --now nginx
