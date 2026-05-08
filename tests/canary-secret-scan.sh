#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/canary-secret-scan.sh"
FIXTURES="$ROOT/tests/fixtures/canary-secret-scan"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/canary-secret-scan.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

need jq

bash -n "$SCRIPT"
[ -x "$SCRIPT" ] || fail "script is not executable"

"$SCRIPT" --list-patterns --json >"$TMP/patterns.json"
jq -e '.synthetic_only == true and (.patterns | length) >= 6' "$TMP/patterns.json" >/dev/null \
  || fail "pattern list should be synthetic and complete"

set +e
"$SCRIPT" --json "$FIXTURES/leaky" >"$TMP/leaky.json"
leaky_rc=$?
set -e
[ "$leaky_rc" -eq 1 ] || fail "leaky fixture should exit 1"
jq -e '
  .schema_version == "canary-secret-scan/v1"
  and .synthetic_only == true
  and .leaks_found == 7
  and (.paths | length) == 4
  and (.patterns_matched | sort) == [
    "agent_mail_registration_token_canary",
    "aws_access_key_id_canary",
    "bearer_token_canary",
    "env_secret_canary",
    "github_pat_canary",
    "openai_key_canary"
  ]
  and ([.findings[] | select(has("field_path"))] | length) >= 4
  and ([.findings[] | select(.path | test("callback-evidence.md$"))] | length) == 2
' "$TMP/leaky.json" >/dev/null || {
  jq . "$TMP/leaky.json" >&2
  fail "leaky fixture JSON shape mismatch"
}

if rg -q 'CANARY_TEST_' "$TMP/leaky.json"; then
  jq . "$TMP/leaky.json" >&2
  fail "scanner output echoed a canary value"
fi

"$SCRIPT" --json "$FIXTURES/clean" >"$TMP/clean.json"
jq -e '.leaks_found == 0 and .paths == [] and .patterns_matched == []' "$TMP/clean.json" >/dev/null \
  || fail "clean fixture should pass"

printf 'PASS canary-secret-scan synthetic_leak_caught=true clean_evidence_passes=true\n'
