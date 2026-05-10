#!/usr/bin/env bash
# Regression test for flywheel-j99xb: --idempotency-key gate + per-(key, sources-file)
# whole-run replay on regenerate-dicklesworthstone-sources.sh. Fourth 7axmt-followup.
# Reuses sister j0xpa per-repo-scoped-whole-run-replay pattern, scoped to
# (idempotency_key, sources_file) instead of (idempotency_key, repo).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/regenerate-dicklesworthstone-sources.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/regen-dicklesworthstone-idem.XXXXXX")"
trap 'find "$TMP" -type f -delete 2>/dev/null; find "$TMP" -type d -depth -empty -delete 2>/dev/null; true' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

export REGEN_DICKLESWORTHSTONE_AUDIT_LOG="$TMP/audit.jsonl"

# Fixture: gh repo list output shape with 2 active + 1 archived repos.
cat >"$TMP/fixture.json" <<'JSON'
[
  {"name":"beads","description":"beads-cli","isArchived":false,"updatedAt":"2026-05-10T20:00:00Z","defaultBranchRef":{"name":"main"}},
  {"name":"ntm","description":"ntm","isArchived":false,"updatedAt":"2026-05-09T15:00:00Z","defaultBranchRef":{"name":"main"}},
  {"name":"old-repo","description":"archived","isArchived":true,"updatedAt":"2024-01-01T00:00:00Z","defaultBranchRef":{"name":"master"}}
]
JSON

SOURCES_A="$TMP/sources-a.txt"
SOURCES_B="$TMP/sources-b.txt"

# Test 1: --apply without --idempotency-key returns rc=3 + refusal envelope
set +e
"$SCRIPT" --apply --fixture "$TMP/fixture.json" --sources-file "$SOURCES_A" --json >"$TMP/refused.json" 2>&1
rc=$?
set -e
if [[ "$rc" -eq 3 ]]; then pass "AG1.rc: --apply without --idempotency-key exits 3"
else fail "AG1.rc: expected rc=3, got $rc"; fi
if jq -e '.status == "refused" and (.reason | test("idempotency-key")) and .sources_file' "$TMP/refused.json" >/dev/null 2>&1; then
  pass "AG1.envelope: refusal shape + sources_file field"
else fail "AG1.envelope: refusal envelope malformed"; fi

# Test 2: --idempotency-key without value returns rc=2
set +e
"$SCRIPT" --apply --idempotency-key 2>/dev/null
rc=$?
set -e
if [[ "$rc" -eq 2 ]]; then pass "AG2: --idempotency-key without value exits 2"
else fail "AG2: expected rc=2, got $rc"; fi

# Test 3: --dry-run still works without key
"$SCRIPT" --dry-run --fixture "$TMP/fixture.json" --sources-file "$SOURCES_A" --output "$TMP/rendered.txt" --json >"$TMP/dry.json" 2>&1
if jq -e '.status == "ok" and .mode == "dry-run" and .changed == true and .active_repo_count == 2' "$TMP/dry.json" >/dev/null 2>&1; then
  pass "AG3: dry-run still works without key (2 active repos)"
else fail "AG3: dry-run broken"; fi
if [[ -f "$TMP/rendered.txt" ]] && grep -q 'beads' "$TMP/rendered.txt" && grep -q 'ntm' "$TMP/rendered.txt" && ! grep -q 'old-repo' "$TMP/rendered.txt"; then
  pass "AG3.content: rendered file includes active repos, excludes archived"
else fail "AG3.content: rendered content malformed"; fi

# Test 4: dry-run with key carries idempotency_key in receipt
"$SCRIPT" --dry-run --idempotency-key=ag4-dry --fixture "$TMP/fixture.json" --sources-file "$SOURCES_A" --json >"$TMP/dry-key.json" 2>&1
if jq -e '.idempotency_key == "ag4-dry"' "$TMP/dry-key.json" >/dev/null 2>&1; then
  pass "AG4: dry-run with key carries idempotency_key in receipt"
else fail "AG4: dry-run receipt missing key"; fi

# Test 5: apply with key writes sources file + audit row (status=applied, fresh file)
"$SCRIPT" --apply --idempotency-key=ag5-fresh --fixture "$TMP/fixture.json" --sources-file "$SOURCES_A" --json >"$TMP/ag5.json" 2>&1
if jq -e '.status == "ok" and .changed == true and .idempotency_key == "ag5-fresh"' "$TMP/ag5.json" >/dev/null 2>&1; then
  pass "AG5: apply with key emits ok receipt with key + changed=true"
else fail "AG5: apply envelope malformed"; fi
if [[ -f "$SOURCES_A" ]] && grep -q 'beads' "$SOURCES_A"; then
  pass "AG5.write: sources file written"
else fail "AG5.write: sources file not written"; fi
if [[ -s "$REGEN_DICKLESWORTHSTONE_AUDIT_LOG" ]] && jq -e --arg k "ag5-fresh" '.idempotency_key == $k and .status == "applied"' "$REGEN_DICKLESWORTHSTONE_AUDIT_LOG" >/dev/null 2>&1; then
  pass "AG5.audit: audit log row written with key + status=applied"
else fail "AG5.audit: audit log row missing or wrong shape"; fi

# Test 6: re-run same key + same sources-file → replay
"$SCRIPT" --apply --idempotency-key=ag5-fresh --fixture "$TMP/fixture.json" --sources-file "$SOURCES_A" --json >"$TMP/ag6.json" 2>&1
if jq -e '.status == "replay" and .replay == true and .replay_for_idempotency_key == "ag5-fresh"' "$TMP/ag6.json" >/dev/null 2>&1; then
  pass "AG6: re-run with same key + sources-file → replay"
else fail "AG6: replay did not fire"; fi

# Test 7: same key, different sources-file → applies (per-target scope)
"$SCRIPT" --apply --idempotency-key=ag5-fresh --fixture "$TMP/fixture.json" --sources-file "$SOURCES_B" --json >"$TMP/ag7.json" 2>&1
if jq -e '.status == "ok" and .idempotency_key == "ag5-fresh" and (.sources_file | test("sources-b"))' "$TMP/ag7.json" >/dev/null 2>&1; then
  pass "AG7: same key, different sources-file → applies (per-target scope honored)"
else fail "AG7: per-target scope broken"; fi

# Test 8: fresh key, same sources-file → applies (no replay)
"$SCRIPT" --apply --idempotency-key=ag8-different --fixture "$TMP/fixture.json" --sources-file "$SOURCES_A" --json >"$TMP/ag8.json" 2>&1
if jq -e '.status == "ok" and (.replay // false) == false' "$TMP/ag8.json" >/dev/null 2>&1; then
  pass "AG8: fresh key on same sources-file → applies (no replay)"
else fail "AG8: fresh key incorrectly replayed"; fi

# Test 9: audit log has 3 non-replay rows from AG5 on A, AG7 on B, AG8 on A.
# Each row's status is "applied" (new content) or "no_change" (same content,
# possible if AG5+AG8 land in the same wall-clock second since the default
# --now uses date -u). Count both as "actual writes that happened".
nonreplay_count=$(jq -Rc 'fromjson? | select((.status // "") | IN("applied","no_change"))' "$REGEN_DICKLESWORTHSTONE_AUDIT_LOG" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$nonreplay_count" -eq 3 ]]; then
  pass "AG9: audit log has 3 non-replay rows (per-(key, sources-file) scoping verified)"
else fail "AG9: audit log non-replay row count $nonreplay_count != 3"; fi

# Test 10: audit row carries content_sha256 + backup_path fields
if jq -Rc 'fromjson? | select(.status == "applied")' "$REGEN_DICKLESWORTHSTONE_AUDIT_LOG" 2>/dev/null | tail -1 | jq -e 'has("content_sha256") and has("backup_path")' >/dev/null 2>&1; then
  pass "AG10: audit rows carry content_sha256 + backup_path"
else fail "AG10: audit rows missing content_sha256 or backup_path"; fi

# Test 11: tolerant-parse survives corrupt audit row
cat >>"$REGEN_DICKLESWORTHSTONE_AUDIT_LOG" <<EOF
{corrupt row not valid json}
EOF
"$SCRIPT" --apply --idempotency-key=ag5-fresh --fixture "$TMP/fixture.json" --sources-file "$SOURCES_A" --json >"$TMP/ag11.json" 2>&1
if jq -e '.status == "replay" and .replay == true' "$TMP/ag11.json" >/dev/null 2>&1; then
  pass "AG11: tolerant-parse survives corrupt audit row, replay still fires"
else fail "AG11: tolerant-parse broke"; fi

# Test 12: when changed=false (same content) audit row uses status=no_change.
# The rendered file embeds the "--now" timestamp, so we must pin it to get
# byte-identical content across runs and exercise the cmp -s short-circuit.
PINNED_NOW="2026-05-10T20:00:00Z"
SOURCES_C="$TMP/sources-c.txt"
# First write with pinned --now under one key
"$SCRIPT" --apply --idempotency-key=ag12-write --fixture "$TMP/fixture.json" --sources-file "$SOURCES_C" --now "$PINNED_NOW" --json >/dev/null 2>&1
# Second write with pinned --now + different key (so replay-check skips) should be content-identical
"$SCRIPT" --apply --idempotency-key=ag12-no-change --fixture "$TMP/fixture.json" --sources-file "$SOURCES_C" --now "$PINNED_NOW" --json >"$TMP/ag12.json" 2>&1
if jq -e '.status == "ok" and .changed == false' "$TMP/ag12.json" >/dev/null 2>&1; then
  pass "AG12: content-unchanged path uses changed=false (cmp -s short-circuit with pinned --now)"
else fail "AG12: changed=false detection broken"; fi
if jq -Rc 'fromjson? | select((.idempotency_key // "") == "ag12-no-change")' "$REGEN_DICKLESWORTHSTONE_AUDIT_LOG" 2>/dev/null | jq -e '.status == "no_change"' >/dev/null 2>&1; then
  pass "AG12.audit: no_change audit row written for unchanged content"
else fail "AG12.audit: no_change status not recorded"; fi

# Test 13: --help documents new flag + rc=3
if "$SCRIPT" --help 2>&1 | grep -q -- '--idempotency-key' && "$SCRIPT" --help 2>&1 | grep -qE '^  3  '; then
  pass "AG13: --help documents --idempotency-key + exit code 3"
else fail "AG13: --help missing docs"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
