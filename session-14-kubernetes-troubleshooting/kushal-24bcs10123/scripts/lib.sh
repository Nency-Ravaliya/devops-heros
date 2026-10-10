# shared helpers. Every script cd's into session-14-kubernetes-troubleshooting/ so the commands
# read like the course READMEs (kubectl apply -f 06-crashloopbackoff/...). Everything runs in my own
# namespaces (passed with -n) because the cluster is shared with my other session labs.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ME="$ROOT/kushal-24bcs10123"
L="$ME/logs"
S="$ME/screenshots"
cd "$ROOT"
x()  { printf '\n$ %s\n' "$1"; eval "$1" 2>&1; }
hr() { printf '\n############ %s ############\n' "$1"; }
# background watch into a file, stopped with watch_stop
watch_start() { WATCHFILE="$1"; shift; "$@" -w > "$WATCHFILE" 2>&1 & WATCHPID=$!; sleep 1; }
watch_stop()  { sleep 3; kill "$WATCHPID" 2>/dev/null; wait "$WATCHPID" 2>/dev/null; }
# wait until a pod is Ready (or give up after N seconds)
wait_ready() { kubectl -n "$1" wait --for=condition=Ready pod/"$2" --timeout="${3:-120}s" 2>&1; }
# fresh namespace for a lab
ns_reset() { kubectl delete ns "$1" --ignore-not-found --wait=true >/dev/null 2>&1; kubectl create ns "$1" >/dev/null; echo "namespace/$1 created"; }
# render a text file as a terminal-looking PNG (headless Chrome) -> screenshots/<name>.png
shot_text() { # name title file
  local html="/tmp/shot-$$.html"
  { printf '<html><head><meta charset="utf-8"><style>body{background:#1e1e1e;color:#d4d4d4;font:13px/1.35 Menlo,monospace;padding:18px;margin:0}h1{font-size:13px;color:#9cdcfe;margin:0 0 10px}pre{margin:0;white-space:pre-wrap}</style></head><body><h1>%s</h1><pre>' "$2"
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$3"; printf '</pre></body></html>'; } > "$html"
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars \
    --screenshot="$S/$1.png" --window-size=1200,"${4:-800}" "file://$html" >/dev/null 2>&1
  rm -f "$html"; echo "screenshot -> screenshots/$1.png"; }
shot_url() { # name url
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars \
    --screenshot="$S/$1.png" --window-size=1200,700 "$2" >/dev/null 2>&1; echo "screenshot -> screenshots/$1.png"; }
# macOS has no coreutils `timeout`; small bash stand-in (run cmd, kill it after N seconds)
command -v timeout >/dev/null 2>&1 || timeout() { local t="$1"; shift; "$@" & local p=$!; ( sleep "$t"; kill "$p" 2>/dev/null ) & local w=$!; wait "$p" 2>/dev/null; kill "$w" 2>/dev/null; }
