#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-worker-substrate-gate.sh"
DISPATCH_DOC="$HOME/.claude/commands/flywheel/dispatch.md"
TEMPLATE_DOC="$HOME/.claude/commands/flywheel/_shared/dispatch-template.md"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worker-substrate-default.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }

bash -n "$SCRIPT" && pass "script syntax"

"$SCRIPT" \
  --prompt "Implement a normal dispatch task on a Codex pane." \
  --dispatch-log "$TMP/dispatch-log.jsonl" \
  --task-id default-codex \
  --json >"$TMP/out.json"

jq -e '
  .decision == "pass"
  and .worker_substrate == "codex-pane"
  and .agent_type == "codex"
  and .reason == "ok"
' "$TMP/out.json" >/dev/null \
  && pass "default classification is codex pane" \
  || fail "default classification is codex pane"

jq -e '
  select(.event == "dispatch_worker_substrate_lint")
  | .task_id == "default-codex"
  and .worker_substrate == "codex-pane"
  and .agent_type == "codex"
' "$TMP/dispatch-log.jsonl" >/dev/null \
  && pass "dispatch log records default classification" \
  || fail "dispatch log records default classification"

rg -q 'WORKER_SUBSTRATE:-codex-pane' "$DISPATCH_DOC" \
  && pass "dispatch doc defaults substrate to codex pane" \
  || fail "dispatch doc defaults substrate to codex pane"

rg -q 'agent_type=<codex\\|claude\\|unknown>' "$TEMPLATE_DOC" \
  && pass "packet header documents agent_type enum" \
  || fail "packet header documents agent_type enum"
