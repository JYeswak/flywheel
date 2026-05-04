#!/usr/bin/env bash
set -euo pipefail

VERSION="peer-orch-blocker-watch/v1"
DEFAULT_LEDGER="${FLYWHEEL_CROSS_ORCH_COORDINATION_LEDGER:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"
MODE="doctor"
LEDGER="$DEFAULT_LEDGER"
NOW="${FLYWHEEL_PEER_ORCH_BLOCKER_NOW:-}"
THRESHOLD_SECONDS="${FLYWHEEL_PEER_ORCH_BLOCKER_THRESHOLD_SECONDS:-300}"
JSON=0

usage() {
  cat <<'USAGE'
Usage: peer-orch-blocker-watch.sh [--doctor|--validate|--schema|--examples] [--json] [--ledger PATH] [--now ISO8601] [--threshold-seconds N]

Scans cross-orch coordination JSONL for flywheel-class blockers that have not
been acknowledged by flywheel:1 within the threshold.
USAGE
}

schema() {
  jq -nc --arg version "$VERSION" '{
    schema_version:$version,
    input:"JSONL rows from ~/.local/state/flywheel/cross-orch-coordination.jsonl",
    blocker_type_enum:["flywheel_class","peer_class","external","unknown"],
    output_fields:[
      "status",
      "peer_orch_blocker_age_seconds",
      "stale_blockers_count",
      "stale_blockers",
      "malformed_rows_count",
      "signals"
    ],
    stale_when:"blocker_type=flywheel_class and age_seconds >= threshold_seconds and no flywheel:1 ack row targets that peer after blocker ts"
  }'
}

examples() {
  cat <<'EXAMPLES'
peer-orch-blocker-watch.sh --doctor --json
peer-orch-blocker-watch.sh --ledger /tmp/cross-orch.jsonl --now 2026-05-04T00:10:01Z --json
peer-orch-blocker-watch.sh --validate --ledger /tmp/cross-orch.jsonl --json
EXAMPLES
}

iso_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

json_str() {
  jq -Rn --arg v "$1" '$v'
}

normalize_ledger() {
  local ledger="$1" out="$2" malformed="$3" line_no=0 line
  : >"$out"
  : >"$malformed"
  [[ -f "$ledger" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    [[ -n "${line//[[:space:]]/}" ]] || continue
    if jq -e . >/dev/null 2>&1 <<<"$line"; then
      jq -c --argjson line_no "$line_no" '. + {__line:$line_no}' <<<"$line" >>"$out"
    else
      jq -nc --argjson line_no "$line_no" --arg raw "$line" '{line:$line_no, raw:$raw}' >>"$malformed"
    fi
  done <"$ledger"
}

run_scan() {
  local tmp valid malformed now_json threshold_json
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/peer-orch-blocker-watch.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  valid="$tmp/valid.jsonl"
  malformed="$tmp/malformed.jsonl"
  normalize_ledger "$LEDGER" "$valid" "$malformed"
  NOW="${NOW:-$(iso_now)}"
  now_json="$(json_str "$NOW")"
  threshold_json="$THRESHOLD_SECONDS"
  jq -s \
    --slurpfile malformed "$malformed" \
    --arg version "$VERSION" \
    --arg ledger "$LEDGER" \
    --argjson now "$now_json" \
    --argjson threshold "$threshold_json" '
    def epoch($v):
      ($v // "" | tostring | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601?) // null;
    def text_fields:
      [
        .blocker_type,
        .blocker_class,
        .trauma_class,
        .doctor_error,
        .error,
        .reason,
        .event,
        .action,
        .context
      ] | map(. // "" | tostring | ascii_downcase) | join(" ");
    def inferred_type:
      if (.blocker_type // "") != "" then .blocker_type
      elif (text_fields | test("canonical_doctrine|missing l-rule|missing_l-rule|missing doctor|doctor signal|canonical contract|missing skill|flywheel")) then "flywheel_class"
      elif (text_fields | test("external|upstream|vendor|credential|quota")) then "external"
      elif (text_fields | test("worker|repo|mission|local")) then "peer_class"
      else "unknown" end;
    def sender: (.sender // .from // .source_session // .source // "");
    def target_values:
      [(.receiver // empty), (.target // empty), (.target_session // empty), (.to // empty)]
      | flatten | map(tostring);
    def scalar_text:
      if type == "array" then ((.[0] // "") | tostring)
      elif type == "object" then ""
      else (. // "" | tostring) end;
    def peer_id:
      [
        .sender,
        .from,
        .source_session,
        .session,
        .target_session,
        .receiver,
        .to
      ]
      | map(scalar_text)
      | map(select(. != ""))
      | (.[0] // "")
      | tostring
      | sub(" .*$"; "")
      | sub(":.*$"; "");
    def is_blocker:
      ((inferred_type == "flywheel_class")
       and ((peer_id != "") and (peer_id != "flywheel"))
       and ((sender | tostring | startswith("flywheel:1")) | not)
       and (
         ((.blocker_type // "") != "" and ((.event // "" | tostring | ascii_downcase | test("ack|unblock|fixed|ratified|broadcast")) | not))
         or (.event // "" | tostring | ascii_downcase | test("blocker|blocked|xpane_blocker|doctor_error|canonical_doctrine_drift"))
         or ((.doctor_error // "") != "")
       ));
    def is_flywheel_ack_for($peer; $ts_epoch):
      ((epoch(.ts) // -1) >= $ts_epoch)
      and ((sender | tostring | startswith("flywheel:1")) or ((.from // "" | tostring) == "flywheel:1"))
      and ((target_values | any(. == $peer or startswith($peer + ":"))) or ((.event // "" | tostring | ascii_downcase | test("ack|unblock|response|fixed|ratified|broadcast")) and ((.to // "" | tostring | contains($peer)) or (.target // "" | tostring | contains($peer)))));
    def blocker_row($all_rows):
      . as $b
      | (epoch($b.ts) // null) as $bts
      | (peer_id) as $peer
      | {
          line:$b.__line,
          ts:$b.ts,
          peer:$peer,
          blocker_type:inferred_type,
          blocker_class:($b.blocker_class // $b.doctor_error // $b.trauma_class // $b.event // "unknown"),
          event:($b.event // null),
          age_seconds:(if $bts == null then null else ((epoch($now) // 0) - $bts) end),
          threshold_seconds:$threshold,
          acked:(if ($bts == null or $peer == "") then false else any($all_rows[]; is_flywheel_ack_for($peer; $bts)) end),
          proposed_action:($b.proposed_action // $b.action // null),
          requested_owner:($b.requested_owner // "flywheel:1")
        };
    . as $rows
    | ($rows | map(select(is_blocker) | blocker_row($rows))) as $blockers
    | ($blockers | map(select((.acked | not) and ((.age_seconds // 0) >= .threshold_seconds)))) as $stale
    | {
        schema_version:$version,
        status:(if ($stale|length) > 0 then "fail" elif ($malformed|length) > 0 then "warn" else "pass" end),
        ledger:$ledger,
        checked_rows:($rows|length),
        malformed_rows_count:($malformed|length),
        malformed_rows:$malformed,
        threshold_seconds:$threshold,
        peer_orch_blocker_age_seconds:(($stale | map(.age_seconds // 0) | max) // 0),
        stale_blockers_count:($stale|length),
        stale_blockers:$stale,
        blockers:$blockers,
        signals:[{
          name:"peer_orch_blocker_age_seconds",
          producer:"~/.local/state/flywheel/cross-orch-coordination.jsonl via .flywheel/scripts/peer-orch-blocker-watch.sh",
          measurement:"max age of unacked flywheel_class blocker rows",
          consumer:"flywheel-loop doctor JSON and peer blocker auto-promotion",
          threshold:">=300",
          gate_behavior:"fail when stale_blockers_count > 0",
          promotion_path:"L75 ORCH-BLOCKER-COORDINATION -> flywheel-vc3e"
        }]
      }' "$valid"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --doctor) MODE="doctor"; shift ;;
    --validate) MODE="validate"; shift ;;
    --schema) MODE="schema"; shift ;;
    --examples) MODE="examples"; shift ;;
    --json) JSON=1; shift ;;
    --ledger) LEDGER="${2:-}"; shift 2 ;;
    --now) NOW="${2:-}"; shift 2 ;;
    --threshold-seconds) THRESHOLD_SECONDS="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  schema) schema ;;
  examples) examples ;;
  doctor|validate)
    result="$(run_scan)"
    if [[ "$JSON" -eq 1 ]]; then
      printf '%s\n' "$result"
    else
      jq -r '"status=\(.status) peer_orch_blocker_age_seconds=\(.peer_orch_blocker_age_seconds) stale_blockers_count=\(.stale_blockers_count)"' <<<"$result"
    fi
    if [[ "$MODE" == "validate" ]]; then
      [[ "$(jq -r '.malformed_rows_count' <<<"$result")" == "0" ]] || exit 1
    fi
    ;;
esac
