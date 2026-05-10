#!/usr/bin/env bash
# tests/tentacle-inventory-bump-atomic-fixture.sh
# Bead flywheel-fjw [D4]: regression coverage for the atomic
# INVENTORY trailer bump on tentacle drift.
#
# Acceptance gate (from bead body): "a simulated tentacle version bump
# updates drift row and INVENTORY entry in one commit or produces
# explicit blocked reason". This test simulates the version bump end-
# to-end against an isolated fixture INVENTORY + drift summary, asserts
# the trailer updates atomically, the curated table stays byte-identical,
# and re-running with the same input is idempotent.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BUMPER="${TENTACLE_INVENTORY_BUMP:-$ROOT/.flywheel/scripts/tentacle-inventory-bump.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bumper exists + bash -n + canonical-cli-scoping triad
if [[ -x "$BUMPER" ]] && bash -n "$BUMPER" 2>/dev/null \
  && "$BUMPER" --info >/dev/null 2>&1 \
  && "$BUMPER" --schema >/dev/null 2>&1 \
  && "$BUMPER" --examples >/dev/null 2>&1; then
  pass "bumper exists + bash -n ok + --info/--schema/--examples present"
else
  fail "bumper missing or canonical-cli-scoping triad incomplete"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: --info advertises atomicity + idempotent + curated_table_modified=false
INFO="$("$BUMPER" --info 2>/dev/null)"
if jq -e '
  .schema_version == "tool-info/v1"
  and .name == "tentacle-inventory-bump.sh"
  and .mutates == true
  and .default_mode == "dry-run"
  and (.mutation_requires | index("--apply")) != null
  and .curated_table_modified == false
  and .atomicity == "tempfile-rename-only"
  and .idempotent == true
  and .tracking_bead == "flywheel-fjw"
  and (.consumes_schema | startswith("tentacle-drift-sweep/"))
' >/dev/null 2>&1 <<<"$INFO"; then
  pass "--info advertises atomicity + idempotent + curated_table_modified=false + tracking bead"
else
  fail "--info envelope shape regressed; got: ${INFO:0:200}"
fi

# Build isolated fixture
FIXTURE="$(mktemp -d -t tentacle-inventory-fixture.XXXXXX)"
trap 'rm -rf "$FIXTURE"' EXIT

cat >"$FIXTURE/inventory.md" <<'INVENTORY_EOF'
# Test Fixture Inventory

**Snapshot Date:** 2026-05-03T00:00:00Z

## Full Corpus Table

| Rank | Repo | Stars | Lang | Last Push | Verdict |
|---:|---|---:|---|---|---|
| 1 | `mock_repo_a` | 100 | Go | 2026-04-01 | ADOPT |
| 2 | `mock_repo_b` | 50 | Rust | 2026-03-15 | EVALUATE |

## Clone And Index Notes

- Fixture: 2 mock repos for atomic-bump testing only.
INVENTORY_EOF

CURATED_BEFORE_SHA="$(awk '/^## Clone And Index Notes/{found=1} found{notes=notes$0"\n"; next} {body=body$0"\n"} END{printf "%s", body}' "$FIXTURE/inventory.md" | shasum -a 256 | awk '{print $1}')"
TABLE_BEFORE_SHA="$(awk '/^## Full Corpus Table/,/^## Clone And Index Notes/' "$FIXTURE/inventory.md" | shasum -a 256 | awk '{print $1}')"
# Capture notes-section CONTENT (lines starting with "## Clone..." or "- ")
# rather than the literal range; the surrounding blank lines change
# canonically when the trailer is appended (script normalizes
# trailing blank lines).
NOTES_BEFORE_SHA="$(awk '
  /^## Clone And Index Notes/ { in_notes = 1 }
  /^<!-- BEGIN-TENTACLE-DRIFT-TRAILER -->/ { in_notes = 0 }
  in_notes && (/^## Clone And Index Notes/ || /^- /) { print }
' "$FIXTURE/inventory.md" | shasum -a 256 | awk '{print $1}')"

cat >"$FIXTURE/sweep.json" <<'SWEEP_EOF'
{
  "schema_version": "tentacle-drift-sweep/v1",
  "ts": "2026-05-10T02:00:00Z",
  "status": "warn",
  "repo_count": 2,
  "alert_count": 1,
  "max_commits_behind": 42,
  "ledger_path": "/fixture/sweep.jsonl",
  "alert_ledger_path": "/fixture/alerts.jsonl"
}
SWEEP_EOF

# Test 3: dry-run does NOT mutate the fixture
INVENTORY="$FIXTURE/inventory.md" "$BUMPER" --summary "$FIXTURE/sweep.json" --json >"$FIXTURE/dryrun-receipt.json" 2>"$FIXTURE/dryrun.stderr"
if jq -e '.mode == "dry-run" and .trailer_status == "inserted" and .curated_table_modified == false' >/dev/null 2>&1 <<<"$(cat "$FIXTURE/dryrun-receipt.json")"; then
  if ! grep -q "BEGIN-TENTACLE-DRIFT-TRAILER" "$FIXTURE/inventory.md"; then
    pass "dry-run emits trailer-inserted receipt without mutating fixture"
  else
    fail "dry-run mutated fixture (trailer marker present after dry-run)"
  fi
else
  fail "dry-run receipt malformed; got: $(cat "$FIXTURE/dryrun-receipt.json")"
fi

# Test 4: apply inserts the trailer block atomically
INVENTORY="$FIXTURE/inventory.md" "$BUMPER" --summary "$FIXTURE/sweep.json" --apply --json >"$FIXTURE/apply-receipt.json" 2>"$FIXTURE/apply.stderr"
if jq -e '.mode == "apply" and .trailer_status == "inserted" and .curated_table_modified == false and .atomicity == "tempfile-rename-only"' >/dev/null 2>&1 <<<"$(cat "$FIXTURE/apply-receipt.json")"; then
  pass "apply inserts trailer atomically with curated_table_modified=false"
else
  fail "apply receipt malformed; got: $(cat "$FIXTURE/apply-receipt.json")"
fi

# Test 5: trailer block content carries the sweep metadata
if grep -q "<!-- BEGIN-TENTACLE-DRIFT-TRAILER -->" "$FIXTURE/inventory.md" \
  && grep -q "sweep_ts: 2026-05-10T02:00:00Z" "$FIXTURE/inventory.md" \
  && grep -q "schema_version: tentacle-drift-sweep/v1" "$FIXTURE/inventory.md" \
  && grep -q "repo_count: 2" "$FIXTURE/inventory.md" \
  && grep -q "alert_count: 1" "$FIXTURE/inventory.md" \
  && grep -q "max_commits_behind: 42" "$FIXTURE/inventory.md" \
  && grep -q "status: warn" "$FIXTURE/inventory.md" \
  && grep -q "<!-- END-TENTACLE-DRIFT-TRAILER -->" "$FIXTURE/inventory.md"; then
  pass "trailer block carries sweep_ts + schema + counts + status"
else
  fail "trailer block missing required fields"
fi

# Test 6: curated table region is byte-identical (verdicts/ranks/etc preserved)
TABLE_AFTER_SHA="$(awk '/^## Full Corpus Table/,/^## Clone And Index Notes/' "$FIXTURE/inventory.md" | shasum -a 256 | awk '{print $1}')"
if [[ "$TABLE_BEFORE_SHA" == "$TABLE_AFTER_SHA" ]]; then
  pass "curated table region byte-identical pre/post bump (Verdict + Rationale preserved)"
else
  fail "curated table region drifted; before=$TABLE_BEFORE_SHA after=$TABLE_AFTER_SHA"
fi

# Test 7: idempotency — re-running with identical input is a no-op
INVENTORY="$FIXTURE/inventory.md" "$BUMPER" --summary "$FIXTURE/sweep.json" --apply --json >"$FIXTURE/idempotent-receipt.json" 2>"$FIXTURE/idempotent.stderr"
if jq -e '.trailer_status == "unchanged" and .diff_lines_added == 0 and .diff_lines_removed == 0' >/dev/null 2>&1 <<<"$(cat "$FIXTURE/idempotent-receipt.json")"; then
  pass "idempotent: re-applying identical sweep is a no-op (trailer_status=unchanged)"
else
  fail "idempotency broken; got: $(cat "$FIXTURE/idempotent-receipt.json")"
fi

# Test 8: bump-with-different-ts updates trailer (not no-op)
cat >"$FIXTURE/sweep2.json" <<'SWEEP2_EOF'
{
  "schema_version": "tentacle-drift-sweep/v1",
  "ts": "2026-05-10T03:00:00Z",
  "status": "warn",
  "repo_count": 2,
  "alert_count": 2,
  "max_commits_behind": 100,
  "ledger_path": "/fixture/sweep.jsonl",
  "alert_ledger_path": "/fixture/alerts.jsonl"
}
SWEEP2_EOF
INVENTORY="$FIXTURE/inventory.md" "$BUMPER" --summary "$FIXTURE/sweep2.json" --apply --json >"$FIXTURE/update-receipt.json" 2>"$FIXTURE/update.stderr"
if jq -e '.trailer_status == "updated" and .curated_table_modified == false' >/dev/null 2>&1 <<<"$(cat "$FIXTURE/update-receipt.json")" \
  && grep -q "sweep_ts: 2026-05-10T03:00:00Z" "$FIXTURE/inventory.md" \
  && grep -q "alert_count: 2" "$FIXTURE/inventory.md" \
  && grep -q "max_commits_behind: 100" "$FIXTURE/inventory.md" \
  && ! grep -q "sweep_ts: 2026-05-10T02:00:00Z" "$FIXTURE/inventory.md"; then
  pass "fresh sweep ts updates trailer in-place (old ts removed, new ts present)"
else
  fail "trailer update on fresh ts regressed"
fi

# Test 9: invalid summary schema is rejected with rc=1
echo '{"schema_version":"NOT-tentacle-drift","status":"x"}' > "$FIXTURE/bad-summary.json"
set +e
INVENTORY="$FIXTURE/inventory.md" "$BUMPER" --summary "$FIXTURE/bad-summary.json" --apply >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 1 ]]; then
  pass "invalid summary schema rejected with rc=1"
else
  fail "expected rc=1 on bad schema, got rc=$rc"
fi

# Test 10: missing --summary exits rc=2
set +e
INVENTORY="$FIXTURE/inventory.md" "$BUMPER" --apply >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 2 ]]; then
  pass "missing --summary exits rc=2 (canonical-cli-scoping usage error)"
else
  fail "expected rc=2 on missing --summary, got rc=$rc"
fi

# Test 11: clone-and-index-notes content (header + bullet lines) is
# byte-identical pre/post bump. Surrounding blank lines may shift
# canonically (trailer placement); the content itself must not.
NOTES_AFTER_SHA="$(awk '
  /^## Clone And Index Notes/ { in_notes = 1 }
  /^<!-- BEGIN-TENTACLE-DRIFT-TRAILER -->/ { in_notes = 0 }
  in_notes && (/^## Clone And Index Notes/ || /^- /) { print }
' "$FIXTURE/inventory.md" | shasum -a 256 | awk '{print $1}')"
if [[ "$NOTES_BEFORE_SHA" == "$NOTES_AFTER_SHA" ]]; then
  pass "Clone And Index Notes content byte-identical pre/post bump"
else
  fail "Clone And Index Notes content drifted; before=$NOTES_BEFORE_SHA after=$NOTES_AFTER_SHA"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
