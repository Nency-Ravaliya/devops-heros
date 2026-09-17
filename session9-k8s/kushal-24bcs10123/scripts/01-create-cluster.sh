#!/usr/bin/env bash
# Session 9 / step 1: create a local multi-node Kubernetes cluster with kind (Kubernetes in Docker).
cd "$(dirname "$0")/.." && . scripts/lib.sh
hr "TOOLS"
x "docker version --format 'Docker {{.Server.Version}} ({{.Server.Os}}/{{.Server.Arch}})'"
x "kind version"
x "kubectl version --client"
hr "CREATE CLUSTER"
x "cat kind-cluster.yaml"
x "kind create cluster --config kind-cluster.yaml"
x "kind get clusters"
x "kubectl config current-context"
x "docker ps --filter label=io.x-k8s.kind.cluster=kushal-lab --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
