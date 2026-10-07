# shared helpers. Every script cd's into session-17-devsecops/kushal-24bcs10123 so paths read like the README.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
L="$ROOT/logs"
cd "$ROOT"
export PATH="$HOME/.venvs/devsec/bin:$HOME/.venvs/s16app/bin:/opt/homebrew/bin:$PATH"
x()  { printf '\n$ %s\n' "$1"; eval "$1" 2>&1; }
hr() { printf '\n############ %s ############\n' "$1"; }
