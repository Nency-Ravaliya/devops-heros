# Session 21 screenshot evidence

The submission uses exactly two original screenshots in `../ss/`:

1. `01-tests.png` — nine API tests pass; all three Docker Compose services are running.
2. `02-app.png` — TaskBoard at localhost:3000 with Chhavi Ahlawat and three loaded tasks.

Both are embedded in the session README. No generated terminal screenshots or additional deployment captures are included. Deployment work was stopped at the student's request; unverified components are identified in the README.

The previous minikube cluster and its data were retained. The `opspulse` workloads and Argo CD services were temporarily paused. `restore-opspulse.sh` records their previous replica settings and restores auto-sync; it is provided for a later deliberate restart, not run as part of publishing this submission.
