#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/fleet-coherence-alert.sh"
FIXTURE="$ROOT/.flywheel/fixtures/fleet-coherence-alerts.jsonl"
BASE_EVENTS="$ROOT/.flywheel/fixtures/fleet-coherence-events-v2.jsonl"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-coherence-alert.XXXXXX")"
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

line_count() {
  [[ -f "$1" ]] || { printf '0'; return; }
  wc -l <"$1" | tr -d ' '
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
printf '%s\n' "$*" >>"${MAIL_LOG:?}"
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
printf '%s\n' "$*" >>"${NTM_LOG:?}"
if [[ "${NTM_FAIL:-0}" == "1" ]]; then
  printf 'fixture ntm fail\n' >&2
  exit 4
fi
printf 'Sent to pane\n'
SH
  chmod +x "$TMP/ntm"
}

make_event() {
  local out="$1" event_id="$2" dedupe="$3" session="$4" pane="$5" resend="$6"
  jq -c \
    --arg now "2026-05-08T12:00:00Z" \
    --arg event_id "$event_id" \
    --arg dedupe "$dedupe" \
    --arg session "$session" \
    --argjson pane "$pane" \
    --arg resend "$resend" \
    'select(.record_type=="event") | .event_id=$event_id | .dedupe_key=$dedupe | .session=$session | .pane=$pane | .ts=$now | .source_ts=$now | .first_seen_ts=$now | .last_seen_ts=$now | .resend_after_ts=(if $resend == "null" then null else $resend end) | .l61.ntm_session=$session | .l61.ntm_pane=$pane' \
    "$BASE_EVENTS" | sed -n '1p' >"$out"
}

write_fake_auth
write_fake_mail
write_fake_ntm

export FLYWHEEL_FLEET_COHERENCE_STATE_DIR="$TMP/state"
export FLYWHEEL_FLEET_COHERENCE_EVENTS="$TMP/state/fleet-coherence-events-v2.jsonl"
export FLYWHEEL_FLEET_COHERENCE_LATEST="$TMP/state/fleet-coherence-latest.json"
export FLEET_COHERENCE_ALERT_LEDGER="$TMP/alerts.jsonl"
export FLYWHEEL_FLEET_COHERENCE_NOW="2026-05-08T12:10:00Z"
export MAIL_LOG="$TMP/mail.log"
export NTM_LOG="$TMP/ntm.log"

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
jq empty "$FIXTURE" && pass "alert_fixture_jsonl_valid" || fail "alert_fixture_jsonl_valid"

"$BIN" --info --json --fixtures "$FIXTURE" >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "fleet-coherence-alert.sh" and (.canonical_cli_surfaces | index("--dry-run"))' "info_surface"
"$BIN" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.event_schema_version == 2 and (.l61_pairing_status | index("complete"))' "schema_surface"
for mode in doctor health validate audit; do
  "$BIN" "--$mode" --json --fixtures "$FIXTURE" >"$TMP/$mode.json"
  assert_jq "$TMP/$mode.json" '.status == "ok" and (.fixture_cases | length) == 5' "${mode}_surface"
done
"$BIN" --why --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.status == "ok" and (.reason | test("L61"))' "why_surface"
if "$BIN" --repair --json >"$TMP/repair.json"; then
  fail "repair_refuses"
else
  assert_jq "$TMP/repair.json" '.status == "refused" and .apply == false' "repair_refuses"
fi

make_event "$TMP/success.json" "fc_alert_success" "dual_orchestrator_tick_loop:flywheel:pane1:alert-success" "flywheel" 1 "2026-05-08T12:00:00Z"
MAIL_MESSAGE_ID=msg-success "$BIN" "${base_args[@]}" --event-row "$TMP/success.json" --case success >"$TMP/success-out.json"
assert_jq "$TMP/success-out.json" '.status == "pass" and .attempt.l61_pairing_status == "complete" and .attempt.agent_mail_message_id == "msg-success"' "success_pairing_complete"
assert_jq "$FLYWHEEL_FLEET_COHERENCE_EVENTS" 'select(.event_id == "fc_alert_success" and .l61.l61_pairing_status == "complete" and .l61.agent_mail_message_id == "msg-success" and .l61.ntm_result.exit_code == 0)' "success_event_row_l61_complete"

make_event "$TMP/mail-fail.json" "fc_alert_mail_fail" "dual_orchestrator_tick_loop:flywheel:pane2:mail-fail" "flywheel" 2 "2026-05-08T12:00:00Z"
if MAIL_FAIL=1 "$BIN" "${base_args[@]}" --event-row "$TMP/mail-fail.json" --case agent_mail_fails >"$TMP/mail-fail-out.json"; then
  fail "mail_failure_exits_nonzero"
else
  assert_jq "$TMP/mail-fail-out.json" '.status == "fail" and .attempt.l61_pairing_status == "ntm_only" and .attempt.degraded_reason == "agent_mail_send_failed"' "mail_failure_degrades_ntm_only"
fi

make_event "$TMP/ntm-fail.json" "fc_alert_ntm_fail" "dual_orchestrator_tick_loop:flywheel:pane3:ntm-fail" "flywheel" 3 "2026-05-08T12:00:00Z"
if NTM_FAIL=1 MAIL_MESSAGE_ID=msg-ntm-fail "$BIN" "${base_args[@]}" --event-row "$TMP/ntm-fail.json" --case ntm_fails >"$TMP/ntm-fail-out.json"; then
  fail "ntm_failure_exits_nonzero"
else
  assert_jq "$TMP/ntm-fail-out.json" '.status == "fail" and .attempt.l61_pairing_status == "mail_only" and .attempt.degraded_reason == "ntm_send_failed"' "ntm_failure_degrades_mail_only"
fi

make_event "$TMP/suppress.json" "fc_alert_suppress" "dual_orchestrator_tick_loop:flywheel:pane4:suppress" "flywheel" 4 "2026-05-08T13:00:00Z"
before_mail="$(line_count "$MAIL_LOG")"
before_ntm="$(line_count "$NTM_LOG")"
"$BIN" "${base_args[@]}" --event-row "$TMP/suppress.json" --case resend_suppressed >"$TMP/suppress-first.json"
"$BIN" "${base_args[@]}" --event-row "$TMP/suppress.json" --case resend_suppressed >"$TMP/suppress-second.json"
after_mail="$(line_count "$MAIL_LOG")"
after_ntm="$(line_count "$NTM_LOG")"
[[ "$before_mail" == "$after_mail" && "$before_ntm" == "$after_ntm" ]] && pass "resend_suppressed_does_not_send_channels" || fail "resend_suppressed_does_not_send_channels"
assert_jq "$TMP/suppress-second.json" '.status == "pass" and .attempt.resend_suppressed == true and .attempt.l61_pairing_status == "suppressed"' "resend_suppressed_receipt"

make_event "$TMP/stale.json" "fc_alert_stale" "dual_orchestrator_tick_loop:missing:pane1:stale" "missing" 1 "2026-05-08T12:00:00Z"
if MAIL_MESSAGE_ID=msg-stale "$BIN" "${base_args[@]}" --event-row "$TMP/stale.json" --ntm-session "" --case stale_callback_pane >"$TMP/stale-out.json"; then
  fail "stale_callback_exits_nonzero"
else
  assert_jq "$TMP/stale-out.json" '.status == "fail" and .attempt.l61_pairing_status == "mail_only" and .attempt.degraded_reason == "stale_callback_pane"' "stale_callback_degrades"
fi

jq empty "$TMP/alerts.jsonl" && pass "alert_ledger_jsonl_valid" || fail "alert_ledger_jsonl_valid"
assert_jq "$TMP/alerts.jsonl" 'select(.event_id == "fc_alert_success" and .dedupe_key == "dual_orchestrator_tick_loop:flywheel:pane1:alert-success")' "ledger_carries_event_id_and_dedupe"
jq empty "$FLYWHEEL_FLEET_COHERENCE_EVENTS" && pass "generated_event_rows_jsonl_valid" || fail "generated_event_rows_jsonl_valid"
jq -s -e 'all(.[]; .schema_version == 2 and .record_type == "event" and (.l61 | has("l61_pairing_status")))' "$FLYWHEEL_FLEET_COHERENCE_EVENTS" >/dev/null \
  && pass "generated_event_rows_match_v2_smoke" \
  || fail "generated_event_rows_match_v2_smoke"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 21 ]]
