#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="worker-lifecycle-transaction/v1"
EXPECTED_CODEX_COMMAND="codex --dangerously-bypass-approvals-and-sandbox"
RECEIPT_DIR="${FLYWHEEL_WORKER_LIFECYCLE_RECEIPTS:-$HOME/.local/state/flywheel/worker-lifecycle/receipts}"

json=0
schema=0
self_test=0
receipt_paths=()

usage() {
  cat <<'EOF'
usage: worker-lifecycle-transaction.sh [--json] [--schema] [--self-test] [--receipt PATH ...]

Validates worker lifecycle receipts before spawn/respawn/relaunch/inject actions
are treated as verified capacity. Without --receipt, scans
$FLYWHEEL_WORKER_LIFECYCLE_RECEIPTS or ~/.local/state/flywheel/worker-lifecycle/receipts.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --schema) schema=1; shift ;;
    --self-test) self_test=1; shift ;;
    --receipt) receipt_paths+=("${2:?missing receipt path}"); shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

emit_schema() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" --arg expected "$EXPECTED_CODEX_COMMAND" '{
    schema_version:$schema_version,
    required_receipt_fields:[
      "transaction_id","session","pane","action","pre_capture_ts","post_capture_ts",
      "canonical_operation","verification_status"
    ],
    expected_codex_command_shape:$expected,
    output_fields:[
      "worker_respawn_unverified_count","worker_spawn_shape_drift_count",
      "worker_lifecycle_receipt_missing_count","rows"
    ]
  }'
}

classify_receipt() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    jq -nc --arg path "$path" '{
      path:$path,
      valid_json:false,
      missing_required_fields:["receipt_file"],
      unverified:true,
      spawn_shape_drift:false,
      reason:"receipt_file_missing"
    }'
    return 0
  fi

  if ! jq -e . "$path" >/dev/null 2>&1; then
    jq -nc --arg path "$path" '{
      path:$path,
      valid_json:false,
      missing_required_fields:["valid_json"],
      unverified:true,
      spawn_shape_drift:false,
      reason:"invalid_json"
    }'
    return 0
  fi

  jq -c --arg path "$path" --arg expected "$EXPECTED_CODEX_COMMAND" '
    . as $r
    | (["transaction_id","session","pane","action","pre_capture_ts","post_capture_ts",
        "canonical_operation","verification_status"]
       | map(select((($r[.] // "") | tostring | length) == 0))) as $missing
    | (((($r.runtime // $r.agent_type // $r.kind // "") | ascii_downcase) | contains("codex"))
       and (($r.action // "") | test("spawn|respawn|relaunch|inject"))
       and (($r.command_shape // "") != $expected)) as $shape_drift
    | {
        path:$path,
        valid_json:true,
        transaction_id:($r.transaction_id // null),
        session:($r.session // null),
        pane:($r.pane // null),
        action:($r.action // null),
        runtime:($r.runtime // $r.agent_type // $r.kind // null),
        verification_status:($r.verification_status // "missing"),
        command_shape:($r.command_shape // null),
        missing_required_fields:$missing,
        unverified:((($r.verification_status // "") != "verified")
          or ((($r.post_capture_ts // "") | tostring | length) == 0)
          or (($missing | length) > 0)),
        spawn_shape_drift:$shape_drift
      }
  ' "$path"
}

emit_report() {
  local rows="[]" paths=()
  if [[ "${#receipt_paths[@]}" -gt 0 ]]; then
    paths=("${receipt_paths[@]}")
  elif [[ -d "$RECEIPT_DIR" ]]; then
    shopt -s nullglob
    paths=("$RECEIPT_DIR"/*.json)
    shopt -u nullglob
  fi

  local path row
  for path in "${paths[@]}"; do
    row="$(classify_receipt "$path")"
    rows="$(jq -c --argjson row "$row" '. + [$row]' <<<"$rows")"
  done

  jq -nc --arg schema_version "$SCHEMA_VERSION" --arg receipt_dir "$RECEIPT_DIR" --argjson rows "$rows" '
    ($rows | map(select(.unverified == true)) | length) as $unverified
    | ($rows | map(select(.spawn_shape_drift == true)) | length) as $drift
    | ($rows | map(select(.valid_json != true)) | length) as $missing
    | {
        schema_version:$schema_version,
        status:(if ($unverified + $drift + $missing) > 0 then "warn" else "pass" end),
        receipt_dir:$receipt_dir,
        receipt_count:($rows | length),
        worker_respawn_unverified_count:$unverified,
        worker_spawn_shape_drift_count:$drift,
        worker_lifecycle_receipt_missing_count:$missing,
        rows:$rows
      }'
}

run_self_test() {
  local tmp good bad out
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/worker-lifecycle.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  good="$tmp/good.json"
  bad="$tmp/bad.json"

  jq -nc '{
    transaction_id:"tx-good",session:"flywheel",pane:2,action:"respawn",
    runtime:"codex",command_shape:"codex --dangerously-bypass-approvals-and-sandbox",
    pre_capture_ts:"2026-05-04T00:00:00Z",post_capture_ts:"2026-05-04T00:00:10Z",
    canonical_operation:"ntm send",verification_status:"verified"
  }' >"$good"
  jq -nc '{
    transaction_id:"tx-bad",session:"flywheel",pane:3,action:"respawn",
    runtime:"codex",command_shape:"codex",pre_capture_ts:"2026-05-04T00:00:00Z",
    canonical_operation:"manual",verification_status:"pending"
  }' >"$bad"

  out="$(FLYWHEEL_WORKER_LIFECYCLE_RECEIPTS="$tmp" "$0" --json)"
  jq -nc --arg schema_version "$SCHEMA_VERSION" --argjson report "$out" '{
    schema_version:$schema_version,
    status:(if $report.worker_respawn_unverified_count == 1
      and $report.worker_spawn_shape_drift_count == 1
      and $report.receipt_count == 2 then "pass" else "fail" end),
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
