#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-fleet-health.sh"
LIB="$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-fleet-health-role-split.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  list)
    jq -nc '{sessions:[{name:"fixture"}]}'
    ;;
  health)
    jq -nc '{
      status:"error",
      panes:[
        {pane:0,status:"error",process_status:"exited",agent_type:"user",activity:"active"},
        {pane:1,status:"ok",process_status:"running",agent_type:"cc",activity:"active"},
        {pane:2,status:"ok",process_status:"running",agent_type:"cod",activity:"idle"}
      ]
    }'
    ;;
  *)
    printf 'unsupported fake ntm args: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/ntm"

jq -nc '{
  session:"fixture",
  effective_at:"2026-05-05T00:00:00Z",
  human_pane:0,
  orchestrator_pane:1,
  callback_pane:1,
  worker_panes:[2],
  worker_kinds:{"2":"codex"}
}' >"$TMP/topology.jsonl"

state="$TMP/health.jsonl"
lock="$TMP/health.lock"

env \
  FLYWHEEL_JSONL_APPEND_LIB="$LIB" \
  NTM_FLEET_HEALTH_OUT="$state" \
  NTM_FLEET_HEALTH_LOCK="$lock" \
  "$SCRIPT" \
    --ntm-bin "$TMP/ntm" \
    --topology-file "$TMP/topology.jsonl" \
    --json >"$TMP/out.json" 2>"$TMP/err.txt"

if jq -e '
  .ledger_row.health.status == "error"
  and .ledger_row.agent_pane_health.status == "ok"
  and .ledger_row.agent_pane_health.total == 2
  and .ledger_row.agent_pane_health.unhealthy_count == 0
  and .ledger_row.user_pane_health.status == "error"
  and .ledger_row.user_pane_health.total == 1
  and .ledger_row.user_pane_health.unhealthy_count == 1
  and (.ledger_row.user_pane_health.panes[0].role_source == "topology.human_pane")
' "$TMP/out.json" >/dev/null; then
  pass "overall_error_split_into_agent_ok_user_error"
else
  fail "overall_error_split_into_agent_ok_user_error"
  cat "$TMP/out.json" "$TMP/err.txt" >&2 || true
fi

if jq -e '
  .health.status == "error"
  and .agent_pane_health.status == "ok"
  and .user_pane_health.status == "error"
  and .health_role_split.schema_version == "ntm-health-role-split/v1"
' "$state" >/dev/null; then
  pass "jsonl_row_carries_split_fields"
else
  fail "jsonl_row_carries_split_fields"
  cat "$state" >&2 || true
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "2" && "$fail_count" == "0" ]]
