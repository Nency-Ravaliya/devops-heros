# shared helpers for session 19. Every script cd's into kushal-24bcs10123/ first.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
L="$ROOT/logs"
cd "$ROOT"
x()  { printf '\n$ %s\n' "$1"; eval "$1" 2>&1; }
hr() { printf '\n############ %s ############\n' "$1"; }
# LocalStack: an AWS API emulator in Docker on http://localhost:4566. Any access key works, it just has to be set.
LS="http://localhost:4566"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1 AWS_PAGER=""
awsl() { aws --endpoint-url="$LS" "$@"; }     # "aws local"
# provider binaries are ~700 MB: download once into a shared cache instead of once per project
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"; mkdir -p "$TF_PLUGIN_CACHE_DIR"
# terraform with ANSI colour codes stripped (keeps the real exit code for -detailed-exitcode)
tf() { terraform "$@" 2>&1 | sed $'s/\e\\[[0-9;]*m//g'; return "${PIPESTATUS[0]}"; }
