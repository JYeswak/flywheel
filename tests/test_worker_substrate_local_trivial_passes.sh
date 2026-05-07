#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-worker-substrate-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worker-substrate-local.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }

"$SCRIPT" \
  --worker-substrate local \
  --agent-type unknown \
  --prompt "Print local status and exit." \
  --dispatch-log "$TMP/dispatch-log.jsonl" \
  --task-id local-trivial \
  --json >"$TMP/out.json"

jq -e '
  .decision == "pass"
  and .reason == "ok"
  and .worker_substrate == "local"
  and .agent_type == "unknown"
  and .convergence_keyword_match == false
' "$TMP/out.json" >/dev/null \
  && pass "local trivial task passes" \
  || fail "local trivial task passes"

jq -e '
  select(.event == "dispatch_worker_substrate_lint")
  | .task_id == "local-trivial"
  and .worker_substrate == "local"
  and .decision == "pass"
' "$TMP/dispatch-log.jsonl" >/dev/null \
  && pass "dispatch log records local pass" \
  || fail "dispatch log records local pass"
