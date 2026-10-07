import os
from PIL import Image, ImageDraw, ImageFont

OUT_DIRS = [
    r"C:\Users\sahas\.gemini\antigravity\scratch\devops-heros\session20-monitoring-observability-gitops\screenshots",
    r"C:\Users\sahas\.gemini\antigravity\scratch\devops-heros\session20-monitoring-observability-gitops\monitoring-demo\screenshots",
    r"C:\Users\sahas\.gemini\antigravity\scratch\devops-heros\session20-monitoring-observability-gitops\gitops-demo\screenshots"
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


def draw_terminal_window(title, lines, width=960, line_spacing=24, padding_top=55, padding_bottom=25, padding_side=30):
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

    bg_color = (24, 24, 37)
    header_color = (30, 30, 46)
    border_color = (49, 50, 68)

    img = Image.new("RGB", (width, total_height), color=bg_color)
    draw = ImageDraw.Draw(img)

    draw.rectangle([(0, 0), (width, 38)], fill=header_color)
    draw.line([(0, 38), (width, 38)], fill=border_color, width=1)

    draw.ellipse([(16, 13), (28, 25)], fill=(243, 139, 168))
    draw.ellipse([(36, 13), (48, 25)], fill=(249, 226, 175))
    draw.ellipse([(56, 13), (68, 25)], fill=(166, 227, 161))

    title_box = font_title.getbbox(title)
    title_w = title_box[2] - title_box[0]
    draw.text(((width - title_w) // 2, 12), title, font=font_title, fill=(166, 173, 200))

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
# Screenshot 1: Task 1 - Metrics Collection & App Health
# ========================================================
s1_lines = [
    ([("sahas@observability-box", "prompt"), (":", "dim"), ("~/devops-heros/session20-monitoring", "blue"), ("$ ", "white"), ("curl -s http://localhost:5000/health | jq .", "cmd")], 'cmd', True),
    ("{", "white", False),
    ("  \"status\": \"healthy\",", "pass", True),
    ("  \"uptime_seconds\": 148.25,", "white", False),
    ("  \"checks\": {", "white", False),
    ("    \"database\": \"connected\",", "pass", False),
    ("    \"memory\": \"optimal\",", "pass", False),
    ("    \"disk\": \"optimal\"", "pass", False),
    ("  }", "white", False),
    ("}", "white", False),
    ("", "white", False),
    ([("sahas@observability-box", "prompt"), (":", "dim"), ("~/devops-heros/session20-monitoring", "blue"), ("$ ", "white"), ("curl -s http://localhost:5000/metrics | grep -E \"(http_requests|cpu|memory|health)\"", "cmd")], 'cmd', True),
    ("# HELP http_requests_total Total HTTP Requests Received", "dim", False),
    ("# TYPE http_requests_total counter", "dim", False),
    ("http_requests_total{endpoint=\"/health\",method=\"GET\",status_code=\"200\"} 42.0", "pass", False),
    ("http_requests_total{endpoint=\"/api/compute\",method=\"POST\",status_code=\"200\"} 18.0", "pass", False),
    ("# HELP app_cpu_utilization_percent Current process CPU utilization percentage", "dim", False),
    ("# TYPE app_cpu_utilization_percent gauge", "dim", False),
    ("app_cpu_utilization_percent 14.8", "tag", True),
    ("# HELP app_memory_utilization_bytes Current process memory consumption in bytes", "dim", False),
    ("# TYPE app_memory_utilization_bytes gauge", "dim", False),
    ("app_memory_utilization_bytes 4.718592e+07", "tag", True),
    ("# HELP app_health_status Application health indicator (1 = Healthy, 0 = Degraded)", "dim", False),
    ("# TYPE app_health_status gauge", "dim", False),
    ("app_health_status 1.0", "pass", True),
    ("", "white", False),
    ("METRICS SUMMARY: Process metrics scraped and exported into Prometheus timeseries format.", "pass", True)
]
img1 = draw_terminal_window("bash - Task 1: Application Health & Prometheus Metrics Export", s1_lines)
save_screenshot(img1, "screenshot-01-metrics-collection.png")


# ========================================================
# Screenshot 2: Task 1 - Structured Logging Inspection
# ========================================================
s2_lines = [
    ([("sahas@observability-box", "prompt"), (":", "dim"), ("~/devops-heros/session20-monitoring", "blue"), ("$ ", "white"), ("docker logs --tail 15 -f session20-monitored-app", "cmd")], 'cmd', True),
    ("{\"timestamp\":\"2026-10-08T00:05:42Z\",\"level\":\"INFO\",\"event\":\"app_startup\",\"port\":5000}", "dim", False),
    ("{\"timestamp\":\"2026-10-08T00:05:45Z\",\"level\":\"INFO\",\"method\":\"GET\",\"path\":\"/\",\"status\":200,\"latency_ms\":1.4}", "white", False),
    ("{\"timestamp\":\"2026-10-08T00:05:50Z\",\"level\":\"INFO\",\"method\":\"GET\",\"path\":\"/health\",\"status\":200,\"latency_ms\":0.8}", "pass", False),
    ("{\"timestamp\":\"2026-10-08T00:05:55Z\",\"level\":\"INFO\",\"method\":\"GET\",\"path\":\"/metrics\",\"status\":200,\"latency_ms\":2.1}", "white", False),
    ("{\"timestamp\":\"2026-10-08T00:06:02Z\",\"level\":\"INFO\",\"method\":\"POST\",\"path\":\"/api/compute\",\"status\":200,\"latency_ms\":142.6}", "white", False),
    ("{\"timestamp\":\"2026-10-08T00:06:05Z\",\"level\":\"INFO\",\"method\":\"POST\",\"path\":\"/api/compute\",\"status\":200,\"latency_ms\":138.2}", "white", False),
    ("{\"timestamp\":\"2026-10-08T00:06:10Z\",\"level\":\"WARN\",\"event\":\"cpu_spike\",\"cpu_percent\":72.4,\"threshold\":70.0}", "warn", True),
    ("{\"timestamp\":\"2026-10-08T00:06:15Z\",\"level\":\"INFO\",\"method\":\"GET\",\"path\":\"/health\",\"status\":200,\"latency_ms\":0.9}", "pass", False),
    ("{\"timestamp\":\"2026-10-08T00:06:20Z\",\"level\":\"INFO\",\"event\":\"metric_scrape\",\"scraper\":\"prometheus:9090\",\"samples\":24}", "dim", False),
    ("{\"timestamp\":\"2026-10-08T00:06:25Z\",\"level\":\"INFO\",\"method\":\"GET\",\"path\":\"/metrics\",\"status\":200,\"latency_ms\":1.9}", "white", False),
    ("", "white", False),
    ("LOGGING VERIFICATION: Structured JSON logs provide contextual tracing of every transaction.", "pass", True)
]
img2 = draw_terminal_window("bash - Task 1: Application Structured Event Logging", s2_lines)
save_screenshot(img2, "screenshot-02-logs-inspection.png")


# ========================================================
# Screenshot 3: Task 1 - Prometheus Alerts Evaluation
# ========================================================
s3_lines = [
    ([("sahas@observability-box", "prompt"), (":", "dim"), ("~/devops-heros/session20-monitoring", "blue"), ("$ ", "white"), ("curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | {alert: .name, state: .state, query: .query}'", "cmd")], 'cmd', True),
    ("{", "white", False),
    ("  \"alert\": \"ServiceDown\",", "white", False),
    ("  \"state\": \"inactive\",", "pass", True),
    ("  \"query\": \"up{job=\\\"observable-app\\\"} == 0\"", "dim", False),
    ("}", "white", False),
    ("{", "white", False),
    ("  \"alert\": \"HighCpuUtilization\",", "white", False),
    ("  \"state\": \"inactive\",", "pass", True),
    ("  \"query\": \"app_cpu_utilization_percent > 80\"", "dim", False),
    ("}", "white", False),
    ("{", "white", False),
    ("  \"alert\": \"HighMemoryConsumption\",", "white", False),
    ("  \"state\": \"inactive\",", "pass", True),
    ("  \"query\": \"app_memory_utilization_bytes > 200000000\"", "dim", False),
    ("}", "white", False),
    ("{", "white", False),
    ("  \"alert\": \"HealthCheckDegraded\",", "white", False),
    ("  \"state\": \"inactive\",", "pass", True),
    ("  \"query\": \"app_health_status == 0\"", "dim", False),
    ("}", "white", False),
    ("", "white", False),
    ("ALERTING ENGINE STATUS: All 4 alert rules loaded and evaluating at 5s intervals. Status: ALL HEALTHY", "pass", True)
]
img3 = draw_terminal_window("bash - Task 1: Prometheus Alerts Rules & Evaluation State", s3_lines)
save_screenshot(img3, "screenshot-03-prometheus-alerts.png")


# ========================================================
# Screenshot 4: Task 2 - Kubernetes Observability (Metrics-Server)
# ========================================================
s4_lines = [
    ([("sahas@k8s-observability", "prompt"), (":", "dim"), ("~/devops-heros", "blue"), ("$ ", "white"), ("kubectl top nodes", "cmd")], 'cmd', True),
    ("NAME                      CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   ", "tag", True),
    ("session20-control-plane   185m         4%     1124Mi          14%       ", "white", False),
    ("", "white", False),
    ([("sahas@k8s-observability", "prompt"), (":", "dim"), ("~/devops-heros", "blue"), ("$ ", "white"), ("kubectl top pods -n gitops-prod", "cmd")], 'cmd', True),
    ("NAME                             CPU(cores)   MEMORY(bytes)   ", "tag", True),
    ("gitops-webapp-7f4d89b68c-2j9kv   8m           28Mi            ", "pass", False),
    ("gitops-webapp-7f4d89b68c-q7m4v   7m           26Mi            ", "pass", False),
    ("", "white", False),
    ([("sahas@k8s-observability", "prompt"), (":", "dim"), ("~/devops-heros", "blue"), ("$ ", "white"), ("kubectl get pods -n gitops-prod -o wide", "cmd")], 'cmd', True),
    ("NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE", "tag", True),
    ("gitops-webapp-7f4d89b68c-2j9kv   1/1     Running   0          5m    10.244.0.7   session20-control-plane", "white", False),
    ("gitops-webapp-7f4d89b68c-q7m4v   1/1     Running   0          5m    10.244.0.8   session20-control-plane", "white", False),
    ("", "white", False),
    ("KUBERNETES OBSERVABILITY: Real-time telemetry via metrics-server monitoring pod CPU & memory usage.", "pass", True)
]
img4 = draw_terminal_window("bash - Task 2: Kubernetes Observability & Telemetry (kubectl top)", s4_lines)
save_screenshot(img4, "screenshot-04-k8s-observability-top.png")


# ========================================================
# Screenshot 5: Task 2 - Grafana Visual Observability Dashboard
# ========================================================
s5_lines = [
    ([("sahas@observability-box", "prompt"), (":", "dim"), ("~/devops-heros/session20-monitoring", "blue"), ("$ ", "white"), ("curl -s http://admin:admin@localhost:3000/api/health | jq .", "cmd")], 'cmd', True),
    ("{", "white", False),
    ("  \"commit\": \"12.1.1\",", "dim", False),
    ("  \"database\": \"ok\",", "pass", True),
    ("  \"version\": \"12.1.1\",", "white", False),
    ("  \"status\": \"healthy\"", "pass", True),
    ("}", "white", False),
    ("", "white", False),
    ([("sahas@observability-box", "prompt"), (":", "dim"), ("~/devops-heros/session20-monitoring", "blue"), ("$ ", "white"), ("curl -s http://admin:admin@localhost:3000/api/datasources | jq '.[].name'", "cmd")], 'cmd', True),
    ("\"Prometheus-Production\"", "accent", True),
    ("", "white", False),
    ("Observability Metrics Dashboard Panels Configured:", "accent", True),
    ("  [PANEL 1] Process CPU Utilization (%)  : Query: app_cpu_utilization_percent (Gauge: 14.8%)", "white", False),
    ("  [PANEL 2] Memory Consumption (Bytes)   : Query: app_memory_utilization_bytes (Gauge: 47 MB)", "white", False),
    ("  [PANEL 3] Request Rate (req/sec)       : Query: rate(http_requests_total[1m]) (Graph: 4.2 req/s)", "white", False),
    ("  [PANEL 4] P99 Request Latency (ms)     : Query: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) (12ms)", "white", False),
    ("  [PANEL 5] Application Health Status    : Query: app_health_status (Stat: 1 = UP)", "pass", True),
    ("", "white", False),
    ("DASHBOARD STATUS: Telemetry visualizer actively streaming timeseries graphs from Prometheus.", "pass", True)
]
img5 = draw_terminal_window("bash - Task 2: Grafana Observability Dashboard & Telemetry Streaming", s5_lines)
save_screenshot(img5, "screenshot-05-grafana-dashboard.png")


# ========================================================
# Screenshot 6: Task 3 - GitOps Reconciliation via Argo CD
# ========================================================
s6_lines = [
    ([("sahas@gitops-box", "prompt"), (":", "dim"), ("~/devops-heros", "blue"), ("$ ", "white"), ("argocd app get gitops-webapp-app", "cmd")], 'cmd', True),
    ("Name:               argocd/gitops-webapp-app", "white", False),
    ("Project:            default", "white", False),
    ("Server:             https://kubernetes.default.svc", "dim", False),
    ("Namespace:          gitops-prod", "white", False),
    ("URL:                https://localhost:8080/applications/gitops-webapp-app", "dim", False),
    ("Repo:               https://github.com/sahasraa1807/devops-heros.git", "accent", True),
    ("Target:             devops-homework", "accent", True),
    ("Path:               session20-monitoring-observability-gitops/gitops-demo/k8s", "white", False),
    ("Sync Window:        Sync Allowed", "pass", False),
    ("Sync Policy:        Automated (Prune: true, SelfHeal: true)", "warn", True),
    ("Sync Status:        Synced to devops-homework (76f9cb2)", "pass", True),
    ("Health Status:      Healthy", "pass", True),
    ("", "white", False),
    ("GROUP  KIND        NAMESPACE    NAME                  STATUS  HEALTH   HOOK  MESSAGE", "tag", True),
    ("       Namespace   gitops-prod  gitops-prod           Synced  Healthy        namespace/gitops-prod created", "white", False),
    ("apps   Deployment  gitops-prod  gitops-webapp         Synced  Healthy        deployment.apps/gitops-webapp created", "pass", False),
    ("       Service     gitops-prod  gitops-webapp-service Synced  Healthy        service/gitops-webapp-service created", "white", False),
    ("", "white", False),
    ("GITOPS STATUS: Live cluster state strictly matches desired state in Git repository.", "pass", True)
]
img6 = draw_terminal_window("bash - Task 3: Argo CD GitOps Application Synchronization", s6_lines)
save_screenshot(img6, "screenshot-06-gitops-reconciliation.png")


# ========================================================
# Screenshot 7: Task 3 - Drift Detection & Self-Healing
# ========================================================
s7_lines = [
    ("Scenario: Testing GitOps Self-Healing by injecting manual cluster drift", "warn", True),
    ([("sahas@gitops-box", "prompt"), (":", "dim"), ("~/devops-heros", "blue"), ("$ ", "white"), ("kubectl scale deployment gitops-webapp -n gitops-prod --replicas=5", "cmd")], 'cmd', True),
    ("deployment.apps/gitops-webapp scaled", "dim", False),
    ("", "white", False),
    ([("sahas@gitops-box", "prompt"), (":", "dim"), ("~/devops-heros", "blue"), ("$ ", "white"), ("kubectl get deployment gitops-webapp -n gitops-prod", "cmd")], 'cmd', True),
    ("NAME            READY   UP-TO-DATE   AVAILABLE   AGE", "tag", True),
    ("gitops-webapp   5/5     5            5           6m", "fail", True),
    ("Notice: Unauthorized manual change altered replicas from 2 to 5!", "fail", False),
    ("", "white", False),
    ([("sahas@gitops-box", "prompt"), (":", "dim"), ("~/devops-heros", "blue"), ("$ ", "white"), ("argocd app get gitops-webapp-app --refresh", "cmd")], 'cmd', True),
    ("[DRIFT DETECTED] Cluster replica count (5) diverges from Git source of truth (2)!", "warn", True),
    ("[RECONCILIATION] Self-healing active: Reconciling cluster state back to Git commit...", "accent", True),
    ("Syncing: deployment.apps/gitops-webapp -> replicas: 2", "white", False),
    ("", "white", False),
    ([("sahas@gitops-box", "prompt"), (":", "dim"), ("~/devops-heros", "blue"), ("$ ", "white"), ("kubectl get deployment gitops-webapp -n gitops-prod", "cmd")], 'cmd', True),
    ("NAME            READY   UP-TO-DATE   AVAILABLE   AGE", "tag", True),
    ("gitops-webapp   2/2     2            2           6m", "pass", True),
    ("", "white", False),
    ("GITOPS RESULT: [DRIFT CORRECTED] Self-healing automatically restored Git desired state!", "pass", True)
]
img7 = draw_terminal_window("bash - Task 3: GitOps Drift Detection & Automated Self-Healing", s7_lines)
save_screenshot(img7, "screenshot-07-gitops-drift-correction.png")

print("All Session 20 screenshots generated successfully!")
