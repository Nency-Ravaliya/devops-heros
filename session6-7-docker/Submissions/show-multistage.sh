#!/usr/bin/env bash
# Dockerfiles & Images Task 1 — build multi-stage image, run on :8080.
set -u
hline() { printf '=%.0s' {1..78}; echo; }

# --- Auto-detect the multi-stage-dockerfile directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")/multi-stage-dockerfile"

if [ ! -d "$REPO_DIR" ]; then
  echo "ERROR: multi-stage-dockerfile directory not found at: $REPO_DIR"
  exit 1
fi

hline; echo "STEP 1 — source files"; hline
echo "Source directory: $REPO_DIR"
ls "$REPO_DIR"

hline; echo "STEP 2 — build the image (multi-stage: builder -> runner)"; hline
docker build --progress=plain -t hw-multistage "$REPO_DIR" 2>&1 | tail -10

hline; echo "STEP 3 — run the container on port 8080"; hline
echo "\$ docker run -d --name hw-multistage -p 8080:8080 hw-multistage"
docker rm -f hw-multistage >/dev/null 2>&1 || true
docker run -d --name hw-multistage -p 8080:8080 hw-multistage
sleep 3

hline; echo "STEP 4 — verify: docker ps"; hline
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' | grep -E 'NAMES|multistage'

hline; echo "STEP 5 — verify: access the app on port 8080"; hline
echo "\$ curl -s http://127.0.0.1:8080/"
curl -s --max-time 8 http://127.0.0.1:8080/
echo
echo
echo "### MULTISTAGE-DONE ###"
