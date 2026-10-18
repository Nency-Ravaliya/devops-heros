#!/usr/bin/env bash
# run-security-scans.sh: run the scans of the DevSecOps pipeline (devsecops.yml) on a laptop.
#
#   bash security/run-security-scans.sh <project-folder>
#
# <project-folder> must be a git clone of StockPilot (final-devops-project layout: application/, docker/ and the git
# history, because the secret scan reads every commit). Only Docker is required: each tool runs
# in a container, so nothing has to be installed. Every scan prints its own output, and the
# script ends with a summary table, the local "security gate".
#
# Exit code: 0 = every gate is open, 1 = at least one gate is closed.
#
# Optional environment variables:
#   IMAGE_PREFIX        name prefix of the local images (default: s17)
#   TRIVY_CACHE_VOLUME  Docker volume that keeps the Trivy vulnerability database (default: trivy-cache)

set -u
export MSYS_NO_PATHCONV=1            # Git Bash on Windows: do not rewrite /paths given to docker

# absolute paths that Docker understands (pwd -W gives C:/... in Git Bash on Windows, pwd is enough elsewhere)
abs() { (cd "$1" && { pwd -W 2>/dev/null || pwd; }); }
PROJECT=$(abs "${1:?usage: run-security-scans.sh <project-folder>}") || exit 2
SEC=$(abs "$(dirname "${BASH_SOURCE[0]}")")
PREFIX=${IMAGE_PREFIX:-s17}
CACHE=${TRIVY_CACHE_VOLUME:-trivy-cache}

SEMGREP_VERSION=1.181.0
PIP_AUDIT_VERSION=2.10.1
GITLEAKS_IMAGE=zricethezav/gitleaks:v8.30.1
TRIVY_IMAGE=aquasec/trivy:0.75.0

declare -A RESULT
ORDER=()
run() {                              # run "<name>" <command...>   -> remembers the exit code
  local name=$1; shift
  echo; echo "===== $name ====="
  "$@"; RESULT[$name]=$?; ORDER+=("$name")
  echo "----- $name: exit code ${RESULT[$name]}"
}

# 1. SAST: Semgrep (our own rules + the public python / javascript / dockerfile packs)
sast() {
  docker run --rm -v "$PROJECT:/src:ro" -v "$SEC:/work/security:ro" -w /src python:3.12-slim bash -c "
    pip install -q --root-user-action=ignore --disable-pip-version-check semgrep==$SEMGREP_VERSION &&
    semgrep scan --config /work/security/semgrep-rules.yml --config p/python --config p/javascript \
      --config p/dockerfile --metrics=off --no-git-ignore --error application/backend application/frontend/src docker"
}

# 2. SCA: known vulnerabilities in the dependencies
sca_python() {
  docker run --rm -v "$PROJECT/application/backend:/src:ro" python:3.12-slim bash -c "
    pip install -q --root-user-action=ignore --disable-pip-version-check pip-audit==$PIP_AUDIT_VERSION &&
    pip-audit -r /src/requirements.txt --progress-spinner off"
}
sca_node() {
  docker run --rm -v "$PROJECT/application/frontend:/src:ro" node:22-alpine sh -c "
    cp -r /src /app && cd /app && npm audit --omit=dev --audit-level=high"
}

# 3. Secret scan over the full git history
secret_scan() {
  docker run --rm -v "$PROJECT:/repo:ro" -v "$SEC:/cfg:ro" "$GITLEAKS_IMAGE" \
    git /repo --config /cfg/.gitleaks.toml --no-banner --redact --verbose
}

# 4. Docker build (the images that are scanned next)
docker_build() {
  docker build -q -t "$PREFIX-backend:local" -f "$PROJECT/docker/backend.Dockerfile" "$PROJECT/application/backend" >/dev/null &&
  docker build -q -t "$PREFIX-frontend:local" -f "$PROJECT/docker/frontend.Dockerfile" "$PROJECT/application/frontend" >/dev/null
}

# 5. Container image scan with Trivy (exit code 1 on HIGH / CRITICAL that has a fix)
trivy_image() {
  docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v "$SEC:/work/security:ro" \
    -v "$CACHE:/root/.cache" -w /work "$TRIVY_IMAGE" image --config security/trivy.yaml "$1"
}

run "SAST  semgrep"                 sast
run "SCA   pip-audit (backend)"     sca_python
run "SCA   npm audit (frontend)"    sca_node
run "Secrets gitleaks (history)"    secret_scan
run "Docker build (2 images)"       docker_build
run "Image scan trivy (backend)"    trivy_image "$PREFIX-backend:local"
run "Image scan trivy (frontend)"   trivy_image "$PREFIX-frontend:local"

echo; echo "================ SECURITY GATE (local) ================"
fail=0
for name in "${ORDER[@]}"; do
  if [ "${RESULT[$name]}" -eq 0 ]; then verdict="PASS"; else verdict="FAIL"; fail=1; fi
  printf '%-32s %s (exit %s)\n' "$name" "$verdict" "${RESULT[$name]}"
done
if [ "$fail" -eq 0 ]; then echo "GATE OPEN: nothing blocks the push of the images."
else echo "GATE CLOSED: fix the findings above before pushing."; fi
exit "$fail"
