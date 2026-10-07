#!/usr/bin/env bash
# "Build" step for a Python service: byte-compile, bundle the sources and write build metadata.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf build && mkdir -p build
python -m compileall -q app
cp -r app requirements.txt Dockerfile build/
cat > build/build-info.txt <<INFO
app:          unit-converter
version:      $(python -c 'import app; print(app.__version__)')
git_sha:      ${GITHUB_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo local)}
build_number: ${GITHUB_RUN_NUMBER:-local}
built_at:     $(date -u +%Y-%m-%dT%H:%M:%SZ)
built_by:     ${GITHUB_ACTOR:-$(whoami)}
runner:       ${RUNNER_OS:-$(uname -s)} / ${RUNNER_ARCH:-$(uname -m)}
python:       $(python --version)
INFO
echo "build/ contents:"; find build -type f | sort; echo; cat build/build-info.txt
