#!/usr/bin/env bash
set -euo pipefail

VERSION="mission-lock-readiness-doctor/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MISSION_PATH="$ROOT/.flywheel/MISSION.md"
PLAN_PATH="$ROOT/.flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06"
COMMAND="doctor"
JSON_OUT=0
QUIET=0
for arg in "$@"; do [[ "$arg" == "--json" ]] && JSON_OUT=1; done

usage() {
  printf '%s\n' \
    'usage:' \
    '  mission-lock-readiness-doctor.sh [doctor|health|validate|audit|schema] [--mission MISSION.md] [--plan PLAN_DIR] [--json] [--quiet]' \
    '  mission-lock-readiness-doctor.sh --info|--help|--examples [--json]'
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:["mission-lock-readiness-doctor.sh --json","mission-lock-readiness-doctor.sh doctor --mission .flywheel/MISSION.md --json","mission-lock-readiness-doctor.sh validate --plan .flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06 --json"]}'
  else
    printf '%s\n' 'mission-lock-readiness-doctor.sh --json' 'mission-lock-readiness-doctor.sh doctor --mission .flywheel/MISSION.md --json' 'mission-lock-readiness-doctor.sh validate --plan .flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06 --json'
  fi
}

info() {
  jq -nc --arg version "$VERSION" '{name:"mission-lock-readiness-doctor.sh",version:$version,mutates:false,audit_only_default:true,canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],canonical_cli_verbs:["doctor","health","validate","audit","schema"],doctor_fields:["mission_lock_readiness_health_score","blocked_surfaces","phase0_scaffold_bead_suggestions","repair_receipt_identity_fields"],exit_codes:{"0":"healthy","1":"readiness_incomplete","2":"usage"}}'
}

schema_payload() {
  jq -nc --arg version "$VERSION" '{schema_version:$version,score_range:[0,1],producer_inputs:["mission-lock-output-schema-validator","mission-lock-scaffold-validator","plan-state-lens-merge validate"],consumer:"flywheel-loop doctor field set",promotion:"health<1 emits Phase 0 scaffold suggestions; no mutation in audit-only mode"}'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|validate|audit|schema) COMMAND="$1"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --mission) [[ $# -ge 2 ]] || die_usage "--mission requires a path"; MISSION_PATH="$2"; shift 2 ;;
    --plan) [[ $# -ge 2 ]] || die_usage "--plan requires a path"; PLAN_PATH="$2"; shift 2 ;;
    --info) info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --examples) examples; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) MISSION_PATH="$1"; shift ;;
  esac
done

if [[ "$COMMAND" == "schema" ]]; then schema_payload; exit 0; fi
[[ -r "$MISSION_PATH" ]] || die_usage "mission file not readable: $MISSION_PATH"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-lock-readiness.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
SCHEMA_VALIDATOR="$ROOT/.flywheel/scripts/mission-lock-output-schema-validator.sh"
SCAFFOLD_VALIDATOR="$ROOT/.flywheel/scripts/mission-lock-scaffold-validator.sh"
LENS_MERGE="$ROOT/.flywheel/scripts/plan-state-lens-merge.sh"

run_json() {
  local out="$1"; shift
  set +e
  "$@" --json >"$out" 2>"$out.err"
  local rc=$?
  set -e
  return "$rc"
}

schema_rc=2
if [[ -x "$SCHEMA_VALIDATOR" ]]; then
  run_json "$TMP/schema.json" bash "$SCHEMA_VALIDATOR" --mission "$MISSION_PATH" || schema_rc=$?
  schema_rc="${schema_rc:-0}"
else
  jq -nc '{status:"skip",errors:[]}' >"$TMP/schema.json"
fi
schema_status="$(jq -r '.status // "skip"' "$TMP/schema.json" 2>/dev/null || printf 'fail')"
[[ "$schema_status" == "pass" ]] && schema_verdict=pass || schema_verdict=fail
[[ -x "$SCHEMA_VALIDATOR" ]] || schema_verdict=skip

scaffold_rc=2
if [[ -x "$SCAFFOLD_VALIDATOR" ]]; then
  run_json "$TMP/scaffold.json" bash "$SCAFFOLD_VALIDATOR" --mission "$MISSION_PATH" || scaffold_rc=$?
  scaffold_rc="${scaffold_rc:-0}"
else
  jq -nc '{verdict:"skip",blockers:[],checks:{blocked_readiness_states:[]}}' >"$TMP/scaffold.json"
fi
scaffold_verdict="$(jq -r '.verdict // "skip"' "$TMP/scaffold.json" 2>/dev/null || printf 'fail')"
[[ -x "$SCAFFOLD_VALIDATOR" ]] || scaffold_verdict=skip

if [[ -x "$LENS_MERGE" && -e "$PLAN_PATH" ]]; then
  if run_json "$TMP/lens.json" bash "$LENS_MERGE" validate --plan "$PLAN_PATH"; then
    lens_consistent=true
  else
    lens_consistent=false
  fi
else
  jq -nc '{status:"fail",malformed_count:1}' >"$TMP/lens.json"
  lens_consistent=false
fi

: >"$TMP/surfaces.txt"
: >"$TMP/suggestions.jsonl"
suggest() {
  local slug="$1" summary="$2" finding="$3"
  printf '%s\n' "$slug" >>"$TMP/surfaces.txt"
  jq -nc --arg slug "$slug" --arg summary "$summary" --arg finding "$finding" '{slug:$slug,summary:$summary,blocking_finding:$finding}' >>"$TMP/suggestions.jsonl"
}

if [[ "$schema_verdict" != "pass" ]]; then
  codes="$(jq -r '[.errors[]?.code] | unique | join(",")' "$TMP/schema.json")"
  suggest "mission-lock-output-schema" "Backfill mission-lock output schema fields and sidecar JSON until schema validator passes." "schema:${codes:-validator_unavailable}"
fi
if [[ "$scaffold_verdict" == "blocked" ]]; then
  jq -r '.blockers[]?' "$TMP/scaffold.json" | while read -r item; do [[ -n "$item" ]] && printf 'mission-lock-scaffold:%s\n' "$item" >>"$TMP/surfaces.txt"; done
  suggest "mission-lock-scaffold" "Repair required markdown sections, section hashes, substrate pointers, or negative invariants." "scaffold:blocked"
elif [[ "$scaffold_verdict" != "ready" ]]; then
  suggest "mission-lock-scaffold-backfill" "Add section-hash receipts and substrate inventory so legacy mission lock reaches ready." "scaffold:${scaffold_verdict}"
fi
if [[ "$lens_consistent" != "true" ]]; then
  suggest "plan-state-lens-merge" "Repair plan STATE lens merge rows so readiness can trust parallel audit state." "IDEM-004"
fi
jq -r '.checks.blocked_readiness_states[]?' "$TMP/scaffold.json" 2>/dev/null | while read -r item; do [[ -n "$item" ]] && printf 'blocked-readiness:%s\n' "$item" >>"$TMP/surfaces.txt"; done

score="$(python3 - "$schema_verdict" "$scaffold_verdict" "$lens_consistent" <<'PY'
import sys
schema, scaffold, lens = sys.argv[1:]
score = 1.0
if schema == "fail": score -= 0.55
elif schema == "skip": score -= 0.20
if scaffold == "blocked": score -= 0.35
elif scaffold in {"incomplete","skip","fail"}: score -= 0.15
if lens != "true": score -= 0.45
print(f"{max(0.0, min(1.0, score)):.2f}")
PY
)"
surfaces_json="$(jq -R -s -c 'split("\n")[:-1] | unique' "$TMP/surfaces.txt")"
suggestions_json="$(jq -s -c '.' "$TMP/suggestions.jsonl")"
identity_payload="$(jq -nc --arg mission_sha "$(shasum -a 256 "$MISSION_PATH" | awk '{print $1}')" --arg schema "$schema_verdict" --arg scaffold "$scaffold_verdict" --argjson lens "$lens_consistent" --argjson surfaces "$surfaces_json" '{mission_sha:$mission_sha,schema:$schema,scaffold:$scaffold,lens:$lens,surfaces:$surfaces}')"
repair_key="$(printf '%s' "$identity_payload" | shasum -a 256 | awk '{print "sha256:" $1}')"

payload="$(jq -nc \
  --arg version "$VERSION" \
  --arg command "$COMMAND" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg mission "$(cd "$(dirname "$MISSION_PATH")" && pwd -P)/$(basename "$MISSION_PATH")" \
  --arg schema "$schema_verdict" \
  --arg scaffold "$scaffold_verdict" \
  --argjson lens "$lens_consistent" \
  --argjson score "$score" \
  --argjson surfaces "$surfaces_json" \
  --argjson suggestions "$suggestions_json" \
  --arg repair_key "$repair_key" \
  --argjson schema_result "$(cat "$TMP/schema.json")" \
  --argjson scaffold_result "$(cat "$TMP/scaffold.json")" \
  --argjson lens_result "$(cat "$TMP/lens.json")" \
  '{schema_version:$version,command:$command,ts:$ts,mission_md_path:$mission,schema_validator_verdict:$schema,scaffold_validator_verdict:$scaffold,lens_merge_consistent:$lens,mission_lock_readiness_health_score:$score,blocked_surfaces:$surfaces,phase0_scaffold_bead_suggestions:$suggestions,repair_receipt_identity_fields:{repair_idempotency_key:$repair_key,expected_blocked_surfaces_resolved:$surfaces},audit_only:true,upstream_results:{schema:$schema_result,scaffold:$scaffold_result,lens_merge:$lens_result}}')"

if [[ "$QUIET" -eq 0 && "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
elif [[ "$QUIET" -eq 0 ]]; then
  jq -r '"health=\(.mission_lock_readiness_health_score) schema=\(.schema_validator_verdict) scaffold=\(.scaffold_validator_verdict) lens=\(.lens_merge_consistent)"' <<<"$payload"
fi
[[ "$(jq -r '.mission_lock_readiness_health_score == 1' <<<"$payload")" == true ]]
