#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_LOCK_REPAIR_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-lock-repair}"
REPO="${FLYWHEEL_LOCK_REPAIR_REPO:-<flywheel-repo>}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

"$BIN" --help | rg -q 'flywheel-lock-repair doctor'
"$BIN" doctor --repo "$REPO" --json | jq -e '.command=="doctor" and .scope=="locks"' >/dev/null
"$BIN" health --repo "$REPO" --json | jq -e '.command=="health" and .status=="ok"' >/dev/null
"$BIN" --no-color --no-emoji --width 100 health --repo "$REPO" --json | jq -e '.command=="health"' >/dev/null
"$BIN" validate locks --repo "$REPO" --json | jq -e '.command=="doctor"' >/dev/null
"$BIN" audit --repo "$REPO" --json | jq -e '.command=="audit" and (.mutation_ledgers|length)>=1' >/dev/null
"$BIN" why flywheel-64kr --json | jq -e '.command=="why" and .id=="flywheel-64kr"' >/dev/null
"$BIN" --info --json | jq -e '.command=="info" and .binary and .sha256' >/dev/null
"$BIN" --examples --json | jq -e '.command=="examples" and (.examples|length)>=5' >/dev/null
"$BIN" quickstart --json | jq -e '.command=="quickstart" and .status=="ok" and (.steps|length)>=5' >/dev/null
"$BIN" help repair --json | jq -e '.command=="help" and .topic=="repair"' >/dev/null
"$BIN" schema quickstart --json | jq -e '.schema_version=="flywheel-lock-repair.canonical.v1" and .command=="quickstart"' >/dev/null

"$BIN" completion bash >"$TMPDIR/bash-completion"
rg -q 'complete -F _flywheel_lock_repair_completion flywheel-lock-repair' "$TMPDIR/bash-completion"
"$BIN" completion zsh >"$TMPDIR/zsh-completion"
rg -q '^compadd ' "$TMPDIR/zsh-completion"

"$BIN" --explain --idempotency-key 64kr-test repair --scope locks --repo "$REPO" --dry-run --json \
  | jq -e '.command=="repair" and .scope=="locks" and .dry_run==true and .explain==true and .idempotency_key=="64kr-test" and (.planned_actions|length)==3 and (.would_write|length)==0 and (.audit_log|test("lock-log.jsonl"))' >/dev/null

"$BIN" --repo "$REPO" --dry-run --json \
  | jq -e '.command=="repair" and .dry_run==true and (.planned_actions|length)==3' >/dev/null

fixture="$TMPDIR/apply-fixture"
mkdir -p "$fixture/.flywheel"
for name in MISSION GOAL STATE; do
  printf '%s\n' '---' 'status: locked' 'lock_hash: stale' '---' "${name} body" >"$fixture/.flywheel/$name.md"
done
"$BIN" --explain --idempotency-key apply-fixture repair --scope locks --repo "$fixture" --apply --json \
  | jq -e '.command=="repair" and .apply==true and .audit_logged==true and (.actual_actions|length)==3 and (.writes|index(".flywheel/lock-log.jsonl"))' >/dev/null
[[ "$(wc -l <"$fixture/.flywheel/lock-log.jsonl" | tr -d ' ')" == "3" ]]
jq -e 'select(.idempotency_key=="apply-fixture")' "$fixture/.flywheel/lock-log.jsonl" >/dev/null

set +e
"$BIN" definitely-bad >"$TMPDIR/bad.out" 2>"$TMPDIR/bad.err"
bad_rc=$?
set -e
[[ "$bad_rc" -eq 2 ]]
rg -q 'unknown argument' "$TMPDIR/bad.err"

bash "$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh" "$BIN" >"$TMPDIR/check-cli-scoping"
rg -q 'Summary: 4 pass, 0 fail' "$TMPDIR/check-cli-scoping"

echo "PASS flywheel-lock-repair canonical CLI smoke"
