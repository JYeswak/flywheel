#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/journey-smoke.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-journey-smoke-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  local rc=$?
  set +e
  return "$rc"
}

if bash -n "$SCRIPT" && "$SCRIPT" --help >/dev/null; then
  pass "syntax"
else
  fail "syntax"
fi

run_capture "$TMP/matrix.json" "$TMP/matrix.err" "$SCRIPT" --matrix claude,codex,openclaw,gemini,reduced --dry-run --json
matrix_rc=$?
if [[ "$matrix_rc" -eq 0 ]] && jq -e '
  .schema_version == "flywheel.journey_smoke.v0"
  and .status == "pass"
  and (.rows | length == 5)
  and ([.rows[] | select(.registry_valid == true)] | length == 5)
  and ([.rows[] | select(.id == "reduced" and .runtime_proven == true and .dispatch_or_simulate == "pass")] | length == 1)
' "$TMP/matrix.json" >/dev/null; then
  pass "matrix envelope"
else
  fail "matrix envelope rc=${matrix_rc}"
fi

if jq -e '
  .rows[]
  | select(.id == "reduced")
  | .stages.preflight.status == "pass"
    and .stages.init.status == "initialized"
    and .stages.doctor.status == "pass"
    and .stages.tick.status == "pass"
    and .stages.dispatch_or_simulate.status == "pass"
    and .stages.dispatch_or_simulate.real_dispatch == false
    and .stages.closeout.status == "pass"
    and .stages.inspect_next_action.status == "pass"
' "$TMP/matrix.json" >/dev/null; then
  pass "reduced runtime stages"
else
  fail "reduced runtime stages"
fi

if jq -e '
  [.rows[] | select(.id != "reduced" and .registry_valid == true and .runtime_proven == false and .dispatch_or_simulate == "not_run")]
  | length == 4
' "$TMP/matrix.json" >/dev/null; then
  pass "agent lanes remain registry-only"
else
  fail "agent lanes remain registry-only"
fi

run_capture "$TMP/reduced.json" "$TMP/reduced.err" "$SCRIPT" --matrix reduced --dry-run --json
reduced_rc=$?
if [[ "$reduced_rc" -eq 0 ]] && jq -e '.summary.lanes == 1 and .summary.runtime_proven == 1' "$TMP/reduced.json" >/dev/null; then
  pass "reduced-only matrix"
else
  fail "reduced-only matrix rc=${reduced_rc}"
fi

run_capture "$TMP/unknown.out" "$TMP/unknown.err" "$SCRIPT" --matrix unknown --dry-run --json
unknown_rc=$?
if [[ "$unknown_rc" -eq 64 ]] && rg -q "unknown journey-smoke lane" "$TMP/unknown.err"; then
  pass "unknown lane rejected"
else
  fail "unknown lane rejected rc=${unknown_rc}"
fi

if ! rg -n '/Users/josh|TOKEN|CANARY|secret' "$TMP"/*.json >/dev/null; then
  pass "outputs avoid private markers"
else
  fail "outputs avoid private markers"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
