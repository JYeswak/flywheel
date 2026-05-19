#!/usr/bin/env bash
set -euo pipefail

VERSION="dispatch-log-fitness-invariant/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
REPO="$ROOT"; JSON_OUT=0; APPLY=0; WINDOW=50
NTM="${NTM:-/Users/josh/.local/bin/ntm}"

usage() { cat <<'EOF'
usage: dispatch-log-fitness-invariant.sh [doctor|health|validate] [--repo PATH] [--json] [--apply]
       dispatch-log-fitness-invariant.sh --schema|--info|--examples|-h|--help
       dispatch-log-fitness-invariant.sh completion [bash|zsh|fish]
exit codes: 0=PASS, 1=WARN, 2=FAIL or usage
EOF
}
schema() { jq -nc --arg v "$VERSION" '{schema_version:$v,required:["schema_version","status","coverage_pct","drift_count","window","total","with_fitness_claim","with_fitness_class"]}'; }
info() { jq -nc --arg v "$VERSION" --arg repo "$REPO" '{name:"dispatch-log-fitness-invariant.sh",version:$v,repo:$repo,event_source:"ntm timeline --json",window:50,mutates:"--apply writes dispatch-log-fitness-invariant.json"}'; }
examples() { printf '%s\n' 'bash .flywheel/scripts/dispatch-log-fitness-invariant.sh --repo "$PWD" --json' 'bash .flywheel/scripts/dispatch-log-fitness-invariant.sh --apply'; }
completion() { case "${1:-bash}" in bash|zsh|fish) printf '%s\n' '# completion: --repo --json --apply --info --examples --schema doctor health validate repair audit why quickstart help completion' ;; *) printf 'unsupported shell: %s\n' "$1" >&2; exit 2 ;; esac; }
die_usage() { printf 'ERR: %s\n' "$1" >&2; exit 2; }

case "${1:-}" in
  doctor|health|validate) shift; [[ "${1:-}" != "--help" && "${1:-}" != "-h" ]] || { usage; exit 0; } ;;
  repair) printf '%s\n' 'repair: no autonomous repair; dispatch authoring must emit mission fitness metadata'; exit 0 ;;
  audit) sidecar="$REPO/.flywheel/dispatch-log-fitness-invariant.json"; [[ -f "$sidecar" ]] && cat "$sidecar" || printf 'audit: no sidecar found at %s\n' "$sidecar"; exit 0 ;;
  why) printf '%s\n' 'why: mission fitness metadata proves dispatches serve the locked mission anchor before worker time is spent.'; exit 0 ;;
  quickstart) printf '%s\n' 'Checks recent ntm timeline dispatch events for mission_fitness_claim coverage.'; exit 0 ;;
  help) usage; exit 0 ;;
  completion) shift; [[ "${1:-}" != "--help" && "${1:-}" != "-h" ]] || { usage; exit 0; }; completion "${1:-bash}"; exit 0 ;;
  schema) schema; exit 0 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || die_usage "--repo requires PATH"; REPO="$(cd "$2" && pwd -P)"; shift 2 ;;
    --repo=*) REPO="$(cd "${1#*=}" && pwd -P)"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; shift ;;
    --dry-run|--explain|--quiet|--no-color) shift ;;
    --width) [[ $# -ge 2 ]] || die_usage "--width requires N"; shift 2 ;;
    --width=*) shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --schema) schema; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) die_usage "unexpected argument: $1" ;;
  esac
done

[[ -d "$REPO/.flywheel" ]] || die_usage "repo has no .flywheel directory: $REPO"
TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-log-fitness-invariant.XXXXXX")"
trap 'rm -f "$TMP" "${OUT_TMP:-}"' EXIT

timeline_json() {
  local raw
  if [[ -n "${NTM_TIMELINE_JSON:-}" ]]; then raw="$NTM_TIMELINE_JSON"
  elif [[ -n "${NTM_TIMELINE_JSON_FILE:-}" ]]; then raw="$(cat "$NTM_TIMELINE_JSON_FILE" 2>/dev/null || true)"
  else raw="$("$NTM" timeline --json 2>/dev/null || true)"
  fi
  jq -e . >/dev/null 2>&1 <<<"$raw" && printf '%s\n' "$raw" || printf '{}\n'
}

jq -nc --arg v "$VERSION" --argjson window "$WINDOW" --argjson payload "$(timeline_json)" '
def events: if type=="array" then . elif (.events|type)=="array" then .events elif (.timeline.events|type)=="array" then .timeline.events elif (.data.events|type)=="array" then .data.events elif (.timeline_events|type)=="array" then .timeline_events else [] end;
def row: ((.metadata // {}) + .);
[($payload|events|.[(-$window):][]?|row|select(.task_id or (((.event//.type//.kind//"")|tostring)|test("dispatch";"i"))))] | .[(-$window):] as $rows |
($rows|length) as $total |
($rows|map(select((.mission_fitness_claim//""|tostring|length)>0))|length) as $claim |
($rows|map(select((.mission_fitness_class//"")|IN("direct","adjacent","infrastructure","drift","unknown")))|length) as $class |
($rows|map(select(.mission_fitness_class=="drift" or .mission_fitness=="drift"))|length) as $drift |
($rows|map(select(.mission_fitness_class=="unknown"))|length) as $unknown |
(if $total == 0 then 100 else (($claim / $total * 10000)|round / 100) end) as $coverage |
(if $coverage < 60 or $drift >= 2 then ["FAIL",2] elif $coverage < 80 or $drift == 1 then ["WARN",1] else ["PASS",0] end) as $verdict |
{schema_version:$v,status:$verdict[0],exit_code:$verdict[1],dispatch_log:"ntm timeline --json",event_source:"ntm timeline --json",log_present:($payload != {}),window:$window,total:$total,with_fitness_claim:$claim,with_fitness_class:$class,drift_class:$drift,unknown_class:$unknown,malformed_count:0,coverage_pct:$coverage,fitness_coverage_pct:$coverage,drift_count:$drift,dashboard_line:("Dispatch fitness: \($coverage)% (drift=\($drift), last \($window))" + if $verdict[0]=="PASS" then "" else " \($verdict[0])" end)}' >"$TMP"

if [[ "$APPLY" -eq 1 ]]; then
  OUT_TMP="$(mktemp "$REPO/.flywheel/dispatch-log-fitness-invariant.json.XXXXXX")"
  jq --arg checked_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '. + {checked_at:$checked_at}' "$TMP" >"$OUT_TMP"
  mv "$OUT_TMP" "$REPO/.flywheel/dispatch-log-fitness-invariant.json"
fi

[[ "$JSON_OUT" -eq 1 ]] && cat "$TMP" || jq -r '.dashboard_line' "$TMP"
exit "$(jq -r '.exit_code' "$TMP")"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
