# Session 15: Helm Homework

## Task 1 - Helm commands

Used `helm lint`, `template`, `install`, `list`, `status`, `get values`, `upgrade`, `history`, and `rollback` with the Notes chart mini project.

![Helm commands](screenshots/task1.png)

<br><br>

![Helm release status and values](screenshots/task1.1.png)

<br><br>

![Helm upgrade and Kubernetes resources](screenshots/task1.2.png)

<br><br>

![Helm release details](screenshots/task1.3.png)

## Task 2 - Rollback workflow

Completed the workflow: install, upgrade, verify, upgrade with a broken image tag, inspect release history, roll back to the healthy revision, and verify. Helm history shows the deployed and superseded revisions.

![Release history and rollback](screenshots/task2.png)

<br><br>

![Rollback verification](screenshots/task2.1.png)

<br><br>

![Release history after rollback](screenshots/task2.2.png)

## Task 3 - Mini project

The Notes chart passed `helm lint`. The release was installed, upgraded with production values, rolled back, and its Kubernetes resources were verified. Chart files are in [`mini-project/notes-chart/`](mini-project/notes-chart/).

![Notes chart installation and upgrade](screenshots/task3.png)

<br><br>

![Notes release rollback](screenshots/task3.1.png)

<br><br>

![Mini-project release history](screenshots/task3.2.png)

<br><br>

![Mini-project Kubernetes resources](screenshots/task3.3.png)
