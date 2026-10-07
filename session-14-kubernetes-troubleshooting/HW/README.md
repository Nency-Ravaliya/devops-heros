# Session 14 Homework: Kubernetes Troubleshooting

**Submitted by:** Piyush Bansal

All demos were run on Docker Desktop Kubernetes (single arm64 node). The output in each README is real.

| Task | README | What's in it |
|---|---|---|
| 1. Kubernetes Commands | [01-kubectl-commands/README.md](01-kubectl-commands/README.md) | get, get -o wide, describe, logs, exec, events, explain, top |
| 2. Common Issues | [02-common-issues/README.md](02-common-issues/README.md) | CrashLoopBackOff, ImagePullBackOff, ErrImagePull, Pending, ContainerCreating, Service connectivity, DNS, Pod networking, configuration. Each one has the problem, investigation, root cause, fix and verification |
| 3. Mini Project | [03-mini-project/README.md](03-mini-project/README.md) | The session's troubleshooting challenge: broken image, wrong Service selector, the answers and the table |

Not completed as planned: in the ErrImagePull case the registry lookup was slow, so the Pod showed
`ContainerCreating`/`Pulling` and never reached the `ErrImagePull` status within my capture window. The cause
was still confirmed through the Docker Hub API, and the `ErrImagePull` status shows up in the ImagePullBackOff
case and in the mini project.
