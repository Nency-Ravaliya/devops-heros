#!/bin/sh
b(){ echo; echo "=====[$1]====="; }
apk add --no-cache curl >/dev/null 2>&1
b "HOST-OS"
uname -srm; cat /etc/os-release | grep PRETTY; echo "hostname: $(hostname)"

b "T1-create-networks"
docker network create frontend-net
docker network create backend-net
docker network create database-net
b "T1-network-ls"
docker network ls
b "T1-run-frontend"
docker run -d --name frontend --network frontend-net nginx:alpine 2>&1 | tail -1
b "T1-run-backend"
docker run -d --name backend --network frontend-net alpine:3.20 sleep infinity 2>&1 | tail -1
b "T1-attach-backend-to-second-network"
docker network connect database-net backend && echo "backend is now attached to BOTH frontend-net and database-net"
b "T1-run-database"
docker run -d --name database --network database-net -e MYSQL_ROOT_PASSWORD=Root@1234 -e MYSQL_DATABASE=devops mysql:8.0 2>&1 | tail -1
b "T1-container-networks"
for c in frontend backend database; do
  echo "$c -> $(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}({{$v.IPAddress}}) {{end}}' $c)"
done
b "T1-ps"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
sleep 25
b "T1-backend-to-frontend (shared: frontend-net) EXPECT SUCCESS"
docker exec backend ping -c 3 frontend
b "T1-backend-http-to-frontend"
docker exec backend wget -qO- --timeout=5 http://frontend | head -6
b "T1-backend-to-database (shared: database-net) EXPECT SUCCESS"
docker exec backend ping -c 3 database
b "T1-backend-tcp-to-mysql-3306"
docker exec backend sh -c 'nc -z -w 3 database 3306 && echo "port 3306 OPEN on database" || echo "port 3306 closed"'
b "T1-frontend-to-database (NO shared network) EXPECT FAILURE"
docker exec frontend ping -c 2 -W 3 database; echo "(exit code: $?)"
b "T1-frontend-to-backend (shared: frontend-net) EXPECT SUCCESS"
docker exec frontend ping -c 2 backend
b "T1-network-inspect-frontend-net"
docker network inspect frontend-net -f '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
b "T1-network-inspect-database-net"
docker network inspect database-net -f '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
b "T1-network-inspect-backend-net"
docker network inspect backend-net -f 'Containers attached: {{len .Containers}}'
b "T1-mysql-check"
docker exec database mysql -uroot -pRoot@1234 -e "SHOW DATABASES;" 2>&1 | grep -v Warning

b "T2-pull-apache2"
docker pull httpd:2.4 2>&1 | tail -2
b "T2-run-apache-host-network"
docker run -d --name apache-host --network host httpd:2.4 2>&1 | tail -1
sleep 6
b "T2-ps-host-mode"
docker ps --filter name=apache-host --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"
b "T2-inspect-host-mode"
docker inspect apache-host -f 'NetworkMode={{.HostConfig.NetworkMode}} | PortBindings={{.HostConfig.PortBindings}} | Networks={{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}'
b "T2-access-apache-on-port-80-from-the-host"
curl -s http://localhost:80/
b "T2-http-code-and-headers"
curl -sI http://localhost:80/ | head -5
curl -s -o /dev/null -w "http_code=%{http_code} port=%{remote_port} ip=%{remote_ip}\n" http://localhost:80/
b "T2-port-80-is-listening-on-the-host-itself"
netstat -tulpn 2>/dev/null | grep ':80 ' || ss -tulpn 2>/dev/null | grep ':80 '
b "T2-compare-bridge-container-ports"
docker ps --filter name=frontend --format "{{.Names}} PORTS='{{.Ports}}'"
docker ps --filter name=apache-host --format "{{.Names}} PORTS='{{.Ports}}'"
b "T2-apache-logs"
docker logs apache-host 2>&1 | tail -4

b "T3-create-folder-and-file-on-the-host"
mkdir -p /root/bindmount
cat > /root/bindmount/index.html <<'EOF'
<!doctype html>
<html>
  <head><title>Bind Mount Demo</title></head>
  <body>
    <h1>Hello students</h1>
  </body>
</html>
EOF
ls -l /root/bindmount
cat /root/bindmount/index.html
b "T3-bind-mount-into-nginx"
docker run -d --name nginx-bind -p 8085:80 -v /root/bindmount:/usr/share/nginx/html nginx:alpine 2>&1 | tail -1
sleep 4
b "T3-access-nginx-website"
curl -s http://localhost:8085/
b "T3-inspect-the-mount"
docker inspect nginx-bind -f '{{range .Mounts}}Type={{.Type}} Source={{.Source}} Destination={{.Destination}} RW={{.RW}}{{end}}'
b "T3-file-is-the-same-file-inside-the-container"
docker exec nginx-bind cat /usr/share/nginx/html/index.html | head -3
docker exec nginx-bind stat -c 'inode=%i size=%s' /usr/share/nginx/html/index.html
stat -c 'inode=%i size=%s' /root/bindmount/index.html
b "T3-record-start-time-before-modifying"
docker inspect nginx-bind -f 'StartedAt={{.State.StartedAt}} RestartCount={{.RestartCount}}'
b "T3-modify-index.html-on-the-host"
cat > /root/bindmount/index.html <<'EOF'
<!doctype html>
<html>
  <head><title>Bind Mount Demo</title></head>
  <body>
    <h1>Hello students</h1>
    <h2>This line was added on the HOST while the container kept running.</h2>
    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>
  </body>
</html>
EOF
echo "index.html modified on the host"
b "T3-verify-change-WITHOUT-restarting-the-container"
curl -s http://localhost:8085/
b "T3-prove-container-never-restarted"
docker inspect nginx-bind -f 'StartedAt={{.State.StartedAt}} RestartCount={{.RestartCount}}'
docker ps --filter name=nginx-bind --format "{{.Names}} {{.Status}}"
b "T3-write-from-inside-the-container-appears-on-the-host"
docker exec nginx-bind sh -c 'echo "<!-- written from inside the container -->" >> /usr/share/nginx/html/index.html'
tail -2 /root/bindmount/index.html
b "T3-named-volume-for-comparison"
docker volume create demo-vol >/dev/null
docker volume inspect demo-vol -f 'Name={{.Name}} Driver={{.Driver}} Mountpoint={{.Mountpoint}}'
docker run --rm -v demo-vol:/data alpine:3.20 sh -c 'echo "data in a named volume" > /data/file.txt; cat /data/file.txt'
ls -l /var/lib/docker/volumes/demo-vol/_data

b "T4-overlay-driver-available"
docker info --format '{{.Plugins.Network}}'
b "T4-swarm-status"
docker info --format 'Swarm: {{.Swarm.LocalNodeState}}'
b "T4-init-swarm-and-create-overlay"
docker swarm init --advertise-addr 127.0.0.1 2>&1 | head -3
docker network create --driver overlay --attachable app-overlay 2>&1 | tail -1
b "T4-overlay-network-listed"
docker network ls --filter driver=overlay
b "T4-overlay-inspect"
docker network inspect app-overlay -f 'Name={{.Name}} Driver={{.Driver}} Scope={{.Scope}} Attachable={{.Attachable}} Subnet={{range .IPAM.Config}}{{.Subnet}}{{end}}'
b "T4-attach-containers-to-overlay"
docker run -d --name ov-a --network app-overlay alpine:3.20 sleep infinity >/dev/null 2>&1
docker run -d --name ov-b --network app-overlay alpine:3.20 sleep infinity >/dev/null 2>&1
sleep 4
docker exec ov-a ping -c 3 ov-b
b "T4-overlay-vs-bridge-scope"
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" | grep -E "NAME|overlay|frontend-net|host"

b "FINAL-PS"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"
b "FINAL-NETWORK-LS"
docker network ls
