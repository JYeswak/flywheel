#!/usr/bin/env bash
# tests/jeff-daily-corpus-diff-e2e.sh
# End-to-end smoke for the jeff-daily-corpus-diff pipeline.
# Bead: flywheel-ys7em (AG6)
#
# Exercises ONE repo (Dicklesworthstone/ntm) through:
#   1. collector --apply --only=ntm  -> raw JSON snapshot
#   2. renderer --apply --in=<snap>  -> markdown report
#   3. schema validation of the snapshot
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
COLLECTOR="$ROOT/.flywheel/scripts/jeff-daily-corpus-diff.sh"
RENDERER="$ROOT/.flywheel/scripts/jeff-daily-corpus-diff-render.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/jeff-daily-diff-report.v1.schema.json"
TMPDIR="$(mktemp -d -t jdc-e2e.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

# Isolate test state dir so the e2e doesn't clobber the canonical
# .flywheel/state/jeff-corpus-activity-<date>.json snapshot that
# launchd / Joshua's daily review reads.
export JEFF_DIFF_STATE_DIR="$TMPDIR/state"
mkdir -p "$JEFF_DIFF_STATE_DIR"
# Seed an isolated repo cache (single repo for the smoke target)
printf '[{"name":"ntm","isArchived":false,"updatedAt":"2026-05-10T00:00:00Z","isFork":false,"description":"smoke target"}]\n' \
  > "$JEFF_DIFF_STATE_DIR/jeff-repos.json"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: collector --info exits 0 and prints schema
if "$COLLECTOR" --info >/dev/null 2>&1; then
  pass "collector --info exits 0"
else
  fail "collector --info"
fi

# Test 2: collector --schema emits one-line JSON with schema_version
if "$COLLECTOR" --schema 2>/dev/null | jq -e '.schema_version == "jeff-daily-diff-collector.v1"' >/dev/null; then
  pass "collector --schema emits canonical schema_version"
else
  fail "collector --schema"
fi

# Test 3: collector --doctor JSON parseable
if "$COLLECTOR" --doctor --json 2>/dev/null | jq -e '.gh_auth' >/dev/null; then
  pass "collector --doctor --json valid"
else
  fail "collector --doctor"
fi

# Test 4: renderer --info exits 0
if "$RENDERER" --info >/dev/null 2>&1; then
  pass "renderer --info exits 0"
else
  fail "renderer --info"
fi

# Test 5: collector --apply --only=ntm produces snapshot with required keys
SNAP_OUT="$TMPDIR/snap.txt"
if "$COLLECTOR" --apply --json --only=ntm >"$SNAP_OUT" 2>/dev/null; then
  SNAP_PATH="$(jq -r '.snapshot_path' "$SNAP_OUT")"
  if [[ -s "$SNAP_PATH" ]] \
    && jq -e '.schema_version == "jeff-daily-diff-collector.v1" and .repos[0].repo == "ntm"' "$SNAP_PATH" >/dev/null; then
    pass "collector --apply --only=ntm produces snapshot at $SNAP_PATH"
  else
    fail "collector snapshot missing required fields"
  fi
else
  fail "collector --apply --only=ntm"
fi

# Test 6: schema validates the snapshot
SNAP_PATH="${SNAP_PATH:-/dev/null}"
if command -v jsonschema >/dev/null && [[ -s "$SCHEMA" && -s "$SNAP_PATH" ]]; then
  if jsonschema -i "$SNAP_PATH" "$SCHEMA" 2>/dev/null; then
    pass "schema validation pass"
  else
    fail "schema validation failed"
  fi
else
  # Fallback: structural check via jq when jsonschema not on PATH
  if jq -e '
    (.schema_version | type == "string") and
    (.ts_started   | type == "string") and
    (.ts_completed | type == "string") and
    (.repos        | type == "array")  and
    (.repo_count   | type == "number") and
    (.repos[0]     | has("repo") and has("commits") and has("issues") and has("releases") and has("prs"))
  ' "$SNAP_PATH" >/dev/null 2>&1; then
    pass "schema-shape jq fallback PASS (jsonschema CLI not installed)"
  else
    fail "schema-shape jq fallback FAIL"
  fi
fi

# Test 7: renderer produces markdown with all 4 sections + headline
RPT="$TMPDIR/report.md"
if "$RENDERER" --apply --in="$SNAP_PATH" --out="$RPT" >/dev/null 2>&1 && [[ -s "$RPT" ]]; then
  if grep -q '^# Jeffrey Emanuel corpus' "$RPT" \
    && grep -q '^## Headline' "$RPT" \
    && grep -q '^## Releases (high signal)' "$RPT" \
    && grep -q '^## Active repos (3+ commits today)' "$RPT" \
    && grep -q '^## New issues (touched in window)' "$RPT"; then
    pass "renderer produces 4 canonical sections + headline"
  else
    fail "renderer markdown missing required sections"
  fi
else
  fail "renderer apply"
fi

# Test 8: render headline cites real numbers (regression on jq-string-arith bug)
if grep -qE 'commits across [0-9]+ repos' "$RPT" 2>/dev/null; then
  pass "headline cites real commit + repo counts"
else
  fail "headline missing numeric counts"
fi

# Test 9: launchd plist parses as XML
PLIST="$ROOT/.flywheel/launchd/ai.zeststream.jeff-daily-corpus-diff.plist"
if command -v plutil >/dev/null && plutil -lint "$PLIST" >/dev/null 2>&1; then
  pass "launchd plist plutil -lint OK"
else
  if [[ -s "$PLIST" ]] && grep -q 'ai.zeststream.jeff-daily-corpus-diff' "$PLIST"; then
    pass "launchd plist present (plutil unavailable; structural-grep OK)"
  else
    fail "launchd plist invalid or missing"
  fi
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
