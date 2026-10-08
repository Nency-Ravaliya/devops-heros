![alt text](image-1.png)
![alt text](image.png)
![alt text](image-2.png)
![alt text](image-3.png)
![alt text](image-4.png)
![alt text](image-6.png)
![alt text](image-5.png)
![alt text](image-7.png)
![alt text](image-8.png)

# Session 21: TaskBoard Final DevOps Project

## Local execution

The TaskBoard stack was run using the documented Docker Compose workflow. It starts PostgreSQL, the FastAPI backend, and the React/Nginx frontend.

During verification, the backend attempted its Alembic migration before PostgreSQL was ready. `docker-compose.yml` now has a PostgreSQL health check and waits for `service_healthy`, so the migration completes before Uvicorn starts.

![Compose stack and health checks](screenshots/task-1-local-compose/stack-and-health.png)

## Quality and deployment assets

- Backend API tests: **3 passed**.
- Helm TaskBoard chart: **lint passed**.
- The repository contains Dockerfiles, Compose configuration, Helm, Kubernetes, monitoring, CI/CD, Terraform, and troubleshooting folders as described in the main project README.

![Tests and Helm lint](screenshots/task-2-quality-and-helm/tests-and-helm-lint.png)

## Troubleshooting lab

The deliberately broken image and Service manifests, plus the TaskBoard namespace manifest, were validated with client-side Kubernetes dry runs. They are ready for the investigation steps documented in `README.md` when a suitable cluster/image registry target is configured.

![Troubleshooting manifest validation]

## Notes

The local application and validation steps were executed without provisioning AWS infrastructure, pushing container images, or running a GitHub-hosted workflow. Those stages require the repository, cloud account, registry, and GitHub secrets described in the main README.
