# 03 - Kubernetes Deployment

## Objective

Deploy the Docker image stored in GHCR to Kubernetes.

## Kubernetes Manifests

```text
k8s/
├── deployment.yaml
└── service.yaml
```

## deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devsecops-python
spec:
  replicas: 2
  selector:
    matchLabels:
      app: devsecops-python
  template:
    metadata:
      labels:
        app: devsecops-python
    spec:
      containers:
        - name: devsecops-python
          image: ghcr.io/OWNER/REPOSITORY:TAG
          ports:
            - containerPort: 5000
          readinessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 10
            periodSeconds: 20
```

Replace the image with the exact image pushed to GHCR.

## service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: devsecops-python-service
spec:
  type: NodePort
  selector:
    app: devsecops-python
  ports:
    - port: 5000
      targetPort: 5000
      nodePort: 30080
```

## Manual Deployment

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Check:

```bash
kubectl get deployment
kubectl get pods
kubectl get service
```

Test a local cluster:

```bash
kubectl port-forward svc/devsecops-python-service 8080:5000
curl http://localhost:8080/health
```

## Deployment from GitHub Actions

A GitHub-hosted runner needs Kubernetes credentials and network access to the target cluster.

```yaml
deploy:
  name: Deploy to Kubernetes
  needs:
    - push
  runs-on: ubuntu-latest
  environment:
    name: development

  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup kubectl
      uses: azure/setup-kubectl@v4
      with:
        version: latest

    - name: Configure Kubernetes
      run: |
        mkdir -p ~/.kube
        echo "${{ secrets.KUBE_CONFIG }}" | base64 --decode > ~/.kube/config

    - name: Update application image
      run: |
        kubectl set image deployment/devsecops-python \
          devsecops-python=ghcr.io/${{ github.repository }}:${{ github.sha }}

    - name: Wait for rollout
      run: |
        kubectl rollout status deployment/devsecops-python

    - name: Verify deployment
      run: |
        kubectl get deployment devsecops-python
        kubectl get pods
```

`kubectl set image` updates the Deployment's container image and triggers a rolling update. `kubectl rollout status` watches the rollout until it completes. citeturn0search6turn0search1

## Important Classroom Note

A GitHub-hosted runner cannot automatically reach Kubernetes running on a student's laptop through Docker Desktop, Kind, or Minikube.

For the classroom:

```text
GitHub Actions
   ↓
Build + Security + GHCR

Local Kubernetes
   ↓
Manual deployment practice
```

For real automated CD, use a reachable cloud/shared cluster or an appropriately configured self-hosted runner.

## Practice Questions

1. Push the image to GHCR.
2. Deploy it to local Kubernetes.
3. Change the image tag.
4. Run `kubectl set image`.
5. Watch the rollout.
6. Verify the new Pods.
