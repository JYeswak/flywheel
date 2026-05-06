#!/usr/bin/env bash
set -euo pipefail

VERSION="two-truth-sources-validator.v1.0.0"
SCHEMA_VERSION="two-truth-sources-decision/v1"
NTM="${TWO_TRUTH_SOURCES_NTM:-/Users/josh/.local/bin/ntm}"
LEDGER="${TWO_TRUTH_SOURCES_LEDGER:-$HOME/.local/state/flywheel/two-truth-sources-validator-ledger.jsonl}"
SESSION=""
PANE=""
REQUIRED_SOURCES=2
JSON_OUT=0

usage() {
  cat <<'USAGE'
usage:
  two-truth-sources-validator.sh check --session NAME --pane N [--required-sources 2] [--json]
  two-truth-sources-validator.sh --info|--help|--examples
USAGE
}

examples() {
  cat <<'EXAMPLES'
two-truth-sources-validator.sh check --session flywheel --pane 3 --json
two-truth-sources-validator.sh check --session skillos --pane 2 --required-sources 3
TWO_TRUTH_SOURCES_NTM=/tmp/fake-ntm TWO_TRUTH_SOURCES_LEDGER=/tmp/ledger.jsonl two-truth-sources-validator.sh check --session fixture --pane 2 --json
EXAMPLES
}

info() {
  jq -nc \
    --arg name "two-truth-sources-validator.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ntm "$NTM" \
    --arg ledger "$LEDGER" \
    '{name:$name,version:$version,schema_version:$schema_version,ntm:$ntm,ledger:$ledger,purpose:"fail-closed pre-dispatch pane-state cross-check",exit_codes:{"0":"allow","1":"refuse / fail closed","2":"usage"}}'
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

fail_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

json_null_or_string() {
  local value="${1:-}"
  if [[ -z "$value" || "$value" == "null" ]]; then
    printf 'null'
  else
    jq -nc --arg value "$value" '$value'
  fi
}

pane_json_number() {
  if [[ "$PANE" =~ ^[0-9]+$ ]]; then
    printf '%s' "$PANE"
  else
    printf 'null'
  fi
}

probe_activity() {
  local tmp err rc raw parsed
  tmp="$(mktemp "${TMPDIR:-/tmp}/two-truth-activity.XXXXXX")"
  err="$(mktemp "${TMPDIR:-/tmp}/two-truth-activity-err.XXXXXX")"
  set +e
  "$NTM" --robot-activity="$SESSION" --panes="$PANE" --json >"$tmp" 2>"$err"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]] || ! jq -e . "$tmp" >/dev/null 2>&1; then
    jq -nc --arg stderr "$(cat "$err")" --argjson rc "$rc" '{ok:false,source:"robot_activity",reason:"probe_failure",ntm_rc:$rc,stderr:$stderr}'
    rm -f "$tmp" "$err"
    return 0
  fi
  raw="$(cat "$tmp")"
  rm -f "$tmp" "$err"
  parsed="$(jq -c --arg pane "$PANE" '
    def rows: ([.agents[]?, .panes[]?, .workers[]?, .rows[]?] | map(select(type == "object")));
    rows as $rows
    | ($rows | map(select(((.pane_idx // .pane // .idx // .id // "") | tostring) == $pane)) | .[0] // (if ($rows | length) == 1 then $rows[0] else null end)) as $a
    | {
        ok:((.success // true) == true and $a != null),
        source:"robot_activity",
        pane:(($pane | tonumber?) // $pane),
        state:(if $a == null then null else (($a.state // $a.robot_state // $a.activity_state // null) | tostring) end),
        agent_type:(if $a == null then null else (($a.agent_type // $a.type // null) | tostring) end),
        capture_provenance:(if $a == null then null else (($a.capture_provenance // .source_health.tmux.provenance // .source_health.provenance // null) | tostring) end),
        capture_error:(if $a == null then null else ($a.capture_error // null) end),
        capture_collected_at:(if $a == null then null else ($a.capture_collected_at // .captured_at // null) end),
        detected_patterns:(if $a == null then [] else ($a.detected_patterns // []) end)
      }
  ' <<<"$raw" 2>/dev/null || true)"
  if [[ -z "$parsed" ]]; then
    jq -nc '{ok:false,source:"robot_activity",reason:"parse_failure"}'
  else
    printf '%s\n' "$parsed"
  fi
}

probe_tail() {
  local tmp err rc raw parsed text last_line chevron reminder chevron_char
  tmp="$(mktemp "${TMPDIR:-/tmp}/two-truth-tail.XXXXXX")"
  err="$(mktemp "${TMPDIR:-/tmp}/two-truth-tail-err.XXXXXX")"
  set +e
  "$NTM" --robot-tail="$SESSION" --panes="$PANE" --lines=20 --json >"$tmp" 2>"$err"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]] || ! jq -e . "$tmp" >/dev/null 2>&1; then
    jq -nc --arg stderr "$(cat "$err")" --argjson rc "$rc" '{ok:false,source:"robot_tail",reason:"probe_failure",ntm_rc:$rc,stderr:$stderr,last_line:null,chevron_visible:false,reminder_template:false}'
    rm -f "$tmp" "$err"
    return 0
  fi
  raw="$(cat "$tmp")"
  rm -f "$tmp" "$err"
  parsed="$(jq -c --arg pane "$PANE" '
    def object_text($p):
      if ($p.text? != null) then ($p.text | tostring)
      elif ($p.content? != null) then ($p.content | tostring)
      elif ($p.capture? != null) then ($p.capture | tostring)
      elif ($p.output? != null) then ($p.output | tostring)
      elif (($p.lines? // null) | type) == "array" then ($p.lines | map(tostring) | join("\n"))
      else "" end;
    def text_of($p):
      if ($p | type) == "object" then object_text($p)
      elif ($p | type) == "array" then ($p | map(tostring) | join("\n"))
      elif $p == null then ""
      else ($p | tostring) end;
    (.panes // null) as $panes
    | (
        if ($panes | type) == "array" then
          [$panes[] | select((((.pane // .pane_idx // .index // .id // "") | tostring) == $pane) or (($panes | length) == 1))] | .[0] // null
        elif ($panes | type) == "object" then
          ($panes[$pane] // null)
        else null end
      ) as $target
    | {
        ok:((.success // true) == true and $target != null),
        source:"robot_tail",
        pane:(($pane | tonumber?) // $pane),
        text:text_of($target),
        pane_state:(if ($target | type) == "object" then (($target.state // $target.status // $target.activity_state // null) | tostring) else null end),
        capture_provenance:(if ($target | type) == "object" then (($target.capture_provenance // .source_health.tmux.provenance // .source_health.provenance // null) | tostring) else ((.source_health.tmux.provenance // .source_health.provenance // null) | tostring) end),
        source_health_status:((.source_health.tmux.status // .source_health.status // null) | tostring)
      }
  ' <<<"$raw" 2>/dev/null || true)"
  if [[ -z "$parsed" ]]; then
    jq -nc '{ok:false,source:"robot_tail",reason:"parse_failure",last_line:null,chevron_visible:false,reminder_template:false}'
    return 0
  fi
  text="$(jq -r '.text // ""' <<<"$parsed")"
  last_line="$(printf '%s\n' "$text" | awk 'NF { line=$0 } END { print line }')"
  chevron_char="$(printf '\342\200\272')"
  chevron=false
  if printf '%s\n' "$text" | grep -Fq "$chevron_char"; then
    chevron=true
  fi
  reminder=false
  if printf '%s\n' "$text" | grep -Eiq 'Improve documentation in @filename|Find and fix a bug in @filename|@filename|template stub|generic template prompt'; then
    reminder=true
  fi
  jq -c --arg last_line "$last_line" --argjson chevron "$chevron" --argjson reminder "$reminder" \
    'del(.text) + {last_line:$last_line,chevron_visible:$chevron,reminder_template:$reminder}' <<<"$parsed"
}

probe_health() {
  local tmp err rc raw parsed
  tmp="$(mktemp "${TMPDIR:-/tmp}/two-truth-health.XXXXXX")"
  err="$(mktemp "${TMPDIR:-/tmp}/two-truth-health-err.XXXXXX")"
  set +e
  "$NTM" --robot-agent-health="$SESSION" --no-caut --json >"$tmp" 2>"$err"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]] || ! jq -e . "$tmp" >/dev/null 2>&1; then
    jq -nc --arg stderr "$(cat "$err")" --argjson rc "$rc" '{ok:false,source:"robot_agent_health",reason:"probe_failure",ntm_rc:$rc,stderr:$stderr}'
    rm -f "$tmp" "$err"
    return 0
  fi
  raw="$(cat "$tmp")"
  rm -f "$tmp" "$err"
  parsed="$(jq -c --arg pane "$PANE" '
    (.panes // {}) as $panes
    | ($panes[$pane] // null) as $p
    | {ok:((.success // true) == true and $p != null),source:"robot_agent_health",pane:(($pane | tonumber?) // $pane),agent_type:($p.agent_type // null),health_grade:($p.health_grade // null),recommendation:($p.recommendation // null),issues:($p.issues // [])}
  ' <<<"$raw" 2>/dev/null || true)"
  [[ -n "$parsed" ]] && printf '%s\n' "$parsed" || jq -nc '{ok:false,source:"robot_agent_health",reason:"parse_failure"}'
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")"
  jq -c . <<<"$row" >>"$LEDGER"
}

emit_decision() {
  local decision="$1" reason="$2" agreement="$3" detail="$4" sources_probed="$5" source1="$6" source2="$7" source3="$8"
  local payload rc ledger_written=true
  [[ "$decision" == "allow" ]] && rc=0 || rc=1
  payload="$(jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg session "$SESSION" \
    --argjson pane "$(pane_json_number)" \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --arg agreement "$agreement" \
    --argjson detail "$(json_null_or_string "$detail")" \
    --argjson sources_probed "$sources_probed" \
    --argjson required_sources "$REQUIRED_SOURCES" \
    --argjson source_1 "$source1" \
    --argjson source_2 "$source2" \
    --argjson source_3 "$source3" \
    --arg ledger "$LEDGER" \
    '{schema_version:$schema_version,version:$version,ts:$ts,session:$session,pane:$pane,decision:$decision,sources_probed:$sources_probed,required_sources:$required_sources,agreement:$agreement,disagreement_detail:$detail,source_1:$source_1,source_2:$source_2,source_3:$source_3,reason:$reason,ledger_appended:$ledger,ledger_written:true}')"
  if ! append_ledger "$payload"; then
    ledger_written=false
    payload="$(jq -c '.ledger_written=false | .decision="refuse" | .reason="ledger_append_failed"' <<<"$payload")"
    rc=1
  fi
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"decision=\(.decision) reason=\(.reason) agreement=\(.agreement) sources_probed=\(.sources_probed)"' <<<"$payload"
  fi
  [[ "$ledger_written" == "true" ]] || printf 'WARN: ledger append failed: %s\n' "$LEDGER" >&2
  exit "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    check) shift ;;
    --session) SESSION="${2:-}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --pane) PANE="${2:-}"; shift 2 ;;
    --pane=*) PANE="${1#*=}"; shift ;;
    --required-sources) REQUIRED_SOURCES="${2:-}"; shift 2 ;;
    --required-sources=*) REQUIRED_SOURCES="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --examples) examples; exit 0 ;;
    --info) info; exit 0 ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
done

[[ -n "$SESSION" && -n "$PANE" ]] || fail_usage "check requires --session and --pane"
[[ "$REQUIRED_SOURCES" =~ ^[0-9]+$ && "$REQUIRED_SOURCES" -ge 2 && "$REQUIRED_SOURCES" -le 3 ]] || fail_usage "--required-sources must be 2 or 3"

source1="$(probe_activity)"
source2="$(probe_tail)"
source3="null"
sources_probed=2

state="$(jq -r '.state // "" | ascii_upcase' <<<"$source1")"
activity_ok="$(jq -r '.ok' <<<"$source1")"
tail_ok="$(jq -r '.ok' <<<"$source2")"
chevron="$(jq -r '.chevron_visible' <<<"$source2")"
reminder="$(jq -r '.reminder_template' <<<"$source2")"
prov1="$(jq -r '.capture_provenance // ""' <<<"$source1")"
prov2="$(jq -r '.capture_provenance // ""' <<<"$source2")"

if [[ "$REQUIRED_SOURCES" -eq 3 || ( "$state" != "WAITING" && "$chevron" == "true" ) || ( "$state" == "WAITING" && ( "$chevron" != "true" || "$reminder" == "true" ) ) ]]; then
  source3="$(probe_health)"
  sources_probed=3
fi

if [[ "$activity_ok" != "true" || "$tail_ok" != "true" ]]; then
  emit_decision "refuse" "probe_failure" "partial" "one_or_more_required_probes_failed" "$sources_probed" "$source1" "$source2" "$source3"
fi

if [[ "$REQUIRED_SOURCES" -eq 3 && "$(jq -r '.ok' <<<"$source3")" != "true" ]]; then
  emit_decision "refuse" "probe_failure" "partial" "required_third_probe_failed" "$sources_probed" "$source1" "$source2" "$source3"
fi

if [[ "$prov1" != "live" || "$prov2" != "live" ]]; then
  emit_decision "refuse" "stale_capture" "partial" "capture_provenance_not_live" "$sources_probed" "$source1" "$source2" "$source3"
fi

if [[ "$state" == "WAITING" && "$chevron" == "true" && "$reminder" != "true" ]]; then
  emit_decision "allow" "sources_agree_waiting_chevron" "agree" "" "$sources_probed" "$source1" "$source2" "$source3"
fi

if [[ "$state" == "WAITING" && "$reminder" == "true" ]]; then
  emit_decision "refuse" "capture_disagreement_reminder_template" "disagree" "robot_activity_waiting_but_tail_reminder_template" "$sources_probed" "$source1" "$source2" "$source3"
fi

if [[ "$state" == "WAITING" ]]; then
  emit_decision "refuse" "capture_disagreement_no_chevron" "disagree" "robot_activity_waiting_but_tail_has_no_chevron" "$sources_probed" "$source1" "$source2" "$source3"
fi

if [[ "$state" == "ERROR" && "$chevron" == "true" && "$reminder" != "true" ]]; then
  emit_decision "refuse" "capture_disagreement_robot_activity_misclassification" "disagree" "robot_activity_error_but_tail_clean_chevron" "$sources_probed" "$source1" "$source2" "$source3"
fi

emit_decision "refuse" "pane_not_waiting" "disagree" "robot_activity_state_not_waiting" "$sources_probed" "$source1" "$source2" "$source3"
