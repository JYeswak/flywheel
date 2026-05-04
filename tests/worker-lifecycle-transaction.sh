#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/worker-lifecycle-transaction.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worker-lifecycle-test.XXXXXX")"
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

bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"
"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "worker-lifecycle-transaction/v1" and (.required_receipt_fields | index("verification_status"))' "schema exposes receipt contract"

"$SCRIPT" --self-test --json >"$TMP/self-test.json"
assert_jq "$TMP/self-test.json" '.status == "pass" and .report.worker_respawn_unverified_count == 1 and .report.worker_spawn_shape_drift_count == 1' "self-test detects unverified respawn and codex shape drift"

if [[ "$fail_count" -gt 0 ]]; then
  exit 1
fi
