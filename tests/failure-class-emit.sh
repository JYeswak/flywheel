#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HELPER="$ROOT/.flywheel/scripts/failure-class-emit.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/failure-class-emit.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

classify() {
  local name="$1" raw="$2"
  local out="$TMP/$name.json"
  "$HELPER" --raw "$raw" --json >"$out"
  printf '%s\n' "$out"
}

bash -n "$HELPER"
pass "helper shell syntax"

info_out="$TMP/info.json"
"$HELPER" --info >"$info_out"
assert_jq "$info_out" '.schema_version == "failure-taxonomy-envelope/v1" and .mutates == false' "canonical --info"

schema_out="$TMP/schema.json"
"$HELPER" schema >"$schema_out"
assert_jq "$schema_out" '.retry_policy_enum == ["none","exponential","manual","permanent"]' "retry policy enum"
assert_jq "$schema_out" '(.failure_class_enum | length) == 10 and (.failure_class_enum | index("correctness")) and (.failure_class_enum | index("invalid_callback"))' "failure class enum"

open_child="$(classify open-child 'validator_verdict=BLOCK_CLOSE_open_child_wbnb')"
assert_jq "$open_child" '.failure_class == "gate_unmet_open_children" and .retry_policy == "none"' "open child close block classified"

dcg="$(classify dcg 'dcg_block_handled=redirect_truncate_varfolders')"
assert_jq "$dcg" '.failure_class == "dcg_blocked_destructive_command" and .retry_policy == "manual"' "dcg redirect classified"

reservation="$(classify reservation 'bead_close_blocked_by=.beads_reservation_conflict_PurpleMeadow')"
assert_jq "$reservation" '.failure_class == "file_reservation_conflict" and .retry_policy == "manual"' "reservation conflict classified"

runtime="$(classify runtime 'runtime_unresponsive')"
assert_jq "$runtime" '.failure_class == "transient" and .retry_policy == "exponential"' "runtime timeout classified retryable"

artifact="$(classify artifact 'artifact_missing')"
assert_jq "$artifact" '.failure_class == "missing_artifact" and .retry_policy == "manual"' "missing artifact classified"

drift="$(classify drift 'context_drift')"
assert_jq "$drift" '.failure_class == "context_drift" and .retry_policy == "manual"' "context drift classified"

correctness="$(classify correctness 'l112_verify_failed')"
assert_jq "$correctness" '.failure_class == "correctness" and .retry_policy == "permanent"' "correctness regression classified permanent"

invalid="$(classify invalid 'missing_did_didnt_gaps')"
assert_jq "$invalid" '.failure_class == "invalid_callback" and .retry_policy == "manual"' "invalid callback classified manual"

assert_jq "$correctness" '.retry_policy != "exponential" and .failure_class != "transient"' "correctness is not a flake"
assert_jq "$invalid" '.retry_policy != "exponential" and .failure_class != "transient"' "invalid callback is not a flake"

unknown="$(classify unknown 'new_future_failure_shape')"
assert_jq "$unknown" '.failure_class == "unknown" and .retry_policy == "manual"' "unknown fallback preserves routing"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
