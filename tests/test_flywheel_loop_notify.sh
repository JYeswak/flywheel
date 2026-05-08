#!/usr/bin/env bash
set -euo pipefail

LOOP="${FLYWHEEL_LOOP_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d -t 4vg3.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_roster() {
  local path="$1"
  {
    jq -nc '{ts:"2026-05-08T00:00:00Z",event:"session_active",session:"flywheel",agent_mail_project:"/Users/josh/.local/state/flywheel/fleet-mail-project",agent_mail_identity:"LavenderGlen"}'
    jq -nc '{ts:"2026-05-08T00:00:00Z",event:"session_active",session:"alpsinsurance",agent_mail_project:"/Users/josh/Developer/alpsinsurance",agent_mail_identity:"CoralRaven"}'
    jq -nc '{ts:"2026-05-08T00:00:00Z",event:"session_active",session:"missing-id",agent_mail_project:"/Users/josh/Developer/missing-id",agent_mail_identity:null}'
  } >"$path"
}

write_pulse() {
  local path="$1" alive="${2:-true}"
  jq -nc --argjson alive "$alive" '{ts:"2026-05-08T00:01:00Z",session:"alpsinsurance",orch_pane_alive:$alive}' >"$path"
  jq -nc '{ts:"2026-05-08T00:01:00Z",session:"missing-id",orch_pane_alive:true}' >>"$path"
}

run_notify() {
  local name="$1"; shift
  local out="$TMP/$name.json" rc=0
  FLYWHEEL_NOTIFY_FAKE_SEND=1 FLYWHEEL_NOTIFY_FAKE_MESSAGE_ID="msg-$name" \
    "$LOOP" notify --now 2026-05-08T00:02:00Z "$@" >"$out" || rc=$?
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

if bash -n "$LOOP"; then pass "dispatcher_syntax"; else fail "dispatcher_syntax"; fi
if bash -n /Users/josh/.claude/skills/.flywheel/lib/portable/notify.sh; then pass "notify_module_syntax"; else fail "notify_module_syntax"; fi

roster="$TMP/team-roster.jsonl"
pulse="$TMP/team-pulse.jsonl"
audit="$TMP/coordination-audit.jsonl"
write_roster "$roster"
write_pulse "$pulse" true

active_out="$(run_notify active --to alpsinsurance --from flywheel --subject "handoff ready" --body "ready" --roster "$roster" --pulse "$pulse" --audit-log "$audit" --json)"
assert_jq "$active_out" '.status == "sent" and .delivery_result == "sent" and .resolved_destination.agent_mail_project == "/Users/josh/Developer/alpsinsurance" and .resolved_destination.agent_mail_identity == "CoralRaven" and .audit_row_appended == true' "active_destination_routes_and_sends"
assert_jq "$audit" '.schema_version == "flywheel-loop-notify-audit/v1" and .dest_session == "alpsinsurance" and .dest_identity == "CoralRaven" and (.subject_hash | type == "string") and (.subject? == null) and (.body? == null)' "audit_row_shape_has_hash_not_text"

missing_out="$(run_notify missing --to unknown --from flywheel --subject "ping" --body "body" --roster "$roster" --pulse "$pulse" --audit-log "$TMP/missing-audit.jsonl" --json)"
[[ "$(cat "$TMP/missing.rc")" == "2" ]] && pass "missing_roster_exit_code" || fail "missing_roster_exit_code"
assert_jq "$missing_out" '.status == "refused" and .failure_class == "missing_roster" and .delivery_result == "not_sent"' "missing_roster_refused"

dead_pulse="$TMP/dead-pulse.jsonl"
write_pulse "$dead_pulse" false
dead_out="$(run_notify dead --to alpsinsurance --from flywheel --subject "ping" --body "body" --roster "$roster" --pulse "$dead_pulse" --audit-log "$TMP/dead-audit.jsonl" --json)"
[[ "$(cat "$TMP/dead.rc")" == "2" ]] && pass "dead_destination_exit_code" || fail "dead_destination_exit_code"
assert_jq "$dead_out" '.status == "refused" and .failure_class == "destination_dead"' "dead_destination_refused"

missing_id_out="$(run_notify missing-id --to missing-id --from flywheel --subject "ping" --body "body" --roster "$roster" --pulse "$pulse" --audit-log "$TMP/missing-id-audit.jsonl" --json)"
[[ "$(cat "$TMP/missing-id.rc")" == "2" ]] && pass "missing_identity_exit_code" || fail "missing_identity_exit_code"
assert_jq "$missing_id_out" '.status == "refused" and .failure_class == "missing_identity"' "missing_identity_refused"

token_audit="$TMP/token-audit.jsonl"
token_out="$(run_notify token --to alpsinsurance --from flywheel --subject "Bearer aa.bb-cc" --body "registration_token=abcdefghijklmnopqrstuvwxyz123456" --roster "$roster" --pulse "$pulse" --audit-log "$token_audit" --json)"
assert_jq "$token_out" '.status == "sent" and .token_safety.raw_token_patterns_found >= 2 and .token_safety.agent_mail_token_echo == false' "token_patterns_scrubbed"
if grep -E 'aa\.bb-cc|abcdefghijklmnopqrstuvwxyz123456|Bearer ' "$token_out" "$token_audit" >/dev/null; then
  fail "no_raw_token_in_output_or_audit"
else
  pass "no_raw_token_in_output_or_audit"
fi

help_out="$TMP/help.txt"
"$LOOP" notify --help >"$help_out"
if rg -q "JSON output|Failure classes|missing_roster|agent_mail_send_failed" "$help_out"; then
  pass "help_documents_json_and_failure_classes"
else
  fail "help_documents_json_and_failure_classes"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
