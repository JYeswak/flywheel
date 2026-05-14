#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/auto-l112-gate.sh"
CLOSE="$ROOT/.flywheel/scripts/br-close-with-gate.sh"
REAL_HOME="$(dscl . -read "/Users/$(id -un)" NFSHomeDirectory 2>/dev/null | awk '{print $2}' || true)"
REAL_HOME="${REAL_HOME:-$HOME}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/auto-l112-gate-orch-adoption.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
SKILL_ROUTES="canonical-cli-scoping=n/a,rust-best-practices=n/a,python-best-practices=n/a,readme-writing=n/a"

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

write_envelope() {
  local file="$1" command="$2" expected="$3" timeout="${4:-5}"
  # bead flywheel-bgtv8 (META-RULE 2026-05-09 calibrate-test-to-actual-contract):
  # br-close-with-gate.sh now invokes callback-envelope-schema-validator which
  # requires 8 quality-bar fields (quality_bar_passed, composite_score,
  # jeff_score, donella_score, joshua_score, rust/python_clean, cli_canonical,
  # readme_quality). The validator was added/extended after this test was
  # written; envelopes that omit these fields fail with
  # `failure_class=callback_envelope_schema_failed`. Write default-pass values
  # so the gate exercise probes the L112 probe (the unit-under-test) rather
  # than the schema-completeness gate (which is a separate concern).
  {
    printf 'l112_probe_command=%s\n' "$command"
    printf 'l112_probe_expected=%s\n' "$expected"
    printf 'l112_probe_timeout_sec=%s\n' "$timeout"
    printf 'skill_auto_routes_addressed=%s\n' "$SKILL_ROUTES"
    printf 'quality_bar_passed=yes\n'
    printf 'composite_score=9.5\n'
    printf 'jeff_score=9.5\n'
    printf 'donella_score=9.5\n'
    printf 'joshua_score=9.5\n'
    printf 'rust/python_clean=n/a\n'
    printf 'cli_canonical=yes\n'
    printf 'readme_quality=n/a\n'
  } >"$file"
}

append_dispatch_log() {
  local row="$1"
  jq -e . >/dev/null <<<"$row"
  printf '%s\n' "$row" >>"$TMP/repo/.flywheel/dispatch-log.jsonl"
}

has_l112_envelope() {
  local file="$1"
  grep -q '^l112_probe_command=' "$file" &&
    grep -q '^l112_probe_expected=' "$file" &&
    grep -q '^l112_probe_timeout_sec=' "$file"
}

close_done_callback() {
  local bead="$1" task_id="$2" envelope="$3" reason="$4" output rc gate_status fix_bead_id
  if ! has_l112_envelope "$envelope"; then
    PATH="$TMP/bin:$PATH" br update "$bead" --status closed >/dev/null
    append_dispatch_log "$(jq -nc --arg task_id "$task_id" --arg bead "$bead" \
      '{event:"auto_l112_gate_close",task_id:$task_id,bead_id:$bead,gate_status:"gate_envelope_missing",status:"warn",close_allowed:true}')"
    return 0
  fi

  set +e
  output="$(env \
    HOME="$REAL_HOME" \
    PATH="$TMP/bin:$PATH" \
    AUTO_L112_GATE_BIN="$GATE" \
    AUTO_L112_GATE_BR_BIN="$TMP/bin/br" \
    AUTO_L112_GATE_LEDGER="$TMP/auto-l112-gate-ledger.jsonl" \
    AUTO_L112_GATE_BR_CREATE_WRAPPER="$TMP/fake-br-create" \
    AUTO_L112_GATE_DISABLE_SANDBOX_EXEC=1 \
    "$CLOSE" --bead "$bead" --task-id "$task_id" --callback-envelope-file "$envelope" --reason "$reason" --json)"
  rc=$?
  set -e

  if [[ "$rc" -eq 0 ]]; then
    gate_status="gate_pass"
    append_dispatch_log "$(jq -nc --arg task_id "$task_id" --arg bead "$bead" --argjson receipt "$output" \
      '{event:"auto_l112_gate_close",task_id:$task_id,bead_id:$bead,gate_status:"gate_pass",status:"pass",close_allowed:true,receipt:$receipt}')"
    return 0
  fi

  gate_status="gate_fail"
  fix_bead_id="$(jq -r '.gate.fix_bead_id // null' <<<"$output" 2>/dev/null || printf 'null')"
  append_dispatch_log "$(jq -nc --arg task_id "$task_id" --arg bead "$bead" --arg fix_bead_id "$fix_bead_id" --argjson receipt "$output" \
    '{event:"auto_l112_gate_close",task_id:$task_id,bead_id:$bead,gate_status:"gate_fail",status:"fail",close_allowed:false,fix_bead_id:$fix_bead_id,receipt:$receipt}')"
  return 1
}

mkdir -p "$TMP/repo/.flywheel" "$TMP/bin"
: >"$TMP/repo/.flywheel/dispatch-log.jsonl"
: >"$TMP/br.log"
: >"$TMP/br-create.log"

cat >"$TMP/bin/br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_BR_LOG:?}"
case "${1:-}" in
  close)
    jq -nc --arg id "${2:-unknown}" '{id:$id,status:"closed"}'
    ;;
  update)
    jq -nc --arg id "${2:-unknown}" '{id:$id,status:"closed"}'
    ;;
  *)
    jq -nc '{status:"ok"}'
    ;;
esac
SH
chmod +x "$TMP/bin/br"
export FAKE_BR_LOG="$TMP/br.log"

cat >"$TMP/fake-br-create" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_BR_CREATE_LOG:?}"
printf '[{"id":"flywheel-fixmock"}]\n'
SH
chmod +x "$TMP/fake-br-create"
export FAKE_BR_CREATE_LOG="$TMP/br-create.log"

pass_env="$TMP/pass.env"
write_envelope "$pass_env" "printf 'OK\n'" "grep:OK" 5
if close_done_callback flywheel-pass task-pass "$pass_env" "fixture pass" &&
  grep -q '^close flywheel-pass' "$TMP/br.log" &&
  jq -e 'select(.task_id == "task-pass" and .gate_status == "gate_pass" and .close_allowed == true)' "$TMP/repo/.flywheel/dispatch-log.jsonl" >/dev/null; then
  pass "passing_probe_allows_close_and_logs_gate_pass"
else
  fail "passing_probe_allows_close_and_logs_gate_pass"
fi

fail_env="$TMP/fail.env"
write_envelope "$fail_env" "printf 'NO\n'" "grep:OK" 5
if ! close_done_callback flywheel-fail task-fail "$fail_env" "fixture fail" &&
  grep -q 'task-fail' "$TMP/br-create.log" &&
  ! grep -q '^close flywheel-fail' "$TMP/br.log" &&
  jq -e 'select(.task_id == "task-fail" and .gate_status == "gate_fail" and .close_allowed == false and .fix_bead_id == "flywheel-fixmock")' "$TMP/repo/.flywheel/dispatch-log.jsonl" >/dev/null; then
  pass "failing_probe_blocks_close_and_logs_fix_bead"
else
  fail "failing_probe_blocks_close_and_logs_fix_bead"
fi

legacy_env="$TMP/legacy.env"
printf 'legacy_callback_without_l112=true\n' >"$legacy_env"
if close_done_callback flywheel-legacy task-legacy "$legacy_env" "legacy close" &&
  grep -q '^update flywheel-legacy --status closed' "$TMP/br.log" &&
  jq -e 'select(.task_id == "task-legacy" and .gate_status == "gate_envelope_missing" and .status == "warn" and .close_allowed == true)' "$TMP/repo/.flywheel/dispatch-log.jsonl" >/dev/null; then
  pass "legacy_callback_warns_and_allows_close"
else
  fail "legacy_callback_warns_and_allows_close"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
