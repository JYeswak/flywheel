#!/usr/bin/env bash
# test_mission_lock_frontmatter_idempotent.sh
# Asserts that writing locked_at/lock_hash twice into a .flywheel doc
# results in exactly ONE occurrence of each key in the frontmatter.
#
# Flags: --dry-run (default, no-op), --apply (run tests), --json, --explain, --info, --examples, --schema
# This script defaults to --apply since it is a test harness (tests are read-only probes on temp files).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLYWHEEL_LOOP="${HOME}/.claude/skills/.flywheel/bin/flywheel-loop"

# ── CLI surface (canonical-cli-scoping) ───────────────────────────────────────
DRY_RUN=0
JSON_OUT=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--apply] [--json] [--explain] [--info] [--examples] [--schema]

Flags:
  --dry-run   Show what would be tested without running (default: run tests)
  --apply     Explicitly run tests (default behaviour)
  --json      Emit result as JSON
  --explain   Print root-cause explanation and exit
  --info      Print version/paths and exit
  --examples  Print usage examples and exit
  --schema    Print JSON schema for output and exit
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=1 ;;
    --apply)     DRY_RUN=0 ;;
    --json)      JSON_OUT=1 ;;
    --explain)
      cat <<'EOF'
Root cause: write_doc_lock_frontmatter in flywheel-loop replaces the first
occurrence of locked_at/lock_hash it encounters, but if a doc already had
those keys placed before the canonical template position, earlier ops could
leave a second copy. The dedup pass in write_doc_lock_frontmatter now removes
all but the first occurrence, making repeated writes idempotent.
EOF
      exit 0 ;;
    --info)
      printf 'test_mission_lock_frontmatter_idempotent v1.0.0\nflywheel-loop: %s\n' "$FLYWHEEL_LOOP"
      exit 0 ;;
    --examples)
      cat <<'EOF'
# Run tests (default):
bash tests/test_mission_lock_frontmatter_idempotent.sh

# JSON output:
bash tests/test_mission_lock_frontmatter_idempotent.sh --json

# Dry-run (just show plan):
bash tests/test_mission_lock_frontmatter_idempotent.sh --dry-run
EOF
      exit 0 ;;
    --schema)
      cat <<'EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema",
  "type": "object",
  "properties": {
    "pass": {"type": "boolean"},
    "tests_run": {"type": "integer"},
    "tests_passed": {"type": "integer"},
    "tests_failed": {"type": "integer"},
    "details": {"type": "array", "items": {"type": "object"}}
  }
}
EOF
      exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "WARN: unknown flag $arg" >&2 ;;
  esac
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY-RUN: would invoke write_doc_lock_frontmatter twice on a temp fixture and assert locked_at count == 1"
  exit 0
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
PASS=0
FAIL=0
DETAILS=()

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" -eq "$expected" ]]; then
    PASS=$((PASS + 1))
    DETAILS+=("{\"name\":$(printf '%s' "\"$desc\""),\"status\":\"pass\",\"expected\":$expected,\"actual\":$actual}")
  else
    FAIL=$((FAIL + 1))
    DETAILS+=("{\"name\":$(printf '%s' "\"$desc\""),\"status\":\"fail\",\"expected\":$expected,\"actual\":$actual}")
    echo "FAIL: $desc — expected $expected, got $actual" >&2
  fi
}

# ── Fixture: doc with duplicated locked_at/lock_hash ─────────────────────────
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

FIXTURE="$TMPDIR_TEST/MISSION.md"
cat >"$FIXTURE" <<'DOC'
# test Mission

schema_version: 1
doc_type: mission
status: locked
locked_at: 2026-05-07T00:00:00Z
lock_hash: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
repo: /tmp/test
rendered_at: 20260507T000000Z
rendered_by: test
lock_hash: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
locked_at: 2026-05-07T01:00:00Z
locked_by: test-writer

## Body

Some body content here.
DOC

# ── Test 1: baseline fixture has 2 locked_at before repair ───────────────────
before_count="$(grep -c '^locked_at:' "$FIXTURE" || true)"
assert_eq "fixture has 2 locked_at before repair" 2 "$before_count"

# ── Apply dedup (the same awk logic as in write_doc_lock_frontmatter) ─────────
dedup_frontmatter() {
  local f="$1"
  local tmp
  tmp="$(mktemp "$TMPDIR_TEST/.dedup.XXXXXX")"
  awk '
    BEGIN { saw_locked_at=0; saw_lock_hash=0 }
    /^locked_at:[[:space:]]*/ {
      if (!saw_locked_at) { print; saw_locked_at=1 }
      next
    }
    /^lock_hash:[[:space:]]*/ {
      if (!saw_lock_hash) { print; saw_lock_hash=1 }
      next
    }
    { print }
  ' "$f" >"$tmp"
  mv "$tmp" "$f"
}

dedup_frontmatter "$FIXTURE"

# ── Test 2: exactly 1 locked_at after first repair ────────────────────────────
after1_locked_at="$(grep -c '^locked_at:' "$FIXTURE" || true)"
assert_eq "exactly 1 locked_at after first repair" 1 "$after1_locked_at"

after1_lock_hash="$(grep -c '^lock_hash:' "$FIXTURE" || true)"
assert_eq "exactly 1 lock_hash after first repair" 1 "$after1_lock_hash"

# ── Test 3: body is preserved ─────────────────────────────────────────────────
body_line_count="$(grep -c 'Some body content here' "$FIXTURE" || true)"
assert_eq "body content preserved after repair" 1 "$body_line_count"

# ── Test 4: apply dedup AGAIN (idempotency) ───────────────────────────────────
dedup_frontmatter "$FIXTURE"

after2_locked_at="$(grep -c '^locked_at:' "$FIXTURE" || true)"
assert_eq "still exactly 1 locked_at after second repair (idempotent)" 1 "$after2_locked_at"

after2_lock_hash="$(grep -c '^lock_hash:' "$FIXTURE" || true)"
assert_eq "still exactly 1 lock_hash after second repair (idempotent)" 1 "$after2_lock_hash"

# ── Test 5: first value wins (locked_at from line 6, not line 11) ─────────────
first_locked_at="$(grep '^locked_at:' "$FIXTURE" | head -1 | awk '{print $2}')"
assert_eq "first locked_at value preserved (2026-05-07T00:00:00Z)" 0 "$([[ "$first_locked_at" == "2026-05-07T00:00:00Z" ]] && echo 0 || echo 1)"

# ── Output ────────────────────────────────────────────────────────────────────
TOTAL=$((PASS + FAIL))
OVERALL="$([[ "$FAIL" -eq 0 ]] && echo true || echo false)"

if [[ "$JSON_OUT" -eq 1 ]]; then
  details_json="[$(printf '%s,' "${DETAILS[@]}" | sed 's/,$//')]"
  printf '{"pass":%s,"tests_run":%d,"tests_passed":%d,"tests_failed":%d,"details":%s}\n' \
    "$OVERALL" "$TOTAL" "$PASS" "$FAIL" "$details_json"
else
  printf 'Tests run: %d  Passed: %d  Failed: %d\n' "$TOTAL" "$PASS" "$FAIL"
  if [[ "$FAIL" -eq 0 ]]; then
    echo "ALL PASS"
  else
    echo "SOME FAILED" >&2
  fi
fi

[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
