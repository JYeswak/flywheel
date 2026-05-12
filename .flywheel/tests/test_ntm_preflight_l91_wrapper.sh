#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/ntm-preflight-l91-wrapper.sh"
CHECKER="${CANONICAL_CLI_CHECKER:-/Users/josh/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-preflight-l91.XXXXXX")"
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

bash -n "$BIN" && pass "syntax" || fail "syntax"

"$BIN" --help >"$TMP/help.txt"
rg -q 'transport.*prompt.*work|L91' "$TMP/help.txt" && pass "help_surface" || fail "help_surface"

"$BIN" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.command=="doctor" and .status=="pass" and .dependencies.jq==true' "doctor_json"

"$BIN" health --json >"$TMP/health.json"
assert_jq "$TMP/health.json" '.command=="health" and .status=="pass"' "health_json"

"$BIN" validate --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.command=="validate" and .status=="pass"' "validate_json"

"$BIN" audit --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.command=="audit" and .rows==[]' "audit_json"

"$BIN" why --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.command=="why" and (.explanation|contains("transport-only"))' "why_json"

"$BIN" schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '(.required|index("work_started")) and .stable_exit_codes.not_started==1' "schema_json"

"$BIN" repair --dry-run --json >"$TMP/repair-dry.json"
assert_jq "$TMP/repair-dry.json" '.command=="repair" and .status=="pass" and (.actual_actions|length)==0' "repair_dry_run"

if "$BIN" repair --apply --json >"$TMP/repair-apply-no-key.json"; then
  fail "repair_apply_requires_key"
else
  assert_jq "$TMP/repair-apply-no-key.json" '.status=="fail" and (.reason|contains("idempotency-key"))' "repair_apply_requires_key"
fi

"$BIN" preflight \
  --transport-accepted true \
  --prompt-visible true \
  --prompt-submitted true \
  --work-started true \
  --session flywheel \
  --pane 2 \
  --dispatch-id fixture-valid \
  --send-command 'ntm send flywheel --pane=2 --no-cass-check --file /tmp/dispatch.md' \
  --capture-proof live-capture \
  --fresh-window-seconds 300 \
  --json >"$TMP/valid.json"
assert_jq "$TMP/valid.json" '
  .status=="pass"
  and .delivery_receipt.transport_accepted==true
  and .delivery_receipt.prompt_visible_in_target==true
  and .delivery_receipt.prompt_submitted==true
  and .delivery_receipt.work_started==true
  and .delivery_receipt.work_started_validation_status=="valid_prompt_visible_and_pane_active"
' "valid_four_state_passes"

if "$BIN" preflight --transport-accepted true --prompt-visible false --prompt-submitted false --work-started false --json >"$TMP/transport-only.json"; then
  fail "transport_only_fails"
else
  assert_jq "$TMP/transport-only.json" '.status=="fail" and .failure_class=="prompt_not_visible" and .delivery_receipt.work_started==false' "transport_only_fails"
fi

if "$BIN" preflight --transport-accepted true --prompt-visible true --prompt-submitted true --work-started false --json >"$TMP/not-started.json"; then
  fail "work_started_required"
else
  assert_jq "$TMP/not-started.json" '.status=="fail" and .failure_class=="transport_only_success" and .delivery_receipt.work_started_validation_status=="invalid_transport_only_not_work_started"' "work_started_required"
fi

if L91_NOW_EPOCH=2000 "$BIN" preflight --transport-accepted true --prompt-visible true --prompt-submitted true --work-started true --checked-at 1970-01-01T00:00:00Z --fresh-window-seconds 60 --json >"$TMP/stale.json"; then
  fail "stale_receipt_fails"
else
  assert_jq "$TMP/stale.json" '.status=="fail" and .failure_class=="stale_receipt" and .delivery_receipt.fresh==false' "stale_receipt_fails"
fi

cat >"$TMP/receipt.json" <<'JSON'
{
  "transport_accepted": true,
  "prompt_visible_in_target": true,
  "prompt_submitted": true,
  "work_started": true,
  "session": "flywheel",
  "pane": 2,
  "dispatch_id": "fixture-receipt",
  "send_command": "ntm send flywheel --pane=2 --no-cass-check --file /tmp/dispatch.md",
  "capture_proof": "live",
  "classification_source": "fixture"
}
JSON
"$BIN" preflight --receipt "$TMP/receipt.json" --json >"$TMP/receipt-pass.json"
assert_jq "$TMP/receipt-pass.json" '.status=="pass" and .dispatch_id=="fixture-receipt"' "receipt_file_passes"

assert_jq "$TMP/valid.json" '
  .authorized_operations == ["read_receipt","classify_delivery_state","emit_preflight_receipt"]
  and (.forbidden_operations|index("count_transport_only_as_work_started"))
  and .ttl_native
  and .ttl_wrapper
  and .ttl_decision
  and .native_wrapper_delta
' "acceptance_template_fields"

bash "$CHECKER" "$BIN" >/dev/null && pass "canonical_cli_scoping" || fail "canonical_cli_scoping"

printf '\nResults: %d PASS %d FAIL\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
