#!/usr/bin/env bash
set -euo pipefail

VERSION="recovery-escape-then-reprompt.v1.0.0"
SCHEMA_VERSION="recovery-receipt.v1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
NTM_BIN="${RECOVERY_NTM_BIN:-$HOME/.local/bin/ntm}"
LEDGER="${RECOVERY_LEDGER:-$HOME/.local/state/flywheel/codex-stuck-detector.jsonl}"
FUCKUP_LOG="${RECOVERY_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
DISPATCH_LOG="${RECOVERY_DISPATCH_LOG:-$HOME/.local/state/flywheel/dispatch-log.jsonl}"
REPO_DISPATCH_LOG="${RECOVERY_REPO_DISPATCH_LOG:-$REPO_ROOT/.flywheel/dispatch-log.jsonl}"
RECEIPT_DIR="${RECOVERY_RECEIPT_DIR:-$HOME/.local/state/flywheel/recovery-receipts}"
SESSION=""
PANE=""
MAX_STAGE1=2
MAX_STAGE2=2
ESCALATE=1
DRY_RUN=1
APPLY=0
JSON_OUT=0
MODE="run"

usage() {
  cat <<'EOF'
usage:
  recovery-escape-then-reprompt.sh --session NAME --pane N [--dry-run|--apply] [--json]
  recovery-escape-then-reprompt.sh --schema|--explain|--help

flags:
  --max-retry-stage1 N       default 2
  --max-retry-stage2 N       default 2
  --escalate-to-respawn      default true
  --no-escalate-to-respawn
EOF
}

now_iso() { printf '%s\n' "${RECOVERY_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"; }

schema_json() {
  if [[ -f "$REPO_ROOT/.flywheel/validation-schema/v1/recovery-receipt.schema.json" ]]; then
    jq -c . "$REPO_ROOT/.flywheel/validation-schema/v1/recovery-receipt.schema.json"
  else
    jq -nc '{schema_version:"recovery-receipt.schema.v1",required:["schema_version","ts","session","pane","stage_succeeded","recovery_succeeded"]}'
  fi
}

explain_json() {
  jq -nc '{name:"recovery-escape-then-reprompt",stages:["escape_and_verify","reprompt_and_verify_thinking","bounded_respawn_escalation"],safety:"dry-run by default; pane mutation requires --apply"}'
}

append_jsonl_atomic() {
  local path="$1" row="$2" tmp
  mkdir -p "$(dirname "$path")"
  tmp="${path}.$$.$RANDOM.tmp"
  if [[ -f "$path" ]]; then
    cp "$path" "$tmp"
  else
    : >"$tmp"
  fi
  jq -e 'type == "object"' >/dev/null <<<"$row"
  printf '%s\n' "$row" >>"$tmp"
  mv "$tmp" "$path"
}

capture_text() {
  if [[ -n "${RECOVERY_MOCK_CAPTURE:-}" ]]; then printf '%s\n' "$RECOVERY_MOCK_CAPTURE"; return 0; fi
  "$NTM_BIN" copy "${SESSION}:${PANE}" -l 80 2>/dev/null || true
}

has_spinner() { rg -q 'Waiting for background terminal \([0-9]+m [0-9]+s [·•] esc to interrupt\)' <<<"$1"; }
has_chevron() { rg -q '^› ' <<<"$1"; }

mock_stage1_text() {
  case "${RECOVERY_MOCK_SCENARIO:-}" in
    stage1_success) printf '› Ready\n' ;;
    *) printf '• Waiting for background terminal (7m 01s • esc to interrupt)\n› Explain this codebase\n' ;;
  esac
}

activity_state() {
  case "${RECOVERY_MOCK_SCENARIO:-}" in
    stage2_success) printf 'THINKING\n'; return 0 ;;
    stage1_success) printf 'WAITING\n'; return 0 ;;
    stage3) printf 'WAITING\n'; return 0 ;;
    stage3|*) ;;
  esac
  "$NTM_BIN" "--robot-activity=$SESSION" --json 2>/dev/null \
    | jq -r --argjson pane "$PANE" '.agents[]? | select((.pane_idx // .pane) == $pane) | .state' \
    | tail -n 1
}

send_escape() {
  if [[ "$APPLY" -ne 1 ]]; then return 0; fi
  if "$NTM_BIN" send-key "$SESSION" "--pane=$PANE" Escape >/dev/null 2>&1; then return 0; fi
  "$NTM_BIN" send "$SESSION" "--pane=$PANE" --enter=false $'\e' >/dev/null 2>&1
}

last_dispatch_prompt() {
  local log path
  for log in "$DISPATCH_LOG" "$REPO_DISPATCH_LOG"; do
    [[ -f "$log" ]] || continue
    path="$(jq -r --arg session "$SESSION" --argjson pane "$PANE" '
      select((.target_session // .session) == $session and ((.target_pane // .pane) == $pane))
      | .dispatch_file // .prompt_path // .message_file // empty
    ' "$log" 2>/dev/null | tail -n 1)"
    if [[ -n "$path" && -f "$path" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  done
  return 1
}

send_prompt() {
  local prompt_path
  prompt_path="$(last_dispatch_prompt || true)"
  [[ -n "$prompt_path" ]] || return 1
  if [[ "$APPLY" -eq 1 ]]; then
    "$NTM_BIN" send "$SESSION" "--pane=$PANE" --file "$prompt_path" --no-cass-check >/dev/null
  fi
  printf '%s\n' "$prompt_path"
}

write_receipts() {
  local row="$1"
  [[ "$APPLY" -eq 1 ]] || return 0
  append_jsonl_atomic "$LEDGER" "$row"
  append_jsonl_atomic "$FUCKUP_LOG" "$(jq -c '. + {schema_version:"flywheel-fuckup-log.v1",class:"post-callback-reminder-template-recovery",severity:(if .recovery_succeeded then "low" else "high" end),what_happened:"recovery-escape-then-reprompt attempted staged recovery"}' <<<"$row")"
}

run_recovery() {
  [[ -n "$SESSION" && -n "$PANE" ]] || { usage >&2; exit 2; }
  local ts stage="none" success=false stage1=0 stage2=0 s1_count=0 s2_count=0 prompt_path="" text state receipt_path row planned='[]' actual='[]'
  ts="$(now_iso)"
  mkdir -p "$RECEIPT_DIR"
  receipt_path="$RECEIPT_DIR/${SESSION}-${PANE}-${ts//[:]/}.json"
  for ((stage1=1; stage1<=MAX_STAGE1; stage1++)); do
    planned="$(jq -c '. + ["stage1_escape"]' <<<"$planned")"
    send_escape || true
    [[ "$APPLY" -eq 1 ]] && sleep 3
    text="$(mock_stage1_text)"
    if [[ -z "${RECOVERY_MOCK_SCENARIO:-}" ]]; then text="$(capture_text)"; fi
    if has_chevron "$text" && ! has_spinner "$text"; then stage=1; success=true; actual="$(jq -c '. + ["stage1_escape_verified"]' <<<"$actual")"; break; fi
  done
  if [[ "$success" != true ]]; then
    for ((stage2=1; stage2<=MAX_STAGE2; stage2++)); do
      planned="$(jq -c '. + ["stage2_reprompt"]' <<<"$planned")"
      prompt_path="$(send_prompt || true)"
      [[ "$APPLY" -eq 1 ]] && sleep 5
      state="$(activity_state || true)"
      if [[ "$state" == "THINKING" ]]; then stage=2; success=true; actual="$(jq -c '. + ["stage2_reprompt_thinking"]' <<<"$actual")"; break; fi
    done
  fi
  if [[ "$success" != true && "$ESCALATE" -eq 1 ]]; then
    stage=3
    planned="$(jq -c '. + ["stage3_respawn_escalation"]' <<<"$planned")"
    if [[ "$APPLY" -eq 1 ]]; then "$NTM_BIN" respawn "$SESSION" "--panes=$PANE" >/dev/null 2>&1 || true; fi
  fi
  s1_count="$stage1"
  s2_count="$stage2"
  (( s1_count > MAX_STAGE1 )) && s1_count="$MAX_STAGE1"
  (( s2_count > MAX_STAGE2 )) && s2_count="$MAX_STAGE2"
  row="$(jq -nc \
    --arg schema "$SCHEMA_VERSION" --arg version "$VERSION" --arg ts "$ts" --arg session "$SESSION" \
    --argjson pane "$PANE" --arg stage "$stage" --argjson success "$success" --arg path "$receipt_path" \
    --arg prompt "$prompt_path" --argjson dry "$DRY_RUN" --argjson apply "$APPLY" --argjson esc "$ESCALATE" \
    --argjson planned "$planned" --argjson actual "$actual" --argjson s1 "$s1_count" --argjson s2 "$s2_count" \
    '{schema_version:$schema,version:$version,ts:$ts,session:$session,pane:$pane,stage_succeeded:(if $stage == "none" then "none" else ($stage|tonumber) end),recovery_succeeded:$success,recovery_receipt_path:$path,retries_per_stage:{stage1_escape:$s1,stage2_reprompt:$s2},escalate_to_respawn:($esc == 1),dry_run:($dry == 1),apply:($apply == 1),last_prompt_path:$prompt,planned_actions:$planned,actual_actions:$actual}')"
  if [[ "$APPLY" -eq 1 ]]; then
    tmp="$receipt_path.$$.$RANDOM.tmp"; printf '%s\n' "$row" >"$tmp"; mv "$tmp" "$receipt_path"; write_receipts "$row"
  fi
  [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$row" || jq -r '"stage=\(.stage_succeeded) success=\(.recovery_succeeded)"' <<<"$row"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:?}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --pane) PANE="${2:?}"; shift 2 ;;
    --pane=*) PANE="${1#*=}"; shift ;;
    --max-retry-stage1) MAX_STAGE1="${2:?}"; shift 2 ;;
    --max-retry-stage2) MAX_STAGE2="${2:?}"; shift 2 ;;
    --escalate-to-respawn) ESCALATE=1; shift ;;
    --no-escalate-to-respawn) ESCALATE=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --schema) MODE="schema"; shift ;;
    --explain) MODE="explain"; shift ;;
    --help|-h) MODE="help"; shift ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

case "$MODE" in
  run) run_recovery ;;
  schema) schema_json ;;
  explain) explain_json ;;
  help) usage ;;
esac
