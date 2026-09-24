# 07 - Secrets

## 1. What is a Secret?

A secret is sensitive information such as:
* Password
* API Token
* Cloud Credential
* Access Key
* Database Password

---

## 2. Create Repository Secret

Go to:
**Repository** → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Create:
* **Name**: `DEMO_SECRET`
* **Value**: `hello-github-actions`

*(For a classroom demo, use a fake value only.)*

---

## 3. Access Secret

Inside the workflow:
```yaml
env:
  DEMO_SECRET: ${{ secrets.DEMO_SECRET }}
```

---

## 4. Do NOT Hardcode Secrets

**Bad:**
```yaml
password: mypassword123
```

**Good:**
```yaml
password: ${{ secrets.MY_PASSWORD }}
```

---

## 5. Do NOT Print Secrets

**Never do:**
```bash
echo "$DEMO_SECRET"
```

**Instead:**
```bash
if [ -n "$DEMO_SECRET" ]; then
  echo "Secret is available."
fi
```

---

## 6. Expected Output

```text
Secret is available.
```

If the secret is missing:
```text
Secret is not configured.
```
The workflow will fail.

---

### 💡 Key Takeaway
> Secrets should be stored securely and injected into workflows only when required.
