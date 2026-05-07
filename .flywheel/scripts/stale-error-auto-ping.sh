#!/usr/bin/env bash
set -euo pipefail

VERSION="stale-error-auto-ping.v1"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION="flywheel"
PANES="2,3,4"
JSON_OUT=0
APPLY=0
DRY_RUN=1
WATCH=0
INTERVAL_SECONDS=300
ERRORS_FILE=""
PING_TEXT="ping: stale-error auto-recovery probe -- reply alive if read this"

usage() { cat <<'USAGE'
Usage: stale-error-auto-ping.sh [doctor|health|repair|validate] [--session NAME] [--panes 2,3,4] [--dry-run|--apply] [--watch] [--json]
       stale-error-auto-ping.sh validate errors --errors-file PATH [--json]
       stale-error-auto-ping.sh --info [--json] | --examples | --version
Finds temporary L87 stale-error candidates from native `ntm errors --json`.
Apply sends only bounded no-op `ntm send --no-cass-check` pings. Default is dry-run.
USAGE
}
examples() { printf '%s\n' "Examples:" "  .flywheel/scripts/stale-error-auto-ping.sh --json" "  .flywheel/scripts/stale-error-auto-ping.sh --apply --json --session flywheel --panes 2,3,4" "  .flywheel/scripts/stale-error-auto-ping.sh validate errors --errors-file /tmp/ntm-errors.json --json"; }
json_msg() { jq -nc --arg schema_version "$VERSION" --arg status "$1" --arg message "$2" '{schema_version:$schema_version,status:$status,message:$message}'; }

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg schema_version "$VERSION" --arg ntm "$NTM_BIN" --arg session "$SESSION" --arg panes "$PANES" --argjson interval "$INTERVAL_SECONDS" \
      '{schema_version:$schema_version,mode:"info",ntm:$ntm,default_session:$session,default_panes:$panes,default_interval_seconds:$interval,mutation_default:"dry-run",candidate_source:"ntm errors --json",apply_transport:"ntm send --no-cass-check"}'
  else
    printf '%s\nntm=%s\ndefault_session=%s\ndefault_panes=%s\ncandidate_source=ntm errors --json\nmutation_default=dry-run\n' "$VERSION" "$NTM_BIN" "$SESSION" "$PANES"
  fi
}

panes_to_json() { jq -nc --arg panes "$PANES" '$panes | split(",") | map(select(length > 0) | tonumber)'; }

errors_json() {
  if [[ -n "$ERRORS_FILE" ]]; then
    cat "$ERRORS_FILE"
  else
    "$NTM_BIN" errors "$SESSION" --panes "$PANES" --cod --json 2>/dev/null || "$NTM_BIN" "--robot-activity=$SESSION" --activity-type=codex,claude --json
  fi
}

candidates_filter() {
  local panes_json="$1"
  jq --argjson panes "$panes_json" '
    def hay: ([.content // ""] + (.context // [])) | map(tostring) | join("\n");
    def rows: if ((.errors // null) | type) == "array" then .errors[] else (.agents // [])[] | {pane_index:(.pane_idx // .pane),agent_type:(.agent_type // "codex"),match_type:((.detected_patterns // []) | join(",")),content:((.detected_patterns // []) | join(" ")),context:(.detected_patterns // []),timestamp:(.capture_collected_at // null),capture_provenance:(.capture_provenance // null),state:(.state // null)} end;
    [rows | (.pane_index // .pane_idx // .pane) as $p
      | select(($panes | index($p)) and (((.agent_type // "") | ascii_downcase) == "codex"))
      | select((.capture_provenance // "live") == "live" and (.state // "ERROR") == "ERROR")
      | select((hay | test("codex_chevron_prompt")) and ((((.match_type // "") | ascii_downcase) | test("failed|api|error")) or (hay | test("failed_text|api_error"))))
      | {pane_idx:$p,agent_type:(.agent_type // "codex"),match_type:(.match_type // null),content:(.content // null),context:(.context // []),timestamp:(.timestamp // null),source:"ntm_errors_json"}]'
}

run_once() {
  local started panes_json before_file after_file before_candidates after_candidates sends
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  panes_json="$(panes_to_json)"
  before_file="$(mktemp "${TMPDIR:-/tmp}/stale-error-before.XXXXXX")"
  after_file="$(mktemp "${TMPDIR:-/tmp}/stale-error-after.XXXXXX")"

  errors_json >"$before_file"
  before_candidates="$(candidates_filter "$panes_json" <"$before_file")"
  sends=0
  if [[ "$APPLY" -eq 1 ]]; then
    while IFS= read -r pane; do
      [[ -n "$pane" ]] || continue
      "$NTM_BIN" send "$SESSION" --pane="$pane" --no-cass-check "$PING_TEXT" >/dev/null
      sends=$((sends + 1))
    done < <(jq -r '.[].pane_idx' <<<"$before_candidates")
  fi
  errors_json >"$after_file"
  after_candidates="$(candidates_filter "$panes_json" <"$after_file")"

  jq -nc --arg schema_version "$VERSION" --arg ts "$started" --arg session "$SESSION" --argjson panes "$panes_json" \
    --argjson dry_run "$([[ "$DRY_RUN" -eq 1 ]] && echo true || echo false)" --argjson apply "$([[ "$APPLY" -eq 1 ]] && echo true || echo false)" --arg ping_text "$PING_TEXT" \
    --argjson before "$before_candidates" --argjson after "$after_candidates" --argjson sends "$sends" \
    '{schema_version:$schema_version,ts:$ts,mode:"run",session:$session,panes:$panes,candidate_source:"ntm errors --json",dry_run:$dry_run,apply:$apply,stale_error_candidate_count:($before|length),stale_error_candidates:$before,planned_actions:($before|map({action:"ntm_send_ping",pane:.pane_idx,text:$ping_text})),actual_actions:(if $apply then ($before|map({action:"ntm_send_ping",pane:.pane_idx,text:$ping_text})) else [] end),send_count:$sends,post_recheck_candidate_count:($after|length),post_recheck_candidates:$after,recovered_count:(($before|length)-($after|length)),status:(if (($before|length)==0) then "no_candidates" elif $apply and (($after|length)<($before|length)) then "recovered_or_improved" elif $apply then "sent_recheck_still_candidate" else "dry_run_candidates" end)}'
  rm -f "$before_file" "$after_file"
}

main_loop() { while :; do run_once; [[ "$WATCH" -eq 1 ]] || break; sleep "$INTERVAL_SECONDS"; done; }

for arg in "$@"; do [[ "$arg" == "--json" ]] && JSON_OUT=1; done
COMMAND="run"
if [[ $# -gt 0 ]]; then
  case "$1" in doctor|health|repair|validate) COMMAND="$1"; shift ;; esac
fi

while [[ $# -gt 0 ]]; do case "$1" in
  --session) SESSION="${2:?--session requires NAME}"; shift 2 ;;
  --panes) PANES="${2:?--panes requires list}"; shift 2 ;;
  --errors-file|--activity-file) ERRORS_FILE="${2:?--errors-file requires PATH}"; shift 2 ;;
  --dry-run) APPLY=0; DRY_RUN=1; shift ;; --apply) APPLY=1; DRY_RUN=0; shift ;;
  --json) JSON_OUT=1; shift ;; --watch) WATCH=1; shift ;;
  --interval-seconds) INTERVAL_SECONDS="${2:?--interval-seconds requires N}"; shift 2 ;;
  --ping-text) PING_TEXT="${2:?--ping-text requires TEXT}"; shift 2 ;;
  --info) emit_info; exit 0 ;; --examples) examples; exit 0 ;;
  --version) printf '%s\n' "$VERSION"; exit 0 ;; --help|-h) usage; exit 0 ;;
  errors|activity) shift ;; *) printf 'ERR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
esac; done

case "$COMMAND" in
  doctor|health)
    if command -v jq >/dev/null && [[ -x "$NTM_BIN" || -n "$ERRORS_FILE" ]]; then
      [[ "$JSON_OUT" -eq 1 ]] && jq -nc --arg schema_version "$VERSION" --arg mode "$COMMAND" '{schema_version:$schema_version,mode:$mode,status:"pass",checks:{jq:true,ntm:true}}' || printf '%s pass\n' "$COMMAND"
      exit 0
    fi
    [[ "$JSON_OUT" -eq 1 ]] && json_msg fail "missing jq or ntm" || printf '%s fail\n' "$COMMAND"
    exit 1
    ;;
  repair|run) main_loop ;;
  validate) errors_json | jq empty; [[ "$JSON_OUT" -eq 1 ]] && json_msg pass "errors JSON valid" || printf 'errors JSON valid\n' ;;
esac
