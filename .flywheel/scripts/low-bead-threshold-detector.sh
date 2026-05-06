#!/usr/bin/env bash
set -u -o pipefail

VERSION="low-bead-threshold-detector.v1.0.0"
SCHEMA_VERSION="low-bead-threshold/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="${LOW_BEAD_THRESHOLD_REPO:-$REPO_DEFAULT}"
LEDGER="${LOW_BEAD_THRESHOLD_LEDGER:-$HOME/.local/state/flywheel/low-bead-threshold-detector-ledger.jsonl}"
ISSUES_JSONL="${LOW_BEAD_THRESHOLD_ISSUES_JSONL:-$REPO/.beads/issues.jsonl}"
THRESHOLD="${LOW_BEAD_THRESHOLD_THRESHOLD:-10}"
COMMAND=""
AUTO_BEAD=0
JSON_OUT=0

usage() {
  cat <<'EOF'
usage:
  low-bead-threshold-detector.sh check [--repo PATH] [--threshold 10] [--auto-bead] [--json]
  low-bead-threshold-detector.sh --info|--help|--examples

Counts ready beads from .beads/issues.jsonl and signals when the queue is light.
EOF
}

examples() {
  cat <<'EOF'
examples:
  .flywheel/scripts/low-bead-threshold-detector.sh check --json
  .flywheel/scripts/low-bead-threshold-detector.sh check --threshold 20 --json
  LOW_BEAD_THRESHOLD_LEDGER=/tmp/low.jsonl .flywheel/scripts/low-bead-threshold-detector.sh check --auto-bead --json
EOF
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

info_json() {
  jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_VERSION" --arg repo "$REPO" --arg ledger "$LEDGER" \
    '{name:"low-bead-threshold-detector.sh",version:$version,schema_version:$schema,repo:$repo,ledger_path:$ledger,
      commands:["check","--repo","--threshold","--auto-bead","--json","--info","--examples","--help"],
      exits:{"0":"probe completed","2":"usage, missing JSONL, or probe error"}}'
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1
  jq -c . <<<"$row" >>"$LEDGER" 2>/dev/null
}

emit() {
  local payload="$1" text="$2" rc="${3:-0}"
  append_ledger "$payload" || payload="$(jq -c '. + {ledger_append_error:true}' <<<"$payload")"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}

latest_jq='
  def latest:
    reduce .[] as $r ({}; if (($r.id // "") | length) > 0 then .[$r.id] = $r else . end) | [.[]];
  def nonempty($x):
    ($x // null) as $v
    | if $v == null then false
      elif ($v | type) == "array" then ($v | length) > 0
      elif ($v | type) == "object" then ($v | length) > 0
      else (($v | tostring | length) > 0) end;
  def claimed:
    (.assignee // .owner // .claimed_by // "") as $a
    | if ($a | type) == "string"
      then (($a | length) > 0 and (($a | ascii_downcase) != "unassigned") and (($a | ascii_downcase) != "none"))
      else $a != null end;
  def blocked:
    (.blocked == true) or nonempty(.blocker) or nonempty(.blockers) or nonempty(.blocked_by) or ((.dependency_status // "") == "blocked");
'

issues_stats() {
  jq -s -c --argjson threshold "$THRESHOLD" "$latest_jq"'
    latest as $issues
    | [$issues[] | select((.status // "" | ascii_downcase) == "open") | select(blocked | not) | select(claimed | not)] as $ready
    | [$issues[] | select((.status // "" | ascii_downcase) == "in_progress") | select(claimed)] as $progress
    | ($threshold / 2 | ceil) as $yellow_floor
    | {
        issues_count:($issues | length),
        ready_count:($ready | length),
        in_progress_count:($progress | length),
        threshold:$threshold,
        yellow_floor:$yellow_floor,
        signal:(if ($ready | length) >= $threshold then "GREEN" elif ($ready | length) >= $yellow_floor then "YELLOW" else "RED" end),
        status:(if ($ready | length) >= $threshold then "pass" elif ($ready | length) >= $yellow_floor then "warn" else "fail" end)
      }' "$ISSUES_JSONL"
}

existing_hunt_bead() {
  jq -s -r "$latest_jq"'
    latest[]
    | select((.status // "" | ascii_downcase) == "open")
    | select((.title // "") | startswith("hunt-work-"))
    | select((.title // "") == "hunt-work-MISSION-env-skills"
        or (.created_by // "") == "low-bead-threshold-detector"
        or ((.labels // []) | index("low-bead-threshold-work-hunt")))
    | .id // empty' "$ISSUES_JSONL" 2>/dev/null | head -1
}

file_hunt_bead() {
  local audit_ts="$1" existing id desc row
  existing="$(existing_hunt_bead || true)"
  if [[ -n "$existing" ]]; then
    jq -nc --arg id "$existing" '{auto_bead_filed:false,hunt_bead_id:$id,auto_bead_action:"reused"}'
    return 0
  fi
  id="flywheel-hunt-work-mission-env-skills"
  desc="Auto-filed by low-bead-threshold-detector. Ready bead count is below the threshold, so flywheel:1 must hunt work through .flywheel/MISSION.md, .flywheel/GOAL.md, .flywheel/STATE.md, repo environment signals, ~/.claude/skills/, and ~/.codex/skills/; notify Joshua only for a true blocker."
  row="$(jq -nc --arg id "$id" --arg title "hunt-work-MISSION-env-skills" --arg desc "$desc" --arg now "$audit_ts" --arg repo "$REPO" \
    '{id:$id,title:$title,description:$desc,status:"open",priority:0,issue_type:"task",created_at:$now,created_by:"low-bead-threshold-detector",updated_at:$now,source_repo:$repo,labels:["low-bead-threshold-work-hunt","donella-self-organization","jsonl-fallback"],compaction_level:0,original_size:0}')"
  mkdir -p "$(dirname "$ISSUES_JSONL")"
  if printf '%s\n' "$row" >>"$ISSUES_JSONL"; then
    jq -nc --arg id "$id" '{auto_bead_filed:true,hunt_bead_id:$id,auto_bead_action:"jsonl_fallback"}'
  else
    jq -nc --arg id "$id" '{auto_bead_filed:false,hunt_bead_id:$id,auto_bead_action:"append_failed"}'
  fi
}

gray_payload() {
  local audit_ts="$1" warning="$2"
  jq -nc --arg schema "$SCHEMA_VERSION" --arg ts "$audit_ts" --arg repo "$REPO" --arg issues "$ISSUES_JSONL" --arg ledger "$LEDGER" --arg warning "$warning" --argjson threshold "$THRESHOLD" \
    '{schema_version:$schema,audit_ts:$ts,repo:$repo,issues_path:$issues,status:"gray",signal:"GRAY",ready_count:0,in_progress_count:0,threshold:$threshold,yellow_floor:((($threshold / 2)|ceil)),auto_bead_requested:false,auto_bead_filed:false,hunt_bead_id:null,auto_bead_action:"skipped",ledger_appended:$ledger,warnings:[$warning],errors:[],exit_code:2}'
}

run_check() {
  local audit_ts stats action payload signal
  audit_ts="$(now_iso)"
  if [[ ! -f "$ISSUES_JSONL" ]]; then
    payload="$(gray_payload "$audit_ts" "issues_jsonl_missing")"
    emit "$payload" "GRAY issues_jsonl_missing=$ISSUES_JSONL" 2
    return $?
  fi
  stats="$(issues_stats 2>/dev/null)" || {
    payload="$(gray_payload "$audit_ts" "issues_jsonl_parse_error")"
    emit "$payload" "GRAY issues_jsonl_parse_error=$ISSUES_JSONL" 2
    return $?
  }
  signal="$(jq -r '.signal' <<<"$stats")"
  action="$(jq -nc '{auto_bead_filed:false,hunt_bead_id:null,auto_bead_action:"skipped"}')"
  if [[ "$AUTO_BEAD" -eq 1 && "$signal" == "RED" ]]; then
    action="$(file_hunt_bead "$audit_ts")"
  fi
  payload="$(jq -nc --arg schema "$SCHEMA_VERSION" --arg ts "$audit_ts" --arg repo "$REPO" --arg issues "$ISSUES_JSONL" --arg ledger "$LEDGER" \
    --argjson stats "$stats" --argjson action "$action" --argjson requested "$([[ "$AUTO_BEAD" -eq 1 ]] && printf true || printf false)" \
    '$stats + $action + {schema_version:$schema,audit_ts:$ts,repo:$repo,issues_path:$issues,auto_bead_requested:$requested,ledger_appended:$ledger,warnings:[],errors:[],exit_code:0,
      hunt_bead_suggestion:(if $stats.signal == "RED" then {title:"hunt-work-MISSION-env-skills",priority:0,reason:"ready_count_below_yellow_floor"} else null end)}')"
  emit "$payload" "signal=$(jq -r '.signal' <<<"$payload") ready=$(jq -r '.ready_count' <<<"$payload") in_progress=$(jq -r '.in_progress_count' <<<"$payload") threshold=$(jq -r '.threshold' <<<"$payload")" 0
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    check) COMMAND="check"; shift ;;
    --repo) REPO="${2:?}"; ISSUES_JSONL="$REPO/.beads/issues.jsonl"; shift 2 ;;
    --threshold) THRESHOLD="${2:?}"; shift 2 ;;
    --auto-bead) AUTO_BEAD=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info) info_json; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! [[ "$THRESHOLD" =~ ^[1-9][0-9]*$ ]]; then
  printf 'threshold must be a positive integer\n' >&2
  exit 2
fi

if [[ "$COMMAND" != "check" ]]; then
  usage >&2
  exit 2
fi

run_check
