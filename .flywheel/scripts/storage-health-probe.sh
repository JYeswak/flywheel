#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
STORAGE_PROBE="${FLYWHEEL_STORAGE_PROBE:-$ROOT/.flywheel/scripts/storage-probe.sh}"
FIXTURE=""
INPUT_JSON_FILE=""
REPO="$ROOT"
JSON_OUT=1

usage() {
  cat <<'USG'
usage: storage-health-probe.sh [doctor|health] [--json] [--repo PATH] [--fixture PATH]
       storage-health-probe.sh --input-json PATH --json
       storage-health-probe.sh validate --input-json PATH --json
       storage-health-probe.sh repair --json
       storage-health-probe.sh --schema|--info|--examples|--help

Classifies storage into tiers 0-5 using the zesttube storage doctrine:
0 comfortable, 1 monitor, 2 soft_prune, 3 critical, 4 fire, 5 nuclear.
USG
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

schema_json() {
  jq -nc '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"storage-health-probe/v1",
    type:"object",
    required:["schema_version","ts","status","tier","tier_label","free_pct","accumulators","dispatch_gate","dashboard_line"],
    properties:{
      tier:{type:"integer",minimum:0,maximum:5},
      tier_label:{enum:["comfortable","monitor","soft_prune","critical","fire","nuclear"]},
      free_pct:{type:"number"},
      dispatch_gate:{type:"object",required:["blocks_dispatch","reason"]},
      accumulators:{type:"array"}
    }
  }'
}

info_json() {
  jq -nc --arg root "$ROOT" --arg probe "$STORAGE_PROBE" '{
    schema_version:"storage-health-probe/info/v1",
    command:"info",
    root:$root,
    storage_probe:$probe,
    mutates:[],
    canonical_cli:{
      doctor_health_repair:"doctor/health classify storage; repair is n/a because probe is read-only",
      validate_audit_why:"validate supports supplied JSON; audit/why are intentionally n/a until history is recorded by storage-probe.sh",
      json_schema_exit_codes:"--json is default, --schema is published, usage errors exit 2, valid classifications exit 0"
    }
  }'
}

examples_json() {
  jq -nc '{
    schema_version:"storage-health-probe/examples/v1",
    examples:[
      {name:"live",command:".flywheel/scripts/storage-health-probe.sh --json"},
      {name:"fixture",command:".flywheel/scripts/storage-health-probe.sh --fixture tests/fixtures/storage-low.json --json"},
      {name:"doctor",command:".flywheel/scripts/storage-health-probe.sh doctor --json"},
      {name:"validate",command:".flywheel/scripts/storage-health-probe.sh validate --input-json /tmp/storage.json --json"}
    ]
  }'
}

load_metrics_json() {
  if [[ -n "$INPUT_JSON_FILE" ]]; then
    cat "$INPUT_JSON_FILE"
    return 0
  fi
  if [[ -n "$FIXTURE" ]]; then
    cat "$FIXTURE"
    return 0
  fi
  if [[ ! -x "$STORAGE_PROBE" ]]; then
    jq -nc --arg probe "$STORAGE_PROBE" '{status:"fail",disk_free_pct:0,errors:[{code:"storage_probe_missing",path:$probe}]}'
    return 0
  fi
  "$STORAGE_PROBE" --repo "$REPO" --json 2>/dev/null || jq -nc '{status:"fail",disk_free_pct:0,errors:[{code:"storage_probe_failed"}]}'
}

classify_json() {
  local metrics="$1"
  jq -c --arg ts "$(now_iso)" '
    def num($x): (($x // 0) | tonumber);
    def boolish($x): ($x == true or $x == "true" or $x == 1 or $x == "1");
    . as $m
    | (num($m.disk_free_pct // $m.free_pct)) as $free_pct
    | (boolish($m.compaction_failed) or boolish($m.docker_raw_dominates) or boolish($m.machine_blocked) or boolish($m.nuclear_signal) or boolish($m.storage_nuclear)) as $nuclear
    | (boolish($m.storage_backed_services_unhealthy) or boolish($m.docker_unhealthy) or boolish($m.qdrant_unhealthy)) as $service_unhealthy
    | (if $nuclear then 5
       elif $free_pct < 5 then 4
       elif ($free_pct <= 15 or $service_unhealthy) then 3
       elif $free_pct < 30 then 2
       elif $free_pct <= 50 then 1
       else 0 end) as $tier
    | (["comfortable","monitor","soft_prune","critical","fire","nuclear"][$tier]) as $label
    | (if $tier >= 3 then "fail" elif $tier == 2 then "warn" else "ok" end) as $status
    | [
        {name:"developer_dir_gb",value:num($m.developer_dir_gb),unit:"GiB"},
        {name:"local_state_gb",value:num($m.local_state_gb),unit:"GiB"},
        {name:"stale_baks_count",value:num($m.stale_baks_count),unit:"count"},
        {name:"stale_baks_size_mb",value:num($m.stale_baks_size_mb),unit:"MiB"},
        {name:"qdrant_volumes_size_mb",value:num($m.qdrant_volumes_size_mb),unit:"MiB"},
        {name:"tmp_dispatch_artifacts_count",value:num($m.tmp_dispatch_artifacts_count),unit:"count"}
      ] as $accumulators
    | {
        schema_version:"storage-health-probe/v1",
        ts:$ts,
        status:$status,
        tier:$tier,
        tier_label:$label,
        free_pct:$free_pct,
        free_gb:num($m.disk_free_gb),
        total_gb:num($m.disk_total_gb),
        thresholds:{
          comfortable_gt_pct:50,
          monitor_min_pct:30,
          soft_prune_min_pct:15,
          critical_min_pct:5,
          fire_lt_pct:5
        },
        dispatch_gate:{
          blocks_dispatch:($tier >= 3),
          threshold_tier:3,
          reason:(if $tier >= 3 then "tier>=3" else "tier<3" end)
        },
        accumulators:$accumulators,
        source:{
          probe:"storage-probe.sh",
          repo:($m.repo // null),
          source_version:($m.version // null)
        },
        signals:{
          nuclear:$nuclear,
          service_unhealthy:$service_unhealthy,
          source_status:($m.status // null),
          source_tier:($m.tier // null),
          errors:($m.errors // []),
          warnings:($m.warnings // [])
        },
        dashboard_line:("Storage: tier=\($tier)/\($label) free=\($free_pct)% gate=" + (if $tier >= 3 then "block" else "allow" end) + " accumulators=\($accumulators|length)")
      }
  ' <<<"$metrics"
}

run_probe() {
  local metrics
  metrics="$(load_metrics_json)"
  if ! jq -e . >/dev/null 2>&1 <<<"$metrics"; then
    jq -nc '{schema_version:"storage-health-probe/v1",status:"fail",tier:3,tier_label:"critical",free_pct:0,accumulators:[],dispatch_gate:{blocks_dispatch:true,threshold_tier:3,reason:"invalid_metrics_json"},dashboard_line:"Storage: tier=3/critical free=unknown gate=block accumulators=0"}'
    return 0
  fi
  classify_json "$metrics"
}

validate_json() {
  local payload
  payload="$(run_probe)"
  jq -nc --argjson payload "$payload" '{
    schema_version:"storage-health-probe/validate/v1",
    command:"validate",
    status:(if (($payload.tier | type) == "number" and ($payload.accumulators | type) == "array" and ($payload.dispatch_gate.blocks_dispatch | type) == "boolean") then "pass" else "fail" end),
    checks:[
      {name:"tier_number",status:(if (($payload.tier | type) == "number") then "pass" else "fail" end)},
      {name:"accumulators_array",status:(if (($payload.accumulators | type) == "array") then "pass" else "fail" end)},
      {name:"dispatch_gate_boolean",status:(if (($payload.dispatch_gate.blocks_dispatch | type) == "boolean") then "pass" else "fail" end)}
    ],
    payload:$payload
  }'
}

repair_json() {
  jq -nc '{
    schema_version:"storage-health-probe/repair/v1",
    command:"repair",
    status:"not_applicable",
    reason:"read-only classifier; use storage-prune.sh or storage-headroom-watcher.sh for mutation surfaces",
    mutates:[]
  }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health) shift ;;
    validate) shift; MODE="validate" ;;
    repair) shift; MODE="repair" ;;
    --json) JSON_OUT=1; shift ;;
    --repo) REPO="${2:-}"; [[ -n "$REPO" ]] || { echo "ERROR: --repo requires PATH" >&2; exit 2; }; shift 2 ;;
    --fixture) FIXTURE="${2:-}"; [[ -n "$FIXTURE" ]] || { echo "ERROR: --fixture requires PATH" >&2; exit 2; }; shift 2 ;;
    --input-json) INPUT_JSON_FILE="${2:-}"; [[ -n "$INPUT_JSON_FILE" ]] || { echo "ERROR: --input-json requires PATH" >&2; exit 2; }; shift 2 ;;
    --schema) schema_json; exit 0 ;;
    --info) info_json; exit 0 ;;
    --examples) examples_json; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "${MODE:-probe}" in
  validate) validate_json ;;
  repair) repair_json ;;
  probe) run_probe ;;
esac
