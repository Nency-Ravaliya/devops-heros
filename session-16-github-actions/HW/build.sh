#!/bin/bash
# Packages the app into build/ as a tarball + build-info.txt (uploaded as an artifact by CI).
set -euo pipefail

VERSION="${1:-dev}"

echo "================================="
echo "Building session16-calculator ${VERSION}"
echo "================================="
rm -rf build
mkdir -p build

tar -czf "build/session16-calculator-${VERSION}.tar.gz" app/ requirements.txt Dockerfile

cat > build/build-info.txt <<EOF
Application: session16-calculator
Version:     ${VERSION}
Commit:      ${GITHUB_SHA:-local}
Built by:    ${GITHUB_ACTOR:-$(whoami)}
Runner OS:   ${RUNNER_OS:-$(uname -s)}
Build date:  $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

ls -l build
cat build/build-info.txt
echo "Build completed successfully."
