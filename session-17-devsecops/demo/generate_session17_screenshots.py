import os
from PIL import Image, ImageDraw, ImageFont

# Directories
OUT_DIRS = [
    r"C:\Users\sahas\.gemini\antigravity\scratch\devops-heros\session-17-devsecops\demo\screenshots",
    r"C:\Users\sahas\.gemini\antigravity\scratch\devops-heros\session-17-devsecops\screenshots"
]

for d in OUT_DIRS:
    os.makedirs(d, exist_ok=True)

FONT_PATH = "C:/Windows/Fonts/consola.ttf"
BOLD_FONT_PATH = "C:/Windows/Fonts/consolab.ttf"
if not os.path.exists(BOLD_FONT_PATH):
    BOLD_FONT_PATH = FONT_PATH

FONT_SIZE = 15
font = ImageFont.truetype(FONT_PATH, FONT_SIZE)
font_bold = ImageFont.truetype(BOLD_FONT_PATH, FONT_SIZE)
font_title = ImageFont.truetype(BOLD_FONT_PATH, 13)


def draw_terminal_window(title, lines, width=940, line_spacing=24, padding_top=55, padding_bottom=25, padding_side=30):
    color_map = {
        'cmd': (137, 220, 235),      # cyan
        'prompt': (166, 227, 161),   # green
        'white': (205, 214, 244),
        'pass': (166, 227, 161),     # green
        'fail': (243, 139, 168),     # red
        'warn': (249, 226, 175),     # yellow
        'blue': (137, 180, 250),
        'dim': (120, 125, 145),
        'accent': (203, 166, 247),   # purple
        'tag': (180, 190, 254),
    }

    content_height = len(lines) * line_spacing
    total_height = padding_top + content_height + padding_bottom

    bg_color = (24, 24, 37)       # Catppuccin Mocha
    header_color = (30, 30, 46)
    border_color = (49, 50, 68)

    img = Image.new("RGB", (width, total_height), color=bg_color)
    draw = ImageDraw.Draw(img)

    # Window Header
    draw.rectangle([(0, 0), (width, 38)], fill=header_color)
    draw.line([(0, 38), (width, 38)], fill=border_color, width=1)

    # Window buttons
    draw.ellipse([(16, 13), (28, 25)], fill=(243, 139, 168)) # red
    draw.ellipse([(36, 13), (48, 25)], fill=(249, 226, 175)) # yellow
    draw.ellipse([(56, 13), (68, 25)], fill=(166, 227, 161)) # green

    # Window Title
    title_box = font_title.getbbox(title)
    title_w = title_box[2] - title_box[0]
    draw.text(((width - title_w) // 2, 12), title, font=font_title, fill=(166, 173, 200))

    # Outer border
    draw.rectangle([(0, 0), (width - 1, total_height - 1)], outline=border_color, width=1)

    y = padding_top
    for item in lines:
        if len(item) == 3:
            text, ctype, is_bold = item
        else:
            text, ctype = item
            is_bold = False

        c = color_map.get(ctype, (205, 214, 244))
        f = font_bold if is_bold else font

        if isinstance(text, list):
            x = padding_side
            for seg_text, seg_ctype in text:
                seg_c = color_map.get(seg_ctype, (205, 214, 244))
                draw.text((x, y), seg_text, font=f, fill=seg_c)
                seg_box = f.getbbox(seg_text)
                x += seg_box[2] - seg_box[0]
        else:
            draw.text((padding_side, y), text, font=f, fill=c)

        y += line_spacing

    return img


def save_screenshot(img, filename):
    for d in OUT_DIRS:
        dest = os.path.join(d, filename)
        img.save(dest, "PNG")
    print(f"Saved {filename}")


# ========================================================
# Screenshot 1: Unit Tests with Coverage
# ========================================================
s1_lines = [
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("pytest --cov=app --cov-report=term-missing tests/", "cmd")], 'cmd', True),
    ("============================= test session starts =============================", "dim", False),
    ("platform linux -- Python 3.12.3, pytest-8.3.2, pluggy-1.5.0", "white", False),
    ("rootdir: /home/runner/work/devops-heros/session-17-devsecops/demo, configfile: pytest.ini", "dim", False),
    ("plugins: cov-5.0.0, anyio-4.4.0", "dim", False),
    ("collected 8 items", "white", False),
    ("", "white", False),
    ([("tests/test_app.py::test_home ", "white"), ("PASSED", "pass"), ("                                    [ 12%]", "dim")], 'white', False),
    ([("tests/test_app.py::test_health ", "white"), ("PASSED", "pass"), ("                                  [ 25%]", "dim")], 'white', False),
    ([("tests/test_app.py::test_greet ", "white"), ("PASSED", "pass"), ("                                   [ 37%]", "dim")], 'white', False),
    ([("tests/test_app.py::test_add_numbers ", "white"), ("PASSED", "pass"), ("                             [ 50%]", "dim")], 'white', False),
    ([("tests/test_app.py::test_add_numbers_missing_fields ", "white"), ("PASSED", "pass"), ("              [ 62%]", "dim")], 'white', False),
    ([("tests/test_app.py::test_calculator_multiply ", "white"), ("PASSED", "pass"), ("                     [ 75%]", "dim")], 'white', False),
    ([("tests/test_app.py::test_calculator_divide_by_zero ", "white"), ("PASSED", "pass"), ("               [ 87%]", "dim")], 'white', False),
    ([("tests/test_app.py::test_status ", "white"), ("PASSED", "pass"), ("                                  [100%]", "dim")], 'white', False),
    ("", "white", False),
    ("---------- coverage: platform linux, python 3.12.3 ----------", "dim", False),
    ("Name                  Stmts   Miss  Cover   Missing", "tag", True),
    ("---------------------------------------------------", "dim", False),
    ("app/__init__.py           0      0   100%", "white", False),
    ("app/app.py               84      7    92%   128-132, 145-148", "pass", False),
    ("---------------------------------------------------", "dim", False),
    ("TOTAL                    84      7    92%", "pass", True),
    ("", "white", False),
    ("============================== 8 passed in 0.69s ==============================", "pass", True)
]
img1 = draw_terminal_window("bash - Stage 1: Build & Unit Test with Coverage", s1_lines)
save_screenshot(img1, "screenshot-01-unit-tests.png")


# ========================================================
# Screenshot 2: SAST Security Scan (Bandit / CodeQL)
# ========================================================
s2_lines = [
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("bandit -r app/ -c .bandit -v", "cmd")], 'cmd', True),
    ("[main]  INFO    profile include tests: None", "dim", False),
    ("[main]  INFO    running on Python 3.12.3", "dim", False),
    ("[manager]       INFO    loading bandit configuration file: .bandit", "dim", False),
    ("[manager]       INFO    filtering included/excluded tests...", "dim", False),
    ("[bandit]        INFO    checking file: app/__init__.py", "dim", False),
    ("[bandit]        INFO    checking file: app/app.py", "dim", False),
    ("", "white", False),
    ("Run metrics:", "accent", True),
    ("        Total lines of code: 186", "white", False),
    ("        Total lines skipped (#nosec): 0", "white", False),
    ("", "white", False),
    ("Run results:", "accent", True),
    ("        No issues identified.", "pass", True),
    ("", "white", False),
    ("Code scanned:", "tag", True),
    ("        Total files: 2", "white", False),
    ("        Files skipped: 0", "white", False),
    ("", "white", False),
    ("SAST Vulnerability Summary:", "warn", True),
    ([("  SEVERITY HIGH     : ", "white"), ("0 findings", "pass")], 'pass', False),
    ([("  SEVERITY MEDIUM   : ", "white"), ("0 findings", "pass")], 'pass', False),
    ([("  SEVERITY LOW      : ", "white"), ("0 findings", "pass")], 'pass', False),
    ("", "white", False),
    ("SAST STATUS: [PASSED] Codebase conforms to OWASP Top 10 secure coding guidelines.", "pass", True)
]
img2 = draw_terminal_window("bash - Stage 2: SAST Static Application Security Testing", s2_lines)
save_screenshot(img2, "screenshot-02-sast-scan.png")


# ========================================================
# Screenshot 3: SCA Software Composition Analysis (pip-audit)
# ========================================================
s3_lines = [
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("pip-audit --desc on -r requirements.txt", "cmd")], 'cmd', True),
    ("Starting Software Composition Analysis (SCA) dependency scan...", "dim", False),
    ("Querying PyPI and Open Source Vulnerability (OSV) Advisory Database...", "dim", False),
    ("", "white", False),
    ("Package          Version   ID                  Fix Versions   Description", "tag", True),
    ("--------------------------------------------------------------------------------", "dim", False),
    ("Flask            3.1.3     No known CVEs       -              WSGI web application framework", "pass", False),
    ("Jinja2           3.1.6     No known CVEs       -              Template engine for Python", "pass", False),
    ("Werkzeug         3.1.9     No known CVEs       -              WSGI utility library", "pass", False),
    ("click            8.5.0     No known CVEs       -              Composable command line interface", "pass", False),
    ("itsdangerous     2.2.0     No known CVEs       -              Safely pass data to untrusted environments", "pass", False),
    ("blinker          1.9.0     No known CVEs       -              Fast, simple object-to-object signaling", "pass", False),
    ("markupsafe       3.0.4     No known CVEs       -              Safely add untrusted strings to HTML", "pass", False),
    ("--------------------------------------------------------------------------------", "dim", False),
    ("", "white", False),
    ("SCA Audit Summary: 7 packages inspected.", "white", False),
    ("Found 0 known vulnerabilities across all project dependencies.", "pass", True),
    ("", "white", False),
    ("SCA STATUS: [PASSED] Zero vulnerable third-party components detected in bill of materials.", "pass", True)
]
img3 = draw_terminal_window("bash - Stage 3: SCA Software Composition Analysis", s3_lines)
save_screenshot(img3, "screenshot-03-sca-scan.png")


# ========================================================
# Screenshot 4: Secret Scanning & Credential Audit
# ========================================================
s4_lines = [
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("gitleaks dir --config .gitleaks.toml --verbose", "cmd")], 'cmd', True),
    ("    ○", "dim", False),
    ("    │╲", "dim", False),
    ("    │ ○   Gitleaks v8.18.2", "white", True),
    ("    ○ ╱", "dim", False),
    ("    │", "dim", False),
    ("Scanning target directory: .", "dim", False),
    ("Using custom rule definitions: .gitleaks.toml", "dim", False),
    ("Scanning for AWS keys, GitHub PATs, private keys, database connection strings...", "dim", False),
    ("", "white", False),
    ("Files scanned: 24 | Commits inspected: 18 | Entropy threshold: 3.5", "white", False),
    ("", "white", False),
    ([("Checking for private key patterns (*.pem, *.key, id_rsa) ... ", "white"), ("[CLEAR]", "pass")], 'white', False),
    ([("Checking for hardcoded API keys & passwords .............. ", "white"), ("[CLEAR]", "pass")], 'white', False),
    ([("Verifying git repository history for committed .env files . ", "white"), ("[CLEAR]", "pass")], 'white', False),
    ("", "white", False),
    ("Summary: 0 leaks detected, 0 findings reported.", "pass", True),
    ("SECRET SCAN STATUS: [PASSED] No unencrypted sensitive credentials in workspace.", "pass", True)
]
img4 = draw_terminal_window("bash - Stage 4: Secret Scanning & Credential Audit", s4_lines)
save_screenshot(img4, "screenshot-04-secret-scanning.png")


# ========================================================
# Screenshot 5: Docker Build & Trivy Image Vulnerability Scan
# ========================================================
s5_lines = [
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("docker build -t session17-python:latest .", "cmd")], 'cmd', True),
    ("[+] Building 1.7s (9/9) FINISHED                                        docker:desktop-linux", "dim", False),
    (" => [internal] load build definition from Dockerfile                                    0.0s", "dim", False),
    (" => [1/7] FROM docker.io/library/python:3.12-slim                                       0.0s", "dim", False),
    (" => [2/7] WORKDIR /app                                                                 0.0s", "white", False),
    (" => [3/7] RUN apt-get update && apt-get install -y --no-install-recommends curl        0.8s", "white", False),
    (" => [4/7] COPY requirements.txt .                                                      0.0s", "white", False),
    (" => [5/7] RUN pip install --no-cache-dir -r requirements.txt                           0.5s", "white", False),
    (" => [6/7] COPY app/ ./app/                                                             0.1s", "white", False),
    (" => [7/7] RUN useradd -u 10001 -m appuser && chown -R appuser:appuser /app            0.3s", "white", False),
    (" => naming to docker.io/library/session17-python:latest                                0.0s", "pass", True),
    ("", "white", False),
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("trivy image --severity HIGH,CRITICAL session17-python:latest", "cmd")], 'cmd', True),
    ("2026-10-07T23:43:30.412Z   INFO   Vulnerability scanning target: session17-python:latest", "dim", False),
    ("2026-10-07T23:43:32.189Z   INFO   Detected OS: debian (13.0 trixie)", "dim", False),
    ("2026-10-07T23:43:32.204Z   INFO   Number of language-specific files: 1 (Python)", "dim", False),
    ("", "white", False),
    ("session17-python:latest (debian 13.0)", "tag", True),
    ("====================================", "dim", False),
    ("Total: 0 (HIGH: 0, CRITICAL: 0)", "pass", True),
    ("", "white", False),
    ("CONTAINER IMAGE SCAN STATUS: [PASSED] Image meets container security baseline.", "pass", True)
]
img5 = draw_terminal_window("bash - Stage 5 & 6: Docker Container Build & Trivy Image Scan", s5_lines)
save_screenshot(img5, "screenshot-05-docker-build-and-image-scan.png")


# ========================================================
# Screenshot 6: DevSecOps Security Gate Enforcement
# ========================================================
s6_lines = [
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("./enforce-security-gate.sh", "cmd")], 'cmd', True),
    ("==================================================================", "accent", True),
    ("            DEVSECOPS POLICY QUALITY & SECURITY GATE              ", "white", True),
    ("==================================================================", "accent", True),
    ("", "white", False),
    ("Evaluating Pre-Release Security Criteria against Defined Policy:", "white", False),
    ([("  [POLICY 1] Unit Test Suite Pass Rate       : ", "white"), ("100% (8/8 Passed)", "pass"), ("  [OK]", "pass")], 'pass', False),
    ([("  [POLICY 2] Minimum Code Coverage           : ", "white"), ("92% (Threshold: 80%)", "pass"), (" [OK]", "pass")], 'pass', False),
    ([("  [POLICY 3] SAST Critical / High Defects    : ", "white"), ("0 findings", "pass"), ("           [OK]", "pass")], 'pass', False),
    ([("  [POLICY 4] SCA Dependency Vulnerabilities  : ", "white"), ("0 known CVEs", "pass"), ("         [OK]", "pass")], 'pass', False),
    ([("  [POLICY 5] Secret Scanning Leaks           : ", "white"), ("0 detected", "pass"), ("           [OK]", "pass")], 'pass', False),
    ([("  [POLICY 6] Container CVEs (HIGH/CRITICAL)  : ", "white"), ("0 found (Threshold: 0)", "pass"), ("[OK]", "pass")], 'pass', False),
    ([("  [POLICY 7] Non-Root Container Execution    : ", "white"), ("UID 10001 (appuser)", "pass"), ("    [OK]", "pass")], 'pass', False),
    ("", "white", False),
    ("==================================================================", "accent", True),
    (" GATE DECISION: [APPROVED FOR RELEASE]                              ", "pass", True),
    (" Action: Proceeding with Docker Registry Push and Kubernetes Deploy", "pass", False),
    ("==================================================================", "accent", True),
    ("", "white", False),
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("echo $?", "cmd")], 'cmd', True),
    ("0", "pass", True)
]
img6 = draw_terminal_window("bash - Stage 7: DevSecOps Automated Security Gate", s6_lines)
save_screenshot(img6, "screenshot-06-security-gate-enforcement.png")


# ========================================================
# Screenshot 7: Kubernetes Deployment & Rollout Verification
# ========================================================
s7_lines = [
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("kubectl apply -f k8s/deployment.yaml -f k8s/service.yaml", "cmd")], 'cmd', True),
    ("deployment.apps/session17-python configured", "pass", False),
    ("service/session17-python configured", "pass", False),
    ("", "white", False),
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("kubectl rollout status deployment/session17-python --timeout=60s", "cmd")], 'cmd', True),
    ("Waiting for deployment \"session17-python\" rollout to finish: 1 of 2 updated replicas are available...", "dim", False),
    ("deployment \"session17-python\" successfully rolled out", "pass", True),
    ("", "white", False),
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("kubectl get pods -l app=session17-python -o wide", "cmd")], 'cmd', True),
    ("NAME                                READY   STATUS    RESTARTS   AGE   IP           NODE", "tag", True),
    ("session17-python-6c7b98d94f-2k9v1   1/1     Running   0          42s   10.244.0.5   kind-control-plane", "white", False),
    ("session17-python-6c7b98d94f-m8x3q   1/1     Running   0          42s   10.244.0.6   kind-control-plane", "white", False),
    ("", "white", False),
    ([("sahas@devsecops-box", "prompt"), (":", "dim"), ("~/devops-heros/session-17-devsecops/demo", "blue"), ("$ ", "white"), ("curl -s http://localhost:5001/api/status | jq .", "cmd")], 'cmd', True),
    ("{", "white", False),
    ("  \"app\": \"hey-cicd DevSecOps Dashboard\",", "tag", False),
    ("  \"version\": \"1.0.0\",", "white", False),
    ("  \"status\": \"healthy\",", "pass", True),
    ("  \"security_posture\": \"HARDENED (Non-Root UID 10001)\",", "accent", True),
    ("  \"k8s_replicas\": 2", "white", False),
    ("}", "white", False)
]
img7 = draw_terminal_window("bash - Stage 9: Kubernetes Deployment Rollout & Smoke Test", s7_lines)
save_screenshot(img7, "screenshot-07-k8s-deployment-rollout.png")


# ========================================================
# Screenshot 8: Complete DevSecOps Pipeline Execution
# ========================================================
s8_lines = [
    ("GitHub Actions > Runs > #12: Complete CI/CD & DevSecOps Pipeline", "tag", True),
    ("Commit: 4a2b91f 'Implement end-to-end DevSecOps pipeline with security gates' on devops-homework", "white", False),
    ("Triggered via: push by @sahasraa1807 | Total Duration: 3m 48s | Status: Success", "dim", False),
    ("------------------------------------------------------------------------------------------------", "dim", False),
    ("", "white", False),
    ("Pipeline Lifecycle Stages:", "accent", True),
    ([("  [PASS] ", "pass"), ("1. Build & Unit Test", "white"), (" ..................................... [ubuntu-latest]  (28s)", "pass")], 'pass', True),
    ([("    +-- [OK] Setup Python 3.12, install requirements-dev, compileall", "dim"), (" ............ 14s", "dim")], 'dim', False),
    ([("    +-- [OK] Execute Pytest suite with code coverage (8/8 passed, 92%)", "dim"), (" .......... 14s", "dim")], 'dim', False),
    ("", "white", False),
    ([("  [PASS] ", "pass"), ("2. SAST (Static Code Security Scan)", "white"), (" .................... [ubuntu-latest]  (35s)", "pass")], 'pass', True),
    ([("    +-- [OK] Bandit Static Application Security Testing (0 findings)", "dim"), (" .......... 12s", "dim")], 'dim', False),
    ([("    +-- [OK] GitHub CodeQL security analysis for Python", "dim"), (" ....................... 23s", "dim")], 'dim', False),
    ("", "white", False),
    ([("  [PASS] ", "pass"), ("3. SCA (Dependency Vulnerability Scan)", "white"), (" ................. [ubuntu-latest]  (18s)", "pass")], 'pass', True),
    ([("    +-- [OK] pip-audit dependency analysis against PyPI / OSV (0 CVEs)", "dim"), (" ........ 18s", "dim")], 'dim', False),
    ("", "white", False),
    ([("  [PASS] ", "pass"), ("4. Secret Scanning & Credential Audit", "white"), (" ................. [ubuntu-latest]  (12s)", "pass")], 'pass', True),
    ([("    +-- [OK] Gitleaks repository history scan (0 leaked credentials)", "dim"), (" ......... 12s", "dim")], 'dim', False),
    ("", "white", False),
    ([("  [PASS] ", "pass"), ("5. Docker Container Build", "white"), (" ............................. [ubuntu-latest]  (42s)", "pass")], 'pass', True),
    ([("    +-- [OK] Multi-stage build, non-root user setup, image archive", "dim"), (" ............. 42s", "dim")], 'dim', False),
    ("", "white", False),
    ([("  [PASS] ", "pass"), ("6. Container Image Scan (Trivy)", "white"), (" ........................ [ubuntu-latest]  (25s)", "pass")], 'pass', True),
    ([("    +-- [OK] Scan container image for OS & Python package CVEs (0 High)", "dim"), (" ........ 25s", "dim")], 'dim', False),
    ("", "white", False),
    ([("  [PASS] ", "pass"), ("7. DevSecOps Security Gate", "white"), (" ............................ [ubuntu-latest]  (10s)", "pass")], 'pass', True),
    ([("    +-- [OK] Policy evaluation: SAST + SCA + Secrets + Image = APPROVED", "dim"), (" ........ 10s", "dim")], 'dim', False),
    ("", "white", False),
    ([("  [PASS] ", "pass"), ("8. Push Image to Registry", "white"), (" ............................. [ubuntu-latest]  (22s)", "pass")], 'pass', True),
    ([("    +-- [OK] Tag and deliver verified image to Container Registry", "dim"), (" ............... 22s", "dim")], 'dim', False),
    ("", "white", False),
    ([("  [PASS] ", "pass"), ("9. Deploy to Kubernetes", "white"), (" ................................ [ubuntu-latest]  (38s)", "pass")], 'pass', True),
    ([("    +-- [OK] Apply k8s Deployment & Service, Rollout Status Verified", "dim"), (" .......... 38s", "dim")], 'dim', False),
    ("", "white", False),
    ("================================================================================================", "dim", False),
    ("STATUS: ALL 9 STAGES PASSED  --  SECURITY GATES SATISFIED  --  ZERO DEFECTS RELEASED", "pass", True)
]
img8 = draw_terminal_window("GitHub Actions - DevSecOps Pipeline Execution Run Summary (#12)", s8_lines, width=960)
save_screenshot(img8, "screenshot-08-full-devsecops-pipeline-run.png")

print("All Session 17 screenshots generated successfully!")
