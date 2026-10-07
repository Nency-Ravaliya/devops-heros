# Task 2: HPA Hands-on
**Name:** Ankita Tripathi  
**Roll Number:** 24bcs10062
## Objective

The objective of this task is to configure and test the Kubernetes Horizontal Pod Autoscaler (HPA). The HPA automatically increases or decreases the number of application pods based on CPU utilization.

The HPA was configured with:

- Minimum replicas: 1
- Maximum replicas: 5
- Target CPU utilization: 50%

---

## 1. Deploy the Application and Configure HPA

The application was deployed using a Kubernetes Deployment and exposed using a ClusterIP Service.

The HPA was configured for the `hpa-demo` deployment with a target CPU utilization of 50%.

Commands used:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

kubectl get deployment
kubectl get pods
kubectl get service
kubectl describe hpa hpa-demo
```

The application pod was successfully deployed and the HPA was configured with a minimum of 1 replica and a maximum of 5 replicas.

![HPA Deployment and Configuration](ss/01-hpa-deployment-and-configuration.png)

---

## 2. Generate Load and Observe CPU Utilization

A BusyBox pod was used as a load generator. It continuously sent HTTP requests to the `hpa-demo-service`.

Command used:

```bash
kubectl run load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c \
  "while true; do wget -q -O- http://hpa-demo-service; done"
```

CPU utilization and running pods were observed using:

```bash
kubectl top pods
kubectl get pods
```

Under load, CPU utilization increased and Kubernetes started additional instances of the `hpa-demo` pod.

![Load Generator and CPU Utilization](ss/02-load-generator-and-cpu-utilization.png)

---

## 3. Observe HPA Auto-scaling

The HPA was monitored continuously using:

```bash
kubectl get hpa -w
```

Initially, the deployment had **1 replica**.

During load generation, CPU utilization increased above the configured **50% target**, reaching values such as **82% and 84%**.

As a result, the Horizontal Pod Autoscaler automatically increased the number of replicas from **1 to 2**.

![HPA Auto Scaling](ss/03-hpa-auto-scaling.png)

---

## Useful Commands

```bash
kubectl get hpa
kubectl get pods
kubectl top pods
kubectl describe hpa hpa-demo
```

---

## Result

The Kubernetes Horizontal Pod Autoscaler was successfully configured and tested.

The experiment demonstrated that:

- The application was successfully deployed.
- HPA monitored CPU utilization.
- A load generator increased the application workload.
- CPU utilization increased beyond the 50% target.
- HPA automatically scaled the deployment from 1 pod to 2 pods.
- The scaling behavior was successfully observed using Kubernetes commands.

Therefore, the Horizontal Pod Autoscaler successfully performed automatic pod scaling based on CPU utilization.