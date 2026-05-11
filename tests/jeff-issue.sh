#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLI="$ROOT/.flywheel/scripts/jeff-issue.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-issue.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

state="$TMP/state"

python3 -m py_compile "$CLI" && pass "script syntax" || fail "script syntax"
"$CLI" --help | grep -q 'jeff-issue.py doctor' && pass "help shows command surface" || fail "help shows command surface"

"$CLI" --info --json --state-dir "$state" >"$TMP/info.json"
assert_jq "$TMP/info.json" '.mode == "info" and (.submit_requires | index("--idempotency-key"))' "info exposes submit gates"

"$CLI" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '.examples | length >= 4' "examples emit workflows"

"$CLI" schema submit --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.submit_gates | index("post_submit_body_length")' "schema names post-submit verification"

"$CLI" doctor --json --state-dir "$state" >"$TMP/doctor.json" || true
assert_jq "$TMP/doctor.json" '.mode == "doctor" and (.signals[0].name == "jeff_issue_phase_gate_status")' "doctor exposes signal"

"$CLI" health --json --state-dir "$state" >"$TMP/health.json"
assert_jq "$TMP/health.json" '.mode == "health" and .ledger_rows == 0' "health reads empty ledger"

"$CLI" repair --scope state --dry-run --json --state-dir "$state" >"$TMP/repair-dry.json"
assert_jq "$TMP/repair-dry.json" '.status == "dry_run" and (.actual_actions | length) == 0' "repair dry-run is no-op"

"$CLI" repair --scope state --apply --idempotency-key fixture --json --state-dir "$state" >"$TMP/repair-apply.json"
assert_jq "$TMP/repair-apply.json" '.status == "applied" and (.actual_actions | length) >= 2' "repair apply creates state"

"$CLI" validate source --repo Dicklesworthstone/ntm --keywords "runtime handoff" --json --state-dir "$state" >"$TMP/source.json"
assert_jq "$TMP/source.json" '.phase == "source" and .source_probe_complete == true and .dedup.mode == "planned"' "source validation is read-only by default"

"$CLI" draft \
  --repo Dicklesworthstone/ntm \
  --title "Runtime handoff scope leaks across projects" \
  --tracking-bead flywheel-95cp \
  --observed "runtime handoff row from one project overwrites another" \
  --expected "runtime handoff stays scoped per working directory" \
  --repro "ntm handoff write --cwd a && ntm handoff write --cwd b" \
  --source-ref src/main.rs:42 \
  --dry-run \
  --json \
  --state-dir "$state" >"$TMP/draft.json"
assert_jq "$TMP/draft.json" '.phase == "draft" and .status == "pass" and .dry_run == true and (.actual_actions | length) == 0 and (.draft_body | contains("Out of scope"))' "draft dry-run renders template without write"
assert_jq "$TMP/draft.json" '(.draft_body | split("\n") | map(select(startswith("## "))) | length) == 8 and (.draft_body | contains("## Monitor plan"))' "draft renders eight sections with monitor plan"

"$CLI" draft \
  --repo Dicklesworthstone/ntm \
  --title "Runtime handoff scope leaks across projects" \
  --tracking-bead flywheel-95cp \
  --observed "runtime handoff row from one project overwrites another" \
  --expected "runtime handoff stays scoped per working directory" \
  --repro "ntm handoff write --cwd a && ntm handoff write --cwd b" \
  --source-ref src/main.rs:42 \
  --apply \
  --idempotency-key draft-fixture \
  --out "$TMP/draft.md" \
  --json \
  --state-dir "$state" >"$TMP/draft-apply.json"
assert_jq "$TMP/draft-apply.json" '.status == "pass" and (.actual_actions | length) == 1' "draft apply writes with idempotency key"
test -f "$TMP/draft.md" && pass "draft file written" || fail "draft file written"

"$CLI" rubric --draft "$ROOT/.flywheel/jeff-issue-rubric/v1/fixtures/high-quality.md" --json >"$TMP/rubric.json"
assert_jq "$TMP/rubric.json" '.phase == "rubric" and .status == "pass" and .rubric.decision == "auto_post"' "rubric wraps 7-axis gate"

"$CLI" submit \
  --draft "$TMP/draft.md" \
  --repo Dicklesworthstone/ntm \
  --title "Runtime handoff scope leaks across projects" \
  --tracking-bead flywheel-95cp \
  --apply \
  --json \
  --state-dir "$state" >"$TMP/submit-blocked.json" || true
assert_jq "$TMP/submit-blocked.json" '.status == "blocked" and (.blocked_by | index("missing_joshua_approval")) and (.blocked_by | index("missing_idempotency_key"))' "submit fails closed without approval and key"
assert_jq "$TMP/submit-blocked.json" '.blocked_by | index("rubric_not_pass")' "submit requires passing rubric before apply"

mkdir -p "$TMP/bin"
fake_gh="$TMP/bin/gh"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'if [ "${1:-}" = "issue" ] && [ "${2:-}" = "create" ]; then' \
  '  printf "%s\n" "https://github.com/Dicklesworthstone/ntm/issues/999"' \
  '  exit 0' \
  'fi' \
  'if [ "${1:-}" = "issue" ] && [ "${2:-}" = "view" ]; then' \
  '  printf "%s\n" "{\"number\":999,\"url\":\"https://github.com/Dicklesworthstone/ntm/issues/999\",\"title\":\"Fixture\",\"body\":\"non-empty body\"}"' \
  '  exit 0' \
  'fi' \
  'exit 2' >"$fake_gh"
chmod +x "$fake_gh"
JEFF_ISSUES_REGISTRY="$TMP/registry.jsonl" PATH="$TMP/bin:$PATH" "$CLI" submit \
  --draft "$ROOT/.flywheel/jeff-issue-rubric/v1/fixtures/high-quality.md" \
  --repo Dicklesworthstone/ntm \
  --title "Runtime handoff scope leaks across projects" \
  --tracking-bead flywheel-95cp \
  --apply \
  --joshua-approval approved \
  --idempotency-key submit-fixture \
  --json \
  --state-dir "$state" >"$TMP/submit-apply.json"
assert_jq "$TMP/submit-apply.json" '.status == "submitted" and .post_submit_body_length > 0 and .number == 999' "submit apply verifies non-empty posted body"
assert_jq "$TMP/registry.jsonl" '.number == 999 and .tracking_bead == "flywheel-95cp"' "submit apply appends outbound registry"

"$CLI" audit --json --state-dir "$state" >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.rows >= 2' "audit reads mutations"

"$CLI" why draft-fixture --json --state-dir "$state" >"$TMP/why.json"
assert_jq "$TMP/why.json" '.matches | length >= 1' "why traces idempotency key"

"$CLI" completion bash | grep -q 'jeff-issue.py' && pass "completion emits shell hook" || fail "completion emits shell hook"
test -f "$HOME/.claude/commands/flywheel/jeff-issue.md" && pass "slash wrapper exists" || fail "slash wrapper exists"
test -f "$HOME/.claude/commands/flywheel/file-jeff.md" && pass "file-jeff slash wrapper exists" || fail "file-jeff slash wrapper exists"
grep -q -- '--dry-run' "$HOME/.claude/commands/flywheel/file-jeff.md" && pass "file-jeff command generation dry-run default" || fail "file-jeff command generation dry-run default"
if grep -q 'gh issue create' "$HOME/.claude/commands/flywheel/file-jeff.md"; then
  fail "file-jeff wrapper must not contain direct gh issue create"
else
  pass "file-jeff wrapper avoids direct filing"
fi

echo
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
