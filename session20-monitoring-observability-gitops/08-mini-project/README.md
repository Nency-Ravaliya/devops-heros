# Session 20 GitOps Mini Project

This project keeps the workload YAML in Git and uses Argo CD to reconcile it into Kubernetes.

## Files

```text
08-mini-project/
├── argocd-application.yaml
└── app/
    ├── namespace.yaml
    ├── deployment.yaml
    └── service.yaml
```

The Argo CD Application is intentionally outside `app/`. The watched directory contains only the Namespace, Deployment, and Service.

## Run

```bash
kind create cluster --name session20
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Available deployment --all -n argocd --timeout=240s

kubectl apply -f argocd-application.yaml
kubectl get application session20-mini -n argocd
kubectl get all -n session20
```

The desired replica count is two. To demonstrate GitOps, I change that value in Git and push it, then watch Argo CD update the Deployment. To demonstrate self-healing, I manually scale the live Deployment to one replica. Because Git still declares two, Argo CD restores it.

```bash
kubectl scale deployment session20-mini -n session20 --replicas=1
kubectl get deployment session20-mini -n session20 -w
```

This showed me the practical difference between a pipeline that runs `kubectl apply` once and GitOps: Argo CD keeps comparing the cluster with Git after the original deployment.
