#!/bin/bash
set -e
echo "Starting application build"
rm -rf build
mkdir -p build
cp -r app build/app
cp requirements.txt build/
cat > build/build-info.txt <<INFO
Application: Calculator API
Build Status: SUCCESS
Commit: ${GITHUB_SHA:-local}
Build Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
INFO
echo "Build files:"
ls -la build
echo "Build completed successfully."
