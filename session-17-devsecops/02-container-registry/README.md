# 02 - Container Registry

Store the Docker image in a container registry so Kubernetes or another environment can pull it.

For this session we use **GitHub Container Registry (GHCR)**.

## Flow

```text
Docker Build
     ↓
Docker Image
     ↓
GHCR
     ↓
Kubernetes
```

## Image Name

```text
ghcr.io/OWNER/REPOSITORY:TAG
```

Example:

```text
ghcr.io/my-user/session17-devsecops-python:8a72f31
```

## GitHub Actions Permissions

```yaml
permissions:
  contents: read
  packages: write
```

## Login to GHCR

```yaml
- name: Login to GHCR
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

## Build and Push

```yaml
- name: Build image
  run: |
    docker build \
      -t ghcr.io/${{ github.repository }}:${{ github.sha }} .

- name: Push image
  run: |
    docker push \
      ghcr.io/${{ github.repository }}:${{ github.sha }}
```

GitHub documents `GITHUB_TOKEN` authentication and `packages: write` permission for publishing repository-associated images to GHCR. citeturn0search0turn0search7

## Verify

Open the GitHub repository and find the published container package. Confirm that its tag matches the commit SHA.

## Practice Questions

1. Build an image.
2. Login to GHCR through Actions.
3. Push the image.
4. Find the package in GitHub.
5. Copy the exact image name and tag.
