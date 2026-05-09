#!/usr/bin/env bash
# tests/loop_driver_doctor_json_parity_fixture.sh
#
# Behavior-parity fixture for ~/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py
# (582 lines, allow-large receipt cited at line 1).
#
# Bead: flywheel-n5wa5 (Phase 1 of flywheel-hzsro split-plan).
# Plan: .flywheel/audit/flywheel-hzsro/split-plan.md (File 1: 582 → 250 entry + 330 helper module).
#
# Phase-1 scope: capture the JSON output shape this script produces under a
# controlled fixture environment so the post-split version (loop_driver_doctor_json.py
# + loop_driver_doctor_lib.py with function-argument threading) can be verified
# against the same shape. Records pass/fail, not equivalence — exact bytes will
# differ across runs because timestamps and state vary; the shape contract is
# the parity invariant.
#
# Companion: split-plan File 1 caveat about module-scope side effects.
#
# Usage:
#   bash tests/loop_driver_doctor_json_parity_fixture.sh
#   bash tests/loop_driver_doctor_json_parity_fixture.sh --record-baseline   # write a fresh baseline
#   bash tests/loop_driver_doctor_json_parity_fixture.sh --check-shape       # default: shape-parity only

set -euo pipefail

SCRIPT_PATH="${LOOP_DRIVER_DOCTOR_JSON_PATH:-$HOME/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py}"
[[ -f "$SCRIPT_PATH" ]] || { echo "FAIL target script missing: $SCRIPT_PATH" >&2; exit 1; }

mode="check-shape"
case "${1:-}" in
  --record-baseline) mode="record-baseline";;
  --check-shape|"") mode="check-shape";;
  *) echo "usage: $0 [--record-baseline|--check-shape]" >&2; exit 2;;
esac

TMP="$(mktemp -d -t loop-driver-doctor-fixture.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

# Build a minimal fixture environment: synthetic repo, topology, loops dir,
# launch agents dir, log dir, drain receipt ledger.
mkdir -p "$TMP/repo/.flywheel" "$TMP/loops" "$TMP/launch-agents" "$TMP/logs" "$TMP/state"
synth_topology="$TMP/topology.jsonl"
synth_loops_dir="$TMP/loops"
synth_launch_agents="$TMP/launch-agents"
synth_log_dir="$TMP/logs"
synth_drain_ledger="$TMP/state/loop-driver-drain-receipts.jsonl"

# Empty topology line (script tolerates missing topology entries gracefully)
: >"$synth_topology"
# No drain receipts yet (script handles missing ledger gracefully)
: >"$synth_drain_ledger"

# A synthetic active loop marker for the fixture project name "repo"
cat >"$synth_loops_dir/repo.json" <<EOF
{
  "project": "repo",
  "state": "active",
  "tier": "doctor",
  "last_tick": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "expected_interval_seconds": 1800,
  "label": "ai.zeststream.flywheel-tick-repo"
}
EOF

# Synthetic dispatch log line so latest_dispatch_ts() has something to read
echo '{"event":"dispatch","ts":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","task_id":"fixture-1"}' >"$TMP/repo/.flywheel/dispatch-log.jsonl"

# Run the script under fixture env
out_file="$TMP/output.json"
err_file="$TMP/output.err"
set +e
FLYWHEEL_LOOP_MARKER_DIR="$synth_loops_dir" \
FLYWHEEL_LOOP_LAUNCH_AGENTS_DIR="$synth_launch_agents" \
FLYWHEEL_LOOP_LOG_DIR="$synth_log_dir" \
FLYWHEEL_LOOP_DRAIN_RECEIPT_LEDGER="$synth_drain_ledger" \
HOME="$TMP" \
python3 "$SCRIPT_PATH" "$TMP/repo" "$synth_topology" >"$out_file" 2>"$err_file"
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
  echo "FAIL script exited rc=$rc" >&2
  echo "--- stderr ---" >&2
  cat "$err_file" >&2
  exit 1
fi

# Validate shape-parity: every required top-level key must be present
required_keys=(
  active_marker
  dispatch_mode
  driver_status
  active_marker_project_label_loaded
  inactive_marker_post_stop_tick_count
  inactive_marker_post_stop_tick
  last_dispatch_ts
  plist_loaded
  plist_path
  tier
  expected_interval_seconds
  tick_script_exists
  tick_script_executable
  tick_script_contains_ntm_send
  recent_dispatch_sent
  recent_dispatch_ts
  drain_receipts
  pane_prompt_observed
  violations
  warnings
)

missing=()
for k in "${required_keys[@]}"; do
  if ! jq -e --arg k "$k" 'has($k)' <"$out_file" >/dev/null 2>&1; then
    missing+=("$k")
  fi
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "FAIL missing keys: ${missing[*]}" >&2
  echo "--- output ---" >&2
  jq . <"$out_file" >&2 || cat "$out_file" >&2
  exit 1
fi

# Validate nested shape
jq -e '.drain_receipts | has("ledger") and has("latest") and has("latest_state") and has("latest_ts") and has("missing_receipt") and has("stale_receipt")' <"$out_file" >/dev/null \
  || { echo "FAIL drain_receipts substructure" >&2; jq '.drain_receipts' <"$out_file" >&2; exit 1; }

jq -e '.violations | type == "array"' <"$out_file" >/dev/null \
  || { echo "FAIL violations not an array" >&2; exit 1; }

jq -e '.warnings | type == "array"' <"$out_file" >/dev/null \
  || { echo "FAIL warnings not an array" >&2; exit 1; }

# Optional baseline recording
if [[ "$mode" == "record-baseline" ]]; then
  baseline="$HOME/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.parity-baseline.json"
  cp "$out_file" "$baseline"
  echo "PASS shape-parity (20 top-level keys + drain_receipts substructure + array types)"
  echo "RECORDED baseline: $baseline"
  exit 0
fi

echo "PASS shape-parity (20 top-level keys + drain_receipts substructure + array types)"
echo "PASS rc=0 under fixture env (no crashes on synthetic loops/topology/ledger)"
echo "loop_driver_doctor_json shape-parity fixture passed"
