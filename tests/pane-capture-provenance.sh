#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WATCHER="${IDLE_PANE_AUTO_DISPATCH:-$ROOT/.flywheel/scripts/idle-pane-auto-dispatch.sh}"
DISPATCH_MD="${DISPATCH_MD:-/Users/josh/.claude/commands/flywheel/dispatch.md}"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/pane-capture-provenance.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() {
  printf 'FAIL pane-capture-provenance: %s\n' "$*" >&2
  exit 1
}

write_fixture() {
  local name="$1" pane="$2" state="$3" provenance="$4" error="$5"
  jq -nc \
    --argjson pane "$pane" \
    --arg state "$state" \
    --arg provenance "$provenance" \
    --arg error "$error" \
    '{success:true,agents:[{pane_idx:$pane,agent_type:"codex",state:$state,capture_provenance:$provenance,capture_collected_at:"2026-05-04T00:00:00Z",capture_error:$error}]}' \
    >"$tmp/$name.json"
}

selected_panes() {
  jq -r '.agents[] | select(.pane_idx>=2 and .pane_idx<=4 and .state=="WAITING" and .capture_provenance=="live") | .pane_idx' "$1"
}

assert_selected() {
  local fixture="$1" expected="$2" actual
  actual="$(selected_panes "$tmp/$fixture.json" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  [[ "$actual" == "$expected" ]] || fail "$fixture selected '$actual', expected '$expected'"
}

write_fixture live-waiting 2 WAITING live null
write_fixture live-error 3 ERROR live null
write_fixture unavailable-with-error 4 WAITING unavailable '"capture failed"'
write_fixture unavailable-without-error 2 WAITING unavailable null

assert_selected live-waiting 2
assert_selected live-error ""
assert_selected unavailable-with-error ""
assert_selected unavailable-without-error ""

[[ -f "$WATCHER" ]] || fail "watcher missing: $WATCHER"
rg -q 'capture_provenance=="live"' "$WATCHER" || fail "watcher does not require capture_provenance live"
rg -q 'state=="WAITING"' "$WATCHER" || fail "watcher does not require WAITING state"

[[ -f "$DISPATCH_MD" ]] || fail "dispatch doc missing: $DISPATCH_MD"
rg -q 'capture_provenance == "live"' "$DISPATCH_MD" || fail "dispatch gate does not require live capture provenance"
rg -q 'flywheel-respawn or' "$DISPATCH_MD" || fail "dispatch doc does not mention flywheel-respawn route"
rg -q 'flywheel-recovery' "$DISPATCH_MD" || fail "dispatch doc does not mention flywheel-recovery route"

printf 'PASS pane-capture-provenance fixtures=4 repo=%s\n' "$ROOT"
