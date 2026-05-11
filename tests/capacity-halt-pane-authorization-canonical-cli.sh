#!/usr/bin/env bash
# tests/capacity-halt-pane-authorization-canonical-cli.sh
# flywheel-k8gcv.5 (wave-3-05).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/capacity-halt-pane-authorization.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# AG3
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .capabilities and (.subcommands | length >= 5)' >/dev/null && pass "AG3 --info" || fail "AG3 --info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema' >/dev/null && pass "AG3 --schema" || fail "AG3 --schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "AG3 --examples" || fail "AG3 --examples"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks' >/dev/null && pass "AG3 doctor (mutates_state=yes)" || fail "AG3 doctor"

# Canonical subcommands
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health" and has("max_age_seconds")' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why envelope (default)" || fail "why default"
"$SCRIPT" why credential-rotation --json 2>/dev/null | jq -e '.topic == "credential-rotation"' >/dev/null && pass "why credential-rotation topic" || fail "why credential-rotation"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart" and (.steps | length >= 3)' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Repair + apply contract
"$SCRIPT" repair --scope audit-ledger-prime --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .scope == "audit-ledger-prime" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run" || fail "repair --dry-run"
"$SCRIPT" repair --scope audit-ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key returns rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0" || fail "lint RC=$rc"

# Backward-compat fixtures
TMP_TOPO="$(mktemp -t k8gcv5-topo.XXXXXX)"
TMP_LEDGER="$(mktemp -t k8gcv5-led.XXXXXX)"

# Worker pane fixture (matches real session-topology.jsonl shape:
# worker_panes list, orchestrator_pane int, effective_at iso)
NOW_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat >"$TMP_TOPO" <<EOF
{"schema_version":"session-topology/v1","ts":"$NOW_ISO","effective_at":"$NOW_ISO","session":"flywheel","session_status":"live","orchestrator_pane":1,"callback_pane":1,"human_pane":0,"worker_panes":[2,3]}
EOF

CAPACITY_HALT_AUTH_TOPOLOGY="$TMP_TOPO" CAPACITY_HALT_AUTH_LEDGER="$TMP_LEDGER" CAPACITY_HALT_AUTH_NOW_EPOCH="$(date +%s)" \
  "$SCRIPT" --session flywheel --pane 3 --json 2>/dev/null \
  | jq -e '.status == "authorized" and .authorized == true and .role == "worker_pane"' >/dev/null \
  && pass "legacy worker_pane probe authorizes" || fail "legacy worker_pane"

# Orchestrator pane returns protected_refusal rc=5
CAPACITY_HALT_AUTH_TOPOLOGY="$TMP_TOPO" CAPACITY_HALT_AUTH_LEDGER="$TMP_LEDGER" CAPACITY_HALT_AUTH_NOW_EPOCH="$(date +%s)" \
  "$SCRIPT" --session flywheel --pane 1 --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 5 ]] && pass "legacy orchestrator pane returns rc=5 protected_refusal" || fail "legacy orchestrator rc=$rc"

# Unknown pane returns rc=6
CAPACITY_HALT_AUTH_TOPOLOGY="$TMP_TOPO" CAPACITY_HALT_AUTH_LEDGER="$TMP_LEDGER" CAPACITY_HALT_AUTH_NOW_EPOCH="$(date +%s)" \
  "$SCRIPT" --session flywheel --pane 99 --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 6 ]] && pass "legacy unknown pane returns rc=6" || fail "legacy unknown pane rc=$rc"

# Malformed (non-numeric pane) returns rc=3
CAPACITY_HALT_AUTH_TOPOLOGY="$TMP_TOPO" \
  "$SCRIPT" --session flywheel --pane abc --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "legacy non-numeric pane returns rc=3 malformed" || fail "legacy malformed rc=$rc"

# --help
"$SCRIPT" --help 2>&1 | grep -qE 'usage|authorization' && pass "--help shows usage" || fail "--help"

rm -f "$TMP_TOPO" "$TMP_LEDGER"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
