#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jsonl-orphan-migrations.XXXXXX")"
BLOCKED_DIRS=()

cleanup() {
  local dir
  for dir in "${BLOCKED_DIRS[@]}"; do
    chmod 700 "$dir" 2>/dev/null || true
  done
  rm -rf "$TMP"
}
trap cleanup EXIT

# shellcheck disable=SC1090,SC1091
source "$LIB"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

json_line() {
  jq -c . "$1"
}

make_blocked_dir() {
  local dir="$1"
  mkdir -p "$dir"
  chmod 000 "$dir"
  BLOCKED_DIRS+=("$dir")
}

restore_dir() {
  chmod 700 "$1"
}

assert_empty_rejected() {
  local label="$1" rc
  local file="$TMP/$label-empty.jsonl"
  set +e
  fw_jsonl_append_validated "$file" ""
  rc=$?
  set -e
  if [[ "$rc" == "1" && ! -s "$file" ]]; then
    pass "$label empty row rejected"
  else
    fail "$label empty row rejected"
  fi
}

write_fake_ntm() {
  cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  list)
    jq -nc '{sessions:[{name:"fixture"}]}'
    ;;
  --robot-activity=fixture)
    jq -nc '{agents:[{pane_idx:2,agent_type:"codex",state:"WAITING"}]}'
    ;;
  *)
    printf 'unexpected fake ntm call: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
  chmod +x "$TMP/ntm"
}

write_headless_probe() {
  cat >"$TMP/headless-probe" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
jq -nc '{headless_agent_browser_count:1,primary_chrome_profile:false,agent_browser_processes:[{pid:123,age_minutes:90}]}'
SH
  chmod +x "$TMP/headless-probe"
}

write_mobile_tools() {
  mkdir -p "$TMP/bin"
  cat >"$TMP/product-tick" <<'SH'
#!/usr/bin/env bash
exit "${PRODUCT_TICK_RC:-0}"
SH
  chmod +x "$TMP/product-tick"
  cat >"$TMP/receipt-bridge" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${BRIDGE_FAIL:-0}" == "1" ]]; then
  exit 7
fi
jq -nc '{receipt:"ok"}'
SH
  chmod +x "$TMP/receipt-bridge"
  cat >"$TMP/bin/date" <<'SH'
#!/usr/bin/env bash
if [[ "$*" == "-u +%Y-%m-%dT%H:%M:%SZ" ]]; then
  printf '2026-05-05T00:00:00Z\n'
else
  /bin/date "$@"
fi
SH
  chmod +x "$TMP/bin/date"
}

fixture_storage() {
  local path="$1"
  jq -nc '{
    disk_total_gb:100,
    disk_free_gb:50,
    disk_free_pct:50,
    developer_dir_gb:1,
    local_state_gb:1,
    stale_baks_count:0,
    stale_baks_size_mb:0,
    qdrant_volumes_size_mb:0,
    tmp_dispatch_artifacts_count:1
  }' >"$path"
}

test_leverage() {
  local script="$ROOT/.flywheel/scripts/leverage-ceiling-probe.sh" ledger="$TMP/leverage.jsonl" out="$TMP/leverage.out"
  write_fake_ntm
  LEVERAGE_CEILING_LEDGER="$ledger" LEVERAGE_CEILING_NTM_BIN="$TMP/ntm" \
  LEVERAGE_CEILING_SESSIONS="fixture" LEVERAGE_CEILING_ACCOUNTS_ACTIVE=2 \
  LEVERAGE_CEILING_ANTHROPIC_PCT=80 LEVERAGE_CEILING_XAI_PCT=90 \
  FLYWHEEL_JSONL_APPEND_LIB="$LIB" "$script" --json >"$out"
  if [[ "$(json_line "$out")" == "$(json_line "$ledger")" ]]; then
    pass "leverage valid append readback"
  else
    fail "leverage valid append readback"
  fi
  assert_empty_rejected "leverage"
  local blocked="$TMP/leverage-blocked" blocked_out="$TMP/leverage-blocked.out" blocked_err="$TMP/leverage-blocked.err"
  make_blocked_dir "$blocked"
  LEVERAGE_CEILING_LEDGER="$blocked/ledger.jsonl" LEVERAGE_CEILING_NTM_BIN="$TMP/ntm" \
  LEVERAGE_CEILING_SESSIONS="fixture" LEVERAGE_CEILING_ACCOUNTS_ACTIVE=2 \
  LEVERAGE_CEILING_ANTHROPIC_PCT=80 LEVERAGE_CEILING_XAI_PCT=90 \
  FLYWHEEL_JSONL_APPEND_LIB="$LIB" "$script" --json >"$blocked_out" 2>"$blocked_err"
  restore_dir "$blocked"
  if jq -e '.success == true' "$blocked_out" >/dev/null && grep -q 'append failed' "$blocked_err" && [[ ! -e "$blocked/ledger.jsonl" ]]; then
    pass "leverage append failure continues"
  else
    fail "leverage append failure continues"
  fi
}

test_headless() {
  local script="$ROOT/.flywheel/scripts/headless-browser-reap.sh" history="$TMP/headless.jsonl" out="$TMP/headless.out" dry="$TMP/headless-dry.jsonl"
  write_headless_probe
  FLYWHEEL_HEADLESS_BROWSER_PROBE="$TMP/headless-probe" FLYWHEEL_JSONL_APPEND_LIB="$LIB" \
    "$script" --fixture "$TMP/ignored.ps" --history "$dry" --json >/dev/null
  FLYWHEEL_HEADLESS_BROWSER_PROBE="$TMP/headless-probe" FLYWHEEL_JSONL_APPEND_LIB="$LIB" \
    "$script" --apply --fixture "$TMP/ignored.ps" --history "$history" --json >"$out"
  if [[ ! -e "$dry" && "$(json_line "$out")" == "$(json_line "$history")" ]]; then
    pass "headless valid append readback"
  else
    fail "headless valid append readback"
  fi
  assert_empty_rejected "headless"
  local blocked="$TMP/headless-blocked" blocked_out="$TMP/headless-blocked.out" blocked_err="$TMP/headless-blocked.err"
  make_blocked_dir "$blocked"
  FLYWHEEL_HEADLESS_BROWSER_PROBE="$TMP/headless-probe" FLYWHEEL_JSONL_APPEND_LIB="$LIB" \
    "$script" --apply --fixture "$TMP/ignored.ps" --history "$blocked/history.jsonl" --json >"$blocked_out" 2>"$blocked_err"
  restore_dir "$blocked"
  if jq -e '.status == "ok"' "$blocked_out" >/dev/null && grep -q 'append failed' "$blocked_err" && [[ ! -e "$blocked/history.jsonl" ]]; then
    pass "headless append failure continues"
  else
    fail "headless append failure continues"
  fi
}

test_fleet() {
  local script="$ROOT/.flywheel/scripts/frozen-pane-detector-fleet.sh" events="$TMP/fleet-events.jsonl" detector="$TMP/fleet-detector.json" out="$TMP/fleet.out"
  jq -nc '{schema_version:"frozen-pane-detector.v2",success:true,session:"all",source_health:{status:"healthy"},l60_signals_present:{no_silent_darkness:true}}' >"$detector"
  FROZEN_FLEET_DETECTOR_FIXTURE="$detector" FROZEN_FLEET_STATE_DIR="$TMP/fleet-state" \
  FROZEN_FLEET_EVENTS="$events" FROZEN_FLEET_PLIST="$TMP/fleet.plist" \
  FROZEN_FLEET_STDOUT_PATH="$TMP/fleet.out.log" FROZEN_FLEET_STDERR_PATH="$TMP/fleet.err.log" \
  FROZEN_FLEET_STOP_FILE="$TMP/no-stop" FROZEN_FLEET_GLOBAL_STOP_FILE="$TMP/no-global-stop" \
  FROZEN_FLEET_FATAL_FILE="$TMP/no-fatal" FLYWHEEL_JSONL_APPEND_LIB="$LIB" \
    "$script" cycle --json >"$out"
  if [[ "$(json_line "$out")" == "$(json_line "$events")" ]]; then
    pass "fleet valid append readback"
  else
    fail "fleet valid append readback"
  fi
  assert_empty_rejected "fleet"
  local blocked="$TMP/fleet-blocked" blocked_out="$TMP/fleet-blocked.out" blocked_err="$TMP/fleet-blocked.err"
  make_blocked_dir "$blocked"
  FROZEN_FLEET_DETECTOR_FIXTURE="$detector" FROZEN_FLEET_STATE_DIR="$TMP/fleet-blocked-state" \
  FROZEN_FLEET_EVENTS="$blocked/events.jsonl" FROZEN_FLEET_PLIST="$TMP/fleet-blocked.plist" \
  FROZEN_FLEET_STDOUT_PATH="$TMP/fleet-blocked.out.log" FROZEN_FLEET_STDERR_PATH="$TMP/fleet-blocked.err.log" \
  FROZEN_FLEET_STOP_FILE="$TMP/no-stop" FROZEN_FLEET_GLOBAL_STOP_FILE="$TMP/no-global-stop" \
  FROZEN_FLEET_FATAL_FILE="$TMP/no-fatal" FLYWHEEL_JSONL_APPEND_LIB="$LIB" \
    "$script" cycle --json >"$blocked_out" 2>"$blocked_err"
  restore_dir "$blocked"
  if jq -e '.success == true' "$blocked_out" >/dev/null && grep -q 'append failed' "$blocked_err" && [[ ! -e "$blocked/events.jsonl" ]]; then
    pass "fleet append failure continues"
  else
    fail "fleet append failure continues"
  fi
}

test_mobile() {
  local script="$ROOT/.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh" log="$TMP/mobile.jsonl" out_dir="$TMP/mobile-out"
  write_mobile_tools
  PATH="$TMP/bin:$PATH" MOBILE_EATS_PRODUCT_TICK="$TMP/product-tick" MOBILE_EATS_RECEIPT_BRIDGE="$TMP/receipt-bridge" \
  MOBILE_EATS_LOOP_OUT_DIR="$out_dir" MOBILE_EATS_RECEIPT_MIRROR_LOG="$log" FLYWHEEL_JSONL_APPEND_LIB="$LIB" \
    "$script"
  set +e
  PATH="$TMP/bin:$PATH" BRIDGE_FAIL=1 MOBILE_EATS_PRODUCT_TICK="$TMP/product-tick" MOBILE_EATS_RECEIPT_BRIDGE="$TMP/receipt-bridge" \
  MOBILE_EATS_LOOP_OUT_DIR="$out_dir" MOBILE_EATS_RECEIPT_MIRROR_LOG="$log" FLYWHEEL_JSONL_APPEND_LIB="$LIB" \
    "$script"
  bridge_rc=$?
  set -e
  local expected_success expected_error
  expected_success="$(jq -nc --arg ts "2026-05-05T00:00:00Z" --arg out "$out_dir/last_tick_mobile-eats.json" --argjson tick_rc 0 '{ts:$ts,event:"receipt_mirrored",path:$out,tick_exit:$tick_rc}')"
  expected_error="$(jq -nc --arg ts "2026-05-05T00:00:00Z" --arg out "$out_dir/last_tick_mobile-eats.json" --argjson tick_rc 0 --argjson bridge_rc 7 '{ts:$ts,event:"receipt_mirror_failed",path:$out,tick_exit:$tick_rc,bridge_exit:$bridge_rc}')"
  if [[ "$bridge_rc" == "7" ]] && [[ "$(sed -n '1p' "$log")" == "$expected_success" ]] && [[ "$(sed -n '2p' "$log")" == "$expected_error" ]]; then
    pass "mobile valid append readback"
  else
    fail "mobile valid append readback"
  fi
  assert_empty_rejected "mobile"
  local blocked="$TMP/mobile-blocked" blocked_err="$TMP/mobile-blocked.err"
  make_blocked_dir "$blocked"
  PATH="$TMP/bin:$PATH" MOBILE_EATS_PRODUCT_TICK="$TMP/product-tick" MOBILE_EATS_RECEIPT_BRIDGE="$TMP/receipt-bridge" \
  MOBILE_EATS_LOOP_OUT_DIR="$TMP/mobile-blocked-out" MOBILE_EATS_RECEIPT_MIRROR_LOG="$blocked/log.jsonl" \
  FLYWHEEL_JSONL_APPEND_LIB="$LIB" "$script" 2>"$blocked_err"
  restore_dir "$blocked"
  if grep -q 'append failed' "$blocked_err" && [[ ! -e "$blocked/log.jsonl" ]]; then
    pass "mobile append failure continues"
  else
    fail "mobile append failure continues"
  fi
}

test_storage() {
  local script="$ROOT/.flywheel/scripts/storage-probe.sh" fixture="$TMP/storage-fixture.json" history="$TMP/storage.jsonl" out="$TMP/storage.out"
  fixture_storage "$fixture"
  FLYWHEEL_JSONL_APPEND_LIB="$LIB" "$script" --fixture "$fixture" --history "$history" --record-history --json >"$out"
  if [[ "$(json_line "$out")" == "$(json_line "$history")" ]]; then
    pass "storage valid append readback"
  else
    fail "storage valid append readback"
  fi
  assert_empty_rejected "storage"
  local blocked="$TMP/storage-blocked" blocked_out="$TMP/storage-blocked.out" blocked_err="$TMP/storage-blocked.err"
  make_blocked_dir "$blocked"
  FLYWHEEL_JSONL_APPEND_LIB="$LIB" "$script" --fixture "$fixture" --history "$blocked/history.jsonl" --record-history --json >"$blocked_out" 2>"$blocked_err"
  restore_dir "$blocked"
  if jq -e '.version == "storage-probe.v1"' "$blocked_out" >/dev/null && grep -q 'append failed' "$blocked_err" && [[ ! -e "$blocked/history.jsonl" ]]; then
    pass "storage append failure continues"
  else
    fail "storage append failure continues"
  fi
}

test_leverage
test_headless
test_fleet
test_mobile
test_storage

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "15" && "$fail_count" == "0" ]]
