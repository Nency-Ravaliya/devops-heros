#!/usr/bin/env bash
set -euo pipefail
minikube stop -p session21
minikube start -p minikube
# Restore the workloads paused for the Session 21 demo.
kubectl scale deployment/argocd-applicationset-controller -n argocd --replicas=1
kubectl scale deployment/argocd-dex-server -n argocd --replicas=1
kubectl scale deployment/argocd-notifications-controller -n argocd --replicas=1
kubectl scale deployment/argocd-redis -n argocd --replicas=1
kubectl scale deployment/argocd-repo-server -n argocd --replicas=1
kubectl scale deployment/argocd-server -n argocd --replicas=1
kubectl scale statefulset/argocd-application-controller -n argocd --replicas=1
kubectl scale deployment/opspulse-backend -n opspulse --replicas=6
kubectl scale deployment/opspulse-frontend -n opspulse --replicas=2
kubectl scale statefulset/opspulse-postgres -n opspulse --replicas=1
kubectl patch application opspulse -n argocd --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
