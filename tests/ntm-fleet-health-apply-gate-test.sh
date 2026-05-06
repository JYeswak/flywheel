#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-fleet-health.sh"
LIB="$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-fleet-health-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

make_fake_ntm() {
  cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
mode="${FAKE_NTM_MODE:?}"
log="${FAKE_NTM_LOG:?}"
printf '%s\n' "$*" >>"$log"

case "${1:-}" in
  list)
    case "$mode" in
      fail-list)
        printf 'list boom\n' >&2
        exit 7
        ;;
      empty-list)
        jq -nc '{sessions:[]}'
        ;;
      *)
        jq -nc '{sessions:[{name:"alpha"}]}'
        ;;
    esac
    ;;
  health)
    jq -nc '{success:true,stuck_panes:[{pane:2,stuck:true,reason:"fixture"}]}'
    ;;
  *)
    printf 'unsupported fake ntm args: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
  chmod +x "$TMP/ntm"
}

run_health() {
  local name="$1" mode="$2"
  shift 2
  local out="$TMP/$name.json" err="$TMP/$name.err" log="$TMP/$name.ntm.log"
  local state="$TMP/$name-health.jsonl" lock="$TMP/$name.lock"
  local -a env_args=(
    "FAKE_NTM_MODE=$mode"
    "FAKE_NTM_LOG=$log"
    "FLYWHEEL_JSONL_APPEND_LIB=$LIB"
    "NTM_FLEET_HEALTH_OUT=$state"
    "NTM_FLEET_HEALTH_LOCK=$lock"
  )
  if [[ -n "${NTM_FLEET_HEALTH_FORCE_EMPTY_ROW:-}" ]]; then
    env_args+=("NTM_FLEET_HEALTH_FORCE_EMPTY_ROW=$NTM_FLEET_HEALTH_FORCE_EMPTY_ROW")
  fi
  env "${env_args[@]}" "$SCRIPT" \
    --ntm-bin "$TMP/ntm" \
    --topology-file "$TMP/missing-topology.jsonl" \
    "$@" >"$out" 2>"$err"
}

make_fake_ntm

run_health preview normal --auto-restart-stuck --json
if jq -e '.auto_restart.action == "would_restart" and .auto_restart.apply == false and .auto_restart.pane == 2' "$TMP/preview.json" >/dev/null \
  && ! grep -q -- '--auto-restart-stuck' "$TMP/preview.ntm.log" \
  && grep -q '^health alpha --json --threshold ' "$TMP/preview.ntm.log"; then
  pass "auto_restart_preview_does_not_call_mutating_health"
else
  fail "auto_restart_preview_does_not_call_mutating_health"
  cat "$TMP/preview.json" "$TMP/preview.err" "$TMP/preview.ntm.log" >&2 || true
fi

run_health apply normal --auto-restart-stuck --apply --json
if jq -e '.auto_restart.action == "restart_invoked" and .auto_restart.apply == true' "$TMP/apply.json" >/dev/null \
  && grep -q -- '--auto-restart-stuck' "$TMP/apply.ntm.log"; then
  pass "apply_calls_mutating_health_flag"
else
  fail "apply_calls_mutating_health_flag"
  cat "$TMP/apply.json" "$TMP/apply.err" "$TMP/apply.ntm.log" >&2 || true
fi

run_health discovery-failed fail-list --auto-restart-stuck --json
run_health no-sessions empty-list --auto-restart-stuck --json
run_health health normal --auto-restart-stuck --json
if jq -e 'select(.event == "session_discovery_failed" and .list.exit_code == 7)' "$TMP/discovery-failed-health.jsonl" >/dev/null \
  && jq -e 'select(.event == "no_sessions_discovered")' "$TMP/no-sessions-health.jsonl" >/dev/null \
  && jq -e 'select(.session == "alpha" and .health.success == true and .threshold == "10m")' "$TMP/health-health.jsonl" >/dev/null; then
  pass "all_jsonl_append_sites_write_valid_objects"
else
  fail "all_jsonl_append_sites_write_valid_objects"
  cat "$TMP/discovery-failed-health.jsonl" "$TMP/no-sessions-health.jsonl" "$TMP/health-health.jsonl" >&2 || true
fi

NTM_FLEET_HEALTH_FORCE_EMPTY_ROW=1 run_health empty-row normal --auto-restart-stuck --json
if [[ ! -s "$TMP/empty-row-health.jsonl" ]] \
  && grep -q 'failed to append health row' "$TMP/empty-row.err"; then
  pass "empty_jsonl_row_rejected_without_crash"
else
  fail "empty_jsonl_row_rejected_without_crash"
  cat "$TMP/empty-row.json" "$TMP/empty-row.err" "$TMP/empty-row-health.jsonl" >&2 || true
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 4 && "$fail_count" -eq 0 ]]
