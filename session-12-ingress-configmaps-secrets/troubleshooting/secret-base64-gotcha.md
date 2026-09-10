# Stop: The Trailing Newline Secret Bug: Incident Post-Mortem

This issue causes 80% of database authentication failures when students create their first Kubernetes Secrets.

---

## The Incident
- **Symptom:** PostgreSQL pod rejects application connections with `FATAL: password authentication failed for user "yatri_admin"`.
- **The Developer's Claim:** *"I verified the password is correct! In my secret YAML, I typed `echo "mypassword" | base64`."*

---

## The Investigation
Let's see what happens when you run standard `echo`:
```bash
echo "mypassword" | xxd
```
Output:
```text
00000000: 6d79 7061 7373 776f 7264 0a              mypassword.
```
Notice the last byte: `0a`! That is the ASCII character for **`\n` (newline)**!  
When base64 encoded:
```bash
echo "mypassword" | base64
# Yields: bXlwYXNzd29yZAo=
```
The application process receives: `mypassword\n` (11 characters) instead of `mypassword` (10 characters)! The database correctly rejects the password.

---

## The Fix
Always use the `-n` flag to suppress the trailing newline:
```bash
echo -n "mypassword" | base64
# Yields: bXlwYXNzd29yZA==
```
*Notice how the Base64 ends in `==` instead of `Ao=`.*
