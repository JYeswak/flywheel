#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="flywheel.journey_smoke.v0"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
MATRIX="claude,codex,openclaw,gemini,reduced"
DRY_RUN=0
JSON_OUT=0

usage() {
  cat <<'EOF'
usage: scripts/journey-smoke.sh --matrix claude,codex,openclaw,gemini,reduced --dry-run --json

Runs the public first-run journey matrix. Dry-run mode records registry-valid
harness rows and proves the reduced local lane through init, doctor, tick,
dispatch-or-simulate, closeout validation, and inspection.
EOF
}

die_usage() {
  printf 'ERROR: %s\n' "$1" >&2
  usage >&2
  exit 64
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'ERROR: missing required journey-smoke command: %s\n' "$1" >&2
    exit 30
  }
}

lane_registry_row() {
  local lane="$1"
  case "$lane" in
    claude) printf '%s\t%s\t%s\t%s\n' "$lane" "supported-first" "Claude Code" "requires runtime journey proof before public support claim" ;;
    codex) printf '%s\t%s\t%s\t%s\n' "$lane" "supported-first" "Codex CLI" "requires runtime journey proof before public support claim" ;;
    openclaw) printf '%s\t%s\t%s\t%s\n' "$lane" "compatibility-target" "OpenClaw" "compatibility target until daemon or gateway smoke is runtime-proven" ;;
    gemini) printf '%s\t%s\t%s\t%s\n' "$lane" "compatibility-target" "Gemini CLI" "compatibility target until journey smoke is runtime-proven" ;;
    reduced) printf '%s\t%s\t%s\t%s\n' "$lane" "required-fallback" "Reduced local mode" "runtime-proven fallback path without private fleet substrate" ;;
    *) return 1 ;;
  esac
}

json_string_array() {
  jq -Rsc 'split("\n")[:-1]'
}

run_json_capture() {
  local out="$1"
  shift
  set +e
  "$@" >"$out"
  RUN_JSON_CAPTURE_RC=$?
  set -e
  return 0
}

reduced_lane_json() {
  local tmp repo preflight init doctor tick dispatch closeout inspect
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-journey-smoke.XXXXXX")"
  repo="$tmp/repo"
  mkdir -p "$repo"
  git -C "$repo" init -q

  preflight="$tmp/preflight.json"
  init="$tmp/init.json"
  doctor="$tmp/doctor.json"
  tick="$tmp/tick.json"
  dispatch="$tmp/dispatch.json"
  closeout="$tmp/closeout.json"
  inspect="$tmp/inspect.json"

  set +e
  run_json_capture "$preflight" "$ROOT/scripts/preflight.sh" --fixture "$ROOT/fixtures/preflight/partial.json" --json
  local preflight_rc=$RUN_JSON_CAPTURE_RC
  run_json_capture "$init" "$ROOT/bin/flywheel" init --repo "$repo" --json
  local init_rc=$RUN_JSON_CAPTURE_RC
  run_json_capture "$doctor" "$ROOT/bin/flywheel" doctor --repo "$repo" --json
  local doctor_rc=$RUN_JSON_CAPTURE_RC
  run_json_capture "$tick" "$ROOT/bin/flywheel" tick --repo "$repo" --dry-run --json
  local tick_rc=$RUN_JSON_CAPTURE_RC
  run_json_capture "$dispatch" "$ROOT/bin/flywheel" dispatch --repo "$repo" --simulate --json
  local dispatch_rc=$RUN_JSON_CAPTURE_RC
  run_json_capture "$closeout" "$ROOT/bin/flywheel" validate-receipt --repo "$repo" --file .flywheel/last_closeout_receipt.json --json
  local closeout_rc=$RUN_JSON_CAPTURE_RC
  run_json_capture "$inspect" "$ROOT/bin/flywheel" inspect --repo "$repo" --json
  local inspect_rc=$RUN_JSON_CAPTURE_RC
  set -e

  local status="pass"
  for rc in "$preflight_rc" "$init_rc" "$doctor_rc" "$tick_rc" "$dispatch_rc" "$closeout_rc" "$inspect_rc"; do
    if [[ "$rc" -ne 0 && "$rc" -ne 20 ]]; then
      status="fail"
    fi
  done

  jq -nc \
    --arg status "$status" --arg repo "$repo" \
    --argjson preflight "$(jq -c '{status:(if .mode=="reduced" then "pass" else "fail" end), mode, exit_code}' "$preflight")" \
    --argjson init "$(jq -c '{status, mode, private_state_scan}' "$init")" \
    --argjson doctor "$(jq -c '{status, mode, stable_codes}' "$doctor")" \
    --argjson tick "$(jq -c '{status, mode, dry_run}' "$tick")" \
    --argjson dispatch "$(jq -c '{status, mode, real_dispatch, callback_contract}' "$dispatch")" \
    --argjson closeout "$(jq -c '{status, failure_classes}' "$closeout")" \
    --argjson inspect "$(jq -c '{status, next_action}' "$inspect")" \
    '{
      status:$status,
      repo:$repo,
      stages:{
        preflight:$preflight,
        init:$init,
        doctor:$doctor,
        tick:$tick,
        dispatch_or_simulate:$dispatch,
        closeout:$closeout,
        inspect_next_action:$inspect
      }
    }'
}

lane_json() {
  local lane="$1" id tier display note runtime="false" dispatch="not_run" stages="{}"
  if ! row="$(lane_registry_row "$lane")"; then
    printf 'ERROR: unknown journey-smoke lane: %s\n' "$lane" >&2
    return 64
  fi
  IFS=$'\t' read -r id tier display note <<<"$row"
  if [[ "$lane" == "reduced" ]]; then
    stages="$(reduced_lane_json)"
    if jq -e '.status == "pass" and .stages.dispatch_or_simulate.status == "pass"' <<<"$stages" >/dev/null; then
      runtime="true"
      dispatch="pass"
    else
      dispatch="fail"
    fi
  fi
  jq -nc \
    --arg id "$id" --arg tier "$tier" --arg display "$display" --arg note "$note" \
    --argjson runtime "$runtime" --arg dispatch "$dispatch" --argjson stages "$stages" \
    '{
      id:$id,
      display_name:$display,
      support_tier:$tier,
      registry_valid:true,
      runtime_proven:$runtime,
      dry_run:true,
      dispatch_or_simulate:$dispatch,
      evidence:(if $runtime then "runtime_proven" else "registry_valid" end),
      note:$note,
      stages:$stages.stages
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --matrix) [[ $# -ge 2 ]] || die_usage "--matrix requires comma-separated lanes"; MATRIX="$2"; shift 2 ;;
    --matrix=*) MATRIX="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

[[ "$DRY_RUN" -eq 1 ]] || die_usage "--dry-run is required until full harness dispatch is implemented"
need jq
need git

rows_file="$(mktemp -t flywheel-journey-smoke-rows.XXXXXX)"
trap 'rm -f "$rows_file"' EXIT

IFS=',' read -r -a lanes <<<"$MATRIX"
for lane in "${lanes[@]}"; do
  lane="${lane//[[:space:]]/}"
  [[ -n "$lane" ]] || continue
  lane_json "$lane" >>"$rows_file"
done

rows_json="$(jq -s '.' "$rows_file")"
status="pass"
if ! jq -e '
  length > 0
  and all(.[]; .registry_valid == true)
  and ([.[] | select(.id == "reduced" and .runtime_proven == true and .dispatch_or_simulate == "pass")] | length == 1)
' <<<"$rows_json" >/dev/null; then
  status="fail"
fi

payload="$(
  jq -nc --arg sv "$SCHEMA_VERSION" --arg status "$status" --argjson rows "$rows_json" '{
    schema_version:$sv,
    command:"journey-smoke",
    status:$status,
    dry_run:true,
    rows:$rows,
    summary:{
      lanes:($rows | length),
      registry_valid:($rows | map(select(.registry_valid == true)) | length),
      runtime_proven:($rows | map(select(.runtime_proven == true)) | length),
      reduced_dispatch_or_simulate:($rows[] | select(.id == "reduced") | .dispatch_or_simulate)
    }
  }'
)"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  jq -r '.rows[] | [.id,.support_tier,.evidence,.dispatch_or_simulate] | @tsv' <<<"$payload"
fi

[[ "$status" == "pass" ]]
