#!/usr/bin/env bash
# =============================================================================
#  TaskBoard — DevSecOps scan suite + security gate
#
#  Runs every scanner the CI pipeline runs, prints a summary table and exits
#  non-zero (BLOCKS the release) when any gate fails:
#
#    SAST        bandit   (Python, MEDIUM+ severity & confidence)
#                semgrep  (python / javascript / dockerfile rulesets, blocking findings)
#    SCA         pip-audit (backend runtime + dev requirements, any known vuln)
#                npm audit (frontend, HIGH/CRITICAL)
#    Secrets     gitleaks (working tree, custom .gitleaks.toml, ANY secret fails)
#    Dockerfile  hadolint (warnings+) and trivy config (HIGH/CRITICAL misconfig)
#    Images      trivy image (HIGH/CRITICAL with a fix + embedded secrets)
#
#  Usage:   security/run-security-scans.sh [all|sast|sca|secrets|dockerfile|images]...
#  Env:     BACKEND_IMAGE  (default taskboard-backend:1.0.0)
#           FRONTEND_IMAGE (default taskboard-frontend:1.0.0)
#           SKIP_IMAGES=1  skip image scans (e.g. before images are built)
#           REPORT_DIR     where JSON/SARIF/text reports go (default security/reports)
#
#  Only Docker + Python 3 + npm are required: scanners without a local binary
#  run from their official container images.
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SEC="$ROOT/security"
BACKEND="$ROOT/application/backend"
FRONTEND="$ROOT/application/frontend"
REPORT_DIR="${REPORT_DIR:-$SEC/reports}"
BACKEND_IMAGE="${BACKEND_IMAGE:-taskboard-backend:1.0.0}"
FRONTEND_IMAGE="${FRONTEND_IMAGE:-taskboard-frontend:1.0.0}"
SKIP_IMAGES="${SKIP_IMAGES:-0}"

# Pinned scanner images (same versions as .github/workflows/ci.yml)
TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:0.75.0}"
GITLEAKS_IMAGE="${GITLEAKS_IMAGE:-zricethezav/gitleaks:v8.30.1}"
SEMGREP_IMAGE="${SEMGREP_IMAGE:-semgrep/semgrep:1.179.0}"
HADOLINT_IMAGE="${HADOLINT_IMAGE:-hadolint/hadolint:v2.15.1}"

mkdir -p "$REPORT_DIR"
cd "$ROOT" || exit 2
if [ -t 1 ]; then B=$'\e[1m'; R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; N=$'\e[0m'; else B=; R=; G=; Y=; N=; fi

RESULT_NAMES=(); RESULT_STATUS=()
record() { RESULT_NAMES+=("$1"); RESULT_STATUS+=("$2"); }
banner() { printf '\n%s━━━ %s ━━━%s\n' "$B" "$1" "$N"; }
gate()   { # gate <name> <exit-code>
  if [ "$2" -eq 0 ]; then echo "${G}✔ $1: PASS${N}"; record "$1" PASS
  else echo "${R}✘ $1: FAIL (exit $2)${N}"; record "$1" FAIL; fi
}

# ---------------------------------------------------------------- python tools
PY_BIN=""
python_tools() {
  [ -n "$PY_BIN" ] && return 0
  if command -v bandit >/dev/null && command -v pip-audit >/dev/null; then
    PY_BIN="$(dirname "$(command -v bandit)")"; return 0
  fi
  if [ ! -x "$SEC/.venv/bin/bandit" ] || [ ! -x "$SEC/.venv/bin/pip-audit" ]; then
    local py; py="$(command -v python3.12 || command -v python3)"
    echo "installing bandit + pip-audit into security/.venv ($py)"
    "$py" -m venv "$SEC/.venv" && "$SEC/.venv/bin/pip" install -q -r "$SEC/requirements-security.txt" || return 1
  fi
  PY_BIN="$SEC/.venv/bin"
}

# ----------------------------------------------------------------------- SAST
scan_sast() {
  banner "SAST · bandit (Python)"
  python_tools || { gate "SAST bandit" 99; return; }
  "$PY_BIN/bandit" -c security/bandit.yaml -r application/backend/app -f json -o "$REPORT_DIR/bandit.json" --exit-zero -q
  "$PY_BIN/bandit" -c security/bandit.yaml -r application/backend/app -ll -ii -q
  local brc=$?
  [ "$brc" -eq 0 ] && echo "bandit: no MEDIUM+ severity/confidence issues in application/backend/app"
  gate "SAST bandit" "$brc"

  banner "SAST · semgrep (python, javascript, dockerfile)"
  local excludes=() line
  while IFS= read -r line; do
    line="${line%%#*}"; line="${line// /}"; [ -n "$line" ] && excludes+=(--exclude "$line")
  done < "$SEC/.semgrepignore"
  docker run --rm -v "$ROOT:/src" -w /src "$SEMGREP_IMAGE" semgrep scan \
    --config p/python --config p/javascript --config p/dockerfile \
    --metrics=off --disable-version-check --quiet --error "${excludes[@]}" \
    --json-output="reports-semgrep.json" --text application
  local rc=$?
  mv -f "$ROOT/reports-semgrep.json" "$REPORT_DIR/semgrep.json" 2>/dev/null
  [ "$rc" -eq 0 ] && echo "semgrep: 0 blocking findings"
  gate "SAST semgrep" "$rc"
}

# ------------------------------------------------------------------------ SCA
scan_sca() {
  banner "SCA · pip-audit (backend dependencies)"
  python_tools || { gate "SCA pip-audit" 99; return; }
  local rc=0 f
  for f in requirements.txt requirements-dev.txt; do
    echo "-- $f"
    "$PY_BIN/pip-audit" -r "$BACKEND/$f" --progress-spinner off --desc off 2>&1 | grep -v cachecontrol
    [ "${PIPESTATUS[0]}" -ne 0 ] && rc=1
  done
  "$PY_BIN/pip-audit" -r "$BACKEND/requirements.txt" -f json -o "$REPORT_DIR/pip-audit.json" --progress-spinner off >/dev/null 2>&1
  gate "SCA pip-audit" "$rc"

  banner "SCA · npm audit (frontend dependencies, HIGH+)"
  (cd "$FRONTEND" && npm audit --json > "$REPORT_DIR/npm-audit.json" 2>/dev/null; npm audit --audit-level=high)
  gate "SCA npm audit" $?
}

# -------------------------------------------------------------------- secrets
scan_secrets() {
  banner "Secrets · gitleaks (working tree)"
  docker run --rm -v "$ROOT:/repo:ro" -v "$REPORT_DIR:/reports" "$GITLEAKS_IMAGE" \
    dir /repo --config /repo/security/.gitleaks.toml --redact --no-banner --verbose \
    --report-format json --report-path /reports/gitleaks.json
  gate "Secrets gitleaks" $?
}

# ----------------------------------------------------------------- dockerfile
scan_dockerfile() {
  banner "Dockerfile lint · hadolint"
  local rc=0 d
  for d in backend frontend; do
    echo "-- application/$d/Dockerfile"
    docker run --rm -i -v "$SEC/.hadolint.yaml:/.config/hadolint.yaml:ro" "$HADOLINT_IMAGE" \
      hadolint --config /.config/hadolint.yaml - < "$ROOT/application/$d/Dockerfile" || rc=1
  done
  [ "$rc" -eq 0 ] && echo "hadolint: no warnings or errors"
  gate "Dockerfile hadolint" "$rc"

  banner "IaC/Dockerfile misconfig · trivy config (HIGH+)"
  docker run --rm -v "$ROOT:/src:ro" -v trivy-cache:/root/.cache/ -w /src "$TRIVY_IMAGE" \
    config --quiet --disable-telemetry --config "" --severity HIGH,CRITICAL --exit-code 1 \
    --skip-dirs application/frontend/node_modules --skip-dirs application/backend/.venv application
  gate "Dockerfile trivy config" $?
}

# --------------------------------------------------------------------- images
trivy_summary() { # one-line-per-target severity breakdown from a trivy JSON report
  python3 - "$1" <<'PY'
import json, sys, collections
try:
    report = json.load(open(sys.argv[1]))
except Exception as exc:
    sys.exit(f"(no trivy report: {exc})")
total = collections.Counter(); fixable = collections.Counter(); targets = 0
for res in report.get("Results", []):
    targets += 1
    for v in res.get("Vulnerabilities") or []:
        total[v["Severity"]] += 1
        if v.get("FixedVersion"):
            fixable[v["Severity"]] += 1
order = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"]
print(f"{report.get('ArtifactName')}  ({report.get('Metadata', {}).get('OS', {}).get('Family', '?')} "
      f"{report.get('Metadata', {}).get('OS', {}).get('Name', '')}, {targets} targets scanned)")
print("  all findings : " + ", ".join(f"{s} {total[s]}" for s in order))
print("  with a fix   : " + ", ".join(f"{s} {fixable[s]}" for s in order))
print(f"  gate policy  : HIGH/CRITICAL with a fix -> {fixable['HIGH'] + fixable['CRITICAL']} blocking")
PY
}

scan_images() {
  if [ "$SKIP_IMAGES" = "1" ]; then echo "${Y}image scans skipped (SKIP_IMAGES=1)${N}"; return; fi
  local img name
  for img in "$BACKEND_IMAGE" "$FRONTEND_IMAGE"; do
    name="${img%%:*}"
    banner "Container image · trivy $img (HIGH/CRITICAL, fixable)"
    if ! docker image inspect "$img" >/dev/null 2>&1; then
      echo "${R}image $img not found — build it first (docker compose -f docker/docker-compose.yml build)${N}"
      gate "Image $name" 98; continue
    fi
    # full report for the record (all severities), then the gate run with the policy file
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/ \
      -v "$REPORT_DIR:/reports" "$TRIVY_IMAGE" image --quiet --disable-telemetry \
      --format json --output "/reports/trivy-${name}.json" "$img" >/dev/null 2>&1
    trivy_summary "$REPORT_DIR/trivy-${name}.json"
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/ \
      -v "$ROOT:/src:ro" -w /src "$TRIVY_IMAGE" --config security/trivy.yaml \
      image --quiet --disable-telemetry --table-mode detailed "$img"
    gate "Image $name" $?
  done
}

# ----------------------------------------------------------------------- main
STAGES=("$@"); [ ${#STAGES[@]} -eq 0 ] && STAGES=(all)
echo "${B}TaskBoard security scan${N} — $(basename "$ROOT") @ $(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo no-git)"
echo "images: $BACKEND_IMAGE, $FRONTEND_IMAGE   reports: ${REPORT_DIR#"$ROOT"/}"
for s in "${STAGES[@]}"; do
  case "$s" in
    all) scan_sast; scan_sca; scan_secrets; scan_dockerfile; scan_images ;;
    sast) scan_sast ;; sca) scan_sca ;; secrets) scan_secrets ;;
    dockerfile) scan_dockerfile ;; images) scan_images ;;
    *) echo "unknown stage: $s (use all|sast|sca|secrets|dockerfile|images)"; exit 2 ;;
  esac
done

banner "SECURITY GATE"
failed=0
for i in "${!RESULT_NAMES[@]}"; do
  if [ "${RESULT_STATUS[$i]}" = PASS ]; then mark="${G}PASS${N}"; else mark="${R}FAIL${N}"; failed=$((failed+1)); fi
  printf '  %-26s %s\n' "${RESULT_NAMES[$i]}" "$mark"
done
if [ "$failed" -gt 0 ]; then
  echo "${R}${B}⛔ SECURITY GATE FAILED — $failed check(s) failed, release BLOCKED${N}"
  exit 1
fi
echo "${G}${B}✅ SECURITY GATE PASSED — ${#RESULT_NAMES[@]} checks green, release allowed${N}"
