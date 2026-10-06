# Task 3 - Ingress (host + path routing)

**Ujjawal Prabhat - 24BCS10267 - Session 12**

- [x] Two apps + two ClusterIP Services ([`apps.yaml`](apps.yaml))
- [x] Host-based routing Ingress ([`ingress-host.yaml`](ingress-host.yaml)): `a.24bcs10267.local -> app-a`, `b.24bcs10267.local -> app-b`
- [x] Path-based routing Ingress ([`ingress-path.yaml`](ingress-path.yaml)): `apps.24bcs10267.local/a -> app-a`, `/b -> app-b` (prefix stripped by `rewrite-target`)
- [x] `ingressClassName: nginx`, tested with curl on `localhost:8081` (kind maps host 8081 to the controller's port 80) and a `Host` header

I used `*.24bcs10267.local` hostnames so my rules cannot clash with other Ingresses on the shared controller.
`traefik/whoami --name app-x` echoes its name, the pod hostname and the request line it received, so each response shows where the request was routed.

## Deploy

```
$ kubectl apply -f apps.yaml
deployment.apps/app-a created
service/app-a created
deployment.apps/app-b created
service/app-b created

$ kubectl -n s12 get deploy,svc,endpointslices -l '!x' -o wide | grep -E 'NAME|app-'
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                 SELECTOR
deployment.apps/app-a   2/2     2            2           1s    whoami       traefik/whoami:v1.10   app=app-a
deployment.apps/app-b   2/2     2            2           1s    whoami       traefik/whoami:v1.10   app=app-b
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/app-a   ClusterIP   10.96.55.227    <none>        80/TCP    1s    app=app-a
service/app-b   ClusterIP   10.96.162.149   <none>        80/TCP    1s    app=app-b
NAME                                         ADDRESSTYPE   PORTS   ENDPOINTS                   AGE
endpointslice.discovery.k8s.io/app-a-trjqt   IPv4          80      10.244.1.174,10.244.2.123   1s
endpointslice.discovery.k8s.io/app-b-mbj5s   IPv4          80      10.244.1.175,10.244.2.124   1s

$ kubectl apply -f ingress-host.yaml -f ingress-path.yaml
ingress.networking.k8s.io/host-routing created
ingress.networking.k8s.io/path-routing created

$ kubectl -n s12 get ingress
NAME           CLASS   HOSTS                                   ADDRESS     PORTS   AGE
host-routing   nginx   a.24bcs10267.local,b.24bcs10267.local   localhost   80      20s
path-routing   nginx   apps.24bcs10267.local                   localhost   80      20s

$ kubectl -n s12 describe ingress host-routing
Name:             host-routing
Labels:           <none>
Namespace:        s12
Address:          localhost
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host                Path  Backends
  ----                ----  --------
  a.24bcs10267.local
                      /   app-a:80 (10.244.1.174:80,10.244.2.123:80)
  b.24bcs10267.local
                      /   app-b:80 (10.244.1.175:80,10.244.2.124:80)
Annotations:          <none>
Events:
  Type    Reason  Age               From                      Message
  ----    ------  ----              ----                      -------
  Normal  Sync    7s (x2 over 20s)  nginx-ingress-controller  Scheduled for sync

$ kubectl -n s12 describe ingress path-routing
Name:             path-routing
Labels:           <none>
Namespace:        s12
Address:          localhost
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host                   Path  Backends
  ----                   ----  --------
  apps.24bcs10267.local
                         /a(/|$)(.*)   app-a:80 (10.244.1.174:80,10.244.2.123:80)
                         /b(/|$)(.*)   app-b:80 (10.244.1.175:80,10.244.2.124:80)
Annotations:             nginx.ingress.kubernetes.io/rewrite-target: /$2
                         nginx.ingress.kubernetes.io/use-regex: true
Events:
  Type    Reason  Age               From                      Message
  ----    ------  ----              ----                      -------
  Normal  Sync    7s (x2 over 20s)  nginx-ingress-controller  Scheduled for sync
```

`ADDRESS localhost` comes from the controller's `--publish-status-address=localhost`. The ingress-nginx controller found both Ingresses (`Sync` event)
and resolved each backend Service to its pod IPs.

## Verify routing

```
### host-based routing
$ curl -s -H 'Host: a.24bcs10267.local' http://localhost:8081/ | grep -E '^(Name|Hostname|Host):|^GET'
Name: app-a
Hostname: app-a-6575476df-skrxt
GET / HTTP/1.1
Host: a.24bcs10267.local

$ curl -s -H 'Host: b.24bcs10267.local' http://localhost:8081/ | grep -E '^(Name|Hostname|Host):|^GET'
Name: app-b
Hostname: app-b-9c4ff6c47-nsd67
GET / HTTP/1.1
Host: b.24bcs10267.local

$ for i in 1 2 3 4; do curl -s -H 'Host: a.24bcs10267.local' http://localhost:8081/ | grep Hostname; done
Hostname: app-a-6575476df-djbbw
Hostname: app-a-6575476df-skrxt
Hostname: app-a-6575476df-djbbw
Hostname: app-a-6575476df-skrxt

$ for i in 1 2 3 4; do curl -s -H 'Host: b.24bcs10267.local' http://localhost:8081/ | grep Hostname; done
Hostname: app-b-9c4ff6c47-pnjsk
Hostname: app-b-9c4ff6c47-nsd67
Hostname: app-b-9c4ff6c47-pnjsk
Hostname: app-b-9c4ff6c47-pnjsk

### path-based routing
$ curl -s -H 'Host: apps.24bcs10267.local' http://localhost:8081/a | grep -E '^(Name|Hostname|Host):|^GET'
Name: app-a
Hostname: app-a-6575476df-skrxt
GET / HTTP/1.1
Host: apps.24bcs10267.local

$ curl -s -H 'Host: apps.24bcs10267.local' http://localhost:8081/b/orders/42 | grep -E '^(Name|Hostname|Host|X-Forwarded-For|X-Real-Ip):|^GET'
Name: app-b
Hostname: app-b-9c4ff6c47-nsd67
GET /orders/42 HTTP/1.1
Host: apps.24bcs10267.local
X-Forwarded-For: 192.168.65.1
X-Real-Ip: 192.168.65.1

$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: apps.24bcs10267.local' http://localhost:8081/c
404

$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: unknown.24bcs10267.local' http://localhost:8081/
404

$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8081/
404

$ curl -s --resolve a.24bcs10267.local:8081:127.0.0.1 http://a.24bcs10267.local:8081/ | grep -E '^(Name|Host):'
Name: app-a
Host: a.24bcs10267.local:8081

### controller access log
$ kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=300 | grep -E 's12-app-(a|b)-80' | tail -4
192.168.65.1 - - [06/Oct/2026:12:02:54 +0000] "GET / HTTP/1.1" 200 454 "-" "curl/8.7.1" 81 0.000 [s12-app-b-80] [] 10.244.1.175:80 454 0.001 200 10ee2926b4d64958122abbcb9ae4cbbb
192.168.65.1 - - [06/Oct/2026:12:02:54 +0000] "GET /a HTTP/1.1" 200 459 "-" "curl/8.7.1" 85 0.001 [s12-app-a-80] [] 10.244.1.174:80 459 0.001 200 e898553167225a7f1792a91cba0d12a5
192.168.65.1 - - [06/Oct/2026:12:02:54 +0000] "GET /b/orders/42 HTTP/1.1" 200 469 "-" "curl/8.7.1" 95 0.001 [s12-app-b-80] [] 10.244.2.124:80 469 0.002 200 0f392dd93efbb702be8cf225ed0ed0e9
192.168.65.1 - - [06/Oct/2026:12:02:54 +0000] "GET / HTTP/1.1" 200 464 "-" "curl/8.7.1" 86 0.001 [s12-app-a-80] [] 10.244.2.123:80 464 0.001 200 4a9932941afe6f1edb2606be5dda0e19
```

What the outputs show:

| Request | Routed to | Proof |
|---|---|---|
| `Host: a.24bcs10267.local` `/` | app-a | `Name: app-a`, alternating between both app-a pods |
| `Host: b.24bcs10267.local` `/` | app-b | `Name: app-b`, both app-b pods |
| `Host: apps.24bcs10267.local` `/a` | app-a | the app received `GET /` (prefix `/a` removed) |
| `Host: apps.24bcs10267.local` `/b/orders/42` | app-b | the app received `GET /orders/42` (rewrite `/$2`) |
| `/c` or an unknown host | none | `404` from the controller's default backend |

The controller access log confirms the upstream for each request (`[s12-app-a-80]`, `[s12-app-b-80]`) and the pod IP it chose.
`--resolve` (or an `/etc/hosts` entry `127.0.0.1 a.24bcs10267.local`) lets a browser-style request use the real hostname.
