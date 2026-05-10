#!/usr/bin/env bash
set -euo pipefail

VERSION="plan-state-lens-merge/v1"
JSON_OUT=0
QUIET=0
CMD=""
PLAN=""
LENS=""
ROW_JSON=""

usage() {
  cat <<'USAGE'
usage: plan-state-lens-merge.sh append --plan PATH --lens NAME --row-json JSON [--json] [--quiet]
       plan-state-lens-merge.sh derived --plan PATH [--json] [--quiet]
       plan-state-lens-merge.sh validate --plan PATH [--json] [--quiet]
       plan-state-lens-merge.sh --info|--help|--examples [--json]
USAGE
}

info() {
  jq -nc --arg version "$VERSION" '{
    name:"plan-state-lens-merge",
    schema_version:$version,
    subcommands:["append","derived","validate"],
    canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],
    row_schema:"plan-state-lens-row/v1"
  }'
}

examples() {
  jq -nc '{examples:[
    "plan-state-lens-merge.sh append --plan .flywheel/PLANS/x --lens security --row-json '\''{\"findings_by_severity\":{\"high\":1}}'\'' --json",
    "plan-state-lens-merge.sh derived --plan .flywheel/PLANS/x --json",
    "plan-state-lens-merge.sh validate --plan .flywheel/PLANS/x --json"
  ]}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    append|derived|validate) CMD="$1"; shift ;;
    --plan) PLAN="${2:?--plan requires PATH}"; shift 2 ;;
    --plan=*) PLAN="${1#*=}"; shift ;;
    --lens) LENS="${2:?--lens requires NAME}"; shift 2 ;;
    --lens=*) LENS="${1#*=}"; shift ;;
    --row-json) ROW_JSON="${2:?--row-json requires JSON}"; shift 2 ;;
    --row-json=*) ROW_JSON="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

state_path() {
  [[ -d "$PLAN" ]] && printf '%s/STATE.json\n' "$PLAN" || printf '%s\n' "$PLAN"
}

sha_text() { shasum -a 256 | awk '{print "sha256:" $1}'; }

state_sha() {
  jq -S 'walk(if type=="object" then del(.state_written_sha) else . end)' "$1" | sha_text
}

atomic_write() {
  local path="$1" content="$2" dir tmp
  dir="$(dirname "$path")"
  tmp="$(mktemp "$dir/.STATE.json.XXXXXX")"
  printf '%s\n' "$content" >"$tmp"
  mv "$tmp" "$path"
}

emit() {
  local payload="$1"
  [[ "$QUIET" -eq 1 ]] && return
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"status=\(.status) command=\(.command)"' <<<"$payload"
  fi
}

derived_payload() {
  local state="$1"
  jq -c --arg version "$VERSION" '
    def sev($r; $k): (($r.findings_by_severity[$k] // $r.audit_findings_by_severity[$k] // $r.severity_counts[$k] // 0) | tonumber);
    (.lens_merge_rows // []) as $rows
    | ($rows | map(.supersedes? // empty)) as $sup
    | (reduce $rows[] as $r ({}; if (($sup | index($r.audit_lens_identity_key)) != null) then . else .[$r.lens] = $r end)) as $by_lens
    | ($by_lens | to_entries | map(.value)) as $active
    | {
        schema_version:$version,
        command:"derived",
        status:"pass",
        lens_rows_count:($rows | length),
        effective_lenses_count:($active | length),
        audit_lenses_complete:($active | map(.lens)),
        audit_findings_by_severity:{
          critical:($active | map(sev(.;"critical")) | add // 0),
          high:($active | map(sev(.;"high")) | add // 0),
          medium:($active | map(sev(.;"medium")) | add // 0),
          low:($active | map(sev(.;"low")) | add // 0)
        },
        audit_disposition_by_lens:(reduce $active[] as $r ({}; .[$r.lens] = ($r.audit_disposition // "unknown")))
      }
    | .audit_findings_count = ([.audit_findings_by_severity[]] | add)
  ' "$state"
}

[[ -n "$CMD" ]] || { usage >&2; exit 2; }
[[ -n "$PLAN" ]] || { usage >&2; exit 2; }
STATE="$(state_path)"
[[ -r "$STATE" ]] || { printf 'ERR state file not readable: %s\n' "$STATE" >&2; exit 2; }

case "$CMD" in
  derived)
    payload="$(derived_payload "$STATE")"
    emit "$payload"
    ;;
  validate)
    payload="$(jq -c --arg version "$VERSION" --arg state "$STATE" '
      (.lens_merge_rows // []) as $rows
      | [$rows[]? | select((.lens? | not) or (.ts? | not) or (.state_observed_sha? | not) or (.state_written_sha? | not) or (.audit_lens_identity_key? | not))] as $bad
      | {
          schema_version:$version,
          command:"validate",
          state_path:$state,
          status:(if ($bad|length)==0 then "pass" else "fail" end),
          row_count:($rows|length),
          malformed_count:($bad|length),
          malformed_rows:$bad
        }' "$STATE")"
    emit "$payload"
    [[ "$(jq -r '.status' <<<"$payload")" == pass ]]
    ;;
  append)
    [[ -n "$LENS" && -n "$ROW_JSON" ]] || { usage >&2; exit 2; }
    jq -e 'type == "object"' >/dev/null <<<"$ROW_JSON" || { printf 'ERR row-json must be object\n' >&2; exit 2; }
    observed="$(state_sha "$STATE")"
    supplied="$(jq -r '.state_observed_sha // empty' <<<"$ROW_JSON")"
    race=false; retry_count=0
    if [[ -n "$supplied" && "$supplied" != "$observed" ]]; then
      race=true; retry_count=1; observed="$(state_sha "$STATE")"
    fi
    identity="$(jq -r '.audit_lens_identity_key // empty' <<<"$ROW_JSON")"
    if [[ -z "$identity" ]]; then
      identity="$(printf '%s\n%s\n' "$LENS" "$ROW_JSON" | sha_text)"
    fi
    if jq -e --arg id "$identity" 'any(.lens_merge_rows[]?; .audit_lens_identity_key == $id)' "$STATE" >/dev/null; then
      payload="$(jq -nc --arg version "$VERSION" --arg state "$STATE" --arg id "$identity" '{schema_version:$version,command:"append",status:"already_present",state_path:$state,audit_lens_identity_key:$id,appended:false}')"
      emit "$payload"; exit 0
    fi
    ts="$(jq -r '.ts // empty' <<<"$ROW_JSON")"; [[ -n "$ts" ]] || ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    row="$(jq -c --arg lens "$LENS" --arg ts "$ts" --arg observed "$observed" --arg id "$identity" \
      '. + {schema_version:(.schema_version // "plan-state-lens-row/v1"), lens:$lens, ts:$ts, state_observed_sha:$observed, audit_lens_identity_key:$id}' <<<"$ROW_JSON")"
    candidate="$(jq -c --argjson row "$row" '.lens_merge_rows = ((.lens_merge_rows // []) + [$row])' "$STATE")"
    written="$(jq -S 'walk(if type=="object" then del(.state_written_sha) else . end)' <<<"$candidate" | sha_text)"
    final="$(jq -c --arg written "$written" '.lens_merge_rows[-1].state_written_sha = $written' <<<"$candidate")"
    atomic_write "$STATE" "$final"
    payload="$(jq -nc --arg version "$VERSION" --arg state "$STATE" --arg id "$identity" --argjson race "$race" --argjson retry "$retry_count" --arg observed "$observed" --arg written "$written" '{schema_version:$version,command:"append",status:"appended",state_path:$state,audit_lens_identity_key:$id,race_detected:$race,retry_count:$retry,state_observed_sha:$observed,state_written_sha:$written,appended:true}')"
    emit "$payload"
    ;;
esac
