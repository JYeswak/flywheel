#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
FIXTURE="$ROOT/.flywheel/tests/fixtures/capacity-halt-live"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/capacity-halt-live-detect.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

set +e
"$SCRIPT" --fixture "$FIXTURE" --dry-run --json >"$TMP/live.out" 2>"$TMP/live.err"
rc=$?
set -e

[[ "$rc" -eq 1 ]] && pass "capacity_halt_returns_stuck_rc" || {
  fail "capacity_halt_returns_stuck_rc"
  cat "$TMP/live.err" >&2 || true
}

assert_jq "$TMP/live.out" '.status == "stuck" and .stuck_count == 1' "capacity_halt_stuck_count"
assert_jq "$TMP/live.out" '.dry_run == true and .apply == false' "capacity_halt_no_mutation"
assert_jq "$TMP/live.out" '.panes[0].subclass == "model_at_capacity_halt"' "capacity_halt_subclass"
assert_jq "$TMP/live.out" '.panes[0].recommended_recovery == "auto_continue"' "capacity_halt_recovery"
assert_jq "$TMP/live.out" '(.panes[0].hash_t0 | length) == 64 and (.panes[0].hash_t1 | length) == 64' "capacity_halt_hashes_present"

printf 'Capacity live detect summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
