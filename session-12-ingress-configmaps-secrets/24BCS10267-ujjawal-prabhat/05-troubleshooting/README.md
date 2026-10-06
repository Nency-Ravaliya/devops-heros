# Task 5 - Troubleshooting

**Ujjawal Prabhat - 24BCS10267 - Session 12**

The course's [`../../troubleshooting/`](../../troubleshooting) folder for this session contains **one** scenario,
`secret-base64-gotcha.md`. It is a write-up rather than a manifest, so I turned it into a real, reproducible failure against a
real PostgreSQL (case 1). To cover the rest of the session (Ingress and ConfigMaps), I added three more broken manifests of my own
(cases 2-4), using the same method.

Layout: `broken/` = the faulty manifest, `fixed/` = the corrected one, [`postgres.yaml`](postgres.yaml) = DB server for case 1.

| # | Scenario | Symptom | Root cause | Fix |
|---|---|---|---|---|
| 1 | Course: secret base64 gotcha | `FATAL: password authentication failed` | `echo` without `-n`, so the base64 value contains `mypassword\n` | `echo -n` / `stringData` / `--from-literal` |
| 2 | Ingress with wrong class | 404, no ADDRESS, no events | `ingressClassName: nginx-internal` does not exist, so no controller handles it | `ingressClassName: nginx` |
| 3 | Ingress with wrong service port | 503 Service Temporarily Unavailable | backend `port: 8080`, but the Service only exposes 80 | `port: 80` |
| 4 | ConfigMap key typo | `CreateContainerConfigError` | `key: log_level`, but the ConfigMap has `LOG_LEVEL` | use the exact key |

---

## Case 1 - Secret base64 trailing newline (course scenario)

Broken: [`broken/01-app-db-secret.yaml`](broken/01-app-db-secret.yaml) | Fixed: [`fixed/01-app-db-secret.yaml`](fixed/01-app-db-secret.yaml)

The PostgreSQL server gets its password from a Secret created correctly with `--from-literal`. The client app gets the "same" password
from a Secret whose base64 was produced with `echo "mypassword" | base64`.

```
$ kubectl -n s12 create secret generic pg-server-secret --from-literal=POSTGRES_PASSWORD=mypassword
secret/pg-server-secret created

$ kubectl apply -f postgres.yaml
deployment.apps/pg created
service/pg created

$ kubectl -n s12 get pods -l app=pg
NAME                  READY   STATUS    RESTARTS   AGE
pg-5b4b878d88-flzs7   1/1     Running   0          18s

## BEFORE (broken)
$ kubectl apply -f broken/01-app-db-secret.yaml
secret/app-db-secret created
pod/db-client created

$ kubectl -n s12 get pod db-client
NAME        READY   STATUS   RESTARTS   AGE
db-client   0/1     Error    0          2s

$ kubectl -n s12 logs db-client
psql: error: connection to server at "pg" (10.96.89.69), port 5432 failed: FATAL:  password authentication failed for user "yatri_admin"

$ kubectl -n s12 logs deploy/pg --tail=20 | grep -E 'FATAL|DETAIL'
2026-10-06 12:04:50.774 UTC [85] FATAL:  password authentication failed for user "yatri_admin"
2026-10-06 12:04:50.774 UTC [85] DETAIL:  Connection matched file "/var/lib/postgresql/data/pg_hba.conf" line 128: "host all all all scram-sha-256"

## investigate
$ kubectl -n s12 get secret app-db-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d | xxd
00000000: 6d79 7061 7373 776f 7264 0a              mypassword.

$ kubectl -n s12 get secret pg-server-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d | xxd
00000000: 6d79 7061 7373 776f 7264                 mypassword

$ kubectl -n s12 get secret app-db-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d | wc -c
      11

$ echo 'mypassword' | base64
bXlwYXNzd29yZAo=

$ echo -n 'mypassword' | base64
bXlwYXNzd29yZA==

## fix
$ kubectl -n s12 delete pod db-client
pod "db-client" deleted from s12 namespace

$ kubectl apply -f fixed/01-app-db-secret.yaml
secret/app-db-secret configured
pod/db-client created

$ kubectl -n s12 get pod db-client
NAME        READY   STATUS      RESTARTS   AGE
db-client   0/1     Completed   0          2s

$ kubectl -n s12 logs db-client
 current_user |                                            version
--------------+------------------------------------------------------------------------------------------------
 yatri_admin  | PostgreSQL 16.15 on aarch64-unknown-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit
(1 row)


$ kubectl -n s12 get secret app-db-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d | xxd
00000000: 6d79 7061 7373 776f 7264                 mypassword
```

**Root cause:** `xxd` shows the client's password ends with byte `0a` (`\n`), so it is 11 bytes, while the server's is 10. Postgres compared
`mypassword\n` with `mypassword` and correctly rejected it. The giveaway in the YAML is `...Ao=` at the end of the base64 instead of `...A==`.
**Fix:** encode with `echo -n`. Better still, avoid hand-made base64 completely by using `stringData:` or `kubectl create secret --from-literal`.
After applying the fixed Secret and recreating the client pod (env vars from Secrets are read only at container start), the login succeeds.

---

## Case 2 - Ingress references a non-existent IngressClass

Broken: [`broken/02-ingress-wrong-class.yaml`](broken/02-ingress-wrong-class.yaml) | Fixed: [`fixed/02-ingress-wrong-class.yaml`](fixed/02-ingress-wrong-class.yaml)

```
## BEFORE (broken)
$ kubectl apply -f broken/02-ingress-wrong-class.yaml
ingress.networking.k8s.io/wrong-class created

$ kubectl -n s12 get ingress wrong-class
NAME          CLASS            HOSTS                    ADDRESS   PORTS   AGE
wrong-class   nginx-internal   class.24bcs10267.local             80      20s

$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: class.24bcs10267.local' http://localhost:8081/
404

$ kubectl -n s12 describe ingress wrong-class | sed -n '/^Ingress Class/p;/^Events/,$p'
Ingress Class:    nginx-internal
Events:                   <none>

## investigate
$ kubectl get ingressclass
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       76m

$ kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --since=2m | grep -i wrong-class | tail -3
W1006 12:04:54.373650      11 controller.go:336] ignoring ingress wrong-class in s12 based on annotation : no object matching key "nginx-internal" in local store
I1006 12:04:54.373863      11 main.go:107] "successfully validated configuration, accepting" ingress="s12/wrong-class"
I1006 12:04:54.376685      11 store.go:436] "Ignoring ingress because of error while validating ingress class" ingress="s12/wrong-class" error="no object matching key \"nginx-internal\" in local store"

## fix
$ kubectl apply -f fixed/02-ingress-wrong-class.yaml
ingress.networking.k8s.io/wrong-class configured

$ kubectl -n s12 get ingress wrong-class
NAME          CLASS   HOSTS                    ADDRESS     PORTS   AGE
wrong-class   nginx   class.24bcs10267.local   localhost   80      40s

$ curl -s -H 'Host: class.24bcs10267.local' http://localhost:8081/ | grep -E '^(Name|Host):'
Name: app-a
Host: class.24bcs10267.local
```

**Root cause:** the Ingress was accepted by the API server (it is valid YAML), but no IngressClass `nginx-internal` exists, so **no controller
handles it**. The signs are: `Events: <none>` (no `Sync` event, compare with Task 3), 404 from the default backend, and the controller log line
`Ignoring ingress because of error while validating ingress class`. An empty `ADDRESS` is a hint, but it does not prove anything by itself. The
working Ingress in case 3 also had no ADDRESS at the 20 s mark and got `localhost` later, because the controller updates status periodically.
**Fix:** `kubectl get ingressclass`, then use a class that exists (`nginx`). Within seconds ADDRESS = `localhost` and app-a answers.

---

## Case 3 - Ingress backend uses the wrong Service port

Broken: [`broken/03-ingress-wrong-port.yaml`](broken/03-ingress-wrong-port.yaml) | Fixed: [`fixed/03-ingress-wrong-port.yaml`](fixed/03-ingress-wrong-port.yaml)

```
## BEFORE (broken)
$ kubectl apply -f broken/03-ingress-wrong-port.yaml
ingress.networking.k8s.io/wrong-port created

$ kubectl -n s12 get ingress wrong-port
NAME         CLASS   HOSTS                   ADDRESS   PORTS   AGE
wrong-port   nginx   port.24bcs10267.local             80      20s

$ curl -s -w 'HTTP %{http_code}\n' -H 'Host: port.24bcs10267.local' http://localhost:8081/ | tail -3
</body>
</html>
HTTP 503

## investigate
$ kubectl -n s12 describe ingress wrong-port | sed -n '/^Rules/,/^Annotations/p'
Rules:
  Host                   Path  Backends
  ----                   ----  --------
  port.24bcs10267.local
                         /   app-b:8080 (10.244.1.175:80,10.244.2.124:80)
Annotations:             <none>

$ kubectl -n s12 get svc app-b -o jsonpath='{.spec.ports}{"\n"}'
[{"port":80,"protocol":"TCP","targetPort":80}]

$ kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --since=2m | grep -iE 'app-b.*8080|8080.*app-b' | tail -2
192.168.65.1 - - [06/Oct/2026:12:05:54 +0000] "GET / HTTP/1.1" 503 190 "-" "curl/8.7.1" 84 0.000 [s12-app-b-8080] [] - - - - 1fd8dfb290f7ace4802387688640435f

## fix
$ kubectl apply -f fixed/03-ingress-wrong-port.yaml
ingress.networking.k8s.io/wrong-port configured

$ kubectl -n s12 describe ingress wrong-port | sed -n '/^Rules/,/^Annotations/p'
Rules:
  Host                   Path  Backends
  ----                   ----  --------
  port.24bcs10267.local
                         /   app-b:80 (10.244.1.175:80,10.244.2.124:80)
Annotations:             <none>

$ curl -s -w 'HTTP %{http_code}\n' -H 'Host: port.24bcs10267.local' http://localhost:8081/ | grep -E '^(Name|HTTP)'
Name: app-b
HTTP 200
```

**Root cause:** the Ingress backend is `app-b:8080`, but Service `app-b` only defines port `80`. `describe ingress` misleadingly still lists the
pod IPs (it resolves by Service name). The controller, however, finds no endpoints for port 8080: the access log shows upstream `[s12-app-b-8080]`
with `-` for the upstream address and status **503**.
**Fix:** point the backend at the Service **port** (80), not the container port or an arbitrary number. After that: HTTP 200 from app-b.

---

## Case 4 - Pod references a ConfigMap key that does not exist

Broken: [`broken/04-configmap-missing-key.yaml`](broken/04-configmap-missing-key.yaml) | Fixed: [`fixed/04-configmap-missing-key.yaml`](fixed/04-configmap-missing-key.yaml)

```
## BEFORE (broken)
$ kubectl apply -f broken/04-configmap-missing-key.yaml
pod/cm-key-demo created

$ kubectl -n s12 get pod cm-key-demo
NAME          READY   STATUS                       RESTARTS   AGE
cm-key-demo   0/1     CreateContainerConfigError   0          10s

$ kubectl -n s12 describe pod cm-key-demo | grep -A8 '^Events'
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Normal   Scheduled  10s               default-scheduler  Successfully assigned s12/cm-key-demo to devops-heros-worker2
  Normal   Pulled     9s (x2 over 10s)  kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Warning  Failed     9s (x2 over 10s)  kubelet            spec.containers{app}: Error: couldn't find key log_level in ConfigMap s12/app-config

## investigate
$ kubectl -n s12 get configmap app-config -o jsonpath='{.data}' | tr ',' '\n' | cut -c1-40
{"APP_ENV":"production"
"LOG_LEVEL":"warn"
"app.properties":"app.name=yatri-booking

## fix
$ kubectl -n s12 delete pod cm-key-demo
pod "cm-key-demo" deleted from s12 namespace

$ kubectl apply -f fixed/04-configmap-missing-key.yaml
pod/cm-key-demo created

$ kubectl -n s12 get pod cm-key-demo
NAME          READY   STATUS    RESTARTS   AGE
cm-key-demo   1/1     Running   0          1s

$ kubectl -n s12 logs cm-key-demo
LOG_LEVEL=warn
```

**Root cause:** ConfigMap keys are case-sensitive. The pod asks for `log_level`, the ConfigMap has `LOG_LEVEL`. The kubelet cannot build the container's
environment, so the pod stays in **`CreateContainerConfigError`**: the image was pulled, but the container is never created. The event message names the exact key.
**Fix:** use the correct key (or set `optional: true` on the reference if the key may legitimately be missing).

---

## General checklist I used

1. `kubectl get <obj>`: look at STATUS / ADDRESS / READY.
2. `kubectl describe <obj>`: **Events** almost always name the problem (FailedScheduling, couldn't find key, ...).
3. `kubectl logs <pod>` (and `--previous`) for app-level errors, e.g. the Postgres `FATAL`.
4. For Ingress: `kubectl get ingressclass`, controller logs (`kubectl -n ingress-nginx logs deploy/ingress-nginx-controller`),
   then follow Service -> port -> EndpointSlice.
5. For Secrets/ConfigMaps: decode and inspect the raw bytes (`base64 -d | xxd`), and check key names exactly.
