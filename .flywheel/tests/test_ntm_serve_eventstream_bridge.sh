#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-serve-eventstream-bridge.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-serve-eventstream-test.XXXXXX")"
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

write_metrics_fixture() {
  local path="$1"
  local bearer_prefix="Bearer" bearer_value="abc.def-ghi"
  local registration_value="fixture-token-should-redact"
  local key_prefix="sk-" key_tail="abcdefghijklmnopqrstuvwxyz"
  jq -nc \
    --arg bearer "$bearer_prefix $bearer_value" \
    --arg registration "$registration_value" \
    --arg api_key "$key_prefix$key_tail" \
    '{
    schema_version:"ntm-metrics-doctor-probe.v1",
    status:"ok",
    scope:{session:"flywheel",doctor:"ntm_metrics"},
    checked_at:"2026-05-07T16:00:00Z",
    metrics:{capacity_class:"ok",remaining_units:72,window_reset_at:"2026-05-07T17:00:00Z",source:"fixture"},
    findings:[],
    gate:"none",
    action:"continue_dispatch",
    bearer_header:$bearer,
    registration_token:$registration,
    nested:{api_key:$api_key},
    l112_observed:"OK_ntm_migrate_W1M"
  }' >"$path"
}

write_fail_metrics_fixture() {
  local path="$1"
  jq -nc '{
    schema_version:"ntm-metrics-doctor-probe.v1",
    status:"fail",
    scope:{session:"flywheel",doctor:"ntm_metrics"},
    checked_at:"2026-05-07T16:00:00Z",
    metrics:{capacity_class:"critical",remaining_units:3,window_reset_at:"2026-05-07T17:00:00Z",source:"fixture"},
    findings:[{severity:"error",reason:"quota_critical"}],
    gate:"dispatch_capacity_gate",
    action:"pause_dispatch_until_reset_or_rotate_provider",
    l112_observed:"OK_ntm_migrate_W1M"
  }' >"$path"
}

make_fake_metrics_probe() {
  local path="$TMP/ntm-metrics-doctor-probe"
  cat >"$path" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_METRICS_LOG:?}"
jq -nc '{schema_version:"ntm-metrics-doctor-probe.v1",status:"ok",scope:{session:"flywheel"},metrics:{capacity_class:"ok",remaining_units:88,window_reset_at:"2026-05-07T17:00:00Z",source:"fake-probe"},findings:[],gate:"none",action:"continue_dispatch",l112_observed:"OK_ntm_migrate_W1M"}'
SH
  chmod +x "$path"
  printf '%s\n' "$path"
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"

fixture="$TMP/metrics.json"
write_metrics_fixture "$fixture"

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "ntm-serve-eventstream-bridge" and .default_bind_host == "127.0.0.1" and .native_surface == "ntm serve eventstream" and .canonical_cli.doctor == true and .canonical_cli.repair == true and (.authorized_operations | index("payload_redaction"))' "info_json_contract"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "ntm-serve-eventstream-bridge.v1" and .default_bind_host == "127.0.0.1" and .content_type == "text/event-stream" and (.required | index("payload_redacted"))' "schema_json_contract"

"$SCRIPT" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 4' "examples_json_contract"

"$SCRIPT" why --reason redaction --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.status == "ok" and .reason == "redaction" and (.explanations.redaction | contains("redaction"))' "why_json_contract"

"$SCRIPT" repair --dry-run --json >"$TMP/repair.json"
assert_jq "$TMP/repair.json" '.status == "ok" and .repair_mode == "dry_run" and .mutation_performed == false and (.planned_actions | index("stop serve process if running"))' "repair_dry_run_contract"

"$SCRIPT" validate --fixture "$fixture" --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.status == "ok" and .event.content_type == "text/event-stream" and .eventstream_ready == true and .payload_redacted == true and .data.registration_token == "[SCRUBBED:secret_field]" and .data.nested.api_key == "[SCRUBBED:secret_field]" and .data.bearer_header == "[SCRUBBED:secret_field]" and .l112_observed == "OK_ntm_migrate_W1S"' "validate_redacted_event_json"

"$SCRIPT" audit --fixture "$fixture" --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.audit.default_bind_host == "127.0.0.1" and .audit.redaction_applied == true and .audit.content_type == "text/event-stream" and (.audit.data_keys | index("metrics"))' "audit_json_contract"

"$SCRIPT" event --fixture "$fixture" >"$TMP/event.sse"
grep -q '^event: ntm_metrics$' "$TMP/event.sse" && pass "sse_event_line" || fail "sse_event_line"
grep -q '^id: 1$' "$TMP/event.sse" && pass "sse_id_line" || fail "sse_id_line"
grep -q '^retry: 5000$' "$TMP/event.sse" && pass "sse_retry_line" || fail "sse_retry_line"
sed -n 's/^data: //p' "$TMP/event.sse" >"$TMP/event-data.json"
assert_jq "$TMP/event-data.json" '.payload_redacted == true and .data.registration_token == "[SCRUBBED:secret_field]" and .event.content_type == "text/event-stream"' "sse_data_json_redacted"
if ! rg -q 'fixture-token-should-redact|abcdefghijklmnopqrstuvwxyz|abc.def-ghi' "$TMP/event.sse"; then
  pass "sse_payload_secret_values_absent"
else
  fail "sse_payload_secret_values_absent"
fi

"$SCRIPT" serve --dry-run --json >"$TMP/serve-dry.json"
assert_jq "$TMP/serve-dry.json" '.serve.host == "127.0.0.1" and .serve.would_bind == true and .serve.content_type == "text/event-stream"' "serve_dry_run_loopback_default"

set +e
"$SCRIPT" serve --host 0.0.0.0 --dry-run --json >"$TMP/nonloopback.json"
nonloop_rc=$?
set -e
if [[ "$nonloop_rc" == "3" ]]; then pass "non_loopback_refused"; else fail "non_loopback_refused_rc=$nonloop_rc"; fi
assert_jq "$TMP/nonloopback.json" '.status == "fail" and .findings[0].reason == "non_loopback_bind_refused"' "non_loopback_refusal_receipt"

fake_probe="$(make_fake_metrics_probe)"
FAKE_METRICS_LOG="$TMP/fake-metrics.log" "$SCRIPT" validate --metrics-probe "$fake_probe" --json >"$TMP/fake-probe.json"
assert_jq "$TMP/fake-probe.json" '.status == "ok" and .data.metrics.remaining_units == 88' "metrics_probe_invoked_contract"
grep -q '^validate --session flywheel --json$' "$TMP/fake-metrics.log" && pass "metrics_probe_invoked_with_validate" || fail "metrics_probe_invoked_with_validate"

fail_fixture="$TMP/fail-metrics.json"
write_fail_metrics_fixture "$fail_fixture"
set +e
"$SCRIPT" validate --fixture "$fail_fixture" --json >"$TMP/fail-event.json"
fail_rc=$?
set -e
if [[ "$fail_rc" == "1" ]]; then pass "fail_metrics_exits_nonzero"; else fail "fail_metrics_exits_nonzero_rc=$fail_rc"; fi
assert_jq "$TMP/fail-event.json" '.status == "fail" and .eventstream_ready == false and .data.gate == "dispatch_capacity_gate"' "fail_metrics_event_receipt"

ready="$TMP/ready.json"
"$SCRIPT" serve --fixture "$fixture" --port 0 --max-events 1 --max-requests 1 --ready-file "$ready" >"$TMP/server.out" 2>"$TMP/server.err" &
server_pid=$!
for _ in $(seq 1 50); do
  [[ -s "$ready" ]] && break
  sleep 0.1
done
if [[ -s "$ready" ]]; then pass "server_ready_file_written"; else fail "server_ready_file_written"; fi
server_port="$(jq -r '.port' "$ready")"
python3 - "$server_port" >"$TMP/http.sse" <<'PY'
import sys
import urllib.request
port = sys.argv[1]
with urllib.request.urlopen(f"http://127.0.0.1:{port}/events", timeout=5) as response:
    print(response.read().decode(), end="")
PY
wait "$server_pid"
grep -q '^event: ntm_metrics$' "$TMP/http.sse" && pass "http_eventstream_serves_sse" || fail "http_eventstream_serves_sse"
sed -n 's/^data: //p' "$TMP/http.sse" >"$TMP/http-data.json"
assert_jq "$TMP/http-data.json" '.scope.host == "127.0.0.1" and .payload_redacted == true and .data.registration_token == "[SCRUBBED:secret_field]"' "http_eventstream_payload_redacted"

set +e
"$SCRIPT" --apply --json >"$TMP/apply.json"
apply_rc=$?
set -e
if [[ "$apply_rc" == "3" ]]; then pass "apply_refused_stable"; else fail "apply_refused_stable_rc=$apply_rc"; fi
assert_jq "$TMP/apply.json" '.status == "fail" and .findings[0].reason == "apply_not_supported_read_only_bridge"' "apply_refusal_receipt"

if ! rg -n "(sk-[A-Za-z0-9]{20,}|Bearer [A-Za-z0-9._-]{20,}|refresh_token\"[[:space:]]*:[[:space:]]*\"[^\"]{8,}|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY)" "$SCRIPT" "$0" >/dev/null; then
  pass "secret_scan_clean"
else
  fail "secret_scan_clean"
fi

printf 'ntm_serve_eventstream_bridge_tests pass=%d fail=%d total=%d\n' "$pass_count" "$fail_count" "$((pass_count + fail_count))"
[[ "$fail_count" == 0 ]]
