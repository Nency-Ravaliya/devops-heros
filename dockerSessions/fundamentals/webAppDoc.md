### Terminal cmd(s)

```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ docker build -t nodeapp .
[+] Building 0.3s (7/7) FINISHED                                                                                                               docker:default
 => [internal] load build definition from Dockerfile                                                                                                     0.0s
 => => transferring dockerfile: 106B                                                                                                                     0.0s
 => [internal] load metadata for docker.io/library/nginx:latest                                                                                          0.0s
 => [internal] load .dockerignore                                                                                                                        0.0s
 => => transferring context: 2B                                                                                                                          0.0s
 => [internal] load build context                                                                                                                        0.0s
 => => transferring context: 321B                                                                                                                        0.0s
 => [1/2] FROM docker.io/library/nginx:latest@sha256:b34848eff6db786b6b1282d3a9c3fd0b5563dfb6d261df4923378b419e0d24f0                                    0.1s
 => => resolve docker.io/library/nginx:latest@sha256:b34848eff6db786b6b1282d3a9c3fd0b5563dfb6d261df4923378b419e0d24f0                                    0.0s
 => [2/2] COPY index.html /usr/share/nginx/html/                                                                                                         0.0s
 => exporting to image                                                                                                                                   0.1s
 => => exporting layers                                                                                                                                  0.0s
 => => exporting manifest sha256:d3b12d44e7fae058d818f05d2d89473cbccc0d67202826deca583562eea6f2fc                                                        0.0s
 => => exporting config sha256:20fc161ec6ba901acd97b0250a15904f3fb639ffabc5fbc5dccc76883c61979c                                                          0.0s
 => => exporting attestation manifest sha256:4ef18931450337aa3b1a24f8cbc9f1b9db1341b3d2acd5f3456309ab86e36b9e                                            0.0s
 => => exporting manifest list sha256:24abd12e517231e58462b98ef4f54d38336f8442985c4eeab50e5b8162463d40                                                   0.0s
 => => naming to docker.io/library/nodeapp:latest                                                                                                        0.0s
 => => unpacking to docker.io/library/nodeapp:latest                                                                                                     0.0s
```

```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ ls
Dockerfile  index.html
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ docker images
                                                                                                                                          i Info →   U  In Use
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
hello-world:latest   5dd0d3e6e255       25.9kB         9.49kB    U   
nginx:latest         b34848eff6db        241MB         66.2MB    U   
nodeapp:latest       24abd12e5172        238MB         63.3MB        
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ docker run -it -d -p 80:80 nodeapp:latest 
dd8214ef1d133b69118cab674b0a25672fc4cf38f7698d7fe5609fe732a5a35c
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ ps docker
error: unsupported option (BSD syntax)

Usage:
 ps [options]

 Try 'ps --help <simple|list|output|threads|misc|all>'
  or 'ps --help <s|l|o|t|m|a>'
 for additional help text.

For more details see ps(1).
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED          STATUS          PORTS                                 NAMES
dd8214ef1d13   nodeapp:latest   "/docker-entrypoint.…"   14 seconds ago   Up 13 seconds   0.0.0.0:80->80/tcp, [::]:80->80/tcp   sleepy_roentgen
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED         STATUS         PORTS                                 NAMES
dd8214ef1d13   nodeapp:latest   "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp, [::]:80->80/tcp   sleepy_roentgen
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ docker stop dd8214ef1d133b69118cab674b0a25672fc4cf38f7698d7fe5609fe732a5a35c
dd8214ef1d133b69118cab674b0a25672fc4cf38f7698d7fe5609fe732a5a35c
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ docker -a
unknown shorthand flag: 'a' in -a

Usage:  docker [OPTIONS] COMMAND [ARG...]

Run 'docker --help' for more information
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ docker ps -a
CONTAINER ID   IMAGE            COMMAND                  CREATED         STATUS                      PORTS     NAMES
dd8214ef1d13   nodeapp:latest   "/docker-entrypoint.…"   3 minutes ago   Exited (0) 47 seconds ago             sleepy_roentgen
ac9de54a042b   nginx            "/docker-entrypoint.…"   4 hours ago     Exited (0) 4 hours ago                festive_jepsen
bffdd12c9989   hello-world      "/hello"                 32 hours ago    Exited (0) 32 hours ago               sad_jepsen
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/fundamentals$ 
```

### Output
![webpage](./Screenshot%20from%202026-08-28%2022-53-20.png)