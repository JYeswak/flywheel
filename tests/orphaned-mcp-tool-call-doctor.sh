#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/orphaned-mcp-tool-call-probe.py"
PROMOTE="$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/orphaned-mcp-tool-call.XXXXXX")"
trap 'rm -rf "$TMP" "${repo:-}" "${scratch_parent:-}"' EXIT

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL %s\n' "$1" >&2
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

bash -n "$PROMOTE" && pass "syntax doctor-signal-bead-promotion" || fail "syntax doctor-signal-bead-promotion"
python3 -m py_compile "$PROBE" && pass "syntax orphaned-mcp-tool-call-probe" || fail "syntax orphaned-mcp-tool-call-probe"
"$PROBE" --schema | jq -e '.schema_version == "orphaned-mcp-tool-call-doctor/v1" and (.required | index("evidence_refs"))' >/dev/null \
  && pass "schema exposes evidence refs" || fail "schema exposes evidence refs"

cat >"$TMP/unresolved-after-cancel.jsonl" <<'JSONL'
{"jsonrpc":"2.0","id":"call-1","method":"tools/call","params":{"name":"shell"}}
{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":"call-1","reason":"user"}}
JSONL
"$PROBE" --doctor --json --log "$TMP/unresolved-after-cancel.jsonl" >"$TMP/unresolved.json" || true
assert_jq "$TMP/unresolved.json" '.status == "fail" and .orphaned_mcp_tool_call_count == 1 and .evidence_refs[0].runtime_cancel_notification_seen == true and .evidence_refs[0].original_tools_call_unresolved == true' "unresolved-after-cancel increments count with lifecycle fields"

cat >"$TMP/resolved-after-cancel.jsonl" <<'JSONL'
{"jsonrpc":"2.0","id":"call-2","method":"tools/call","params":{"name":"shell"}}
{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":"call-2","reason":"user"}}
{"jsonrpc":"2.0","id":"call-2","result":{"status":"cancelled"}}
JSONL
"$PROBE" --doctor --json --log "$TMP/resolved-after-cancel.jsonl" >"$TMP/resolved.json"
assert_jq "$TMP/resolved.json" '.status == "pass" and .orphaned_mcp_tool_call_count == 0 and .resolved_after_cancel_count == 1' "resolved-after-cancel does not increment"

cat >"$TMP/pane-capture-unavailable.jsonl" <<'JSONL'
{"event":"pane_capture_unavailable","pane":4,"reason":"capture_failed"}
JSONL
"$PROBE" --doctor --json --log "$TMP/pane-capture-unavailable.jsonl" >"$TMP/capture.json"
assert_jq "$TMP/capture.json" '.orphaned_mcp_tool_call_count == 0' "pane-capture-unavailable alone does not increment"

cat >"$TMP/agent-mail-fd-pressure.jsonl" <<'JSONL'
{"subsystem":"agent-mail","error":"Too many open files","agent_mail_fd_pressure":{"status":"error"}}
JSONL
"$PROBE" --doctor --json --log "$TMP/agent-mail-fd-pressure.jsonl" >"$TMP/fd.json"
assert_jq "$TMP/fd.json" '.orphaned_mcp_tool_call_count == 0' "Agent Mail FD pressure alone does not increment"

FLYWHEEL_MCP_TOOL_CALL_LOG="$TMP/unresolved-after-cancel.jsonl" \
FLYWHEEL_ORPHANED_MCP_TOOL_CALL_PROBE="$PROBE" \
FLYWHEEL_AGENT_MAIL_FD_PROBE=/no/such/probe \
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
FLYWHEEL_DOCTOR_CACHE_DISABLE=1 \
  "$LOOP" doctor --repo "$ROOT" --json >"$TMP/doctor.json" 2>"$TMP/doctor.err" || true
assert_jq "$TMP/doctor.json" '.orphaned_mcp_tool_call_count == 1 and .orphaned_mcp_tool_call_detail.source and .orphaned_mcp_tool_call_detail.checked_at and (.orphaned_mcp_tool_call_detail.evidence_refs | length) == 1' "flywheel-loop doctor exposes orphaned MCP tool-call detail"
assert_jq "$TMP/doctor.json" '(.pane_capture_unavailable_count // 0) == 0 and (.agent_mail_fd_pressure.max_fd_count // 0) == 0 and .orphaned_mcp_tool_call_count == 1' "orphaned signal remains separate from capture and Agent Mail FD signals"

scratch_parent="$ROOT/.flywheel/test-scratch"
mkdir -p "$scratch_parent"
repo="$(mktemp -d "$scratch_parent/orphaned-mcp-promotion.XXXXXX")"
(cd "$repo" && "$HOME/.cargo/bin/br" init --prefix flywheel --json >/dev/null)
jq -nc '{status:"fail",orphaned_mcp_tool_call_count:2,orphaned_mcp_tool_call_detail:{source:"fixture.jsonl",checked_at:"2026-05-08T00:00:00Z",evidence_refs:[{request_id:"call-1"}]}}' >"$TMP/doctor-promotion.json"
DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/doctor-promotion.json" \
BR_BIN="$HOME/.cargo/bin/br" \
  "$PROMOTE" --repo "$repo" --dry-run >"$TMP/promote.json"
assert_jq "$TMP/promote.json" '.symptoms.orphaned_mcp_tool_call.orphaned_mcp_tool_call_count == 2 and (.actions[] | contains("orphaned_mcp_tool_call") and contains("dry-run"))' "promotion route plans orphaned MCP repair bead"

if [ "$fail_count" -gt 0 ]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
