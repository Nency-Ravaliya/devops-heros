#!/bin/bash
set -e
echo "Starting build..."
rm -rf build
mkdir -p build
echo "Application version: 1.0.0" > build/version.txt
echo "Build status: SUCCESS" > build/build-info.txt
cat > build/app.txt <<EOF
Session 16 Calculator Application
This file was generated during the CI build.
EOF
echo "Build completed successfully."
