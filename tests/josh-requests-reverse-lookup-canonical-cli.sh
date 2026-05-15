#!/usr/bin/env bash
# tests/josh-requests-reverse-lookup-canonical-cli.sh
# Canonical-CLI surface tests for .flywheel/scripts/josh-requests-reverse-lookup.py
# Bead: flywheel-meadows-doctor-freshness-gauge-reverse-lookup-cy5ay
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/josh-requests-reverse-lookup.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jrrl-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Canonical info/schema/examples surface
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .schema_version and .capabilities and .bead' >/dev/null \
  && pass "--info exposes name/version/schema/capabilities/bead" \
  || fail "--info missing required fields"

"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema and .output_schema.required' >/dev/null \
  && pass "--schema exposes input/output schemas" \
  || fail "--schema missing input/output schemas"

"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length >= 2' >/dev/null \
  && pass "--examples exposes ≥2 example invocations" \
  || fail "--examples too few"

"$SCRIPT" doctor 2>/dev/null | jq -e '.command == "doctor" and .status and (.checks | length >= 3)' >/dev/null \
  && pass "doctor envelope schema-valid" \
  || fail "doctor envelope wrong shape"

# Fixture probe — minimal jsonl with one absorbed and one open row
cat >"$TMP/jr.jsonl" <<'JSONL'
{"id":"jr-test-001","ts":"2026-05-15T00:00:00Z","status":"open","captured_via":"hook","excerpt":"we need to consider storage on everything we do","prompt_hash":"abc123","repo":"/test"}
{"id":"jr-test-002","ts":"2026-05-15T00:00:01Z","status":"open","captured_via":"hook","excerpt":"DONE flywheel-fake evidence=/tmp/x-evidence.md","prompt_hash":"def456","repo":"/test"}
{"id":"jr-test-003","ts":"2026-05-15T00:00:02Z","status":"closed","captured_via":"hook","excerpt":"already closed","prompt_hash":"ghi789","repo":"/test"}
JSONL

mkdir -p "$TMP/mem" "$TMP/beads"
touch "$TMP/mem/feedback_storage_retention_policy.md"
: >"$TMP/beads/issues.jsonl"  # empty JSONL is valid per the loader
touch "$TMP/incidents.md"

OUT="$("$SCRIPT" check \
  --jr-path "$TMP/jr.jsonl" \
  --memory-dir "$TMP/mem" \
  --incidents-path "$TMP/incidents.md" \
  --beads-jsonl "$TMP/beads/issues.jsonl" \
  --limit 10 2>/dev/null)"

echo "$OUT" | jq -e '.stats.total_rows_in_file == 3 and .stats.open_rows == 2 and .stats.rows_classified == 2' >/dev/null \
  && pass "fixture: classifies 2 open rows out of 3 total" \
  || fail "fixture: row count wrong"

echo "$OUT" | jq -e '.disposition_counts["memory-absorbed"] == 1' >/dev/null \
  && pass "fixture: storage row → memory-absorbed" \
  || fail "fixture: storage row classification wrong"

echo "$OUT" | jq -e '.disposition_counts["done-callback"] == 1' >/dev/null \
  && pass "fixture: DONE row → done-callback" \
  || fail "fixture: DONE row classification wrong"

echo "$OUT" | jq -e '.consumed_count == 2 and .still_open_count == 0 and .consumed_pct == 100.0' >/dev/null \
  && pass "fixture: consumed_count + still_open_count + consumed_pct correct" \
  || fail "fixture: consumed metrics wrong"

echo "$OUT" | jq -e '.schema_version == "flywheel.josh_requests_reverse_lookup.v0"' >/dev/null \
  && pass "schema_version stamped" \
  || fail "schema_version missing"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
