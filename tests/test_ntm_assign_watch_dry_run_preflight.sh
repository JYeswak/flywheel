#!/usr/bin/env bash
# Verify the auto-assign watch preflight uses dry-run planner output only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SESSION="${FLYWHEEL_SESSION:-flywheel}"
TMP="$(mktemp -d -t watch-dry-run.XXXXXX)"
NTM_BIN="${NTM_BIN:-$TMP/ntm}"

cleanup() {
  rm -f "$TMP/ntm" "$TMP/before.json" "$TMP/after.json" "$TMP/out.txt" "$TMP/err.txt" "$TMP/argv.txt"
  rmdir "$TMP" 2>/dev/null || true
}
trap cleanup EXIT

cat >"$NTM_BIN" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  --robot-activity=*)
    jq -nc '{agents:[
      {pane_idx:2,pane:2,agent_type:"codex",state:"WAITING",activity:"WAITING"},
      {pane_idx:3,pane:3,agent_type:"codex",state:"THINKING",activity:"THINKING"},
      {pane_idx:4,pane:4,agent_type:"codex",state:"WAITING",activity:"WAITING"}
    ]}'
    ;;
  assign)
    printf '%s\n' "$*" >"${FAKE_NTM_ARGV:?}"
    printf 'Watching for completions...\n'
    printf 'Would assign (dry-run): flywheel-fixture -> pane 2\n'
    ;;
  *)
    printf 'unexpected fake ntm call: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$NTM_BIN"

normalize_activity() {
  jq -S '[.agents[]? | {
    pane:(.pane // .pane_idx),
    agent_type:(.agent_type // null),
    state:(.state // null),
    activity:(.activity // null)
  }]'
}

"$NTM_BIN" --robot-activity="$SESSION" --json | normalize_activity >"$TMP/before.json"

FAKE_NTM_ARGV="$TMP/argv.txt" "$NTM_BIN" assign "$SESSION" \
  --repo "$ROOT" \
  --watch \
  --dry-run \
  --limit=1 \
  --stop-when-done \
  >"$TMP/out.txt" 2>"$TMP/err.txt"

"$NTM_BIN" --robot-activity="$SESSION" --json | normalize_activity >"$TMP/after.json"

grep -q 'Would assign' "$TMP/out.txt"
if grep -q 'Assigned' "$TMP/out.txt" "$TMP/err.txt"; then
  echo "FAIL: dry-run preflight emitted live assignment wording" >&2
  exit 1
fi

grep -q -- "assign $SESSION" "$TMP/argv.txt"
grep -q -- "--watch" "$TMP/argv.txt"
grep -q -- "--dry-run" "$TMP/argv.txt"
grep -q -- "--limit=1" "$TMP/argv.txt"
grep -q -- "--stop-when-done" "$TMP/argv.txt"

diff -u "$TMP/before.json" "$TMP/after.json" >/dev/null

echo "PASS ntm assign --watch --dry-run preflight emits Would assign and leaves pane state unchanged"
