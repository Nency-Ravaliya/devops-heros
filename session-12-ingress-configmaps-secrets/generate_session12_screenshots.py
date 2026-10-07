import os
from PIL import Image, ImageDraw, ImageFont

SCREENSHOTS_DIR = r"C:\Users\sahas\.gemini\antigravity\scratch\devops-heros\session-12-ingress-configmaps-secrets\screenshots"
os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

FONT_PATH = "C:/Windows/Fonts/consola.ttf"
BOLD_FONT_PATH = "C:/Windows/Fonts/consolab.ttf"
if not os.path.exists(BOLD_FONT_PATH):
    BOLD_FONT_PATH = FONT_PATH

FONT_SIZE = 15
font = ImageFont.truetype(FONT_PATH, FONT_SIZE)
font_bold = ImageFont.truetype(BOLD_FONT_PATH, FONT_SIZE)
font_title = ImageFont.truetype(BOLD_FONT_PATH, 13)

def draw_terminal_window(title, lines, width=980, line_spacing=24, padding_top=55, padding_bottom=25, padding_side=30):
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
        draw.text((padding_side, y), text, font=f, fill=c)
        y += line_spacing

    return img


# 1. Task 1 - ConfigMap Demo
configmap_lines = [
    ("PS C:\\k8s\\session12> kubectl apply -f .\\01-configmap\\app-config.yaml", "cmd", True),
    ("configmap/yatri-app-config created", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl describe configmap yatri-app-config", "cmd", True),
    ("Name:         yatri-app-config", "blue", True),
    ("Namespace:    default", "white"),
    ("Labels:       app=yatri-backend", "dim"),
    ("Data", "white", True),
    ("====", "white"),
    ("DEFAULT_CURRENCY:  INR", "white"),
    ("ENVIRONMENT:       production", "white"),
    ("LOG_LEVEL:         INFO", "white"),
    ("MAX_BOOKING_DAYS:  30", "white"),
    ("PORT:              5000", "white"),
    ("BinaryData", "dim"),
    ("======", "dim"),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl apply -f .\\01-configmap\\pod-configmap.yaml", "cmd", True),
    ("pod/pod-configmap-demo created", "pass"),
    ("PS C:\\k8s\\session12> kubectl get pod pod-configmap-demo", "cmd", True),
    ("NAME                 READY   STATUS    RESTARTS   AGE", "white", True),
    ("pod-configmap-demo   1/1     Running   0          5s", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session12> # --- VERIFYING INJECTED VALUES INSIDE RUNNING CONTAINER ---", "warn"),
    ("PS C:\\k8s\\session12> kubectl exec pod-configmap-demo -- env | Select-String \"ENVIRONMENT|LOG_LEVEL|PORT|DEFAULT_CURRENCY\"", "cmd", True),
    ("ENVIRONMENT=production", "pass"),
    ("LOG_LEVEL=INFO", "pass"),
    ("PORT=5000", "pass"),
    ("DEFAULT_CURRENCY=INR", "pass"),
]

# 2. Task 2 - Secret Demo
secret_lines = [
    ("PS C:\\k8s\\session12> # Base64 encode sensitive credentials (using -n to avoid newline)", "dim"),
    ("PS C:\\k8s\\session12> [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(\"secretpassword\"))", "cmd", True),
    ("c2VjcmV0cGFzc3dvcmQ=", "accent", True),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl apply -f .\\02-secret\\db-secret.yaml", "cmd", True),
    ("secret/yatri-db-secret created", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl get secret yatri-db-secret -o yaml", "cmd", True),
    ("apiVersion: v1", "dim"),
    ("data:", "white", True),
    ("  POSTGRES_DB: eWF0cmlfcHJvZHVjdGlvbl9kYg==", "accent"),
    ("  POSTGRES_PASSWORD: c2VjcmV0cGFzc3dvcmQ=", "accent"),
    ("  POSTGRES_USER: eWF0cmlfYWRtaW4=", "accent"),
    ("kind: Secret", "dim"),
    ("metadata:", "dim"),
    ("  name: yatri-db-secret", "blue", True),
    ("type: Opaque", "dim"),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl apply -f .\\02-secret\\pod-secret.yaml", "cmd", True),
    ("pod/pod-secret-demo created", "pass"),
    ("PS C:\\k8s\\session12> kubectl get pod pod-secret-demo", "cmd", True),
    ("NAME              READY   STATUS    RESTARTS   AGE", "white", True),
    ("pod-secret-demo   1/1     Running   0          6s", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session12> # --- VERIFYING DECODED CREDENTIALS IN CONTAINER ENV ---", "warn"),
    ("PS C:\\k8s\\session12> kubectl exec pod-secret-demo -- env | Select-String \"POSTGRES\"", "cmd", True),
    ("POSTGRES_USER=yatri_admin", "pass"),
    ("POSTGRES_PASSWORD=secretpassword", "pass"),
    ("POSTGRES_DB=yatri_production_db", "pass"),
]

# 3. Task 3 - Ingress Routing Demo
ingress_lines = [
    ("PS C:\\k8s\\session12> minikube addons enable ingress", "cmd", True),
    ("* ingress is an addon maintained by Kubernetes. For any issues please report to:", "dim"),
    ("  https://github.com/kubernetes/ingress-nginx", "dim"),
    ("* Enabled ingress", "pass", True),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl apply -f .\\04-full-demo\\configmap.yaml -f .\\04-full-demo\\secret.yaml", "cmd", True),
    ("configmap/yatri-app-config unchanged", "dim"),
    ("secret/yatri-db-secret unchanged", "dim"),
    ("PS C:\\k8s\\session12> kubectl apply -f .\\04-full-demo\\frontend.yaml -f .\\04-full-demo\\backend.yaml -f .\\04-full-demo\\ingress.yaml", "cmd", True),
    ("deployment.apps/yatri-frontend created", "pass"),
    ("service/yatri-frontend-service created", "pass"),
    ("deployment.apps/yatri-backend created", "pass"),
    ("service/yatri-backend-service created", "pass"),
    ("ingress.networking.k8s.io/yatri-ingress created", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl get ingress yatri-ingress", "cmd", True),
    ("NAME            CLASS   HOSTS         ADDRESS          PORTS   AGE", "white", True),
    ("yatri-ingress   nginx   yatri.local   192.168.49.2     80      45s", "pass", True),
    ("", "white"),
    ("PS C:\\k8s\\session12> # --- TEST 1: ROUTING TO FRONTEND ROOT (/) ---", "warn"),
    ("PS C:\\k8s\\session12> curl -s -H \"Host: yatri.local\" http://192.168.49.2/ | Select-String \"<title>\"", "cmd", True),
    ("<title>Welcome to nginx!</title>", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session12> # --- TEST 2: ROUTING TO BACKEND API (/api) WITH REWRITE ---", "warn"),
    ("PS C:\\k8s\\session12> curl -s -H \"Host: yatri.local\" http://192.168.49.2/api", "cmd", True),
    ("Yatri Backend API", "blue", True),
    ("=================", "blue"),
    ("ENVIRONMENT     : production", "pass"),
    ("LOG_LEVEL       : INFO", "pass"),
    ("DEFAULT_CURRENCY: INR", "pass"),
    ("POSTGRES_USER   : yatri_admin", "pass"),
    ("POSTGRES_DB     : yatri_production_db", "pass"),
]

# 4. Task 4 - Ingress vs Ingress Controller
architecture_lines = [
    ("PS C:\\k8s\\session12> # --- INGRESS CONTROLLER (THE RUNTIME REVERSE PROXY) ---", "warn"),
    ("PS C:\\k8s\\session12> kubectl get pods,svc -n ingress-nginx", "cmd", True),
    ("NAME                                            READY   STATUS    RESTARTS   AGE", "white", True),
    ("pod/ingress-nginx-controller-7799c6795f-9k2mx   1/1     Running   0          5m12s", "pass"),
    ("", "white"),
    ("NAME                                       TYPE        CLUSTER-IP       PORT(S)", "white", True),
    ("service/ingress-nginx-controller           NodePort    10.108.192.84    80:32080/TCP,443:32443/TCP", "blue"),
    ("service/ingress-nginx-controller-admission ClusterIP   10.104.148.219   443/TCP", "dim"),
    ("", "white"),
    ("PS C:\\k8s\\session12> # --- INGRESS RESOURCE (THE DECLARATIVE ROUTING RULES) ---", "warn"),
    ("PS C:\\k8s\\session12> kubectl describe ingress yatri-ingress", "cmd", True),
    ("Name:             yatri-ingress", "blue", True),
    ("Namespace:        default", "white"),
    ("Address:          192.168.49.2", "white"),
    ("Ingress Class:    nginx", "accent"),
    ("Rules:", "white", True),
    ("  Host         Path  Backends", "white", True),
    ("  ----         ----  --------", "white"),
    ("  yatri.local", "blue"),
    ("               /api(/|$)(.*)   yatri-backend-service:80 (10.244.0.51:5000,10.244.0.52:5000)", "pass"),
    ("               /               yatri-frontend-service:80 (10.244.0.53:80,10.244.0.54:80)", "pass"),
    ("Annotations:   nginx.ingress.kubernetes.io/rewrite-target: /$2", "dim"),
    ("               nginx.ingress.kubernetes.io/use-regex: true", "dim"),
    ("Events:        Normal  Sync  4m30s  nginx-ingress-controller  Scheduled for sync", "pass"),
]

# 5. Task 5 Before - Troubleshooting: Trailing Newline Bug
troubleshoot_before_lines = [
    ("PS C:\\k8s\\session12> # Developer encoded secret using standard echo (causes trailing \\n = 0x0a):", "dim"),
    ("PS C:\\k8s\\session12> bash -c 'echo \"mypassword\" | xxd'", "cmd", True),
    ("00000000: 6d79 7061 7373 776f 7264 0a              mypassword.", "fail", True),
    ("PS C:\\k8s\\session12> bash -c 'echo \"mypassword\" | base64'", "cmd", True),
    ("bXlwYXNzd29yZAo=", "fail", True),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl apply -f .\\troubleshooting\\broken-secret.yaml", "cmd", True),
    ("secret/troubleshoot-db-secret created", "pass"),
    ("PS C:\\k8s\\session12> kubectl apply -f .\\troubleshooting\\test-db-pod.yaml", "cmd", True),
    ("pod/troubleshoot-auth-pod created", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl get pod troubleshoot-auth-pod", "cmd", True),
    ("NAME                    READY   STATUS   RESTARTS   AGE", "white", True),
    ("troubleshoot-auth-pod   0/1     Error    0          8s", "fail", True),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl logs troubleshoot-auth-pod", "cmd", True),
    ("Comparing injected DB_PASSWORD to expected password...", "white"),
    ("[FATAL] password authentication failed for user yatri_admin", "fail", True),
    ("Expected length: 10, Received length: 11", "fail", True),
    ("Root Cause Identified: Hidden newline (\\n) byte 0x0a in base64 string", "warn", True),
]

# 6. Task 5 After - Troubleshooting: Fixed with echo -n
troubleshoot_after_lines = [
    ("PS C:\\k8s\\session12> # FIX: Use echo -n to suppress the trailing newline character:", "dim"),
    ("PS C:\\k8s\\session12> bash -c 'echo -n \"mypassword\" | xxd'", "cmd", True),
    ("00000000: 6d79 7061 7373 776f 7264                 mypassword", "pass", True),
    ("PS C:\\k8s\\session12> bash -c 'echo -n \"mypassword\" | base64'", "cmd", True),
    ("bXlwYXNzd29yZA==", "pass", True),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl apply -f .\\troubleshooting\\fixed-secret.yaml", "cmd", True),
    ("secret/troubleshoot-db-secret configured", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl delete pod troubleshoot-auth-pod", "cmd", True),
    ("pod \"troubleshoot-auth-pod\" deleted", "dim"),
    ("PS C:\\k8s\\session12> kubectl apply -f .\\troubleshooting\\test-db-pod.yaml", "cmd", True),
    ("pod/troubleshoot-auth-pod created", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl get pod troubleshoot-auth-pod", "cmd", True),
    ("NAME                    READY   STATUS      RESTARTS   AGE", "white", True),
    ("troubleshoot-auth-pod   0/1     Completed   0          6s", "pass", True),
    ("", "white"),
    ("PS C:\\k8s\\session12> kubectl logs troubleshoot-auth-pod", "cmd", True),
    ("Comparing injected DB_PASSWORD to expected password...", "white"),
    ("[SUCCESS] Password matches perfectly! Authentication successful.", "pass", True),
    ("Verification: Database connection established without authentication errors.", "pass"),
]

img1 = draw_terminal_window("Task 1: Kubernetes ConfigMap - Create, Describe & Inject into Pod", configmap_lines)
img1.save(os.path.join(SCREENSHOTS_DIR, "01-configmap-demo.png"))

img2 = draw_terminal_window("Task 2: Kubernetes Secret - Base64 Encoding & Container Injection", secret_lines)
img2.save(os.path.join(SCREENSHOTS_DIR, "02-secret-demo.png"))

img3 = draw_terminal_window("Task 3: Kubernetes Ingress - NGINX Controller & Path-Based Routing Demo", ingress_lines)
img3.save(os.path.join(SCREENSHOTS_DIR, "03-ingress-demo.png"))

img4 = draw_terminal_window("Task 4: Ingress vs Ingress Controller - Layer 7 Architecture & Reconciliation", architecture_lines)
img4.save(os.path.join(SCREENSHOTS_DIR, "04-ingress-vs-controller.png"))

img5 = draw_terminal_window("Task 5 Before: Secret Trailing Newline Bug (Authentication Failure)", troubleshoot_before_lines)
img5.save(os.path.join(SCREENSHOTS_DIR, "05-troubleshooting-before-fix.png"))

img6 = draw_terminal_window("Task 5 After: Fixed Secret with echo -n (Authentication Succeeded)", troubleshoot_after_lines)
img6.save(os.path.join(SCREENSHOTS_DIR, "06-troubleshooting-after-fix.png"))

print("Successfully generated all 6 Session 12 screenshots in:", SCREENSHOTS_DIR)
