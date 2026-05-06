#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/watcher-isomorphic-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/watcher-isomorphic.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,220p' "$file" >&2 || true
  fi
}

write_plist() {
  local path="$1" label="$2"
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>
  <key>ProgramArguments</key>
  <array><string>/bin/echo</string><string>fixture</string></array>
</dict>
</plist>
XML
}

seed_common() {
  local dir="$1"
  mkdir -p "$dir/state" "$dir/LaunchAgents" "$dir/LaunchAgents/.disabled"
  printf '%s\n' \
    '{"fixture_cases":[{"fixture_id":"G_post_completion_buffer_no_autosubmit","status":"pass"}]}' \
    >"$dir/selftest.json"
  printf '%s\n' \
    '{"ts":"2026-05-05T02:00:00Z","event":"recovery","false_positive":false}' \
    >"$dir/recovery.jsonl"
  write_plist "$dir/LaunchAgents/ai.zeststream.fixture.plist" "ai.zeststream.fixture"
  printf '%s\n' \
    '{"ts":"2026-05-05T02:00:00Z","action":"register","label":"ai.zeststream.fixture","reason":"fixture watcher proof bead flywheel-1uors"}' \
    >"$dir/registry.jsonl"
  printf '%s\n' \
    '[{"id":"flywheel-open","status":"open"},{"id":"flywheel-progress","status":"in_progress"}]' \
    >"$dir/ready.json"
  printf '%s\n' \
    '{"total":116,"by_class":{"silent-write":45,"destructive-default":64,"unregistered-process":7}}' \
    >"$dir/trauma.json"
  printf '%s\n' \
    '[{"id":"action-1","has_receipt":true}]' \
    >"$dir/receipts.json"
}

run_case() {
  local dir="$1" outfile="$2"
  WATCHER_ISOMORPHIC_REPO="$ROOT" \
  WATCHER_ISOMORPHIC_STATE_DIR="$dir/state" \
  WATCHER_ISOMORPHIC_RECOVERY_LEDGER="$dir/recovery.jsonl" \
  WATCHER_ISOMORPHIC_SELFTEST_FIXTURE="$dir/selftest.json" \
  WATCHER_ISOMORPHIC_PLIST_REGISTRY="$dir/registry.jsonl" \
  WATCHER_ISOMORPHIC_LA_DIR="$dir/LaunchAgents" \
  WATCHER_ISOMORPHIC_DISABLED_DIR="$dir/LaunchAgents/.disabled" \
  WATCHER_ISOMORPHIC_READY_FIXTURE="$dir/ready.json" \
  WATCHER_ISOMORPHIC_TRAUMA_CURRENT="$dir/trauma.json" \
  WATCHER_ISOMORPHIC_RECEIPT_FIXTURE="$dir/receipts.json" \
  WATCHER_ISOMORPHIC_NOW="2026-05-05T02:30:00Z" \
    "$SCRIPT" --doctor --json >"$outfile" || true
}

if bash -n "$SCRIPT"; then
  pass "probe syntax"
else
  fail "probe syntax"
fi

base="$TMP/base"
seed_common "$base"
run_case "$base" "$TMP/base.json"
assert_jq "$TMP/base.json" '.schema_version == "watcher-isomorphic-probe.v1" and (.probes | length == 5)' "schema and five probes"
assert_jq "$TMP/base.json" '.status == "pass" and .watcher_reenable_recommendation == "green"' "all-pass fixture is green"
assert_jq "$TMP/base.json" '.sub_gaps_addressed | length == 7' "seven gaps addressed"
assert_jq "$TMP/base.json" '.trauma_trend_jsonl_bootstrapped == true and .baseline_total == 116' "trauma baseline bootstraps"
assert_jq "$TMP/base.json" '.tuning_ledger_initialized == true and .watcher_tuning_count_30d >= 1' "tuning ledger initializes"

fp="$TMP/fp"
seed_common "$fp"
printf '%s\n' '{"ts":"2026-05-05T02:00:00Z","event":"recovery","false_positive":true}' >"$fp/recovery.jsonl"
run_case "$fp" "$TMP/fp.json"
assert_jq "$TMP/fp.json" '.probes.pane_health.status == "fail" and .probes.pane_health.false_positive_count_24h == 1' "pane false-positive rate fails"

missing_g="$TMP/missing-g"
seed_common "$missing_g"
printf '%s\n' '{"fixture_cases":[{"fixture_id":"F_queued_not_submitted","status":"pass"}]}' >"$missing_g/selftest.json"
run_case "$missing_g" "$TMP/missing-g.json"
assert_jq "$TMP/missing-g.json" '.probes.pane_health.status == "fail" and .probes.pane_health.fixture_g_post_completion_buffer == "fail"' "fixture G is required"

plist_orphan="$TMP/plist-orphan"
seed_common "$plist_orphan"
write_plist "$plist_orphan/LaunchAgents/ai.zeststream.orphan.plist" "ai.zeststream.orphan"
run_case "$plist_orphan" "$TMP/plist-orphan.json"
assert_jq "$TMP/plist-orphan.json" '.probes.plist_registry_truth.status == "fail" and .probes.plist_registry_truth.unregistered_plist_count == 1' "reverse plist walk catches unregistered plist"

plist_generic="$TMP/plist-generic"
seed_common "$plist_generic"
printf '%s\n' '{"ts":"2026-05-05T02:00:00Z","action":"register","label":"ai.zeststream.fixture","reason":"registered"}' >"$plist_generic/registry.jsonl"
run_case "$plist_generic" "$TMP/plist-generic.json"
assert_jq "$TMP/plist-generic.json" '.probes.plist_registry_truth.status == "fail" and .probes.plist_registry_truth.generic_reason_count == 1' "generic registry reasons fail"

bead="$TMP/bead"
seed_common "$bead"
printf '%s\n' '[{"id":"flywheel-closed","status":"closed"}]' >"$bead/ready.json"
run_case "$bead" "$TMP/bead.json"
assert_jq "$TMP/bead.json" '.probes.ready_bead_status.status == "fail" and .ready_pool_stale_closed_count == 1' "ready sampler catches closed bead"

trauma="$TMP/trauma"
seed_common "$trauma"
printf '%s\n' '{"total":117,"by_class":{"silent-write":46,"destructive-default":64,"unregistered-process":7}}' >"$trauma/trauma.json"
run_case "$trauma" "$TMP/trauma.json"
assert_jq "$TMP/trauma.json" '.probes.trauma_class_trend.status == "fail" and .trauma_class_trend_24h_delta == 1' "trauma trend fails unexplained regression"

trauma_fix="$TMP/trauma-fix"
seed_common "$trauma_fix"
printf '%s\n' '{"total":117,"by_class":{"silent-write":46,"destructive-default":64,"unregistered-process":7}}' >"$trauma_fix/trauma.json"
WATCHER_ISOMORPHIC_RECENT_FIX_BEAD=1 run_case "$trauma_fix" "$TMP/trauma-fix.json"
assert_jq "$TMP/trauma-fix.json" '.probes.trauma_class_trend.status == "pass" and .probes.trauma_class_trend.recent_fix_bead_explains_regression == true' "recent fix bead can explain trauma regression"

receipt="$TMP/receipt"
seed_common "$receipt"
printf '%s\n' '[{"id":"action-1","has_receipt":false}]' >"$receipt/receipts.json"
run_case "$receipt" "$TMP/receipt.json"
assert_jq "$TMP/receipt.json" '.probes.receipt_completeness.status == "fail" and .orphan_action_count_24h == 1' "receipt sampler catches orphan action"

"$SCRIPT" --schema >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.properties.watcher_reenable_recommendation.enum == ["green","yellow","red"]' "schema exposes recommendation enum"
"$SCRIPT" --info >/dev/null && pass "info command"
"$SCRIPT" --examples >/dev/null && pass "examples command"
"$SCRIPT" quickstart >/dev/null && pass "quickstart command"
"$SCRIPT" completion >/dev/null && pass "completion command"

if [[ "$fail_count" -ne 0 ]]; then
  printf 'FAILED watcher-isomorphic-probe tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'OK watcher-isomorphic-probe tests pass=%s\n' "$pass_count"
