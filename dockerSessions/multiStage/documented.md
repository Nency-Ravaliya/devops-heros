```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/multiStage$ docker images
                                                                                    i Info →   U  In Use
IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
nginx:latest     b34848eff6db        241MB         66.2MB        
node:24-alpine   e67514e5d0f6        235MB         58.8MB        
nodeapp:latest   e1d49547764d        253MB         61.3MB        
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/multiStage$ docker run -it -d -p 8080:5000 --name multiStageNodeApp nodeapp:latest
8f8390a18a99b3485e7b9f7bd37a0f0115bcc6ac47fbe43d07b0b92526f4c0a4
```
```
manav@manav-HP-Pavillion-Laptop-15-eh1xxx:~/Bash-Scripting/scaler/DevOps-InClass/dockerSessions/multiStage$ docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED         STATUS         PORTS                                         NAMES
8f8390a18a99   nodeapp:latest   "docker-entrypoint.s…"   8 seconds ago   Up 8 seconds   0.0.0.0:8080->5000/tcp, [::]:8080->5000/tcp   multiStageNodeApp
```


![webapp screenshot](./Screenshot%20from%202026-08-29%2020-29-38.png)