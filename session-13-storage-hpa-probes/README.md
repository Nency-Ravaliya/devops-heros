Session 13 --- Kubernetes HPA Mini Project

A hands-on Kubernetes mini project demonstrating Horizontal Pod
Autoscaling (HPA) and how Kubernetes automatically adjusts application
replicas based on resource utilization.

What this project demonstrates

Running the application inside a Kubernetes cluster

Exposing the application through Kubernetes resources

Configuring and observing a Horizontal Pod Autoscaler

Verifying the initial application state

Observing the HPA configuration and scaling behaviour through
Kubernetes

Screenshots

All screenshots for this mini project are stored in:

screenshots/
├── init.png
├── hpa.png
└── screenshot-2026-09-30-200427.png

Initial State



HPA Configuration / State



Additional Demonstration



Key Kubernetes Concepts

Horizontal Pod Autoscaler

The HPA continuously observes the configured metric and adjusts the
number of replicas of the target workload to move the observed
utilization toward the configured target.

Conceptually:

                Metrics
                   │
                   ▼
             ┌───────────┐
             │    HPA    │
             └─────┬─────┘
                   │
          desired replica count
                   │
                   ▼
             ┌───────────┐
             │ Deployment│
             └─────┬─────┘
                   │
             ┌─────┴─────┐
             ▼           ▼
           Pod         Pod ...

Useful Commands

kubectl get pods
kubectl get deployment
kubectl get hpa
kubectl describe hpa <hpa-name>
kubectl top pods
kubectl top nodes

Learning Outcome

The main objective of this mini project is to understand HPA as a
control loop rather than simply a command that creates more Pods:

observe metrics
      ↓
compare with desired target
      ↓
calculate desired replicas
      ↓
update workload
      ↓
observe again

This connects Kubernetes autoscaling back to the broader
reconciliation/control-loop model.
