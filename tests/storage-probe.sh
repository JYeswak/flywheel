#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/storage-probe.sh"
PRUNE="$ROOT/.flywheel/scripts/storage-prune.sh"
PROMOTE="$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh"
DAILY="$ROOT/.flywheel/scripts/daily-jeff-ingest.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/storage-probe-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

fixture() {
  local path="$1" pct="$2" baks="$3"
  jq -nc \
    --argjson pct "$pct" \
    --argjson baks "$baks" \
    '{
      disk_total_gb:926,
      disk_free_gb:(926 * $pct / 100),
      disk_free_pct:$pct,
      developer_dir_gb:328,
      local_state_gb:2.1,
      stale_baks_count:$baks,
      stale_baks_size_mb:12.5,
      qdrant_volumes_size_mb:217,
      tmp_dispatch_artifacts_count:3
    }' >"$path"
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

healthy="$TMP/healthy.json"
low="$TMP/low.json"
baks="$TMP/baks.json"
fire="$TMP/fire.json"
fixture "$healthy" 42 0
fixture "$low" 7.9 0
fixture "$baks" 30 6
fixture "$fire" 4.5 1

bash -n "$PROBE" && pass "storage_probe_syntax" || fail "storage_probe_syntax"
bash -n "$PRUNE" && pass "storage_prune_syntax" || fail "storage_prune_syntax"

"$PROBE" --fixture "$healthy" --json >"$TMP/healthy.out"
"$PROBE" --fixture "$low" --json >"$TMP/low.out"
"$PROBE" --fixture "$baks" --json >"$TMP/baks.out"
assert_jq "$TMP/healthy.out" '.status == "ok" and .disk_free_pct == 42 and (.errors | length) == 0' "healthy_fixture_ok"
assert_jq "$TMP/low.out" '.status == "fail" and any(.errors[]; .code == "storage_low_headroom")' "low_free_fails"
assert_jq "$TMP/baks.out" '.status == "fail" and any(.errors[]; .code == "storage_stale_baks_high")' "high_bak_count_fails"

history="$TMP/storage-history.jsonl"
"$PROBE" --fixture "$healthy" --history "$history" --record-history --json >/dev/null
if [ -s "$history" ] && jq -e '.version == "storage-probe.v1"' "$history" >/dev/null; then
  pass "history_append"
else
  fail "history_append"
fi

notify_log="$TMP/notify.log"
notify_bin="$TMP/notify"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"%s"\n' "$notify_log" >"$notify_bin"
chmod +x "$notify_bin"
NOTIFY_BIN="$notify_bin" "$PROBE" --fixture "$fire" --notify --json >/dev/null
if grep -q 'STORAGE LOW' "$notify_log"; then
  pass "fire_threshold_notify"
else
  fail "fire_threshold_notify"
fi

repo="$TMP/repo"
mkdir -p "$repo/.beads.bak.old" "$repo/.beads.bak.keep"
touch -t 202001010101 "$repo/.beads.bak.old"
"$PRUNE" --repo "$repo" --days 7 --dry-run --json >"$TMP/prune.out"
assert_jq "$TMP/prune.out" '.planned.stale_bak_dirs >= 1 and .docker_volumes_pruned == false' "storage_prune_dry_run_plans_only"

fake_br="$TMP/br"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "$1" in' \
  '  list) printf "{\"issues\":[]}\\n" ;;' \
  '  show) printf "[]\\n" ;;' \
  '  create) printf "{\"id\":\"flywheel-storage-fixture\"}\\n" ;;' \
  '  update) printf "{\"id\":\"updated\"}\\n" ;;' \
  '  *) printf "{}\\n" ;;' \
  'esac' >"$fake_br"
chmod +x "$fake_br"
doctor_json="$(jq -nc --slurpfile storage "$TMP/low.out" '{status:"fail",storage:$storage[0]}')"
BR_BIN="$fake_br" DOCTOR_SIGNAL_DOCTOR_JSON="$doctor_json" "$PROMOTE" "$repo" >"$TMP/promote.out"
assert_jq "$TMP/promote.out" '.actions[]? | test("storage")' "doctor_promotion_storage_symptom"

DAILY_JEFF_STORAGE_FIXTURE="$low" DAILY_JEFF_NOTIFY_BIN="$notify_bin" "$DAILY" --dry-run --json >"$TMP/daily-low.out" 2>/dev/null && daily_rc=0 || daily_rc=$?
if [ "$daily_rc" -ne 0 ] && jq -e '.success == false and .reason == "storage_low_headroom"' "$TMP/daily-low.out" >/dev/null; then
  pass "daily_ingest_aborts_on_low_storage"
else
  fail "daily_ingest_aborts_on_low_storage"
  cat "$TMP/daily-low.out" || true
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
