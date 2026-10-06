# Captured 6 Oct 2026 with the containers running

```text
NAMES                 IMAGE                       PORTS
homework-multistage   homework-multistage:local   0.0.0.0:8080->8080/tcp
homework-nginx        homework-nginx:local        0.0.0.0:8084->80/tcp
homework-react        homework-react:local        0.0.0.0:8083->80/tcp
homework-apache       homework-apache:local       0.0.0.0:8082->80/tcp
homework-java         homework-java:local         0.0.0.0:8081->8080/tcp
homework-python       homework-python:local       0.0.0.0:5001->5000/tcp
homework-nodejs       homework-nodejs:local       0.0.0.0:3001->3000/tcp
```

| URL | Response |
|---|---|
| http://localhost:3001 | `<h1>Hello World</h1>` Node.js application running in Docker. |
| http://localhost:5001 | `<h1>Hello World</h1>` Python application running in Docker. |
| http://localhost:8081 | `<h1>Hello World</h1>` Java application running in Docker. |
| http://localhost:8082 | `<h1>Hello World</h1>` Apache web server running in Docker. |
| http://localhost:8083 | React page. The built bundle contains the text `Hello World`. |
| http://localhost:8084 | `<h1>Hello World</h1>` Nginx application running in Docker. |
| http://localhost:8080 | `<h1>Hello World from Docker multi-stage build</h1>` |

Full `curl` transcript: [running-output.txt](running-output.txt).

The containers were stopped after this capture so they would not keep running. Start them again with `./build-and-run.sh` if you still need browser screenshots for the form.
