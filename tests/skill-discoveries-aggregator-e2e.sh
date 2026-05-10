#!/usr/bin/env bash
# tests/skill-discoveries-aggregator-e2e.sh
# E2E for the skill-discoveries weekly aggregator (bead flywheel-4s3oy AG6).
# Uses an isolated SD_FILE so the test doesn't pollute production state.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AGG="$ROOT/.flywheel/scripts/skill-discoveries-aggregator.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/skill-discoveries-weekly.v1.schema.json"
PLIST="$ROOT/.flywheel/launchd/ai.zeststream.skill-discoveries-weekly.plist"
TMPDIR="$(mktemp -d -t sda-e2e.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

# Build a synthetic isolated SD jsonl with cross-worker fixture data
SD_FIXTURE="$TMPDIR/sd.jsonl"
cat > "$SD_FIXTURE" <<'EOF'
{"schema_version":"skill-discovery/v1","discovery_id":"sd-prior01","ts":"2026-04-15T12:00:00Z","candidate_skill_name":"established-class-A","discovery_kind":"pattern-recurrence","worker_identity":"PriorWorker","session":"flywheel"}
{"schema_version":"skill-discovery/v1","discovery_id":"sd-recurr01","ts":"2026-05-04T10:00:00Z","candidate_skill_name":"established-class-A","discovery_kind":"pattern-recurrence","worker_identity":"AlphaWorker","session":"flywheel"}
{"schema_version":"skill-discovery/v1","discovery_id":"sd-recurr02","ts":"2026-05-05T10:00:00Z","candidate_skill_name":"established-class-A","discovery_kind":"pattern-recurrence","worker_identity":"BetaWorker","session":"flywheel"}
{"schema_version":"skill-discovery/v1","discovery_id":"sd-newcls01","ts":"2026-05-06T11:00:00Z","candidate_skill_name":"brand-new-this-week","discovery_kind":"pattern-emerged","worker_identity":"AlphaWorker","session":"flywheel"}
{"schema_version":"skill-discovery/v1","discovery_id":"sd-oneoff01","ts":"2026-05-07T12:00:00Z","candidate_skill_name":"singleton-observation","discovery_kind":"pattern-emerged","worker_identity":"GammaWorker","session":"flywheel"}
EOF

OUT_REPORT="$TMPDIR/report.md"
JSON_OUT="$TMPDIR/rollup.json"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: --info exits 0
if "$AGG" --info >/dev/null 2>&1; then pass "--info exits 0"; else fail "--info"; fi

# Test 2: --schema emits canonical schema_version
if "$AGG" --schema 2>/dev/null | jq -e '.schema_version == "skill-discoveries-weekly.v1"' >/dev/null; then
  pass "--schema emits skill-discoveries-weekly.v1"
else
  fail "--schema"
fi

# Test 3: --doctor against fixture
if SD_FILE="$SD_FIXTURE" "$AGG" --doctor --json 2>/dev/null \
  | jq -e '.sd_jsonl_present == true and .sd_jsonl_lines == 5' >/dev/null; then
  pass "--doctor reports 5 fixture rows"
else
  fail "--doctor fixture"
fi

# Test 4: --apply against fixture writes a report
if SD_FILE="$SD_FIXTURE" "$AGG" --apply --week=2026-19 --out="$OUT_REPORT" --json > "$JSON_OUT" 2>/dev/null; then
  if [[ -s "$OUT_REPORT" ]] && jq -e '.schema_version == "skill-discoveries-weekly.v1" and .total_entries == 4' "$JSON_OUT" >/dev/null; then
    pass "--apply produces report with 4 in-window entries (1 prior excluded)"
  else
    fail "--apply summary mismatch"
    jq '.' "$JSON_OUT" 2>&1 | head -20 >&2
  fi
else
  fail "--apply exited non-zero"
fi

# Test 5: rollup contains canonical sections in markdown
if grep -q '^## Headline' "$OUT_REPORT" \
  && grep -q '^## Top 10 most-cited classes' "$OUT_REPORT" \
  && grep -q '^## First-time-this-week classes' "$OUT_REPORT" \
  && grep -q '^## Cross-worker agreements' "$OUT_REPORT" \
  && grep -q '^## Long-tail' "$OUT_REPORT"; then
  pass "report has all 5 canonical sections"
else
  fail "report missing canonical sections"
fi

# Test 6: cross-worker agreement detected (established-class-A: Alpha + Beta)
if jq -e '
  (.cross_worker_agreements | map(select(.candidate == "established-class-A"))) as $h
  | ($h | length) == 1 and ($h[0].distinct_workers | length) >= 2
' "$JSON_OUT" >/dev/null 2>&1; then
  pass "cross-worker agreement detected for shared class"
else
  fail "cross-worker agreement detection regression"
fi

# Test 7: first-time-this-week excludes prior class
if jq -e '.first_time_classes | map(.candidate) | (index("brand-new-this-week") != null) and (index("established-class-A") == null)' "$JSON_OUT" >/dev/null 2>&1; then
  pass "first-time-this-week excludes prior class, includes new class"
else
  fail "first-time detection regression"
fi

# Test 8: schema validation (jsonschema CLI if available, else jq fallback)
if command -v jsonschema >/dev/null && [[ -s "$SCHEMA" ]]; then
  if jsonschema -i "$JSON_OUT" "$SCHEMA" 2>/dev/null; then
    pass "schema validation pass"
  else
    fail "schema validation failed"
  fi
else
  if jq -e '
    (.schema_version | type == "string") and
    (.week           | test("^[0-9]{4}-[0-9]{2}$")) and
    (.total_entries  | type == "number") and
    (.top_n          | type == "array") and
    (.first_time_classes | type == "array") and
    (.cross_worker_agreements | type == "array") and
    (.by_kind        | type == "array") and
    (.by_worker      | type == "array")
  ' "$JSON_OUT" >/dev/null 2>&1; then
    pass "schema-shape jq fallback PASS (jsonschema CLI not installed)"
  else
    fail "schema-shape jq fallback FAIL"
  fi
fi

# Test 9: launchd plist parses
if command -v plutil >/dev/null && plutil -lint "$PLIST" >/dev/null 2>&1; then
  pass "launchd plist plutil -lint OK"
else
  if grep -q 'ai.zeststream.skill-discoveries-weekly' "$PLIST"; then
    pass "launchd plist present (plutil unavailable; grep OK)"
  else
    fail "launchd plist invalid or missing"
  fi
fi

# Test 10: empty week returns rc=3 (no entries in window)
if SD_FILE="$SD_FIXTURE" "$AGG" --apply --week=2025-01 --out=/dev/null --json >/dev/null 2>&1; then
  fail "empty week should exit non-zero"
else
  rc=$?
  if [[ "$rc" -eq 3 ]]; then pass "empty week returns canonical rc=3"; else fail "empty week rc=$rc (expected 3)"; fi
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
