#!/usr/bin/env bash
set -e

echo "================================================="
echo " Starting Application Packaging & Build"
echo " Author: Durga Prasad (Enrollment: 10012)"
echo " Date: $(date)"
echo "================================================="

BUILD_DIR="build"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/app"

# Copy application artifacts
cp -r app/*.py "${BUILD_DIR}/app/"
cp requirements.txt "${BUILD_DIR}/"

# Generate build metadata
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "local-build")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

cat > "${BUILD_DIR}/build-info.json" <<EOF
{
  "application": "devops-calculator",
  "version": "1.0.0",
  "build_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "git_commit": "${GIT_COMMIT}",
  "git_branch": "${GIT_BRANCH}",
  "status": "SUCCESS"
}
EOF

cat > "${BUILD_DIR}/build-info.txt" <<EOF
Application: DevOps Calculator
Author: Durga Prasad (10012)
Version: 1.0.0
Build Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Git Commit: ${GIT_COMMIT}
Git Branch: ${GIT_BRANCH}
Build Status: SUCCESS
EOF

echo "Build artifacts packaged in ./${BUILD_DIR}:"
ls -la "${BUILD_DIR}"
echo "Build completed successfully."
