#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="flywheel.agent_lane_probe.v0"
JSON_OUT=0
RECEIPT_DIR=""

usage() {
  cat <<'EOF'
usage: scripts/agent-lane-probe.sh [--receipt-dir DIR] --json

Reports public agent-lane status for Claude, Codex, Gemini, and OpenClaw.
CLI presence is recorded, but support remains a compatibility target until a
lane-specific runtime receipt marks runtime_proven=true. A blocked receipt can
name why a lane remains a compatibility target, but it never permits supported
copy.
EOF
}

die_usage() {
  printf 'ERROR: %s\n' "$1" >&2
  usage >&2
  exit 64
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'ERROR: missing required agent-lane-probe command: %s\n' "$1" >&2
    exit 30
  }
}

runtime_receipt_valid() {
  local lane="$1" receipt="$2"
  [[ -n "$receipt" && -s "$receipt" ]] || return 1
  jq -e --arg lane "$lane" '
    def required_stage($name):
      [.journey_stages[]? | select(.name == $name)];
    def stage_pass($name):
      (required_stage($name) | length == 1)
      and (required_stage($name)[0].status == "pass");
    def no_private_findings:
      ((.private_state_scan.findings? // []) | length) == 0;
    .id == $lane
    and .schema_version == "flywheel.agent_lane_runtime_receipt.v0"
    and .runtime_proven == true
    and (.status == "pass" or .status == "runtime_proven")
    and (.generated_at | type == "string" and length > 0)
    and (.agent | type == "string" and length > 0)
    and (.command | type == "string" and contains("journey-smoke.sh"))
    and (.support_scope == "isolated")
    and (.private_state_scan.status == "pass")
    and no_private_findings
    and stage_pass("preflight")
    and stage_pass("init")
    and stage_pass("doctor")
    and stage_pass("tick")
    and stage_pass("dispatch_or_simulate")
    and stage_pass("closeout")
    and stage_pass("inspect_next_action")
  ' "$receipt" >/dev/null 2>&1
}

blocker_receipt_json() {
  local lane="$1" receipt="$2"
  [[ -n "$receipt" && -s "$receipt" ]] || return 0
  jq -c --arg lane "$lane" '
    if (
      .id == $lane
      and .schema_version == "flywheel.agent_lane_blocker_receipt.v0"
      and .status == "blocked"
      and .runtime_proven == false
      and .support_copy_allowed == false
      and .support_scope == "blocked"
      and (.generated_at | type == "string" and length > 0)
      and (.agent | type == "string" and length > 0)
      and (.command | type == "string" and contains("agent-lane-probe.sh"))
      and (.blocker_class | IN(
        "auth_required",
        "adapter_config_required",
        "install_required",
        "daemon_unavailable",
        "public_release_pending",
        "isolated_runtime_receipt_missing"
      ))
      and (.blocker_reason | type == "string" and length > 0)
      and (.next_action | type == "string" and length > 0)
      and (.private_state_scan.status | IN("not_run", "blocked"))
    ) then {
      schema_version,
      status,
      blocker_class,
      blocker_reason,
      next_action,
      generated_at
    } else empty end
  ' "$receipt" 2>/dev/null || true
}

lane_json() {
  local id="$1" display="$2" command_name="$3" receipt="" cli_present="false" runtime_proven="false"
  local blocked_by_receipt="false" blocker_json="null"
  local evidence="registry_valid"
  if command -v "$command_name" >/dev/null 2>&1; then
    cli_present="true"
    evidence="cli_presence_only"
  fi
  if [[ -n "$RECEIPT_DIR" ]]; then
    receipt="$RECEIPT_DIR/$id.json"
  fi
  if runtime_receipt_valid "$id" "$receipt"; then
    runtime_proven="true"
    evidence="runtime_receipt"
  else
    blocker_json="$(blocker_receipt_json "$id" "$receipt")"
    if [[ -n "$blocker_json" ]]; then
      blocked_by_receipt="true"
      evidence="blocker_receipt"
    else
      blocker_json="null"
    fi
  fi

  jq -nc \
    --arg id "$id" \
    --arg display "$display" \
    --arg command_name "$command_name" \
    --argjson cli_present "$cli_present" \
    --argjson runtime_proven "$runtime_proven" \
    --argjson blocked_by_receipt "$blocked_by_receipt" \
    --arg evidence "$evidence" \
    --arg receipt "$receipt" \
    --argjson blocker "$blocker_json" \
    '{
      id:$id,
      display_name:$display,
      command:$command_name,
      cli_present:$cli_present,
      registry_valid:true,
      runtime_proven:$runtime_proven,
      public_status:(if $runtime_proven then "runtime-proven" else "compatibility-target" end),
      support_copy_allowed:$runtime_proven,
      evidence:$evidence,
      blocked_by_receipt:$blocked_by_receipt,
      blocker:$blocker,
      receipt:(if $receipt == "" then null else $receipt end),
      note:(if $runtime_proven
        then "runtime receipt permits supported copy"
        elif $blocked_by_receipt
        then $blocker.blocker_reason
        else "CLI presence is not runtime proof; keep public copy at compatibility-target"
      end)
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --receipt-dir) [[ $# -ge 2 ]] || die_usage "--receipt-dir requires a directory"; RECEIPT_DIR="$2"; shift 2 ;;
    --receipt-dir=*) RECEIPT_DIR="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

[[ "$JSON_OUT" -eq 1 ]] || die_usage "--json is required"
need jq

rows="$(
  {
    lane_json claude "Claude Code" claude
    lane_json codex "Codex CLI" codex
    lane_json gemini "Gemini CLI" gemini
    lane_json openclaw "OpenClaw" openclaw
  } | jq -s '.'
)"

status="pass"
if ! jq -e 'all(.[]; .registry_valid == true and (.support_copy_allowed == .runtime_proven))' <<<"$rows" >/dev/null; then
  status="fail"
fi

jq -nc --arg sv "$SCHEMA_VERSION" --arg status "$status" --argjson rows "$rows" '{
  schema_version:$sv,
  command:"agent-lane-probe",
  status:$status,
  rows:$rows,
  summary:{
    lanes:($rows | length),
    cli_present:($rows | map(select(.cli_present == true)) | length),
    runtime_proven:($rows | map(select(.runtime_proven == true)) | length),
    blocked_receipts:($rows | map(select(.blocked_by_receipt == true)) | length),
    compatibility_targets:($rows | map(select(.public_status == "compatibility-target")) | length)
  }
}'

[[ "$status" == "pass" ]]
