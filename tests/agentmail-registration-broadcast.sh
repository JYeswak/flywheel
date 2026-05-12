#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/agentmail-registration-broadcast.sh"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agentmail-broadcast.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

STATE="$TMP/agent-mail"
SESSIONS="$STATE/sessions"
DEFERRALS="$TMP/identity-overrides"
COORD="$TMP/cross-orch-coordination.jsonl"
SEND_LOG="$TMP/sends.jsonl"
mkdir -p "$SESSIONS" "$DEFERRALS"

write_row() {
  local session="$1" pane="$2" project="$3"
  jq -n \
    --arg session "$session" \
    --argjson pane "$pane" \
    --arg project "$project" \
    '{
      schema_version:"agent-mail-identity-registry/v1",
      session:$session,
      pane:$pane,
      identity_name:null,
      token_path:null,
      token_sha256:null,
      registered_ts:"2026-05-04T00:00:00Z",
      last_used_ts:"2026-05-04T00:00:00Z",
      fleet_mail_project_key:$project,
      predecessor_identity:null,
      rotation_reason:null,
      status:"needs_registration",
      identity_resolved:false
    }' >"$SESSIONS/$session:$pane.json"
}

write_row live 1 /tmp/live-project
write_row mixed 2 /tmp/mixed-project
write_row dead 1 /tmp/dead-project
write_row deferred 1 /tmp/deferred-project

jq -n '{
  schema_version:"identity-registration-deferral/v1",
  issued_at:"2026-05-04T00:00:00Z",
  expires_at:"2026-05-05T00:00:00Z",
  deferred_rows:[{session:"deferred",pane:1,fleet_mail_project_key:"/tmp/deferred-project",live_state:"session_not_running",auto_register_when_live:true,tracking_bead:"flywheel-2uin"}]
}' >"$DEFERRALS/receipt.json"

FAKE_NTM="$TMP/ntm"
cat >"$FAKE_NTM" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "health" ]]; then
  case "${2:-}" in
    live)
      printf '{"session":"live","agents":[{"pane":1,"status":"ok","process_status":"running"}]}\n'
      exit 0
      ;;
    mixed)
      printf '{"session":"mixed","overall_status":"error","agents":[{"pane":1,"status":"error","process_status":"exited"},{"pane":2,"status":"ok","process_status":"running"}]}\n'
      exit 1
      ;;
    deferred|dead)
      exit 1
      ;;
  esac
fi
if [[ "${1:-}" == "message" && "${2:-}" == "--broadcast" ]]; then
  recipients=""
  file=""
  subject=""
  no_raw_tokens=false
  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --to) recipients="${2:-}" ; shift 2 ;;
      --file) file="${2:-}" ; shift 2 ;;
      --subject) subject="${2:-}" ; shift 2 ;;
      --no-raw-tokens) no_raw_tokens=true ; shift ;;
      *) shift ;;
    esac
  done
  jq -n --arg recipients "$recipients" --arg file "$file" --arg subject "$subject" --argjson no_raw_tokens "$no_raw_tokens" \
    '{command:["message","--broadcast"],recipients:$recipients,file:$file,subject:$subject,no_raw_tokens:$no_raw_tokens}' >>"${SEND_LOG:?}"
  exit 0
fi
exit 1
SH
chmod +x "$FAKE_NTM"

export SEND_LOG

broadcast_args=(
  --state-dir "$STATE"
  --deferral-dir "$DEFERRALS"
  --coordination-log "$COORD"
  --request-dir "$TMP"
  --ntm "$FAKE_NTM"
  --now 2026-05-04T01:00:00Z
  --json
)

zsh -n "$SCRIPT" && pass "broadcast_script_syntax" || fail "broadcast_script_syntax"
zsh -n "$LOOP" && pass "flywheel_loop_syntax" || fail "flywheel_loop_syntax"

"$SCRIPT" "${broadcast_args[@]}" >"$TMP/first.json"
assert_jq "$TMP/first.json" '.sent_count == 2 and .dead_count == 2 and .deferred_dead_count == 1 and (.results[] | select(.session=="live").action) == "sent" and (.results[] | select(.session=="mixed").action) == "sent"' "live_rows_broadcast_once"
test "$(jq -s 'length' "$SEND_LOG")" = "1" && pass "ntm_message_broadcast_called_once" || fail "ntm_message_broadcast_called_once"
assert_jq "$SEND_LOG" '.command == ["message","--broadcast"] and .recipients == "live:1,mixed:2" and .no_raw_tokens == true' "ntm_message_broadcast_expands_recipients"
if ! grep -q 'token=' "$TMP"/agentmail-registration-broadcast-*.txt 2>/dev/null; then
  pass "request_omits_raw_token_shape"
else
  fail "request_omits_raw_token_shape"
fi

"$SCRIPT" "${broadcast_args[@]}" >"$TMP/second.json"
assert_jq "$TMP/second.json" '.sent_count == 0 and .deduped_count == 2 and (.results[] | select(.session=="live").action) == "deduped_recent_send" and (.results[] | select(.session=="mixed").action) == "deduped_recent_send"' "repeat_within_window_dedupes"
test "$(jq -s 'length' "$SEND_LOG")" = "1" && pass "dedupe_suppresses_second_send" || fail "dedupe_suppresses_second_send"

"$SCRIPT" "${broadcast_args[@]}" --doctor >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "pass" and .agentmail_pending_registration_broadcasts_count == 0 and .deferred_dead_count == 1' "doctor_passes_when_only_dead_deferred_or_deduped"

rm -f "$COORD" "$SEND_LOG"
"$SCRIPT" "${broadcast_args[@]}" --session mixed --pane 2 --no-raw-tokens >"$TMP/scoped.json"
assert_jq "$TMP/scoped.json" '.sent_count == 1 and .rows_checked == 1 and .session_filter == "mixed" and .pane_filter == 2 and .no_raw_tokens == true and (.results[] | select(.session=="mixed").action) == "sent"' "scoped_broadcast_sends_target_only"
test "$(jq -s 'length' "$SEND_LOG")" = "1" && pass "scoped_broadcast_ntm_send_once" || fail "scoped_broadcast_ntm_send_once"
assert_jq "$SEND_LOG" '.recipients == "mixed:2"' "scoped_broadcast_recipient_expansion"

rm -f "$COORD" "$SEND_LOG"
"$SCRIPT" "${broadcast_args[@]}" --dry-run >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.sent_count == 0 and .agentmail_pending_registration_broadcasts_count == 2 and (.results[] | select(.session=="dead").action) == "dead_session" and (.results[] | select(.session=="deferred").action) == "deferred_dead_session"' "dry_run_counts_live_unsent_but_skips_dead_deferred"

FLYWHEEL_AGENT_MAIL_STATE_DIR="$STATE" "$LOOP" doctor --repo "$ROOT" --json >"$TMP/loop-doctor.json" || true
assert_jq "$TMP/loop-doctor.json" '.agentmail_pending_registration_broadcasts_count >= 0 and (.agentmail_registration_broadcast.signals[]?.name == "agentmail_pending_registration_broadcasts_count")' "flywheel_loop_doctor_exposes_broadcast_signal"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
