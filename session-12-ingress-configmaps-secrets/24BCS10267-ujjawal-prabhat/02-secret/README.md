# Task 2 - Secret

**Ujjawal Prabhat - 24BCS10267 - Session 12**

- [x] Create a Secret (from the CLI, **not** from a committed file)
- [x] Inject it as env vars and as a volume, and verify inside the container
- [x] Show that base64 is **encoding, not encryption** (decoded with `base64 -d`, and read in plain text straight from etcd)
- [x] Explain why real secrets must not be committed. Only [`secret.example.yaml`](secret.example.yaml) (placeholders) is in git
- [x] Safer alternatives: Sealed Secrets, External Secrets Operator, SOPS

Files: [`secret.example.yaml`](secret.example.yaml) (template with placeholders), [`pod-with-secret.yaml`](pod-with-secret.yaml),
[`.gitignore`](.gitignore) (blocks `secret.yaml`, `*.secret.yaml` and `.env` from being committed).

The password used below (`Demo-Only-P@ss-24BCS`) is a throwaway demo value that existed only in my local kind cluster.
It is shown on purpose, to prove that anyone with read access can recover a Secret's value.

## Create, inject, verify

```
$ kubectl -n s12 create secret generic db-credentials --from-literal=DB_USER=yatri_app --from-literal=DB_PASSWORD='Demo-Only-P@ss-24BCS'
secret/db-credentials created

$ kubectl -n s12 get secret db-credentials
NAME             TYPE     DATA   AGE
db-credentials   Opaque   2      0s

$ kubectl -n s12 describe secret db-credentials
Name:         db-credentials
Namespace:    s12
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
DB_PASSWORD:  20 bytes
DB_USER:      9 bytes

$ kubectl -n s12 get secret db-credentials -o yaml
apiVersion: v1
data:
  DB_PASSWORD: RGVtby1Pbmx5LVBAc3MtMjRCQ1M=
  DB_USER: eWF0cmlfYXBw
kind: Secret
metadata:
  creationTimestamp: "2026-10-06T12:01:47Z"
  name: db-credentials
  namespace: s12
  resourceVersion: "21922"
  uid: 8b1c8e6f-2972-43c4-acef-de422fa2fe50
type: Opaque

$ kubectl apply -f pod-with-secret.yaml
pod/secret-demo created

### verify inside the container
$ kubectl -n s12 exec secret-demo -- sh -c 'echo DB_USER=$DB_USER; echo DB_PASSWORD length=${#DB_PASSWORD}'
DB_USER=yatri_app
DB_PASSWORD length=20

$ kubectl -n s12 exec secret-demo -- ls -laL /etc/creds
total 12
drwxrwxrwt    3 root     root           120 Oct  6 12:01 .
drwxr-xr-x    1 root     root          4096 Oct  6 12:01 ..
drwxr-xr-x    2 root     root            80 Oct  6 12:01 ..2026_10_06_12_01_47.1420692433
drwxr-xr-x    2 root     root            80 Oct  6 12:01 ..data
-r--------    1 root     root            20 Oct  6 12:01 DB_PASSWORD
-r--------    1 root     root             9 Oct  6 12:01 DB_USER

$ kubectl -n s12 exec secret-demo -- cat /etc/creds/DB_USER
yatri_app
$ kubectl -n s12 exec secret-demo -- sh -c 'mount | grep /etc/creds'
tmpfs on /etc/creds type tmpfs (ro,relatime,size=8124516k,noswap)
```

- Env vars: `DB_USER` is readable, and the password is there (20 chars). I printed only its length, because logging secrets is a bad habit.
- Volume: each key is a file with mode `0400` (`-r--------`) from `defaultMode`. It is mounted as **tmpfs** (RAM), so it is never written to the node's disk.
- `describe secret` shows only byte counts. `get -o yaml` shows the base64 values.

## base64 is NOT encryption

```
### base64 is NOT encryption
$ kubectl -n s12 get secret db-credentials -o jsonpath='{.data.DB_PASSWORD}'; echo
RGVtby1Pbmx5LVBAc3MtMjRCQ1M=

$ kubectl -n s12 get secret db-credentials -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo
Demo-Only-P@ss-24BCS

$ echo -n 'Demo-Only-P@ss-24BCS' | base64
RGVtby1Pbmx5LVBAc3MtMjRCQ1M=

$ kubectl -n s12 get secret db-credentials -o go-template='{{range $k,$v := .data}}{{$k}}={{$v | base64decode}}{{"\n"}}{{end}}'
DB_PASSWORD=Demo-Only-P@ss-24BCS
DB_USER=yatri_app

### how it is stored in etcd (no encryption-at-rest configured on kind)
$ kubectl -n kube-system exec etcd-devops-heros-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/s12/db-credentials --print-value-only | strings | grep -E 'DB_|Demo|yatri'
A{"f:data":{".":{},"f:DB_PASSWORD":{},"f:DB_USER":{}},"f:type":{}}B
DB_PASSWORD
Demo-Only-P@ss-24BCS
DB_USER
yatri_app

$ docker exec devops-heros-control-plane grep -c encryption-provider-config /etc/kubernetes/manifests/kube-apiserver.yaml
0
```

1. **base64 is reversible by anyone.** `base64 -d` gives back the password, and `echo -n ... | base64` gives exactly the stored string.
   There is no key involved. base64 only exists so binary data can be stored in YAML/JSON.
2. **In etcd the Secret is stored in plain text**, unless the API server is started with an `EncryptionConfiguration`
   (`--encryption-provider-config`). This kind cluster has none (`grep -c` = 0), so reading etcd (or a backup of it) shows `Demo-Only-P@ss-24BCS` directly.
3. Real protection comes from **RBAC** (who may `get secrets`), plus encryption at rest (KMS provider), plus audit logging.
   My admin user can read it. The namespace's `default` ServiceAccount cannot:

```
### who can read it = whoever has RBAC get on secrets
$ kubectl auth can-i get secrets -n s12
yes

$ kubectl auth can-i get secrets -n s12 --as=system:serviceaccount:s12:default
no
```

## Why secrets must never be committed to Git

- A Secret YAML only *looks* protected. Anyone who can read the repo can decode it in one command (shown above).
- Git history is permanent. Deleting the file later does not remove it from old commits, forks, clones, CI caches or PR diffs.
  A leaked credential has to be **rotated**, not just deleted.
- Repos get shared much more widely than production access: interns, contractors, open-sourcing, CI logs, bots.
- Automated scanners (GitHub secret scanning, trufflehog) look for leaked keys in public repos within minutes.
- Note: the course's own `02-secret/db-secret.yaml` and `04-full-demo/secret.yaml` contain base64-encoded passwords in git. That is fine
  for a classroom demo, but it is exactly the pattern to avoid in real projects.

**What I did instead:** git only has [`secret.example.yaml`](secret.example.yaml) with `<placeholders>`. The real Secret was created with
`kubectl create secret generic ... --from-literal`, and `.gitignore` blocks real secret files.

## Safer ways to manage secrets in GitOps

| Tool | How it works | What is in git |
|---|---|---|
| **Sealed Secrets** (Bitnami) | `kubeseal` encrypts a Secret with the cluster controller's **public key**. Only the controller in that cluster (private key) can decrypt it into a normal Secret | `SealedSecret` YAML (ciphertext), safe to commit |
| **External Secrets Operator** | A CRD (`ExternalSecret`) references a key in AWS Secrets Manager / GCP Secret Manager / Azure Key Vault / HashiCorp Vault. The operator fetches it and creates or refreshes the Secret | Only a *reference* (path/key name), no secret data |
| **SOPS** (+ age / PGP / cloud KMS) | Encrypts only the **values** inside YAML/JSON files, keys stay readable. Decrypted at deploy time (Flux has native support, Argo CD/Helm via plugins) | Encrypted values, readable structure for diffs |
| Vault Agent / CSI Secrets Store driver | Secret is injected into the pod at runtime from Vault or a cloud store, often never becoming a Kubernetes Secret | Nothing |

Also: enable **encryption at rest** for Secrets (KMS v2), use tight RBAC, prefer volume mounts over env vars (env vars leak into
crash dumps, `/proc/<pid>/environ` and child processes), and rotate credentials.
