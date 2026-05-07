#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-worker-substrate-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worker-substrate-block.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }

set +e
"$SCRIPT" \
  --worker-substrate background-agent \
  --agent-type unknown \
  --prompt "Run a convergence synthesis audit wave." \
  --dispatch-log "$TMP/dispatch-log.jsonl" \
  --task-id blocked-background \
  --json >"$TMP/out.json"
rc=$?
set -e

[[ "$rc" -eq 1 ]] \
  && pass "background convergence dispatch is blocked" \
  || fail "background convergence dispatch is blocked"

jq -e '
  .decision == "reject"
  and .reason == "convergence_to_background_agent_blocked"
  and .worker_substrate == "background-agent"
  and .agent_type == "unknown"
  and .convergence_keyword_match == true
' "$TMP/out.json" >/dev/null \
  && pass "block reason is structured" \
  || fail "block reason is structured"

jq -e '
  select(.event == "dispatch_worker_substrate_lint")
  | .task_id == "blocked-background"
  and .decision == "reject"
  and .reason == "convergence_to_background_agent_blocked"
' "$TMP/dispatch-log.jsonl" >/dev/null \
  && pass "dispatch log records blocked lint" \
  || fail "dispatch log records blocked lint"
