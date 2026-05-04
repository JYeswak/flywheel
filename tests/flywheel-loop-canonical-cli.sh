#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

"$BIN" --info --json \
  | jq -e '.command=="info" and .binary and .flywheel_home' >/dev/null

"$BIN" --no-color --no-emoji --width 100 health --repo /Users/josh/Developer/flywheel --json \
  | jq -e '.command=="health" and .repo=="/Users/josh/Developer/flywheel"' >/dev/null

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

"$BIN" --explain --idempotency-key hxzw-test repair --scope doctrine --repo /Users/josh/Developer/flywheel --dry-run --json \
  | jq -e '.command=="repair" and .dry_run==true and .explain==true and .idempotency_key=="hxzw-test" and (.audit_log|test("flywheel-loop-repair.jsonl")) and (.planned_actions|length)>=1 and (.would_write|length)==0 and (.would_delete|length)==0 and (.would_call_external|length)==0 and (.blocked_by|length)==0 and (has("actions")|not) and (has("actual_actions")|not)' >/dev/null

"$BIN" audit --repo /Users/josh/Developer/flywheel --json \
  | jq -e '.command=="audit" and .writes_are_repo_local==true' >/dev/null

"$BIN" why flywheel-hxzw --json \
  | jq -e '.command=="why" and .id=="flywheel-hxzw"' >/dev/null

bash "$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh" flywheel-loop >"$TMPDIR/check-cli-scoping"
rg -q 'Summary: 4 pass, 0 fail' "$TMPDIR/check-cli-scoping"

echo "PASS flywheel-loop canonical CLI smoke"
