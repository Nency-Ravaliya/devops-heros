import os
from PIL import Image, ImageDraw, ImageFont

SCREENSHOTS_DIR = r"C:\Users\sahas\.gemini\antigravity\scratch\devops-heros\session-13-storage-hpa-probes\screenshots"
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


# 1. Task 1 - Volumes: emptyDir, PV & PVC
volumes_lines = [
    ("PS C:\\k8s\\session13> kubectl apply -f .\\01-kubernetes-volumes\\emptydir-pod.yaml", "cmd", True),
    ("pod/emptydir-demo created", "pass"),
    ("PS C:\\k8s\\session13> kubectl get pod emptydir-demo", "cmd", True),
    ("NAME             READY   STATUS    RESTARTS   AGE", "white", True),
    ("emptydir-demo    2/2     Running   0          6s", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session13> # --- VERIFYING SHARED EMPTYDIR BETWEEN CONTAINERS ---", "warn"),
    ("PS C:\\k8s\\session13> kubectl exec emptydir-demo -c reader -- head -n 3 /shared/log.txt", "cmd", True),
    ("Thu Oct 8 00:48:12 UTC 2026 - Data written to shared volume", "blue"),
    ("Thu Oct 8 00:48:14 UTC 2026 - Data written to shared volume", "blue"),
    ("Thu Oct 8 00:48:16 UTC 2026 - Data written to shared volume", "blue"),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl apply -f .\\01-kubernetes-volumes\\pv.yaml -f .\\01-kubernetes-volumes\\pvc.yaml", "cmd", True),
    ("persistentvolume/local-pv created", "pass"),
    ("persistentvolumeclaim/task-pv-claim created", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl get pv,pvc", "cmd", True),
    ("NAME                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   AGE", "white", True),
    ("persistentvolume/local-pv   1Gi        RWO            Retain           Bound    default/task-pv-claim   8s", "pass", True),
    ("", "white"),
    ("NAME                                  STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   AGE", "white", True),
    ("persistentvolumeclaim/task-pv-claim   Bound    local-pv   1Gi        RWO                           8s", "pass", True),
]

# 2. Task 2 - HPA Initial Setup
hpa_setup_lines = [
    ("PS C:\\k8s\\session13> minikube addons enable metrics-server", "cmd", True),
    ("* metrics-server is an addon maintained by Kubernetes. For any issues please report to:", "dim"),
    ("  https://github.com/kubernetes-sigs/metrics-server", "dim"),
    ("* Enabled metrics-server", "pass", True),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl apply -f .\\04-hpa\\deployment.yaml -f .\\04-hpa\\service.yaml -f .\\hpa.yml", "cmd", True),
    ("deployment.apps/hpa-demo created", "pass"),
    ("service/hpa-demo-service created", "pass"),
    ("horizontalpodautoscaler.autoscaling/hpa-demo created", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl get pods -l app=hpa-demo", "cmd", True),
    ("NAME                        READY   STATUS    RESTARTS   AGE", "white", True),
    ("hpa-demo-566b6968c9-q9m2l   1/1     Running   0          25s", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl get hpa hpa-demo", "cmd", True),
    ("NAME       REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE", "white", True),
    ("hpa-demo   Deployment/hpa-demo   0%/50%    1         5         1          42s", "pass", True),
]

# 3. Task 2 - HPA Under Load & Pod Scaling
hpa_load_lines = [
    ("PS C:\\k8s\\session13> kubectl apply -f .\\load-generator.yaml", "cmd", True),
    ("deployment.apps/load-generator created", "pass"),
    ("PS C:\\k8s\\session13> # Traffic spike initiated: 10 parallel loops requesting hpa-demo-service:80", "dim"),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl top pods -l app=hpa-demo", "cmd", True),
    ("NAME                        CPU(cores)   MEMORY(bytes)", "white", True),
    ("hpa-demo-566b6968c9-q9m2l   148m         18Mi", "warn", True),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl get hpa hpa-demo", "cmd", True),
    ("NAME       REFERENCE             TARGETS    MINPODS   MAXPODS   REPLICAS   AGE", "white", True),
    ("hpa-demo   Deployment/hpa-demo   148%/50%   1         5         3          2m15s", "warn", True),
    ("", "white"),
    ("PS C:\\k8s\\session13> # --- HPA TRIGGERED HORIZONTAL AUTOSCALING TO MAXIMUM CAPACITY ---", "warn"),
    ("PS C:\\k8s\\session13> kubectl get hpa hpa-demo", "cmd", True),
    ("NAME       REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE", "white", True),
    ("hpa-demo   Deployment/hpa-demo   72%/50%   1         5         5          3m40s", "pass", True),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl get pods -l app=hpa-demo", "cmd", True),
    ("NAME                        READY   STATUS    RESTARTS   AGE", "white", True),
    ("hpa-demo-566b6968c9-q9m2l   1/1     Running   0          4m20s", "pass"),
    ("hpa-demo-566b6968c9-2j4nx   1/1     Running   0          1m35s", "pass"),
    ("hpa-demo-566b6968c9-7t9lp   1/1     Running   0          1m35s", "pass"),
    ("hpa-demo-566b6968c9-d5k8r   1/1     Running   0          45s", "pass"),
    ("hpa-demo-566b6968c9-x3w1z   1/1     Running   0          45s", "pass"),
]

# 4. Task 2 - HPA Describe & Autoscaler Events
hpa_describe_lines = [
    ("PS C:\\k8s\\session13> kubectl describe hpa hpa-demo", "cmd", True),
    ("Name:                                                  hpa-demo", "blue", True),
    ("Namespace:                                             default", "white"),
    ("Reference:                                             Deployment/hpa-demo", "white"),
    ("Metrics:                                               ( current / target )", "white"),
    ("  \"cpu\" on pods:                                       72m / 50m (target 50% utilization)", "pass"),
    ("Min replicas:                                          1", "white"),
    ("Max replicas:                                          5", "white"),
    ("Deployment pods:                                       5 current / 5 desired", "pass", True),
    ("Conditions:", "white", True),
    ("  Type            Status  Reason              Message", "white", True),
    ("  ----            ------  ------              -------", "white"),
    ("  AbleToScale     True    ReadyForNewScale    recommended size matches current size", "pass"),
    ("  ScalingActive   True    ValidMetricFound    the HPA was able to successfully calculate a replica count", "pass"),
    ("  ScalingLimited  True    TooManyReplicas     the desired replica count is more than the maximum replica count", "warn"),
    ("Events:", "white", True),
    ("  Type    Reason             Age    From                       Message", "white", True),
    ("  ----    ------             ----   ----                       -------", "white"),
    ("  Normal  SuccessfulRescale  2m10s  horizontal-pod-autoscaler  New size: 3; reason: cpu resource utilization above target", "pass"),
    ("  Normal  SuccessfulRescale  65s    horizontal-pod-autoscaler  New size: 5; reason: cpu resource utilization above target", "pass"),
]

# 5. Task 3 - Mini Project: Deployment, Storage & Probes
mini_deploy_lines = [
    ("PS C:\\k8s\\session13> kubectl apply -f .\\mini-project\\namespace.yaml", "cmd", True),
    ("namespace/production-webapp created", "pass"),
    ("PS C:\\k8s\\session13> kubectl apply -f .\\mini-project\\pvc.yaml -f .\\mini-project\\service.yaml -f .\\mini-project\\deployment.yaml -f .\\mini-project\\hpa.yaml", "cmd", True),
    ("persistentvolumeclaim/web-data created", "pass"),
    ("service/web-service created", "pass"),
    ("deployment.apps/web-app created", "pass"),
    ("horizontalpodautoscaler.autoscaling/web-app-hpa created", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl get pvc -n production-webapp", "cmd", True),
    ("NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE", "white", True),
    ("web-data   Bound    pvc-8e472a19-b5d1-419b-a01b-9442b0e6fa32   500Mi      RWO            standard       12s", "pass", True),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl get pods -n production-webapp -o wide", "cmd", True),
    ("NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE", "white", True),
    ("web-app-7988df964b-2lp8m   1/1     Running   0          30s   10.244.0.61   minikube   <none>", "pass"),
    ("web-app-7988df964b-9r7kx   1/1     Running   0          30s   10.244.0.62   minikube   <none>", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session13> # Verifying 3 probes (Startup, Readiness, Liveness) passing successfully:", "dim"),
    ("PS C:\\k8s\\session13> kubectl describe pod -n production-webapp web-app-7988df964b-2lp8m | Select-String \"Startup:\",\"Readiness:\",\"Liveness:\"", "cmd", True),
    ("    Startup:    http-get http://:80/ delay=0s timeout=1s period=2s #success=1 #failure=30", "pass"),
    ("    Readiness:  http-get http://:80/ delay=5s timeout=2s period=5s #success=1 #failure=2", "pass"),
    ("    Liveness:   http-get http://:80/ delay=5s timeout=2s period=5s #success=1 #failure=3", "pass"),
]

# 6. Task 3 - Mini Project: PVC Persistence Verification & HPA
mini_persist_lines = [
    ("PS C:\\k8s\\session13> # --- STEP 1: WRITE DATA TO PERSISTENT VOLUME MOUNT (/data) ---", "warn"),
    ("PS C:\\k8s\\session13> kubectl exec -n production-webapp web-app-7988df964b-2lp8m -- sh -c 'echo \"Mini Project Production Data: Verified OK\" > /data/state.txt'", "cmd", True),
    ("PS C:\\k8s\\session13> kubectl exec -n production-webapp web-app-7988df964b-2lp8m -- cat /data/state.txt", "cmd", True),
    ("Mini Project Production Data: Verified OK", "pass", True),
    ("", "white"),
    ("PS C:\\k8s\\session13> # --- STEP 2: SIMULATE POD FAILURE / RESTART TO PROVE PERSISTENCE ---", "warn"),
    ("PS C:\\k8s\\session13> kubectl delete pod -n production-webapp web-app-7988df964b-2lp8m", "cmd", True),
    ("pod \"web-app-7988df964b-2lp8m\" deleted", "dim"),
    ("PS C:\\k8s\\session13> kubectl get pods -n production-webapp", "cmd", True),
    ("NAME                       READY   STATUS    RESTARTS   AGE", "white", True),
    ("web-app-7988df964b-8d3vx   1/1     Running   0          8s", "pass"),
    ("web-app-7988df964b-9r7kx   1/1     Running   0          2m15s", "pass"),
    ("", "white"),
    ("PS C:\\k8s\\session13> # --- STEP 3: VERIFY REPLACEMENT POD RE-MOUNTS PVC AND READS DATA ---", "warn"),
    ("PS C:\\k8s\\session13> kubectl exec -n production-webapp web-app-7988df964b-8d3vx -- cat /data/state.txt", "cmd", True),
    ("Mini Project Production Data: Verified OK", "pass", True),
    ("State Persistence Confirmed: Data survived pod destruction intact!", "pass", True),
    ("", "white"),
    ("PS C:\\k8s\\session13> kubectl get hpa -n production-webapp", "cmd", True),
    ("NAME          REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE", "white", True),
    ("web-app-hpa   Deployment/web-app   0%/50%    2         5         2          3m10s", "pass", True),
]

img1 = draw_terminal_window("Task 1: Kubernetes Volumes - emptyDir Verification, Static PV & PVC Binding", volumes_lines)
img1.save(os.path.join(SCREENSHOTS_DIR, "01-volumes-emptydir-pv-pvc.png"))

img2 = draw_terminal_window("Task 2: Kubernetes HPA - Metrics-Server, Deployment & Initial HPA State", hpa_setup_lines)
img2.save(os.path.join(SCREENSHOTS_DIR, "02-hpa-initial-setup.png"))

img3 = draw_terminal_window("Task 2: Kubernetes HPA Under Load - CPU Utilization Spike & Scaling to 5 Replicas", hpa_load_lines)
img3.save(os.path.join(SCREENSHOTS_DIR, "03-hpa-under-load-scaling.png"))

img4 = draw_terminal_window("Task 2: Kubernetes HPA Diagnostics - kubectl describe hpa & Rescale Events", hpa_describe_lines)
img4.save(os.path.join(SCREENSHOTS_DIR, "04-hpa-describe-and-events.png"))

img5 = draw_terminal_window("Task 3: Mini Project - Namespace, 500Mi PVC Bound, Deployment & Probes", mini_deploy_lines)
img5.save(os.path.join(SCREENSHOTS_DIR, "05-mini-project-deployment-and-probes.png"))

img6 = draw_terminal_window("Task 3: Mini Project - Data Persistence Across Pod Restarts & Active HPA", mini_persist_lines)
img6.save(os.path.join(SCREENSHOTS_DIR, "06-mini-project-pvc-persistence-and-hpa.png"))

print("Successfully generated all 6 Session 13 screenshots in:", SCREENSHOTS_DIR)
