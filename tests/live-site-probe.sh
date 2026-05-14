#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/live_site_probe.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-live-site-probe.XXXXXX")"
SERVER_PID=""
trap '[[ -n "$SERVER_PID" ]] && kill "$SERVER_PID" 2>/dev/null || true; rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

mkdir -p "$TMP/site/about" "$TMP/site/assets"
cat >"$TMP/site/index.html" <<'HTML'
<!doctype html><html lang="en"><head><link rel="stylesheet" href="/styles.css"></head><body>
<a href="/about/#team">About</a>
<img src="/assets/loop-map.svg" alt="Loop map">
<a href="https://example.com">External</a>
</body></html>
HTML
cat >"$TMP/site/about/index.html" <<'HTML'
<!doctype html><html lang="en"><body><h1 id="team">Team</h1><a href="/">Home</a></body></html>
HTML
printf 'body { color: #111; }\n' >"$TMP/site/styles.css"
printf '<svg xmlns="http://www.w3.org/2000/svg"></svg>\n' >"$TMP/site/assets/loop-map.svg"

python3 - "$TMP/site" "$TMP/port" <<'PY' &
import functools
import http.server
import pathlib
import socketserver
import sys

directory = sys.argv[1]
port_file = pathlib.Path(sys.argv[2])


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        return


handler = functools.partial(QuietHandler, directory=directory)
with socketserver.TCPServer(("127.0.0.1", 0), handler) as httpd:
    port_file.write_text(str(httpd.server_address[1]), encoding="utf-8")
    httpd.serve_forever()
PY
SERVER_PID=$!

for _ in $(seq 1 50); do
  [[ -s "$TMP/port" ]] && break
  sleep 0.1
done
if [[ ! -s "$TMP/port" ]]; then
  fail "fixture server started"
  exit 1
fi
pass "fixture server started"

base_url="http://127.0.0.1:$(cat "$TMP/port")/"
if result="$(python3 "$SCRIPT" --site "$TMP/site" --base-url "$base_url" --json)" \
  && jq -e '
    .schema_version == "flywheel.live_site_probe.v0"
    and .status == "pass"
    and .source_count == 2
    and .probe_count >= 4
    and .failure_count == 0
    and .skipped_external_count == 1
  ' <<<"$result" >/dev/null; then
  pass "valid fixture probes first-party pages and assets"
else
  fail "valid fixture probes first-party pages and assets"
  jq -c . <<<"${result:-{}}" >&2
fi

cat >"$TMP/site/about/index.html" <<'HTML'
<!doctype html><html lang="en"><body><h1>No target id</h1></body></html>
HTML
if broken="$(python3 "$SCRIPT" --site "$TMP/site" --base-url "$base_url" --json 2>/dev/null)"; then
  fail "broken fixture exits non-zero"
else
  if jq -e '.status == "fail" and any(.failures[]; .reason == "missing_fragment")' <<<"$broken" >/dev/null; then
    pass "broken fixture reports missing fragment"
  else
    fail "broken fixture reports missing fragment"
    jq -c . <<<"$broken" >&2
  fi
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
