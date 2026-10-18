# Session 16: CI/CD with GitHub Actions

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

The root workflow `.github/workflows/session16-cicd.yml` tests the HTTP
application, uploads test output, builds an image, and publishes a commit-SHA tag
to GHCR on trusted pushes. Pull requests build without registry credentials.
Run `python -m unittest -v`, then `python app.py` and curl `/health` locally.

CI checks code and builds; CD prepares and deploys tested releases. A workflow
contains jobs, jobs run on runners, and steps execute commands or actions. `needs`
ensures deployment follows successful tests and build. Artifacts preserve test evidence.

Enable Actions in the fork. Configure the `practice` environment's `KUBE_CONFIG`
secret with a least-privilege practice-cluster kubeconfig, then run the workflow
manually with deploy checked. The cluster must be reachable from the runner.
Private GHCR images need imagePullSecrets; public teaching images can be pulled
without registry credentials. `GITHUB_TOKEN` comes from Actions and is not committed.
Pipeline run evidence is pending. Local checks are in `evidence/`.

The workflow also runs for relevant pushes to the combined submission branch.
GHCR publication and deployment are restricted to this student's fork; pull
requests run tests and builds without publishing or deploying.

## Verification

Five HTTP endpoint tests passed; Docker build and HTTP check passed.

GitHub Actions run, GHCR publication and cluster deployment are pending.

Command output: [evidence/](evidence/).
