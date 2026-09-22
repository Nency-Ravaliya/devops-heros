# Secrets

```yaml
- name: Push Docker image
  env:
    DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
  run: echo "$DOCKER_PASSWORD" | docker login -u myuser --password-stdin
```

Never hardcode passwords or API keys in workflow files.

---

## 1. The Problem

Without secrets:

```yaml
# BAD - Never do this
- name: Deploy
  run: aws configure set aws_access_key_id AKIAIOSFODNN7EXAMPLE
```

This exposes your credentials in Git history. Anyone who has access to the repository can read them.

---

## 2. What are GitHub Secrets?

GitHub Secrets are encrypted key-value pairs stored securely in GitHub.

```text
Stored in GitHub (encrypted at rest)
        │
        ▼
Referenced in workflows as ${{ secrets.NAME }}
        │
        ▼
Injected at runtime into the runner
        │
        ▼
Masked in all workflow logs
```

---

## 3. Create a Secret

Steps:

```text
1. Go to your GitHub repository
2. Click Settings
3. Click Secrets and variables > Actions
4. Click New repository secret
5. Enter Name: DOCKER_PASSWORD
6. Enter Value: your-actual-password
7. Click Add secret
```

You can never read the secret value again after saving. You can only update or delete it.

---

## 4. Use a Secret in a Workflow

```yaml
name: Deploy

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Login to Docker Hub
        env:
          DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
          DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
        run: |
          echo "$DOCKER_PASSWORD" | docker login \
            -u "$DOCKER_USERNAME" --password-stdin
```

---

## 5. Secrets are Masked in Logs

If a secret value is printed accidentally, GitHub replaces it with `***`:

```text
Run echo "$DOCKER_PASSWORD"
***
```

---

## 6. Environment-Level Secrets

You can have different secrets for different environments:

```text
Repository secrets:     available to all workflows
Environment secrets:    only available when deploying to that environment
```

Set environment secrets:

```text
Settings > Environments > New environment > "production"
Add secrets for that environment
```

Use in workflow:

```yaml
jobs:
  deploy:
    environment: production
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying to production"
```

---

## 7. Common Secrets You Will Use

```text
DOCKER_USERNAME       = Docker Hub username
DOCKER_PASSWORD       = Docker Hub password or token
AWS_ACCESS_KEY_ID     = AWS access key
AWS_SECRET_ACCESS_KEY = AWS secret key
KUBECONFIG            = base64-encoded kubeconfig file
SLACK_WEBHOOK_URL     = Slack notification webhook
GITHUB_TOKEN          = automatically provided by GitHub
```

`GITHUB_TOKEN` is special. GitHub provides it automatically for every workflow run. You do not need to create it.

---

## 8. Using GITHUB_TOKEN

```yaml
- name: Push to GitHub Container Registry
  run: |
    echo "${{ secrets.GITHUB_TOKEN }}" | \
      docker login ghcr.io -u ${{ github.actor }} --password-stdin
    docker push ghcr.io/${{ github.repository }}/myapp:latest
```

`GITHUB_TOKEN` lets you push to GitHub Container Registry and GitHub Packages without creating a separate secret.

---

## Key Learning

```text
Never hardcode credentials in workflow YAML
Store secrets in GitHub > Settings > Secrets and variables
Reference as ${{ secrets.SECRET_NAME }}
Secrets are masked in logs
GITHUB_TOKEN is provided automatically for every run
```

---

## Reference

* **Using secrets in GitHub Actions:** https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
* **GITHUB_TOKEN permissions:** https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication
