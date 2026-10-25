#!/usr/bin/env bash
# 01: what the CI "test" and "build" jobs do, run on my laptop first.
. "$(dirname "$0")/lib.sh"
cd unit-converter
x "python --version"
x "pytest -v"
hr "build step = byte-compile + bundle + build-info"
x "./build.sh"
x "rm -rf build"
