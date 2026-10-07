# 06 - Secret Scanning

Detect and prevent credentials and other sensitive values from being committed to source control.

## Examples of Secrets

```text
API keys
Passwords
Access tokens
Private keys
Cloud credentials
Database credentials
```

## Never Do This

```python
AWS_ACCESS_KEY = "real-secret-value"
```

Never commit real credentials to Git.

## Better Approach

Use environment variables or a proper secret manager.

```python
import os

api_key = os.getenv("API_KEY")
```

In GitHub Actions:

```yaml
${{ secrets.API_KEY }}
```

## GitHub Secret Scanning

GitHub Secret Scanning can detect supported credential patterns in repository content. Push protection can help block supported secrets before they are pushed.

## Classroom Demo

Use only a fake value for demonstration:

```text
DEMO_API_KEY=replace-with-test-value
```

Do not use a real cloud key.

## If a Real Secret Is Leaked

Deleting the line is not enough.

```text
Secret exposed
     ↓
Revoke / rotate credential
     ↓
Remove it from code/history as required
     ↓
Check for unauthorized use
     ↓
Store replacement securely
```

Treat a real exposed credential as compromised.

## Practice Questions

Answer:

1. Why should secrets not be stored in source code?
2. What is the difference between a GitHub Actions secret and a source-code secret?
3. What should you do if a real cloud key is pushed accidentally?
