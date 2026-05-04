#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/docs-validation-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/docs-validation-test.XXXXXX")"
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
assert_jq "$TMP/schema.json" '.schema_version == "docs-validation-probe/v1" and (.output_fields | index("docs_validation_failed_count"))' "schema exposes docs counts"

"$SCRIPT" --self-test --json >"$TMP/self-test.json"
assert_jq "$TMP/self-test.json" '.status == "pass" and .report.docs_validation_failed_count == 1 and .report.docs_validation_pending_count == 1' "self-test detects self-validation and pending docs"

if [[ "$fail_count" -gt 0 ]]; then
  exit 1
fi
