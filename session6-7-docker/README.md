# Docker Hello World Applications

This repository contains 6 simple "Hello World" web applications, each containerized using Docker. This project demonstrates how to write Dockerfiles, build images, and run containers across various technology stacks and web servers.

---

## Repository Structure

- **`nodejs-app/`**: A native Node.js HTTP web server.
- **`python-app/`**: A Python web application utilizing the Flask framework.
- **`java-app/`**: A compiled Java HTTP server using standard JDK libraries (`com.sun.net.httpserver`).
- **`Apache-app/`**: A static HTML page served by the Apache HTTP Server (`httpd:2.4-alpine`).
- **`React-app/`**: A React front-end application rendered with Babel and served via Nginx (`nginx:alpine`).
- **`nginx-app/`**: A static HTML page served directly by an Nginx web server (`nginx:alpine`).

---

## Port Mappings & Live URLs

Once running, the applications are mapped to the following local ports on the host machine:

| Application | Container Port | Host Port | Local URL | Displayed Header |
| :--- | :--- | :--- | :--- | :--- |
| **Node.js** | 3000 | 3000 | [http://localhost:3000](http://localhost:3000) | `Hello World from Node.js!` |
| **Python (Flask)** | 5000 | 5000 | [http://localhost:5000](http://localhost:5000) | `Hello World from Python Flask!` |
| **Java** | 8080 | 8080 | [http://localhost:8080](http://localhost:8080) | `Hello World from Java!` |
| **Apache** | 80 | 8081 | [http://localhost:8081](http://localhost:8081) | `Hello World from Apache!` |
| **React** | 80 | 8082 | [http://localhost:8082](http://localhost:8082) | `Hello World from React!` |
| **Nginx** | 80 | 8083 | [http://localhost:8083](http://localhost:8083) | `Hello World from Nginx!` |

---

## Execution & Proof of Learning

### 1. Node.js Application
- **Build Image:**
  ```powershell
  cd nodejs-app
  docker build -t nodejs-hello .
  ```
- **Run Container:**
  ```powershell
  docker run -d -p 3000:3000 --name nodejs-container nodejs-hello
  ```
- **Local URL:** [http://localhost:3000](http://localhost:3000)
- **Displayed Output:** `Hello World from Node.js!`
-![alt text](<Screenshot 2026-09-03 213351-1.png>)
---

### 2. Python Application
- **Build Image:**
  ```powershell
  cd python-app
  docker build -t python-hello .
  ```
- **Run Container:**
  ```powershell
  docker run -d -p 5000:5000 --name python-container python-hello
  ```
- **Local URL:** [http://localhost:5000](http://localhost:5000)
- **Displayed Output:** `Hello World from Python Flask!`
- ![alt text](<Screenshot 2026-09-03 213604.png>)

---

### 3. Java Application
- **Build Image:**
  ```powershell
  cd java-app
  docker build -t java-hello .
  ```
- **Run Container:**
  ```powershell
  docker run -d -p 8080:8080 --name java-container java-hello
  ```
- **Local URL:** [http://localhost:8080](http://localhost:8080)
- **Displayed Output:** `Hello World from Java!`
- ![alt text](<Screenshot 2026-09-03 213619.png>)

---

### 4. Apache Application
- **Build Image:**
  ```powershell
  cd Apache-app
  docker build -t apache-hello .
  ```
- **Run Container:**
  ```powershell
  docker run -d -p 8081:80 --name apache-container apache-hello
  ```
- **Local URL:** [http://localhost:8081](http://localhost:8081)
- **Displayed Output:** `Hello World from Apache!`
- ![alt text](<Screenshot 2026-09-03 213636.png>)

---

### 5. React Application
- **Build Image:**
  ```powershell
  cd React-app
  docker build -t react-hello .
  ```
- **Run Container:**
  ```powershell
  docker run -d -p 8082:80 --name react-container react-hello
  ```
- **Local URL:** [http://localhost:8082](http://localhost:8082)
- **Displayed Output:** `Hello World from React!`
- ![alt text](<Screenshot 2026-09-03 213700.png>)

---

### 6. Nginx Application
- **Build Image:**
  ```powershell
  cd nginx-app
  docker build -t nginx-hello .
  ```
- **Run Container:**
  ```powershell
  docker run -d -p 8083:80 --name nginx-container nginx-hello
  ```
- **Local URL:** [http://localhost:8083](http://localhost:8083)
- **Displayed Output:** `Hello World from Nginx!`
- ![alt text](<Screenshot 2026-09-03 213718.png>)

