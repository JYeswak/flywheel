#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/fleet-coherence-alert.sh"
FIXTURE="$ROOT/.flywheel/fixtures/fleet-coherence-alerts.jsonl"
BASE_EVENTS="$ROOT/.flywheel/fixtures/fleet-coherence-events-v2.jsonl"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-coherence-alert-degraded.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_fake_auth() {
  cat >"$TMP/auth-probe" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
jq -nc '{schema_version:"fleet-mail-auth-probe/v1",status:"pass",ready:true,identity_name:"LavenderGlen",identity_source:"fixture",l61:{vault_token_validated:true}}'
SH
  chmod +x "$TMP/auth-probe"
}

write_fake_mail() {
  cat >"$TMP/mail-send" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${MAIL_FAIL:-0}" == "1" ]]; then
  jq -nc '{status:"fail",code:"fixture_mail_fail"}'
  exit 2
fi
jq -nc --arg id "${MAIL_MESSAGE_ID:-msg-fixture}" '{status:"ok",message_id:$id}'
SH
  chmod +x "$TMP/mail-send"
}

write_fake_ntm() {
  cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${NTM_FAIL:-0}" == "1" ]]; then
  printf 'fixture ntm fail\n' >&2
  exit 4
fi
printf 'Sent to pane\n'
SH
  chmod +x "$TMP/ntm"
}

make_event() {
  local out="$1" event_id="$2" dedupe="$3" session="$4" pane="$5" severity="$6"
  jq -c \
    --arg now "2026-05-08T12:00:00Z" \
    --arg event_id "$event_id" \
    --arg dedupe "$dedupe" \
    --arg session "$session" \
    --arg severity "$severity" \
    --argjson pane "$pane" \
    'select(.record_type=="event") | .event_id=$event_id | .dedupe_key=$dedupe | .session=$session | .pane=$pane | .severity=$severity | .state="open" | .ts=$now | .source_ts=$now | .first_seen_ts=$now | .last_seen_ts=$now | .resend_after_ts="2026-05-08T12:30:00Z" | .l61.ntm_session=$session | .l61.ntm_pane=$pane' \
    "$BASE_EVENTS" | sed -n '1p' >"$out"
}

write_fake_auth
write_fake_mail
write_fake_ntm

export FLYWHEEL_FLEET_COHERENCE_STATE_DIR="$TMP/state"
export FLYWHEEL_FLEET_COHERENCE_EVENTS="$TMP/state/fleet-coherence-events-v2.jsonl"
export FLYWHEEL_FLEET_COHERENCE_LATEST="$TMP/state/fleet-coherence-latest.json"
export FLEET_COHERENCE_ALERT_LEDGER="$TMP/alerts.jsonl"
export FLYWHEEL_FLEET_COHERENCE_NOW="2026-05-08T12:40:00Z"

base_args=(
  --auth-probe "$TMP/auth-probe"
  --agent-mail-send "$TMP/mail-send"
  --ntm-bin "$TMP/ntm"
  --ledger "$TMP/alerts.jsonl"
  --fixtures "$FIXTURE"
  --sender-session flywheel
  --sender-pane 1
  --to FoggyBear
  --json
)

bash -n "$BIN" && pass "script_syntax" || fail "script_syntax"
jq empty "$FIXTURE" && pass "fixture_jsonl_valid" || fail "fixture_jsonl_valid"

"$BIN" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '(.l61_pairing_status | index("degraded")) and (.l61_pairing_status | index("failed"))' "schema_exposes_degraded_and_failed"

for mode in doctor health validate; do
  "$BIN" "--$mode" --json --fixtures "$FIXTURE" >"$TMP/$mode.json"
  assert_jq "$TMP/$mode.json" '.status == "ok" and (.fixture_cases | index("both_legs_fail"))' "${mode}_fixture_contract"
done

make_event "$TMP/mail-fail.json" "fc_degraded_mail_fail" "dual_orchestrator_tick_loop:flywheel:pane2:mail-fail" "flywheel" 2 "error"
if MAIL_FAIL=1 "$BIN" "${base_args[@]}" --event-row "$TMP/mail-fail.json" --case agent_mail_fails >"$TMP/mail-fail-out.json"; then
  fail "mail_fail_exits_nonzero"
else
  assert_jq "$TMP/mail-fail-out.json" '.status == "fail" and .attempt.l61_pairing_status == "degraded" and .attempt.channel == "agent_mail" and .attempt.degraded_reason == "agent_mail_send_failed" and .attempt.retry_after_ts != null and .attempt.retry_recommended == true' "mail_fail_degraded_with_retry_metadata"
fi

make_event "$TMP/ntm-fail.json" "fc_degraded_ntm_fail" "dual_orchestrator_tick_loop:flywheel:pane3:ntm-fail" "flywheel" 3 "error"
if NTM_FAIL=1 MAIL_MESSAGE_ID=msg-ntm "$BIN" "${base_args[@]}" --event-row "$TMP/ntm-fail.json" --case ntm_fails >"$TMP/ntm-fail-out.json"; then
  fail "ntm_fail_exits_nonzero"
else
  assert_jq "$TMP/ntm-fail-out.json" '.status == "fail" and .attempt.l61_pairing_status == "degraded" and .attempt.channel == "ntm" and .attempt.degraded_reason == "ntm_send_failed" and .attempt.retry_after_ts != null' "ntm_fail_degraded_with_channel_error"
fi

make_event "$TMP/both-fail.json" "fc_degraded_both_fail" "dual_orchestrator_tick_loop:flywheel:pane5:both-fail" "flywheel" 5 "error"
if MAIL_FAIL=1 NTM_FAIL=1 "$BIN" "${base_args[@]}" --event-row "$TMP/both-fail.json" --case both_legs_fail >"$TMP/both-fail-out.json"; then
  fail "both_fail_exits_nonzero"
else
  assert_jq "$TMP/both-fail-out.json" '.status == "fail" and .attempt.l61_pairing_status == "failed" and .attempt.channel == "both" and .attempt.degraded_reason == "both_channels_failed"' "both_fail_status_failed"
fi
assert_jq "$FLYWHEEL_FLEET_COHERENCE_EVENTS" 'select(.event_id == "fc_degraded_both_fail_alert_channel_degraded" and .class == "alert_channel_degraded" and .state == "open" and .severity == "error" and .evidence.alert_channel_degraded.channel == "both")' "both_fail_writes_alert_channel_degraded_error"

"$BIN" --audit --json --fixtures "$FIXTURE" --ledger "$TMP/alerts.jsonl" >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.delivered_count == 0 and .degraded_count == 2 and .failed_count == 1 and .suppressed_count == 0' "audit_counts_degraded_separate_from_delivered"

jq empty "$TMP/alerts.jsonl" && pass "alert_ledger_jsonl_valid" || fail "alert_ledger_jsonl_valid"
jq empty "$FLYWHEEL_FLEET_COHERENCE_EVENTS" && pass "events_jsonl_valid" || fail "events_jsonl_valid"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 13 ]]
