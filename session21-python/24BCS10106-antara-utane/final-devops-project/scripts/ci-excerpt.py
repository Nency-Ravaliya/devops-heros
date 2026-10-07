#!/usr/bin/env python3
"""Extract the interesting lines of a GitHub Actions run log for the README.

    gh run view <id> -R Antara Utane/devops-heros --log > run.log
    python3 scripts/ci-excerpt.py run.log > docs/outputs/ci-run-<id>-excerpts.txt
Lines are copied verbatim (only the per-line timestamp is dropped).
"""
import re
import sys

KEEP = {
    "Run pytest with coverage": r"PASSED|FAILED|TOTAL|passed|failed|app/",
    "Helm lint (all value files)": r"Linting|linted",
    "Semgrep scan": r"Findings|Rules run|Targets scanned|Ran \d+ rules",
    "pip-audit": r"No known vulnerabilities|Found \d+ known",
    "Trivy filesystem scan (dependencies)": r"requirements.txt|Total:",
    "Gitleaks (scoped to project folder)": r"scanned|leaks found|no leaks",
    "Build image (multi-stage, non-root)": r"user=|naming to|exporting manifest",
    "Build image (multi-stage, non-root, amd64+arm64)": r"platform manifests|^linux/|exporting manifest list|\[linux/(amd64|arm64) runtime 5/5\]",
    "Trivy image scan": r"fixable HIGH/CRITICAL|Total:|linux/(amd64|arm64)  sha256",
    "Evaluate policy (block on any HIGH/CRITICAL, SAST finding or secret)": r"-> (PASS|FAIL)",
    "Push scanned image with skopeo": r"Login Succeeded|^manifest linux|\"Tags\"|\"[0-9a-f]{40}\"|sha-|session-21-latest",
    "Create kind cluster": r"Creating cluster|Ready|Set kubectl context",
    "helm upgrade --install": r"STATUS|REVISION|deployed|Release",
    "Rollout status": r"successfully rolled out|stockpilot-|NAME",
    "Smoke test": r"curl|\{\"|stockpilot",
}

ts = re.compile(r"^\d{4}-\d\d-\d\dT[\d:.]+Z ")
ansi = re.compile(r"(\x1b|\^\[)\[[0-9;]*m")
seen_steps = []
out = {}
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    parts = line.rstrip("\n").split("\t", 2)
    if len(parts) != 3:
        continue
    job, step, text = parts
    text = ansi.sub("", ts.sub("", text.lstrip("﻿")))
    pat = KEEP.get(step)
    if not pat or text.startswith(("##[group]", "##[endgroup]", "shell:", "env:")) or text.startswith("  "):
        if not (pat and text.startswith("  ") and re.search(pat, text)):
            continue
    if "echo " in text or "GITHUB_" in text:
        continue
    if re.search(pat, text):
        key = (job, step)
        if key not in out:
            out[key] = []
            seen_steps.append(key)
        out[key].append(text)

for job, step in seen_steps:
    print(f"=== [{job}] {step}")
    for t in out[(job, step)][:40]:
        print("   ", t[:200])
    print()
