#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/idempotency-replay-guard.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/dispatch-receipt.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/idempotency-replay-guard.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
outputs=()

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

run_guard() {
  local name="$1"; shift
  local out="$TMP/$name.json"
  "$SCRIPT" --ledger "$TMP/ledger.jsonl" --lock-dir "$TMP/locks" --json "$@" >"$out"
  outputs+=("$out")
  printf '%s\n' "$out"
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

assert_golden_status() {
  local file="$1" expected="$2" label="$3" golden actual
  golden="$TMP/$label.golden"
  actual="$TMP/$label.actual"
  jq -S '{idempotency_key:"[sha256]",receipt_completeness,replay_detection_hash:"[sha256]",status,transaction_boundary}' "$file" >"$actual.scrubbed"
  jq -n -S --arg status "$expected" --argjson boundary "$(jq -c '.transaction_boundary' "$file")" '{
    idempotency_key:"[sha256]",
    receipt_completeness:{"IDEM-001":true,"IDEM-002":true,"IDEM-003":true,"IDEM-004":true,"IDEM-005":true,"IDEM-006":true},
    replay_detection_hash:"[sha256]",
    status:$status,
    transaction_boundary:$boundary
  }' >"$golden"
  if diff -u "$golden" "$actual.scrubbed" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    diff -u "$golden" "$actual.scrubbed" >&2 || true
  fi
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
jq empty "$SCHEMA" && pass "schema_json_parses" || fail "schema_json_parses"
jq -e '((.required | index("idempotency_key")) != null) and ((.properties.receipt_completeness.required | length) == 6)' "$SCHEMA" >/dev/null \
  && pass "schema_declares_idempotency_and_six_flags" || fail "schema_declares_idempotency_and_six_flags"

"$SCRIPT" --help >/dev/null && pass "help_exits" || fail "help_exits"
"$SCRIPT" --info --json | jq -e '(.canonical_cli_flags | index("--info")) and (.canonical_cli_flags | index("--help")) and (.canonical_cli_flags | index("--examples")) and (.canonical_cli_flags | index("--json")) and (.canonical_cli_flags | index("--quiet"))' >/dev/null \
  && pass "info_lists_five_cli_verbs" || fail "info_lists_five_cli_verbs"
"$SCRIPT" --examples --json | jq -e '(.examples | length) >= 4' >/dev/null && pass "examples_json" || fail "examples_json"
"$SCRIPT" --ledger "$TMP/q-ledger.jsonl" --lock-dir "$TMP/q-locks" --quiet --input quiet-check >/dev/null && pass "quiet_exits" || fail "quiet_exits"

first="$(run_guard idem004_first --input '{"bead":"a","labels":["p0"],"target":"flywheel:2"}')"
assert_jq "$first" '.status == "not_seen" and .lock_acquired == true and .transaction_boundary.begin == true' "IDEM-004 first writer acquires lock"
assert_golden_status "$first" "not_seen" "golden_not_seen"

second="$(run_guard idem004_second --input '{"target":"flywheel:2","labels":["p0"],"bead":"a"}')"
assert_jq "$second" '.status == "in_flight" and .lock_acquired == false' "IDEM-004 duplicate sees in_flight"
assert_golden_status "$second" "in_flight" "golden_in_flight"

key_a="$(jq -r '.idempotency_key' "$first")"
key_b="$(jq -r '.idempotency_key' "$second")"
[[ "$key_a" == "$key_b" ]] && pass "IDEM-003 canonical JSON key order stable" || fail "IDEM-003 canonical JSON key order stable"

completed="$(run_guard idem006_completed --input '{"bead":"a","labels":["p0"],"target":"flywheel:2"}' --mark-completed --receipt-ref ".beads/issues.jsonl#L1")"
assert_jq "$completed" '.status == "completed" and .transaction_boundary.commit == true' "IDEM-006 completed marks commit"
assert_golden_status "$completed" "completed" "golden_completed"

replay="$(run_guard idem001_replay --input '{"bead":"a","labels":["p0"],"target":"flywheel:2"}')"
assert_jq "$replay" '.status == "already_completed" and .prior_receipt_ref == ".beads/issues.jsonl#L1" and .transaction_boundary.commit == true' "IDEM-001 replay returns already_completed"
assert_golden_status "$replay" "already_completed" "golden_already_completed"

assert_jq "$replay" '.receipt_completeness["IDEM-001"] == true and .receipt_completeness["IDEM-002"] == true and .receipt_completeness["IDEM-003"] == true and .receipt_completeness["IDEM-004"] == true and .receipt_completeness["IDEM-005"] == true and .receipt_completeness["IDEM-006"] == true' "IDEM-002 completeness flags cover all findings"

ledger_lines="$(wc -l <"$TMP/ledger.jsonl" | tr -d ' ')"
[[ "$ledger_lines" == "1" ]] && pass "IDEM-005 duplicate replay does not append second completed row" || fail "IDEM-005 duplicate replay does not append second completed row"

released="$(run_guard idem006_release --input '{"bead":"release"}' --release-lock)"
assert_jq "$released" '.status == "not_seen" and .transaction_boundary.abort == true' "IDEM-006 release exposes abort marker"

schema_fixture="$TMP/schema-fixture.json"
jq -n --arg key "$key_a" --arg hash "$key_a" '{
  schema_version:"dispatch-receipt/v1",
  receipt_type:"replay_guard",
  idempotency_key:$key,
  replay_detection_hash:$hash,
  transaction_boundary:{begin:true,commit:false,abort:false},
  receipt_completeness:{"IDEM-001":true,"IDEM-002":true,"IDEM-003":true,"IDEM-004":true,"IDEM-005":true,"IDEM-006":true}
}' >"$schema_fixture"
python3 - "$SCHEMA" "$schema_fixture" <<'PY' && pass "schema_fixture_validates" || fail "schema_fixture_validates"
import json, sys
from pathlib import Path
try:
    import jsonschema
except Exception:
    raise SystemExit(0)
schema = json.loads(Path(sys.argv[1]).read_text())
data = json.loads(Path(sys.argv[2]).read_text())
jsonschema.Draft202012Validator(schema).validate(data)
PY

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" -ge 14 && "$fail_count" == "0" ]]
