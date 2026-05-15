#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-fleet-health.sh"
LIB="$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-fleet-health-topology.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  list)
    jq -nc '{sessions:[{name:"fixture"}]}'
    ;;
  health)
    jq -nc '{status:"ok",panes:[{pane:1,status:"ok",agent_type:"cc"},{pane:2,status:"ok",agent_type:"codex"}]}'
    ;;
  *)
    printf 'unsupported fake ntm args: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/ntm"

seed_previous_count() {
  local out="$1" count="$2"
  jq -nc --argjson count "$count" \
    '{ts:"2026-05-01T00:00:00Z",session:"fixture",topology_observer:{schema_version:"ntm-fleet-health.topology-observer/v1",status:"ok",row_count:$count,previous_row_count:null,row_count_decreased:false,regression:false}}' >"$out"
}

write_topology() {
  local file="$1" mode="$2"
  case "$mode" in
    unconfirmed)
      jq -nc '{session:"fixture",effective_at:"2026-05-02T00:00:00Z",orchestrator_pane:1,worker_panes:[2]}' >"$file"
      ;;
    confirmed)
      jq -nc '{session:"fixture",effective_at:"2026-05-02T00:00:00Z",orchestrator_pane:1,worker_panes:[2],joshua_confirmed_at:"2026-05-02T00:01:00Z",confirmed_via:"operator_ack_rebuild"}' >"$file"
      ;;
    walk)
      jq -nc '{session:"fixture",effective_at:"2026-05-02T00:00:00Z",orchestrator_pane:1,worker_panes:[2],walk_in_progress:true}' >"$file"
      ;;
    *)
      printf 'unknown topology mode %s\n' "$mode" >&2
      return 2
      ;;
  esac
}

run_case() {
  local name="$1" mode="$2"
  local topology="$TMP/$name-topology.jsonl" out_file="$TMP/$name-health.jsonl" lock="$TMP/$name.lock"
  write_topology "$topology" "$mode"
  seed_previous_count "$out_file" 3
  env \
    FLYWHEEL_JSONL_APPEND_LIB="$LIB" \
    NTM_FLEET_HEALTH_OUT="$out_file" \
    NTM_FLEET_HEALTH_LOCK="$lock" \
    "$SCRIPT" \
      --ntm-bin "$TMP/ntm" \
      --topology-file "$topology" \
      --json >"$TMP/$name.json"
}

if bash -n "$SCRIPT"; then pass "script syntax"; else fail "script syntax"; fi

run_case unconfirmed unconfirmed
assert_jq "$TMP/unconfirmed.json" \
  '.ledger_row.topology_observer.status == "regression"
   and .ledger_row.topology_observer.row_count == 1
   and .ledger_row.topology_observer.previous_row_count == 3
   and .ledger_row.topology_observer.row_count_decreased == true
   and .ledger_row.topology_observer.regression == true' \
  "unconfirmed row-count decrease is a regression"

run_case confirmed confirmed
assert_jq "$TMP/confirmed.json" \
  '.ledger_row.topology_observer.status == "confirmed_rebuild"
   and .ledger_row.topology_observer.row_count_decreased == true
   and .ledger_row.topology_observer.regression == false
   and .ledger_row.topology_observer.confirmed_rebuild == true
   and .ledger_row.topology_observer.confirmed_via_present == true
   and .ledger_row.topology_observer.joshua_confirmed_rows == 1' \
  "Joshua-confirmed rebuild suppresses regression"

run_case walk walk
assert_jq "$TMP/walk.json" \
  '.ledger_row.topology_observer.status == "walk_in_progress"
   and .ledger_row.topology_observer.row_count_decreased == true
   and .ledger_row.topology_observer.regression == false
   and .ledger_row.topology_observer.walk_in_progress == true
   and .ledger_row.topology_observer.walk_in_progress_rows == 1' \
  "walk-in-progress suppresses regression"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL ntm-fleet-health-topology-regression tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS ntm-fleet-health-topology-regression tests pass=%s fail=0\n' "$pass_count"
