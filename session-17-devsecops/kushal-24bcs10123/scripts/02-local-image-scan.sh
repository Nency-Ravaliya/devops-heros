#!/usr/bin/env bash
# 02: build the hardened image and scan it with trivy, exactly like jobs 6 and 7.
. "$(dirname "$0")/lib.sh"
cd secure-converter
x "docker build --build-arg GIT_SHA=$(git rev-parse --short HEAD) --build-arg BUILD_NUMBER=local -t ghcr.io/kushaltalati/secure-converter:local . 2>&1 | tail -3"
x "docker image inspect ghcr.io/kushaltalati/secure-converter:local --format 'size={{.Size}} user={{.Config.User}} healthcheck={{.Config.Healthcheck.Test}}'"
x "trivy image --config security/trivy.yaml --ignorefile security/.trivyignore --scanners vuln ghcr.io/kushaltalati/secure-converter:local 2>&1 | grep -vE 'B / |KiB|MiB'; echo exit=\${PIPESTATUS[0]}"
hr "for comparison: the same image WITHOUT ignore-unfixed and with all severities"
x "trivy image --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL --scanners vuln --format table ghcr.io/kushaltalati/secure-converter:local 2>&1 | grep -vE 'B / |KiB|MiB' | sed -n '/Report Summary/,/Legend/p'"
