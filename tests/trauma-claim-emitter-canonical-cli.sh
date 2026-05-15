#!/usr/bin/env bash
# tests/trauma-claim-emitter-canonical-cli.sh
# Canonical-CLI + behavior tests for .flywheel/scripts/trauma-claim-emitter.sh
# Goal: P2 of substrate-compounding-v2 (FCLA W1).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/trauma-claim-emitter.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/trauma-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# Isolate: point env at temp paths
export TRAUMA_EMITTER_FUCKUP_LOG="$TMP/fuckup.jsonl"
export TRAUMA_EMITTER_INCIDENTS="$TMP/INCIDENTS.md"
export TRAUMA_EMITTER_RECOVERY_SKILL="$TMP/recovery.md"
export TRAUMA_EMITTER_OUT="$TMP/out.jsonl"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then
  pass "shellcheck: syntax"
else
  fail "syntax"
fi

if "$SCRIPT" --info --json 2>/dev/null | jq -e '.name == "trauma-claim-emitter" and .schema_version and .subcommands' >/dev/null; then
  pass "--info exposes name/schema/subcommands"
else
  fail "--info"
fi
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version and .input_schema and .output_schema' >/dev/null; then
  pass "--schema exposes I/O schemas"
else
  fail "--schema"
fi
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length >= 2' >/dev/null; then
  pass "--examples >=2 invocations"
else
  fail "--examples"
fi

# Fixture: 3 fuckup rows, one already in INCIDENTS, one already in SKILL, one novel
cat >"$TRAUMA_EMITTER_FUCKUP_LOG" <<'JSONL'
{"ts":"2026-05-15T00:00:01Z","class":"known-class-in-incidents","session":"flywheel","severity":"medium","what_happened":"x"}
{"ts":"2026-05-15T00:00:02Z","class":"known-class-in-skill","session":"flywheel","severity":"medium","what_happened":"y"}
{"ts":"2026-05-15T00:00:03Z","class":"novel-class-z","session":"flywheel","severity":"high","what_happened":"z"}
{"ts":"2026-05-15T00:00:04Z","class":"test-class","session":"flywheel","severity":"low","what_happened":"should_skip"}
JSONL
echo "## known-class-in-incidents" >"$TRAUMA_EMITTER_INCIDENTS"
echo "## known-class-in-skill" >"$TRAUMA_EMITTER_RECOVERY_SKILL"

# Dry-run should NOT write to out (status JSON is the first line; candidates array follows)
STATUS_LINE="$("$SCRIPT" emit --dry-run --json 2>&1 | head -1 || true)"
if echo "$STATUS_LINE" | jq -e '.status == "dry_run" and .candidate_count == 3' >/dev/null; then
  pass "dry-run reports candidate_count=3 (excludes test-class)"
else
  fail "dry-run count wrong"
  echo "$STATUS_LINE" >&2
fi
if [[ ! -f "$TRAUMA_EMITTER_OUT" ]]; then
  pass "dry-run does NOT write to disk"
else
  fail "dry-run wrote to disk"
fi

# Real emit should write 3 rows
if "$SCRIPT" emit --json 2>&1 | jq -e '.status == "emitted" and .candidate_count == 3' >/dev/null; then
  pass "emit writes 3 candidates"
else
  fail "emit count wrong"
fi
if [[ -f "$TRAUMA_EMITTER_OUT" ]]; then
  pass "emit writes to expected path"
else
  fail "out path not created"
fi
row_count="$(jq -s 'length' "$TRAUMA_EMITTER_OUT" 2>/dev/null || echo 0)"
if [[ "$row_count" == "3" ]]; then
  pass "out has 3 rows"
else
  fail "row count wrong: got $row_count"
fi

# Schema-shape validation per row
all_valid=1
while IFS= read -r row; do
  echo "$row" | jq -e '.schema_version == "flywheel.trauma_candidate.v0" and .class and .ts and .proposed_disposition and .recommended_skillos_loop' >/dev/null || { all_valid=0; break; }
done <"$TRAUMA_EMITTER_OUT"
if [[ "$all_valid" == "1" ]]; then
  pass "all rows match schema flywheel.trauma_candidate.v0"
else
  fail "schema violation"
fi

# Disposition classification
known_count="$(jq -s '[.[] | select(.proposed_disposition == "known")] | length' "$TRAUMA_EMITTER_OUT")"
new_count="$(jq -s '[.[] | select(.proposed_disposition == "new")] | length' "$TRAUMA_EMITTER_OUT")"
if [[ "$known_count" == "2" && "$new_count" == "1" ]]; then
  pass "disposition correct: 2 known (INCIDENTS + SKILL hits) + 1 new"
else
  fail "disposition: known=$known_count new=$new_count"
fi

# Env-disable check (script returns 3 by design; capture output separately)
DISABLED_OUT="$(FLYWHEEL_TRAUMA_EMITTER=0 "$SCRIPT" emit --json 2>&1 || true)"
if echo "$DISABLED_OUT" | jq -e '.status == "disabled"' >/dev/null; then
  pass "FLYWHEEL_TRAUMA_EMITTER=0 disables emit"
else
  fail "env disable broken"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
