#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

"$BIN" --info --json \
  | jq -e '.command=="info" and .binary and .flywheel_home' >/dev/null

"$BIN" --no-color --no-emoji --width 100 health --repo <flywheel-repo> --json \
  | jq -e '.command=="health" and .repo=="<flywheel-repo>"' >/dev/null

"$BIN" --examples --json \
  | jq -e '.command=="examples" and (.examples|length)>=5 and all(.examples[]; has("name") and has("command"))' >/dev/null

"$BIN" quickstart --json \
  | jq -e '.command=="quickstart" and .status=="ok" and (.steps|length)>=5' >/dev/null

"$BIN" help health --json \
  | jq -e '.command=="help" and .topic=="health" and (.text|test("health"))' >/dev/null

"$BIN" schema quickstart --json \
  | jq -e '.schema_version=="flywheel-loop.canonical.v1" and .command=="quickstart"' >/dev/null

"$BIN" completion bash >"$TMPDIR/bash"
rg -q 'complete -F _flywheel_loop_completion flywheel-loop' "$TMPDIR/bash"

"$BIN" completion zsh >"$TMPDIR/zsh"
rg -q '^compadd ' "$TMPDIR/zsh"

"$BIN" --explain --idempotency-key hxzw-test repair --scope doctrine --repo <flywheel-repo> --dry-run --json \
  | jq -e '.command=="repair" and .dry_run==true and .explain==true and .idempotency_key=="hxzw-test" and (.audit_log|test("flywheel-loop-repair.jsonl")) and (.planned_actions|length)>=1 and (.would_write|length)==0 and (.would_delete|length)==0 and (.would_call_external|length)==0 and (.blocked_by|length)==0 and (has("actions")|not) and (has("actual_actions")|not)' >/dev/null

"$BIN" audit --repo <flywheel-repo> --json \
  | jq -e '.command=="audit" and .writes_are_repo_local==true' >/dev/null

"$BIN" why flywheel-hxzw --json \
  | jq -e '.command=="why" and .id=="flywheel-hxzw"' >/dev/null

bash "$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh" flywheel-loop >"$TMPDIR/check-cli-scoping"
# flywheel-wzjo9.1.7 calibration: check-cli-scoping.sh now reports 13 checks
# (was 4 when this test was written); accept any positive pass count with 0 fail.
rg -q 'Summary: [1-9][0-9]* pass, 0 fail' "$TMPDIR/check-cli-scoping"

# ---- Fillin-specific assertions (flywheel-wzjo9.1.7) ----

# Native colliding-verb regression guard: doctor reaches portable_doctor
# (returns loop-driver-doctor schema, NOT scaffold-meta-doctor)
"$BIN" doctor --repo <flywheel-repo> --scope loop-driver --json \
  | jq -e '.schema_version=="loop-driver-doctor/v1"' >/dev/null

# Scaffold intercept fully bypassed: --info has native shape (.binary, .flywheel_home)
"$BIN" --info --json \
  | jq -e '.binary and .flywheel_home and (.command=="info")' >/dev/null

# Scaffold-meta surfaces still callable directly via scaffold_main when needed.
# (Direct call: source the file, override SCAFFOLD_AUDIT_LOG, invoke scaffold_main.)
SCAFFOLD_AUDIT_LOG=/tmp/__wzjo9-1-7-scaffold-test.jsonl bash -c "
  source $BIN >/dev/null 2>&1 || true
  scaffold_emit_schema doctor 2>/dev/null
" 2>/dev/null | jq -e '.scope=="scaffold-meta" and .surface=="doctor"' >/dev/null

# Scaffold-meta-validate has substantive impl (not 'todo')
SCAFFOLD_AUDIT_LOG=/tmp/__wzjo9-1-7-scaffold-test.jsonl bash -c "
  source $BIN >/dev/null 2>&1 || true
  scaffold_cmd_validate env 2>/dev/null
" | jq -e '.subject=="env" and .scope=="scaffold-meta" and (.status | IN("pass","fail"))' >/dev/null

# Lint clean (regression guard for the L4 fix)
.flywheel/scripts/canonical-cli-lint.sh "$BIN" >/dev/null 2>&1

# TODO marker count == 0
[[ "$(grep -c 'TODO(canonical-cli-scaffold)' "$BIN")" == "0" ]]

echo "PASS flywheel-loop canonical CLI smoke (baseline 11 + 6 fillin assertions = 17)"
