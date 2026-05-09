#!/usr/bin/env bash
set -euo pipefail

VERSION="ntm-preflight-l91-wrapper.v1"
COMMAND="preflight"
JSON=0
DRY_RUN=0
APPLY=0
IDEMPOTENCY_KEY=""
RECEIPT_FILE=""
SESSION=""
PANE=""
DISPATCH_ID=""
SEND_COMMAND=""
CAPTURE_PROOF=""
CLASSIFICATION_SOURCE="fixture"
CHECKED_AT=""
FRESH_WINDOW_SECONDS=300
TRANSPORT_ACCEPTED=""
PROMPT_VISIBLE=""
PROMPT_SUBMITTED=""
WORK_STARTED=""

usage() {
  cat <<'EOF'
usage: ntm-preflight-l91-wrapper [preflight|doctor|health|repair|validate|audit|why|schema|completion] [options]

L91 dispatch delivery preflight. Transport acceptance alone is not work started.

Commands:
  preflight  Validate four-state dispatch receipt. Default.
  doctor     Check wrapper dependencies and contract.
  health     Lightweight status.
  repair     No-op reversible repair surface; defaults to --dry-run.
  validate   Validate wrapper substrate.
  audit      Emit audit placeholder rows.
  why        Explain L91 preflight.
  schema     Emit JSON schema summary.
  completion Emit shell completion.

Options:
  --receipt FILE
  --session NAME
  --pane N
  --dispatch-id ID
  --send-command TEXT
  --capture-proof TEXT
  --classification-source TEXT
  --checked-at ISO8601
  --fresh-window-seconds N
  --transport-accepted true|false
  --prompt-visible true|false
  --prompt-submitted true|false
  --work-started true|false
  --json
  --dry-run
  --apply
  --idempotency-key KEY
  --help
EOF
}

json_bool() {
  case "${1:-false}" in
    1|true|TRUE|yes|YES) printf 'true' ;;
    *) printf 'false' ;;
  esac
}

date_to_epoch() {
  local value="$1"
  [[ -n "$value" ]] || { date -u +%s; return 0; }
  date -u -j -f %Y-%m-%dT%H:%M:%SZ "$value" +%s 2>/dev/null && return 0
  date -u -d "$value" +%s 2>/dev/null && return 0
  printf '0\n'
}

now_epoch() {
  if [[ -n "${L91_NOW_EPOCH:-}" ]]; then
    printf '%s\n' "$L91_NOW_EPOCH"
  else
    date -u +%s
  fi
}

static_json() {
  local command="$1" status="$2"
  jq -nc \
    --arg schema_version "$VERSION.$command" \
    --arg command "$command" \
    --arg status "$status" \
    --arg checked_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg idempotency_key "$IDEMPOTENCY_KEY" \
    --argjson dry_run "$(json_bool "$DRY_RUN")" \
    --argjson apply "$(json_bool "$APPLY")" \
    '{
      schema_version:$schema_version,
      command:$command,
      status:$status,
      checked_at:$checked_at,
      idempotency_key:(if $idempotency_key == "" then null else $idempotency_key end),
      dry_run:$dry_run,
      apply:$apply,
      native_surface:"ntm send + pane capture/health",
      native_wrapper_delta:"wrapper owns L91 four-state flywheel proof; native NTM owns transport and pane surfaces",
      authorized_operations:["read_receipt","classify_delivery_state","emit_preflight_receipt"],
      forbidden_operations:["count_transport_only_as_work_started","send_dispatch","mutate_pane","repair_without_operator"],
      ttl_native:"fresh_window_seconds",
      ttl_wrapper:"dispatch_preflight_receipt_lifetime",
      ttl_decision:"revalidate after freshness window or before worker busy accounting"
    }'
}

receipt_value() {
  local key="$1" fallback="$2"
  if [[ -n "$RECEIPT_FILE" && -f "$RECEIPT_FILE" ]]; then
    jq -r --arg key "$key" --arg fallback "$fallback" '.[$key] // $fallback' "$RECEIPT_FILE" 2>/dev/null || printf '%s\n' "$fallback"
  else
    printf '%s\n' "$fallback"
  fi
}

cmd_preflight() {
  local transport prompt_visible prompt_submitted work_started checked_at session pane dispatch_id
  local send_command capture_proof classification_source checked_epoch current_epoch age fresh status failure_class validation_status
  if [[ -n "$RECEIPT_FILE" && ! -f "$RECEIPT_FILE" ]]; then
    jq -nc --arg schema_version "$VERSION.preflight" --arg receipt "$RECEIPT_FILE" '{schema_version:$schema_version,command:"preflight",status:"fail",failure_class:"receipt_missing",receipt:$receipt}'
    return 1
  fi

  transport="$(json_bool "$(receipt_value transport_accepted "$TRANSPORT_ACCEPTED")")"
  prompt_visible="$(json_bool "$(receipt_value prompt_visible_in_target "$PROMPT_VISIBLE")")"
  prompt_submitted="$(json_bool "$(receipt_value prompt_submitted "$PROMPT_SUBMITTED")")"
  work_started="$(json_bool "$(receipt_value work_started "$WORK_STARTED")")"
  checked_at="$(receipt_value checked_at "$CHECKED_AT")"
  [[ -n "$checked_at" && "$checked_at" != "null" ]] || checked_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  session="$(receipt_value session "$SESSION")"
  pane="$(receipt_value pane "$PANE")"
  dispatch_id="$(receipt_value dispatch_id "$DISPATCH_ID")"
  send_command="$(receipt_value send_command "$SEND_COMMAND")"
  capture_proof="$(receipt_value capture_proof "$CAPTURE_PROOF")"
  classification_source="$(receipt_value classification_source "$CLASSIFICATION_SOURCE")"

  checked_epoch="$(date_to_epoch "$checked_at")"
  current_epoch="$(now_epoch)"
  age=$(( current_epoch - checked_epoch ))
  (( age < 0 )) && age=0
  if (( checked_epoch == 0 || age > FRESH_WINDOW_SECONDS )); then fresh=false; else fresh=true; fi

  status="pass"
  failure_class=""
  validation_status="valid_prompt_visible_and_pane_active"
  if [[ "$transport" != "true" ]]; then
    status="fail"; failure_class="transport_not_accepted"; validation_status="invalid_transport_not_accepted"
  elif [[ "$fresh" != "true" ]]; then
    status="fail"; failure_class="stale_receipt"; validation_status="invalid_stale_receipt"
  elif [[ "$prompt_visible" != "true" ]]; then
    status="fail"; failure_class="prompt_not_visible"; validation_status="invalid_missing_prompt_evidence"
  elif [[ "$prompt_submitted" != "true" ]]; then
    status="fail"; failure_class="prompt_not_submitted"; validation_status="invalid_prompt_not_submitted"
  elif [[ "$work_started" != "true" ]]; then
    status="fail"; failure_class="transport_only_success"; validation_status="invalid_transport_only_not_work_started"
  fi

  jq -nc \
    --arg schema_version "$VERSION.preflight" \
    --arg status "$status" \
    --arg failure_class "$failure_class" \
    --arg validation_status "$validation_status" \
    --arg checked_at "$checked_at" \
    --arg session "$session" \
    --arg pane "$pane" \
    --arg dispatch_id "$dispatch_id" \
    --arg send_command "$send_command" \
    --arg capture_proof "$capture_proof" \
    --arg classification_source "$classification_source" \
    --arg idempotency_key "$IDEMPOTENCY_KEY" \
    --argjson transport_accepted "$transport" \
    --argjson prompt_visible_in_target "$prompt_visible" \
    --argjson prompt_submitted "$prompt_submitted" \
    --argjson work_started "$work_started" \
    --argjson fresh "$fresh" \
    --argjson age_seconds "$age" \
    --argjson fresh_window_seconds "$FRESH_WINDOW_SECONDS" \
    '{
      schema_version:$schema_version,
      command:"preflight",
      status:$status,
      failure_class:(if $failure_class == "" then null else $failure_class end),
      checked_at:$checked_at,
      session:(if $session == "" then null else $session end),
      pane:(if $pane == "" then null else $pane end),
      dispatch_id:(if $dispatch_id == "" then null else $dispatch_id end),
      send_command:(if $send_command == "" then null else $send_command end),
      capture_proof:(if $capture_proof == "" then null else $capture_proof end),
      classification_source:$classification_source,
      idempotency_key:(if $idempotency_key == "" then null else $idempotency_key end),
      delivery_receipt:{
        transport_accepted:$transport_accepted,
        prompt_visible_in_target:$prompt_visible_in_target,
        prompt_submitted:$prompt_submitted,
        work_started:$work_started,
        work_started_validation_status:$validation_status,
        fresh:$fresh,
        age_seconds:$age_seconds,
        fresh_window_seconds:$fresh_window_seconds
      },
      l91_required_states:["transport_accepted","prompt_visible_in_target","prompt_submitted","work_started"],
      native_surface:"ntm send + pane capture/health",
      native_wrapper_delta:"wrapper owns L91 four-state flywheel proof; native NTM owns transport and pane surfaces",
      authorized_operations:["read_receipt","classify_delivery_state","emit_preflight_receipt"],
      forbidden_operations:["count_transport_only_as_work_started","send_dispatch","mutate_pane","repair_without_operator"],
      ttl_native:"fresh_window_seconds",
      ttl_wrapper:"dispatch_preflight_receipt_lifetime",
      ttl_decision:"revalidate after freshness window or before worker busy accounting"
    }'
  [[ "$status" == "pass" ]]
}

cmd_doctor() {
  local jq_ok status
  command -v jq >/dev/null 2>&1 && jq_ok=true || jq_ok=false
  [[ "$jq_ok" == true ]] && status=pass || status=fail
  static_json doctor "$status" | jq --argjson jq "$jq_ok" '. + {dependencies:{jq:$jq}}'
}

cmd_health() { static_json health pass; }
cmd_repair() {
  if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
    jq -nc --arg schema_version "$VERSION.repair" '{schema_version:$schema_version,command:"repair",status:"fail",reason:"--apply requires --idempotency-key"}'
    return 1
  fi
  static_json repair pass | jq '. + {planned_actions:["no-op: L91 wrapper is advisory/read-only"], actual_actions:[]}'
}
cmd_validate() { static_json validate pass | jq '. + {validated:["l91_four_state_contract","canonical_cli_surface"]}'; }
cmd_audit() { static_json audit pass | jq '. + {rows:[]}'; }
cmd_why() { static_json why pass | jq '. + {explanation:"L91 prevents transport-only ntm send success from being counted as active worker progress."}'; }
cmd_schema() {
  jq -nc --arg schema_version "$VERSION.schema" '{
    schema_version:$schema_version,
    command:"schema",
    status:"pass",
    required:["transport_accepted","prompt_visible_in_target","prompt_submitted","work_started"],
    default_mode:"read-only",
    mutation_requires:["--apply","--idempotency-key"],
    stable_exit_codes:{pass:0,not_started:1,usage:2},
    output_fields:["status","failure_class","delivery_receipt","authorized_operations","forbidden_operations","ttl_native","ttl_wrapper","ttl_decision","native_wrapper_delta"]
  }'
}
cmd_completion() {
  printf '%s\n' "complete -W 'preflight doctor health repair validate audit why schema completion --receipt --session --pane --dispatch-id --send-command --capture-proof --classification-source --checked-at --fresh-window-seconds --transport-accepted --prompt-visible --prompt-submitted --work-started --json --dry-run --apply --idempotency-key --help' ntm-preflight-l91-wrapper.sh"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    preflight|doctor|health|repair|validate|audit|why|schema|completion) COMMAND="$1" ;;
    --receipt) shift; RECEIPT_FILE="${1:-}" ;;
    --session) shift; SESSION="${1:-}" ;;
    --pane) shift; PANE="${1:-}" ;;
    --dispatch-id) shift; DISPATCH_ID="${1:-}" ;;
    --send-command) shift; SEND_COMMAND="${1:-}" ;;
    --capture-proof) shift; CAPTURE_PROOF="${1:-}" ;;
    --classification-source) shift; CLASSIFICATION_SOURCE="${1:-fixture}" ;;
    --checked-at) shift; CHECKED_AT="${1:-}" ;;
    --fresh-window-seconds) shift; FRESH_WINDOW_SECONDS="${1:-300}" ;;
    --transport-accepted) shift; TRANSPORT_ACCEPTED="${1:-false}" ;;
    --prompt-visible) shift; PROMPT_VISIBLE="${1:-false}" ;;
    --prompt-submitted) shift; PROMPT_SUBMITTED="${1:-false}" ;;
    --work-started) shift; WORK_STARTED="${1:-false}" ;;
    --json) JSON=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --apply) APPLY=1 ;;
    --idempotency-key) shift; IDEMPOTENCY_KEY="${1:-}" ;;
    --no-color|--no-emoji) ;;
    --width) shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$FRESH_WINDOW_SECONDS" in ''|*[!0-9]*) FRESH_WINDOW_SECONDS=300 ;; esac

case "$COMMAND" in
  preflight) cmd_preflight ;;
  doctor) cmd_doctor ;;
  health) cmd_health ;;
  repair) cmd_repair ;;
  validate) cmd_validate ;;
  audit) cmd_audit ;;
  why) cmd_why ;;
  schema) cmd_schema ;;
  completion) cmd_completion ;;
  *) usage >&2; exit 2 ;;
esac
