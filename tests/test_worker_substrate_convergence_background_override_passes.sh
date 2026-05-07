#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-worker-substrate-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worker-substrate-override.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }

JOSHUA_OVERRIDE=1 "$SCRIPT" \
  --worker-substrate background-agent \
  --agent-type unknown \
  --prompt "Run an adversarial review synthesis wave." \
  --dispatch-log "$TMP/dispatch-log.jsonl" \
  --task-id override-background \
  --json >"$TMP/out.json"

jq -e '
  .decision == "pass"
  and .reason == "joshua_override"
  and .worker_substrate == "background-agent"
  and .agent_type == "unknown"
  and .joshua_override_present == true
  and .convergence_keyword_match == true
' "$TMP/out.json" >/dev/null \
  && pass "override allows background convergence dispatch" \
  || fail "override allows background convergence dispatch"

jq -e '
  select(.event == "dispatch_worker_substrate_lint")
  | .task_id == "override-background"
  and .decision == "pass"
  and .reason == "joshua_override"
  and .joshua_override_present == true
' "$TMP/dispatch-log.jsonl" >/dev/null \
  && pass "dispatch log records override lint" \
  || fail "dispatch log records override lint"
