#!/usr/bin/env bash
# tests/scaffold-canonical-cli-e2e.sh
# E2E for the parametric scaffolder. Bead flywheel-ws02m AG5/AG6.
#
# Builds a synthetic fixture target (small inline-arg-parsing script),
# runs scaffolder dry-run + apply + idempotency check, asserts the
# scaffolded target passes the canonical-cli surface (13 assertions),
# and verifies receipt JSONL is appended.
#
# Read-only on production state: SCAFFOLD_RUNS_LOG / SCAFFOLD_INVENTORY
# / SCAFFOLD_TESTS_DIR / SCAFFOLD_REPO_ROOT all overridden to TMPDIR.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCAFFOLDER="$ROOT/.flywheel/scripts/scaffold-canonical-cli.sh"
HELPER_LIB="$ROOT/.flywheel/lib/canonical-cli-helpers.sh"
TMPDIR="$(mktemp -d -t scaffold-cli-e2e.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Build an isolated mini-repo so the scaffolder's REPO_ROOT-relative paths
# resolve cleanly without touching the real flywheel repo state.
MINI_ROOT="$TMPDIR/repo"
mkdir -p "$MINI_ROOT/.flywheel/scripts" "$MINI_ROOT/.flywheel/lib" \
         "$MINI_ROOT/.flywheel/audit/flywheel-cli-inventory" \
         "$MINI_ROOT/.flywheel/state" \
         "$MINI_ROOT/tests"

# Copy the helper lib into the mini-repo
cp "$HELPER_LIB" "$MINI_ROOT/.flywheel/lib/canonical-cli-helpers.sh"

# Synthesize a fixture target: small inline-arg-parsing script
FIXTURE="$MINI_ROOT/.flywheel/scripts/fixture-target.sh"
cat > "$FIXTURE" <<'TARGET'
#!/usr/bin/env bash
# fixture target for scaffold-canonical-cli e2e
set -uo pipefail

VERSION="fixture.v1"
JSON_OUT=0
INPUT=""

usage() { printf 'usage: fixture-target.sh --input X [--json]\n'; }

run() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '{"input":"%s","status":"ok"}\n' "$INPUT"
  else
    printf 'input=%s status=ok\n' "$INPUT"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input) INPUT="${2:-}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'ERR: unknown arg %s\n' "$1" >&2; exit 64 ;;
  esac
done

run
TARGET
chmod +x "$FIXTURE"

# Inventory entry pointing at the fixture (or use --allow-uninventoried)
cat > "$MINI_ROOT/.flywheel/audit/flywheel-cli-inventory/inventory.jsonl" <<INV
{"path":".flywheel/scripts/fixture-target.sh","priority":"P2","lane":"test","signals":{}}
INV

# Override env so scaffolder uses the mini-repo
export SCAFFOLD_REPO_ROOT="$MINI_ROOT"
export SCAFFOLD_HELPER_LIB="$MINI_ROOT/.flywheel/lib/canonical-cli-helpers.sh"
export SCAFFOLD_INVENTORY="$MINI_ROOT/.flywheel/audit/flywheel-cli-inventory/inventory.jsonl"
export SCAFFOLD_RUNS_LOG="$MINI_ROOT/.flywheel/state/scaffold-runs.jsonl"
export SCAFFOLD_TESTS_DIR="$MINI_ROOT/tests"

# Test 1: scaffolder syntax_ok
if bash -n "$SCAFFOLDER" 2>/dev/null; then pass "scaffolder bash -n"; else fail "scaffolder syntax"; fi

# Test 2: --info envelope is canonical
if "$SCAFFOLDER" --info --json 2>/dev/null | jq -e '.schema_version == "scaffold-canonical-cli/v1" and .command == "info"' >/dev/null; then
  pass "--info emits canonical envelope"
else fail "--info envelope"; fi

# Test 3: --schema envelope
if "$SCAFFOLDER" --schema 2>/dev/null | jq -e '.schema_version == "scaffold-canonical-cli/v1" and .command == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope"
else fail "--schema envelope"; fi

# Test 4: --examples envelope
if "$SCAFFOLDER" --examples --json 2>/dev/null | jq -e '.command == "examples" and (.examples | length > 0)' >/dev/null; then
  pass "--examples emits canonical envelope with examples array"
else fail "--examples envelope"; fi

# Test 5: dry-run emits unified diff path + zero side effects
DRY_OUT="$TMPDIR/dry.json"
"$SCAFFOLDER" "$FIXTURE" --dry-run --json > "$DRY_OUT" 2>&1
RC=$?
if [[ "$RC" -eq 0 ]] \
  && jq -e '.status == "dry_run_ok" and .scaffold_lines_added > 0 and .todo_count > 0' "$DRY_OUT" >/dev/null; then
  pass "dry-run emits dry_run_ok envelope with positive scaffold_lines_added + todo_count"
else
  fail "dry-run envelope: $(jq -c '{status, lines: .scaffold_lines_added, todos: .todo_count}' "$DRY_OUT")"
fi

# Test 6: dry-run does NOT mutate the target
if grep -q '^# flywheel-cli-surface: true' "$FIXTURE"; then
  fail "dry-run mutated the target (magic comment present)"
else
  pass "dry-run leaves target untouched (no magic comment)"
fi

# Test 7: dry-run does NOT write runs log
if [[ ! -e "$SCAFFOLD_RUNS_LOG" ]]; then
  pass "dry-run does not write runs log (read-only invariant)"
else
  fail "dry-run wrote runs log"
fi

# Test 8: --apply without --idempotency-key REFUSES (rc=3)
"$SCAFFOLDER" "$FIXTURE" --apply --json >/dev/null 2>&1
RC=$?
if [[ "$RC" -eq 3 ]]; then
  pass "--apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "--apply without key rc=$RC (expected 3)"
fi

# Test 9: --apply with --idempotency-key writes target + receipt
APPLY_OUT="$TMPDIR/apply.json"
"$SCAFFOLDER" "$FIXTURE" --apply --idempotency-key="e2e-test-key" --json > "$APPLY_OUT" 2>&1
RC=$?
if [[ "$RC" -eq 0 ]] \
  && jq -e '.status == "apply_ok"' "$APPLY_OUT" >/dev/null \
  && grep -q '^# flywheel-cli-surface: true' "$FIXTURE"; then
  pass "--apply mutates target + magic comment present"
else
  fail "--apply: $(jq -c '.status' "$APPLY_OUT") magic_comment_present=$(grep -c '^# flywheel-cli-surface: true' "$FIXTURE")"
fi

# Test 10: backup file created during apply
BACKUP_GLOB="${FIXTURE}.bak.scaffold-*"
if compgen -G "$BACKUP_GLOB" >/dev/null; then
  pass "apply created backup file"
else
  fail "apply did not create backup"
fi

# Test 11: receipt JSONL appended
if [[ -s "$SCAFFOLD_RUNS_LOG" ]] \
  && jq -e '.status == "apply_ok" and .target == ".flywheel/scripts/fixture-target.sh" and .idempotency_key == "e2e-test-key"' "$SCAFFOLD_RUNS_LOG" >/dev/null; then
  pass "receipt JSONL appended with apply_ok + idempotency_key"
else
  fail "receipt not appended or malformed: $(cat "$SCAFFOLD_RUNS_LOG" 2>&1 | head -1)"
fi

# Test 12: scaffolded target is bash -n clean
if bash -n "$FIXTURE" 2>/dev/null; then pass "scaffolded target syntax_ok"; else fail "scaffolded target syntax error"; fi

# Test 13: scaffolded target's canonical surface works (smoke)
if "$FIXTURE" --info --json 2>/dev/null | jq -e '.schema_version == "fixture-target/v1" and .command == "info"' >/dev/null; then
  pass "scaffolded target --info works"
else fail "scaffolded --info"; fi

# Test 14: scaffolded canonical subcommands return JSON envelopes
ALL_OK=1
for cmd in doctor health audit; do
  if ! "$FIXTURE" "$cmd" --json 2>/dev/null | jq -e --arg c "$cmd" '.command == $c' >/dev/null; then
    ALL_OK=0
    break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "scaffolded doctor/health/audit emit canonical envelopes"
else
  fail "scaffolded canonical subcommands envelope"
fi

# Test 15: scaffolded backwards-compat — original --input still works
if "$FIXTURE" --input hello --json 2>/dev/null | jq -e '.input == "hello" and .status == "ok"' >/dev/null; then
  pass "scaffolded target preserves backwards-compat (--input flag falls through)"
else
  fail "scaffolded backwards-compat regression"
fi

# Test 16: idempotency — re-running on already-scaffolded target is no-op
IDEM_OUT="$TMPDIR/idem.json"
"$SCAFFOLDER" "$FIXTURE" --dry-run --json > "$IDEM_OUT" 2>&1
if jq -e '.status == "already_scaffolded" and .reason' "$IDEM_OUT" >/dev/null; then
  pass "re-run on scaffolded target returns already_scaffolded"
else
  fail "idempotency regression: $(jq -c .status "$IDEM_OUT")"
fi

# Test 17: re-apply does NOT change the file (idempotency preserved on apply too)
SHA_BEFORE="$(shasum -a 256 "$FIXTURE" | awk '{print $1}')"
"$SCAFFOLDER" "$FIXTURE" --apply --idempotency-key="e2e-rerun" --json >/dev/null 2>&1
SHA_AFTER="$(shasum -a 256 "$FIXTURE" | awk '{print $1}')"
if [[ "$SHA_BEFORE" == "$SHA_AFTER" ]]; then
  pass "apply on already-scaffolded target leaves file byte-identical"
else
  fail "apply on already-scaffolded target mutated file (sha changed)"
fi

# Test 18: scaffolder refuses jeff-stack path (synthesized)
mkdir -p "$MINI_ROOT/.flywheel/scripts/ntm/internal" 2>/dev/null
cp "$FIXTURE.bak.scaffold-"* "$MINI_ROOT/.flywheel/scripts/ntm/internal/jeff-target.sh" 2>/dev/null \
  || cp "$FIXTURE" "$MINI_ROOT/.flywheel/scripts/ntm/internal/jeff-target.sh"
chmod +x "$MINI_ROOT/.flywheel/scripts/ntm/internal/jeff-target.sh"
JEFF_OUT="$TMPDIR/jeff-refusal.json"
"$SCAFFOLDER" "$MINI_ROOT/.flywheel/scripts/ntm/internal/jeff-target.sh" --dry-run --json > "$JEFF_OUT" 2>&1
RC=$?
if [[ "$RC" -eq 66 ]] \
  && jq -e '.status == "refused" and .reason == "jeff_stack_target"' "$JEFF_OUT" >/dev/null; then
  pass "scaffolder refuses jeff-stack target with rc=66"
else
  fail "jeff-stack refusal: rc=$RC reason=$(jq -c '.reason // "none"' "$JEFF_OUT")"
fi

# Test 19: scaffolder refuses uninventoried target by default
mkdir -p "$MINI_ROOT/.flywheel/scripts/uninventoried"
cp "$FIXTURE" "$MINI_ROOT/.flywheel/scripts/uninventoried/orphan.sh"
chmod +x "$MINI_ROOT/.flywheel/scripts/uninventoried/orphan.sh"
UNINV_OUT="$TMPDIR/uninv-refusal.json"
"$SCAFFOLDER" "$MINI_ROOT/.flywheel/scripts/uninventoried/orphan.sh" --dry-run --json > "$UNINV_OUT" 2>&1
RC=$?
if [[ "$RC" -eq 66 ]] \
  && jq -e '.status == "refused" and .reason == "uninventoried_target"' "$UNINV_OUT" >/dev/null; then
  pass "scaffolder refuses uninventoried target with rc=66"
else
  fail "uninventoried refusal: rc=$RC reason=$(jq -c '.reason // "none"' "$UNINV_OUT")"
fi

# Test 20: --allow-uninventoried bypasses uninventoried refusal.
# Use a FRESH non-scaffolded target so the idempotency check doesn't
# preempt the inventory check.
ALLOW_TARGET="$MINI_ROOT/.flywheel/scripts/uninventoried/fresh-orphan.sh"
mkdir -p "$(dirname "$ALLOW_TARGET")"
cat > "$ALLOW_TARGET" <<'A'
#!/usr/bin/env bash
set -uo pipefail
echo "fresh"
A
chmod +x "$ALLOW_TARGET"
ALLOW_OUT="$TMPDIR/allow.json"
"$SCAFFOLDER" "$ALLOW_TARGET" --dry-run --allow-uninventoried --json > "$ALLOW_OUT" 2>&1
RC=$?
if [[ "$RC" -eq 0 ]] \
  && jq -e '.status == "dry_run_ok"' "$ALLOW_OUT" >/dev/null; then
  pass "--allow-uninventoried bypasses uninventoried refusal"
else
  fail "--allow-uninventoried: rc=$RC status=$(jq -c '.status' "$ALLOW_OUT")"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
