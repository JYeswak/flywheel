#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/daily-jeff-ingest.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/daily-jeff-bounds.XXXXXX")"
trap 'rm -r "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

mkdir -p "$TMP/bin" "$TMP/state"

cat >"$TMP/bin/curl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
out=""
url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out="${2:?}"; shift 2 ;;
    http*) url="$1"; shift ;;
    *) shift ;;
  esac
done
printf '%s\n' "$url" >>"${FAKE_CURL_LOG:?}"
case "$url" in
  *api.github.com*)
    printf '[{"name":"ntm"},{"name":"mcp-agent-mail"}]\n' >"$out"
    ;;
  *.atom)
    cat >"$out" <<'XML'
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry><title>fixture commit</title><updated>2026-05-14T00:00:00Z</updated><link href="https://example.test/commit"/></entry>
</feed>
XML
    ;;
  *rss.xml)
    printf '<rss><channel><item><title>Fixture</title><link>https://example.test/rss</link><pubDate>Thu, 14 May 2026 00:00:00 GMT</pubDate></item></channel></rss>\n' >"$out"
    ;;
  *)
    printf '<html>fixture</html>\n' >"$out"
    ;;
esac
SH
chmod +x "$TMP/bin/curl"

cat >"$TMP/storage-probe.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
jq -nc '{status:"pass",disk_free_pct:99,disk_free_gb:999,warnings:[]}'
SH
chmod +x "$TMP/storage-probe.sh"

cat >"$TMP/jeff-shadow.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
jq -nc '{status:"ok",repo_count:0,indexed_count:0,state_file:null}'
SH
chmod +x "$TMP/jeff-shadow.sh"

: >"$TMP/sources.txt"
for i in $(seq 1 20); do
  printf 'https://github.com/Dicklesworthstone/repo-%02d/commits/main.atom\n' "$i" >>"$TMP/sources.txt"
done

FAKE_CURL_LOG="$TMP/curl.log" \
PATH="$TMP/bin:$PATH" \
DAILY_JEFF_STATE_DIR="$TMP/state" \
DAILY_JEFF_SOURCES_FILE="$TMP/sources.txt" \
DAILY_JEFF_CHECK_SCRIPT="$TMP/missing-check.sh" \
DAILY_JEFF_SNAPSHOT_DIFF_SCRIPT="$TMP/missing-snapshot.sh" \
DAILY_JEFF_STORAGE_PROBE="$TMP/storage-probe.sh" \
DAILY_JEFF_SHADOW_SOCRATICODE_SCRIPT="$TMP/jeff-shadow.sh" \
DAILY_JEFF_FETCH_MAX_TIME=1 \
DAILY_JEFF_GITHUB_FEED_LIMIT=3 \
  "$SCRIPT" --dry-run --json >"$TMP/out.json"

atom_fetches="$(grep -c 'github.com/.*/commits/main.atom' "$TMP/curl.log" || true)"
if [[ "$atom_fetches" == "3" ]]; then
  pass "dry_run_bounds_github_atom_fetches"
else
  fail "dry_run_bounds_github_atom_fetches expected=3 actual=$atom_fetches"
  cat "$TMP/curl.log" >&2
fi

if jq -e '.success == true and .dry_run == true and any(.warnings[]; contains("GitHub atom dry-run feed limit applied"))' "$TMP/out.json" >/dev/null; then
  pass "dry_run_receipt_discloses_feed_limit"
else
  fail "dry_run_receipt_discloses_feed_limit"
  cat "$TMP/out.json" >&2
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
