# Kubernetes FQDN (Fully Qualified Domain Name) Guide

## 1. What is FQDN?
An FQDN (Fully Qualified Domain Name) is the complete domain name that specifies the exact location of a host or service within the Domain Name System (DNS) hierarchy.

## 2. Kubernetes DNS Naming Convention
In Kubernetes, every Service created in the cluster is assigned an internal FQDN following this strict format:

```text
<service-name>.<namespace>.svc.cluster.local
```

### Components:
- `<service-name>`: Name of the Kubernetes Service object.
- `<namespace>`: Kubernetes namespace where the service resides (e.g. `default`, `prod`).
- `svc`: Indicates the object type is a Service.
- `cluster.local`: Default cluster domain suffix.

## 3. Namespace-Based DNS Resolution
- **Same Namespace**: A pod in namespace `dev` calling `backend-svc` can use short name `backend-svc`.
- **Cross-Namespace**: A pod in namespace `frontend` calling `backend-svc` in `dev` must use `backend-svc.dev` or the full FQDN `backend-svc.dev.svc.cluster.local`.

## 4. Examples of Kubernetes FQDNs
- Standard Service: `my-database.default.svc.cluster.local`
- Headless Service Pod: `pod-0.my-redis-headless.prod.svc.cluster.local`
