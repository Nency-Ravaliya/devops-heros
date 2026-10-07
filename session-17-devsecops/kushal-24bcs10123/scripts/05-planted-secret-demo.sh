#!/usr/bin/env bash
# 05: what the secret-scan stage catches. A fake AWS access key id is written into the app, scanned, then removed.
# The key is not real: it only has the AKIA + 16 base32 chars shape that the gitleaks aws-access-token rule looks for.
. "$(dirname "$0")/lib.sh"
cd secure-converter
hr "clean tree"
x "gitleaks dir . --config security/gitleaks.toml --exit-code 1 --redact --no-banner 2>&1; echo exit=\$?"
hr "a developer 'temporarily' hard-codes a credential"
x "printf 'S3_BUCKET = \"converter-exports\"\nAWS_ACCESS_KEY_ID = \"AKIAQ3ZX7TP2M6VKL4WD\"  # fake, planted for the secret-scan demo\n' > app/config_example.py"
x "cat app/config_example.py"
x "gitleaks dir . --config security/gitleaks.toml --exit-code 1 --redact --no-banner --verbose 2>&1; echo exit=\$?"
hr "remove it again"
x "rm app/config_example.py"
x "gitleaks dir . --config security/gitleaks.toml --exit-code 1 --redact --no-banner 2>&1; echo exit=\$?"
