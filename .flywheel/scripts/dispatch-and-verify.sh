#!/usr/bin/env bash
# dispatch-and-verify — send a dispatch file to an ntm pane and verify the
# worker actually started thinking (vs. landing in codex's chevron buffer
# without submitting).
#
# Trauma class: codex-chevron-stuck-on-dispatch
# Source finding: mobile-eats/.flywheel/findings/2026-05-06-codex-chevron-stuck-on-dispatch.md
# Promoted to canonical: flywheel:1 verdict 2026-05-06
# Prior path (deprecated): ~/.local/bin/dispatch-and-verify
#
# Usage:
#   dispatch-and-verify.sh [--probe-mode=permissive|strict] <session> <pane> <dispatch-file-path>
#
# Behavior:
#   1. Validates the dispatch file exists.
#   2. Sends the canonical "Read <file> and execute it..." prompt via ntm send.
#   3. Captures post-send baselines, then probes pane state via ntm activity,
#      pane content, and ntm changes.
#   4. Waits 30s + 15s + 15s by default. Empty Enter is fired only after two
#      consecutive STUCK reads.
#   5. Exits 0 on confirmed work evidence; exits 1 with diagnostics if stuck.
#
# Cross-orch coordination ledger: ~/.local/state/flywheel/cross-orch-coordination.jsonl

set -euo pipefail

NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
PROBE_MODE="${DISPATCH_VERIFY_PROBE_MODE:-permissive}"
INITIAL_SLEEP_SECONDS="${DISPATCH_VERIFY_INITIAL_SLEEP_SECONDS:-30}"
RETRY_SLEEP_SECONDS="${DISPATCH_VERIFY_RETRY_SLEEP_SECONDS:-15}"
MAX_PROBES="${DISPATCH_VERIFY_MAX_PROBES:-3}"
SNAPSHOT_LINES="${DISPATCH_VERIFY_SNAPSHOT_LINES:-120}"

print_usage() {
  cat <<'EOF'
usage: dispatch-and-verify [--probe-mode=permissive|strict] <session> <pane> <dispatch-file-path>
       dispatch-and-verify --info [--json]
       dispatch-and-verify --examples [--json]
       dispatch-and-verify --schema

Verifies that an ntm dispatch was actually submitted and the target pane started
work, rather than only accepting text into an input buffer.

Options:
  --probe-mode permissive|strict  Choose pane-start evidence threshold.
  --json                          Emit JSON for supported introspection modes.
  --info                          Print runtime configuration.
  --examples                      Print copy-paste workflows.
  --schema                        Print machine-readable contract.
  -h, --help                      Print this help.

Exit codes:
  0  work-start evidence observed, or introspection succeeded
  1  pane stayed stuck after the probe window
  2  usage/configuration error
EOF
}

usage_error() {
  print_usage >&2
  exit 2
}

info() {
  if [[ "${JSON_OUT:-false}" == "true" ]]; then
    jq -nc --arg ntm "$NTM_BIN" \
      --arg probe_mode "$PROBE_MODE" \
      --arg initial "$INITIAL_SLEEP_SECONDS" \
      --arg retry "$RETRY_SLEEP_SECONDS" \
      --arg max "$MAX_PROBES" \
      '{command:"info",name:"dispatch-and-verify",schema_version:"dispatch-and-verify.info.v1",ntm_bin:$ntm,probe_mode_default:$probe_mode,probe_windows:{initial_sleep_seconds:($initial|tonumber),retry_sleep_seconds:($retry|tonumber),max_probes:($max|tonumber)},mutation:"ntm_send_only",canonical_cli_scoping:["help","info","examples","schema","stable_exit_codes"]}'
  else
    printf 'dispatch-and-verify\n'
    printf '  ntm_bin: %s\n' "$NTM_BIN"
    printf '  probe_mode_default: %s\n' "$PROBE_MODE"
    printf '  probe_windows: initial=%ss retry=%ss max=%s\n' "$INITIAL_SLEEP_SECONDS" "$RETRY_SLEEP_SECONDS" "$MAX_PROBES"
  fi
}

examples() {
  if [[ "${JSON_OUT:-false}" == "true" ]]; then
    jq -nc '{command:"examples",schema_version:"dispatch-and-verify.examples.v1",examples:[{name:"permissive_dispatch",command:".flywheel/scripts/dispatch-and-verify.sh --probe-mode=permissive flywheel 2 /tmp/dispatch_flywheel-abc.md"},{name:"strict_dispatch",command:".flywheel/scripts/dispatch-and-verify.sh --probe-mode=strict flywheel 2 /tmp/dispatch_flywheel-abc.md"},{name:"short_test_window",command:"DISPATCH_VERIFY_INITIAL_SLEEP_SECONDS=0 DISPATCH_VERIFY_RETRY_SLEEP_SECONDS=0 DISPATCH_VERIFY_MAX_PROBES=1 .flywheel/scripts/dispatch-and-verify.sh flywheel 2 /tmp/dispatch_flywheel-abc.md"}]}'
  else
    cat <<'EOF'
EXAMPLES:
  .flywheel/scripts/dispatch-and-verify.sh --probe-mode=permissive flywheel 2 /tmp/dispatch_flywheel-abc.md
  .flywheel/scripts/dispatch-and-verify.sh --probe-mode=strict flywheel 2 /tmp/dispatch_flywheel-abc.md
  DISPATCH_VERIFY_INITIAL_SLEEP_SECONDS=0 DISPATCH_VERIFY_RETRY_SLEEP_SECONDS=0 DISPATCH_VERIFY_MAX_PROBES=1 .flywheel/scripts/dispatch-and-verify.sh flywheel 2 /tmp/dispatch_flywheel-abc.md
EOF
  fi
}

schema() {
  jq -nc '{schema_version:"dispatch-and-verify.schema.v1",command:"schema",exit_codes:{"0":"work-start evidence observed or introspection succeeded","1":"pane stayed stuck after probe window","2":"usage/configuration error"},json_surfaces:["--info --json","--examples --json","--schema"],probe_modes:["permissive","strict"],env_vars:["NTM_BIN","DISPATCH_VERIFY_PROBE_MODE","DISPATCH_VERIFY_INITIAL_SLEEP_SECONDS","DISPATCH_VERIFY_RETRY_SLEEP_SECONDS","DISPATCH_VERIFY_MAX_PROBES","DISPATCH_VERIFY_SNAPSHOT_LINES"]}'
}

ARGS=()
JSON_OUT=false
INTROSPECTION_MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_OUT=true
      shift
      ;;
    --info)
      INTROSPECTION_MODE="info"
      shift
      ;;
    --examples)
      INTROSPECTION_MODE="examples"
      shift
      ;;
    --schema|schema)
      INTROSPECTION_MODE="schema"
      shift
      ;;
    --probe-mode=*)
      PROBE_MODE="${1#--probe-mode=}"
      shift
      ;;
    --probe-mode)
      [[ $# -ge 2 ]] || usage_error
      PROBE_MODE="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

case "$INTROSPECTION_MODE" in
  info) info; exit 0 ;;
  examples) examples; exit 0 ;;
  schema) schema; exit 0 ;;
esac

[[ "${#ARGS[@]}" -eq 3 ]] || usage_error
[[ "$PROBE_MODE" == "permissive" || "$PROBE_MODE" == "strict" ]] || {
  echo "dispatch-and-verify: invalid --probe-mode: $PROBE_MODE" >&2
  exit 2
}

SESSION="${ARGS[0]}"
PANE="${ARGS[1]}"
DISPATCH_FILE="${ARGS[2]}"

if [[ ! -f "$DISPATCH_FILE" ]]; then
  echo "dispatch-and-verify: dispatch file not found: $DISPATCH_FILE" >&2
  exit 2
fi

PROMPT="Read ${DISPATCH_FILE} and execute it..."

ntm_changes_snapshot() {
  "$NTM_BIN" changes "$SESSION" --json 2>/dev/null || printf 'null\n'
}

ntm_conflicts_snapshot() {
  "$NTM_BIN" conflicts "$SESSION" --json --limit 50 2>/dev/null || printf 'null\n'
}

changes_count() {
  jq -r '(.changed_count // .count // (.changes // [] | length) // 0)' 2>/dev/null || printf '0\n'
}

json_hash() {
  shasum -a 256 | awk '{print $1}'
}

pane_snapshot() {
  local text
  text="$("$NTM_BIN" copy "${SESSION}:${PANE}" -l "$SNAPSHOT_LINES" 2>/dev/null || true)"
  if [[ -z "$text" ]]; then
    jq -nc '{ok:false,hash:"",lines:0,bytes:0}'
    return
  fi
  SNAPSHOT_TEXT="$text" python3 -c '
import hashlib, json, os
text = os.environ.get("SNAPSHOT_TEXT", "")
print(json.dumps({
    "ok": True,
    "hash": hashlib.sha256(text.encode()).hexdigest(),
    "lines": len(text.splitlines()),
    "bytes": len(text.encode()),
}, separators=(",", ":")))
'
}

# probe_pane echoes: CLASSIFICATION reason=<reason> state=<state> velocity=<n> content_delta=<bool> changes_delta=<bool>
probe_pane() {
  local activity_json snapshot_json changes_json changes_count_now changes_hash_now
  activity_json="$("$NTM_BIN" --robot-activity="$SESSION" --panes="$PANE" 2>/dev/null || true)"
  if [[ -z "$activity_json" ]]; then
    echo "UNKNOWN reason=activity_unavailable state=UNKNOWN velocity=0 content_delta=false changes_delta=false"
    return
  fi
  snapshot_json="$(pane_snapshot)"
  changes_json="$(ntm_changes_snapshot)"
  changes_count_now="$(printf '%s\n' "$changes_json" | changes_count)"
  changes_hash_now="$(printf '%s\n' "$changes_json" | json_hash)"

  ACTIVITY_JSON="$activity_json" \
  SNAPSHOT_JSON="$snapshot_json" \
  BASELINE_SNAPSHOT_JSON="$BASELINE_SNAPSHOT_JSON" \
  PROBE_MODE="$PROBE_MODE" \
  PRE_CHANGES_COUNT="$PRE_CHANGES_COUNT" \
  CHANGES_COUNT_NOW="$changes_count_now" \
  PRE_CHANGES_HASH="$PRE_CHANGES_HASH" \
  CHANGES_HASH_NOW="$changes_hash_now" \
  python3 -c '
import json, os, sys
pane = sys.argv[1]
data = json.loads(os.environ.get("ACTIVITY_JSON", "") or "{}")
snapshot = json.loads(os.environ.get("SNAPSHOT_JSON", "{}") or "{}")
baseline = json.loads(os.environ.get("BASELINE_SNAPSHOT_JSON", "{}") or "{}")
mode = os.environ.get("PROBE_MODE", "permissive")
pre_count = int(os.environ.get("PRE_CHANGES_COUNT", "0") or 0)
now_count = int(os.environ.get("CHANGES_COUNT_NOW", "0") or 0)
pre_hash = os.environ.get("PRE_CHANGES_HASH", "")
now_hash = os.environ.get("CHANGES_HASH_NOW", "")

def velocity(agent):
    for key in ("velocity", "chars_per_second", "bytes_per_second"):
        try:
            value = float(agent.get(key, 0) or 0)
        except (TypeError, ValueError):
            value = 0
        if value > 0:
            return value
    return 0

def emit(classification, reason, state="UNKNOWN", vel=0, content_delta=False, changes_delta=False):
    print(
        f"{classification} reason={reason} state={state} velocity={vel:g} "
        f"content_delta={str(content_delta).lower()} changes_delta={str(changes_delta).lower()}"
    )

content_delta = bool(
    snapshot.get("ok")
    and baseline.get("ok")
    and snapshot.get("hash")
    and baseline.get("hash")
    and snapshot.get("hash") != baseline.get("hash")
)
changes_delta = (now_count > pre_count) or (bool(pre_hash and now_hash) and now_hash != pre_hash)

for a in data.get("agents", []):
    pane_id = a.get("pane", a.get("pane_idx", ""))
    if str(pane_id) == str(pane):
        state = str(a.get("state", "UNKNOWN") or "UNKNOWN").upper()
        vel = velocity(a)
        working = state in {"THINKING", "GENERATING", "WORKING", "RUNNING", "STALLED"}
        if working and vel > 0:
            emit("THINKING_LIVE", "velocity_positive", state, vel, content_delta, changes_delta); sys.exit(0)
        if working and changes_delta:
            emit("THINKING_LIVE", "ntm_changes_delta", state, vel, content_delta, changes_delta); sys.exit(0)
        if mode == "permissive" and working and content_delta:
            emit("THINKING_LIVE", "pane_content_delta", state, vel, content_delta, changes_delta); sys.exit(0)
        if mode == "permissive" and working:
            # Codex slow-start in working state without live signal. See doctrine.
            emit("THINKING_LIVE", "working_state_quiet", state, vel, content_delta, changes_delta); sys.exit(0)
        if working:
            emit("STUCK", "working_state_without_live_signal", state, vel, content_delta, changes_delta); sys.exit(0)
        if mode == "permissive" and state in {"WAITING", "IDLE", "UNKNOWN"} and (content_delta or changes_delta):
            # Codex booting: state still WAITING/IDLE/UNKNOWN but pane delta visible.
            emit("THINKING_LIVE", "settling_with_delta", state, vel, content_delta, changes_delta); sys.exit(0)
        if state in {"WAITING", "IDLE", "UNKNOWN"}:
            emit("STUCK", f"state_{state.lower()}", state, vel, content_delta, changes_delta); sys.exit(0)
        emit("UNKNOWN", f"state_{state.lower()}", state, vel, content_delta, changes_delta); sys.exit(0)
emit("UNKNOWN", "pane_not_found", "UNKNOWN", 0, content_delta, changes_delta)
' "$PANE"
}

# Initial dispatch. printf 'y\n' answers any interactive confirm ntm may emit.
echo "[dispatch-and-verify] sending dispatch to ${SESSION}:${PANE} -> ${DISPATCH_FILE} (probe_mode=${PROBE_MODE})"
echo "[dispatch-and-verify] ntm conflicts pre-dispatch: $(ntm_conflicts_snapshot | jq -c '{status:(.status // .overall // "unknown"), conflict_count:(.conflict_count // .count // (.conflicts // [] | length) // 0)}' 2>/dev/null || printf 'null')"
PRE_CHANGES_JSON="$(ntm_changes_snapshot)"
PRE_CHANGES_COUNT="$(printf '%s\n' "$PRE_CHANGES_JSON" | changes_count)"
PRE_CHANGES_HASH="$(printf '%s\n' "$PRE_CHANGES_JSON" | json_hash)"
printf 'y\n' | "$NTM_BIN" send "$SESSION" --pane "$PANE" "$PROMPT" >/dev/null
BASELINE_SNAPSHOT_JSON="$(pane_snapshot)"

sleep "$INITIAL_SLEEP_SECONDS"

stuck_reads=0
for attempt in $(seq 1 "$MAX_PROBES"); do
  probe="$(probe_pane)"
  state="${probe%% *}"
  echo "[dispatch-and-verify] attempt ${attempt} state=${state} ${probe#* }"
  if [[ "$state" == "THINKING_LIVE" ]]; then
    echo "[dispatch-and-verify] ntm changes post-dispatch: $(ntm_changes_snapshot | jq -c '{status:(.status // "ok"), changed_count:(.changed_count // .count // (.changes // [] | length) // 0)}' 2>/dev/null || printf 'null')"
    echo "[dispatch-and-verify] OK — worker is thinking."
    exit 0
  fi
  if [[ "$state" == "STUCK" ]]; then
    stuck_reads=$((stuck_reads + 1))
  else
    stuck_reads=0
  fi
  if [[ "$stuck_reads" -ge 2 && "$attempt" -lt "$MAX_PROBES" ]]; then
    echo "[dispatch-and-verify] pane has ${stuck_reads} consecutive STUCK reads; firing empty Enter."
    printf 'y\n' | "$NTM_BIN" send "$SESSION" --pane "$PANE" "" >/dev/null || true
  else
    echo "[dispatch-and-verify] waiting for hysteresis window before retry."
  fi
  [[ "$attempt" -lt "$MAX_PROBES" ]] && sleep "$RETRY_SLEEP_SECONDS"
done

echo "[dispatch-and-verify] FAIL — pane ${SESSION}:${PANE} still stuck after ${MAX_PROBES} probes." >&2
echo "[dispatch-and-verify] diagnostic dump:" >&2
"$NTM_BIN" --robot-activity="$SESSION" --panes="$PANE" >&2 || true
echo "[dispatch-and-verify] pane content failure snapshot: $(pane_snapshot | jq -c . 2>/dev/null || printf 'null')" >&2
echo "[dispatch-and-verify] ntm changes failure snapshot: $(ntm_changes_snapshot | jq -c . 2>/dev/null || printf 'null')" >&2
echo "[dispatch-and-verify] ntm conflicts failure snapshot: $(ntm_conflicts_snapshot | jq -c . 2>/dev/null || printf 'null')" >&2
echo "[dispatch-and-verify] consider: $NTM_BIN respawn ${SESSION} --panes=${PANE} --force" >&2
exit 1

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
