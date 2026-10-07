#!/bin/bash
# Packages the application into build/ - uploaded by the pipeline as an artifact
set -e
echo "================================="
echo "Starting Application Build"
echo "================================="
rm -rf build
mkdir -p build
cp -r app requirements.txt build/
cat > build/build-info.txt <<INFO
Application: Session 16 Calculator API
Build Status: SUCCESS
Commit: ${GITHUB_SHA:-local}
Run: ${GITHUB_RUN_NUMBER:-local}
Build Date: $(date -u)
INFO
tar -czf calculator-build.tar.gz -C build .
ls -la build calculator-build.tar.gz
echo "Build completed successfully."
