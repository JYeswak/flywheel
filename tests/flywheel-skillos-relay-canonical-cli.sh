#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_SKILLOS_RELAY_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-skillos-relay}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

export FLYWHEEL_STATE_DIR="$TMPDIR/state"
export FLYWHEEL_AGENTS_MD="$TMPDIR/AGENTS.md"
export FLYWHEEL_SESSION_TOPOLOGY="$TMPDIR/session-topology.jsonl"
export FLYWHEEL_SKILLOS_RELAY_LEDGER="$TMPDIR/skillos-relay-ledger.jsonl"
export FLYWHEEL_SKILLOS_RELAY_SOFT_LEDGER="$TMPDIR/skillos-relay-soft.jsonl"
export FLYWHEEL_SKILLOS_RELAY_HASH_LEDGER="$TMPDIR/skillos-relay-hash.jsonl"

mkdir -p "$TMPDIR/state"
cat >"$FLYWHEEL_AGENTS_MD" <<'EOF'
# Flywheel fixture

## L82 fixture relay rule

**Rule:** relay this rule in dry-run fixtures.
EOF
jq -nc '{session:"skillos",orchestrator_pane:1,fleet_mail_identity:"SkillosRelayFixture",effective_at:"2026-05-04T00:00:00Z"}' >"$FLYWHEEL_SESSION_TOPOLOGY"

"$BIN" --help | rg -q 'flywheel-skillos-relay doctor'
"$BIN" doctor --json | jq -e '.command=="doctor" and (.drift >= 0)' >/dev/null
"$BIN" --doctor-json | jq -e '.command=="doctor" and (.drift >= 0)' >/dev/null
"$BIN" health --json | jq -e '.command=="health" and .status=="ok"' >/dev/null
"$BIN" --no-color --no-emoji --width 100 health --json | jq -e '.command=="health"' >/dev/null
"$BIN" validate relay --json | jq -e '.command=="doctor" and (.drift >= 0)' >/dev/null
"$BIN" audit --json | jq -e '.command=="audit" and (.mutation_ledgers|length)>=3' >/dev/null
"$BIN" why flywheel-eyvi --json | jq -e '.command=="why" and .id=="flywheel-eyvi"' >/dev/null
"$BIN" --info --json | jq -e '.command=="info" and .binary and .sha256' >/dev/null
"$BIN" --examples --json | jq -e '.command=="examples" and (.examples|length)>=5' >/dev/null
"$BIN" quickstart --json | jq -e '.command=="quickstart" and .status=="ok" and (.steps|length)>=5' >/dev/null
"$BIN" help relay --json | jq -e '.command=="help" and .topic=="relay"' >/dev/null
"$BIN" schema quickstart --json | jq -e '.schema_version=="flywheel-skillos-relay.canonical.v1" and .command=="quickstart"' >/dev/null

"$BIN" completion bash >"$TMPDIR/bash-completion"
rg -q 'complete -F _flywheel_skillos_relay_completion flywheel-skillos-relay' "$TMPDIR/bash-completion"
"$BIN" completion zsh >"$TMPDIR/zsh-completion"
rg -q '^compadd ' "$TMPDIR/zsh-completion"

"$BIN" --explain --idempotency-key eyvi-test repair --scope relay --dry-run --json \
  | jq -e '.command=="repair" and .scope=="relay" and .dry_run==true and .explain==true and .idempotency_key=="eyvi-test" and (.planned_actions|length)==1 and (.actual_actions|length)==0 and (.would_write|length)==0 and (.audit_log|test("skillos-relay-ledger.jsonl"))' >/dev/null

"$BIN" --dry-run --rule L82 >"$TMPDIR/rule-dryrun.ndjson"
jq -s -e '.[0].event=="dry_run_start" and any(.[]; .event=="dry_run" and .rule_id=="L82")' "$TMPDIR/rule-dryrun.ndjson" >/dev/null

set +e
"$BIN" --bogus >"$TMPDIR/bad.out" 2>"$TMPDIR/bad.err"
bad_rc=$?
set -e
[[ "$bad_rc" -eq 2 ]]
rg -q 'unknown argument' "$TMPDIR/bad.err"

bash "$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh" "$BIN" >"$TMPDIR/check-cli-scoping"
rg -q 'Summary: 13 pass, 0 fail' "$TMPDIR/check-cli-scoping"

echo "PASS flywheel-skillos-relay canonical CLI smoke"
