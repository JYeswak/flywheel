#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLI="/Users/josh/.claude/skills/.flywheel/bin/flywheel-conductor"
VALIDATOR="$ROOT/.flywheel/scripts/validate-callback-before-close.sh"
TMP_ROOT="${TMPDIR:-/tmp}/flywheel-conductor-test.$$"
STATE_DIR="$TMP_ROOT/state"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

make_repo() {
  repo="$TMP_ROOT/repo"
  mkdir -p "$repo/.flywheel/scripts"
  cp "$VALIDATOR" "$repo/.flywheel/scripts/validate-callback-before-close.sh"
  chmod +x "$repo/.flywheel/scripts/validate-callback-before-close.sh"
  (cd "$repo" && br init --prefix test >/dev/null)
  bead="$(cd "$repo" && br create "MVP artifact gate test" --priority 1 --type task --description "Acceptance: gate fixture bead" --json | jq -r '.id')"
  printf '%s\t%s\n' "$repo" "$bead"
}

assert_json_eq() {
  file="$1"
  expr="$2"
  expected="$3"
  actual="$(jq -r "$expr" "$file")"
  [ "$actual" = "$expected" ] || fail "$expr expected $expected got $actual"
}

mkdir -p "$TMP_ROOT"
IFS="$(printf '\t')" read -r REPO BEAD <<EOF
$(make_repo)
EOF

GOOD="$TMP_ROOT/good-evidence.md"
cat >"$GOOD" <<EOF
# Evidence

did=3/3 didnt=none gaps=none tests=PASS

Acceptance gates:
- AG1 pass: \`$ROOT/.flywheel/scripts/validate-callback-before-close.sh\`
- AG2 pass: \`$ROOT/tests/fleet-conductor-mvp-gate.sh\`
- AG3 pass: line 42

Executable proof:
\`\`\`bash
bash tests/fleet-conductor-mvp-gate.sh
\`\`\`

Four-lens Self-Grade:
- brand: pass
- sniff: pass
- jeff: pass
- public: pass

Result: shipped validation prevents unsafe MVP artifacts from surfacing.
EOF

BAD="$TMP_ROOT/bad-evidence.md"
cat >"$BAD" <<'EOF'
# Evidence

did=0/3 didnt=flywheel-missing gaps=flywheel-missing tests=FAIL

Acceptance gates:
- AG1 fail

Four-lens Self-Grade:
- brand: pass
- sniff: fail
- jeff: fail
- public: fail
EOF

PREBAR="$TMP_ROOT/prebar-evidence.md"
cat >"$PREBAR" <<'EOF'
# Evidence

artifact_tag=pre-bar

did=0/3 didnt=none gaps=none tests=FAIL

Acceptance gates:
- AG1 not ready

Four-lens Self-Grade:
- brand: pass
- sniff: fail
- jeff: fail
- public: fail
EOF

HELP="$TMP_ROOT/help.txt"
"$CLI" --help >"$HELP"
grep -q -- "--mvp-gate" "$HELP" || fail "help missing --mvp-gate"
"$CLI" --info >/dev/null
"$CLI" --examples >/dev/null
"$CLI" quickstart >/dev/null
"$CLI" help mvp-gate >/dev/null
"$CLI" completion bash >/dev/null
"$CLI" schema mvp-gate --json | jq empty
"$CLI" doctor --json | jq empty
"$CLI" health --state-dir "$STATE_DIR" --json | jq empty
"$CLI" repair --state-dir "$STATE_DIR" --dry-run --json | jq empty
"$CLI" audit --state-dir "$STATE_DIR" --json | jq empty

PASS_JSON="$TMP_ROOT/pass.json"
"$CLI" --mvp-gate "fixture:$GOOD" --repo "$REPO" --bead "$BEAD" --json >"$PASS_JSON"
assert_json_eq "$PASS_JSON" ".schema_version" "flywheel-conductor/mvp-gate/v1"
assert_json_eq "$PASS_JSON" ".status" "pass"
assert_json_eq "$PASS_JSON" ".gate_pass" "true"
assert_json_eq "$PASS_JSON" ".surface_to_joshua" "true"

FAIL_JSON="$TMP_ROOT/fail.json"
if "$CLI" --mvp-gate "fixture:$BAD" --repo "$REPO" --bead "$BEAD" --state-dir "$STATE_DIR" --apply --json >"$FAIL_JSON"; then
  fail "bad evidence should fail the gate"
fi
assert_json_eq "$FAIL_JSON" ".status" "fail"
assert_json_eq "$FAIL_JSON" ".surface_to_joshua" "false"
assert_json_eq "$FAIL_JSON" ".joshua_time_saved.incremented" "true"
jq -e '.rework.bead != null' "$FAIL_JSON" >/dev/null || fail "missing rework bead"
[ "$(wc -l <"$STATE_DIR/joshua-time-saved.jsonl" | tr -d ' ')" = "1" ] || fail "metric ledger should have 1 row"

FAIL_AGAIN_JSON="$TMP_ROOT/fail-again.json"
if "$CLI" --mvp-gate "fixture:$BAD" --repo "$REPO" --bead "$BEAD" --state-dir "$STATE_DIR" --apply --json >"$FAIL_AGAIN_JSON"; then
  fail "bad evidence rerun should still fail the gate"
fi
assert_json_eq "$FAIL_AGAIN_JSON" ".joshua_time_saved.incremented" "false"
[ "$(wc -l <"$STATE_DIR/joshua-time-saved.jsonl" | tr -d ' ')" = "1" ] || fail "metric ledger should dedupe rerun"

PREBAR_JSON="$TMP_ROOT/prebar.json"
"$CLI" --mvp-gate "fixture:$PREBAR" --repo "$REPO" --bead "$BEAD" --state-dir "$STATE_DIR" --json >"$PREBAR_JSON"
assert_json_eq "$PREBAR_JSON" ".status" "pre_bar"
assert_json_eq "$PREBAR_JSON" ".surface_to_joshua" "true"
assert_json_eq "$PREBAR_JSON" ".joshua_time_saved.incremented" "false"

"$CLI" why "$(jq -r '.joshua_time_saved.dedupe_key' "$FAIL_JSON")" --state-dir "$STATE_DIR" --json | jq empty

echo "PASS fleet-conductor-mvp-gate"
