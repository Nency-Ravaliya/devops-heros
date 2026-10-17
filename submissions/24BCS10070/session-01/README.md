# Session 1: DevOps roadmap

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

These are my introductory notes. The shared homework starts with Linux in Session 2.

DevOps connects development and operations through shared responsibility and automation.
A useful starting path is Linux → networking → Git → scripting → containers → Kubernetes
→ CI/CD → cloud and Terraform → monitoring. I would learn one small example at each step.

For a web application, I would keep the source in Git, run tests on a pull request,
build a container image, deploy it, then watch its health and logs. A deployment is
not the end of the work: feedback helps find the next improvement.

| Term | My understanding | Example |
|---|---|---|
| CI | Check changes together often | Run tests on a push |
| Continuous delivery | Keep a tested release ready | Human approves production release |
| Continuous deployment | Automatically release passing changes | Deploy after all gates pass |
| Infrastructure as code | Describe infrastructure in versioned files | Terraform VPC |
| Observability | Use system signals to investigate behaviour | Metrics, logs, traces |

My practice goal is to explain each command I run and understand useful error messages.

## Verification

Introductory notes prepared.

No separate homework was listed for Session 1.
