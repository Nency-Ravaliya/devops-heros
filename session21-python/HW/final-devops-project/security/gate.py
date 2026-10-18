#!/usr/bin/env python3
"""Security gate: reads every scanner report and fails if policy is violated.

Policy (blocking):
  SAST    bandit  - any HIGH severity issue
  SAST    semgrep - any ERROR severity finding
  SCA     trivy   - any HIGH/CRITICAL vulnerability in requirements.txt / package-lock.json
  SCA     pip-audit - any known vulnerability that has a fixed version
  Secrets gitleaks - any finding
  Image   trivy   - any HIGH/CRITICAL vulnerability (fixable) in the backend or frontend image

A missing or unreadable report also fails the gate, so a scanner that crashed
can never be mistaken for a clean scan.

Usage: python gate.py <reports-dir>
"""
import json
import os
import sys


def load(path):
    with open(path) as fh:
        return json.load(fh)


def trivy_high_critical(report):
    hits = []
    for result in report.get("Results") or []:
        for v in result.get("Vulnerabilities") or []:
            if v.get("Severity") in ("HIGH", "CRITICAL"):
                hits.append(f'{v["PkgName"]} {v.get("InstalledVersion", "")} '
                            f'{v["VulnerabilityID"]} {v["Severity"]} '
                            f'(fixed in {v.get("FixedVersion") or "-"})')
    return hits


def bandit_high(report):
    return [f'{r["filename"]}:{r["line_number"]} {r["test_id"]} {r["issue_text"]}'
            for r in report.get("results", []) if r.get("issue_severity") == "HIGH"]


def semgrep_error(report):
    return [f'{r["path"]}:{r["start"]["line"]} {r["check_id"]}'
            for r in report.get("results", []) if r["extra"].get("severity") == "ERROR"]


def pip_audit_fixable(report):
    hits = []
    for dep in report.get("dependencies", []):
        for v in dep.get("vulns", []):
            if v.get("fix_versions"):
                hits.append(f'{dep["name"]} {dep.get("version", "")} {v["id"]} '
                            f'(fixed in {", ".join(v["fix_versions"])})')
    return hits


def gitleaks_findings(report):
    return [f'{f["File"]}:{f["StartLine"]} {f["RuleID"]}' for f in report]


CHECKS = [
    ("SAST    bandit (HIGH)", "bandit.json", bandit_high),
    ("SAST    semgrep (ERROR)", "semgrep.json", semgrep_error),
    ("SCA     trivy fs (HIGH/CRITICAL)", "trivy-fs.json", trivy_high_critical),
    ("SCA     npm lockfile (HIGH/CRITICAL)", "trivy-fs-frontend.json", trivy_high_critical),
    ("SCA     pip-audit (fixable)", "pip-audit.json", pip_audit_fixable),
    ("SECRETS gitleaks (files)", "gitleaks.json", gitleaks_findings),
    ("SECRETS gitleaks (git history)", "gitleaks-history.json", gitleaks_findings),
    ("IMAGE   backend (HIGH/CRITICAL)", "trivy-image-backend.json", trivy_high_critical),
    ("IMAGE   frontend (HIGH/CRITICAL)", "trivy-image-frontend.json", trivy_high_critical),
]


def main():
    reports_dir = sys.argv[1] if len(sys.argv) > 1 else "reports"
    failed = False
    print(f"{'CHECK':<38} {'RESULT':<8} FINDINGS")
    print("-" * 60)
    details = []
    for name, filename, func in CHECKS:
        path = os.path.join(reports_dir, filename)
        try:
            hits = func(load(path))
        except (OSError, ValueError, KeyError, TypeError) as exc:
            print(f"{name:<38} {'ERROR':<8} report unusable: {exc}")
            failed = True
            continue
        status = "FAIL" if hits else "PASS"
        failed = failed or bool(hits)
        print(f"{name:<38} {status:<8} {len(hits)}")
        details += [f"  [{name.split()[0]}] {h}" for h in hits]
    print("-" * 60)
    if details:
        print("Blocking findings:")
        print("\n".join(details))
    if failed:
        print("SECURITY GATE: FAILED - images will NOT be pushed or deployed")
        return 1
    print("SECURITY GATE: PASSED - images can be pushed and deployed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
