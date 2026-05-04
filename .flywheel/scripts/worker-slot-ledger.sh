#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="worker-slot-ledger/v1"
TOPOLOGY="${FLYWHEEL_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
session_filter=""
json=0
schema=0
self_test=0

usage() {
  cat <<'EOF'
usage: worker-slot-ledger.sh [--json] [--schema] [--self-test] [--session NAME] [--topology PATH]

Computes fleet worker slot capacity from the latest row per session in
session-topology.jsonl. It separates configured slots from usable slots so
marker-only, metadata-only, and missing-driver sessions do not inflate capacity.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --schema) schema=1; shift ;;
    --self-test) self_test=1; shift ;;
    --session) session_filter="${2:?missing session}"; shift 2 ;;
    --topology) TOPOLOGY="${2:?missing topology path}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

emit_schema() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" '{
    schema_version:$schema_version,
    input:"session-topology.jsonl",
    output_fields:[
      "fleet_worker_slots_total","fleet_worker_slots_usable",
      "fleet_worker_slots_blocked","rows"
    ],
    latest_row_rule:"last JSONL row per session after sort by session then effective_at/line order"
  }'
}

emit_report() {
  if [[ ! -f "$TOPOLOGY" ]]; then
    jq -nc --arg schema_version "$SCHEMA_VERSION" --arg topology "$TOPOLOGY" '{
      schema_version:$schema_version,
      status:"warn",
      topology_path:$topology,
      topology_missing:true,
      fleet_worker_slots_total:0,
      fleet_worker_slots_usable:0,
      fleet_worker_slots_blocked:0,
      rows:[]
    }'
    return 0
  fi

  jq -cs --arg schema_version "$SCHEMA_VERSION" --arg topology "$TOPOLOGY" --arg session_filter "$session_filter" '
    def text($v): (($v // "") | tostring);
    def has_bad_driver:
      (text(.driver_status) | test("marker_only|missing|stale"; "i"))
      or (text(.launchd_plist_status) | test("missing"; "i"));
    def inactive_session:
      (text(.session_status) | test("metadata_only|out_of_fleet|not_live|session_not_found"; "i"))
      or ((text(.session_status) | length) == 0);
    def worker_count: ((.worker_panes // []) | length);
    def blocker_reasons:
      [
        (if has_bad_driver then "driver_unverified" else empty end),
        (if inactive_session then "session_not_live" else empty end),
        (if (text(.agent_mail_status) | test("missing|stale|orphan"; "i")) then "agent_mail_gap" else empty end)
      ];
    [ .[]
      | select(type == "object" and (.session // "") != "")
      | . + {__line:(input_line_number // 0)}
    ]
    | sort_by(.session, (.effective_at // ""), .__line)
    | group_by(.session)
    | map(.[-1])
    | map(select($session_filter == "" or .session == $session_filter))
    | map(
        . as $row
        | (worker_count) as $total
        | (blocker_reasons) as $reasons
        | {
            session:$row.session,
            status:($row.session_status // null),
            driver_status:($row.driver_status // null),
            agent_mail_status:($row.agent_mail_status // null),
            worker_slots_total:$total,
            worker_slots_usable:(if ($total > 0 and ($reasons | length) == 0) then $total else 0 end),
            worker_slots_blocked:(if ($total > 0 and ($reasons | length) > 0) then $total else 0 end),
            blocker_reasons:$reasons,
            worker_panes:($row.worker_panes // [])
          }
      ) as $rows
    | {
        schema_version:$schema_version,
        status:(if ($rows | map(.worker_slots_blocked) | add // 0) > 0 then "warn" else "pass" end),
        topology_path:$topology,
        sessions_count:($rows | length),
        fleet_worker_slots_total:($rows | map(.worker_slots_total) | add // 0),
        fleet_worker_slots_usable:($rows | map(.worker_slots_usable) | add // 0),
        fleet_worker_slots_blocked:($rows | map(.worker_slots_blocked) | add // 0),
        rows:$rows
      }
  ' "$TOPOLOGY"
}

run_self_test() {
  local tmp topology out
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/worker-slot-ledger.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  topology="$tmp/session-topology.jsonl"
  jq -nc '{session:"flywheel",worker_panes:[2,3],session_status:"live",driver_status:"launchd_prompt_driver_present",agent_mail_status:"ok",effective_at:"2026-05-04T00:00:00Z"}' >>"$topology"
  jq -nc '{session:"vrtx",worker_panes:[2,3],session_status:"live_corrected_marker_only_loop",driver_status:"marker_only_missing_launchd_prompt_driver",agent_mail_status:"missing_session_rows",effective_at:"2026-05-04T00:00:00Z"}' >>"$topology"
  out="$("$0" --topology "$topology" --json)"
  jq -nc --arg schema_version "$SCHEMA_VERSION" --argjson report "$out" '{
    schema_version:$schema_version,
    status:(if $report.fleet_worker_slots_total == 4
      and $report.fleet_worker_slots_usable == 2
      and $report.fleet_worker_slots_blocked == 2 then "pass" else "fail" end),
    report:$report
  }'
}

if [[ "$schema" -eq 1 ]]; then
  emit_schema
elif [[ "$self_test" -eq 1 ]]; then
  run_self_test
else
  emit_report
fi
