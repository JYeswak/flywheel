#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RUNNER="$ROOT/.flywheel/scripts/jeff-intel-scheduled-runner.sh"
DAILY_PLIST="$HOME/Library/LaunchAgents/ai.zeststream.flywheel-daily-jeff-ingest.plist"
X_PLIST="$HOME/Library/LaunchAgents/ai.zeststream.flywheel-jeff-x-poll.plist"
MONTHLY_PLIST="$HOME/Library/LaunchAgents/ai.zeststream.flywheel-jeff-philosophy-monthly.plist"
TENTACLE_DRIFT_PLIST="$ROOT/launchd/ai.zeststream.flywheel-tentacle-drift-sweep.plist"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-intel-schedule.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" || true; fi
}

if bash -n "$RUNNER"; then pass "runner shell syntax"; else fail "runner shell syntax"; fi
if plutil -lint "$DAILY_PLIST" >/dev/null; then pass "daily launchd plist lint"; else fail "daily launchd plist lint"; fi
if plutil -lint "$X_PLIST" >/dev/null; then pass "x launchd plist lint"; else fail "x launchd plist lint"; fi
if plutil -lint "$MONTHLY_PLIST" >/dev/null; then pass "monthly launchd plist lint"; else fail "monthly launchd plist lint"; fi
if plutil -lint "$TENTACLE_DRIFT_PLIST" >/dev/null; then pass "tentacle drift launchd plist lint"; else fail "tentacle drift launchd plist lint"; fi

"$RUNNER" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" \
  '.launchd_labels.daily == "ai.zeststream.flywheel-daily-jeff-ingest" and .launchd_labels.x_hourly == "ai.zeststream.flywheel-jeff-x-poll" and .launchd_labels.monthly_deep_mine == "ai.zeststream.flywheel-jeff-philosophy-monthly" and .launchd_labels.tentacle_drift == "ai.zeststream.flywheel-tentacle-drift-sweep" and .source_cadence.github_git and .source_cadence.website_rss and .source_cadence.x and (.source_cadence.jeff_philosophy | contains("monthly")) and (.source_cadence.tentacle_drift | contains("weekly"))' \
  "schema documents labels and source cadences"
assert_jq "$TMP/schema.json" \
  '.receipt_paths.schedule == "'"$HOME"'/.local/state/jeff-intel/scheduled-runs.jsonl" and .receipt_paths.x_poll == "'"$HOME"'/.local/state/jeff-intel/x-poll.jsonl" and .receipt_paths.jeff_philosophy_audit == "'"$HOME"'/.local/state/jeff-philosophy/audit.jsonl" and .receipt_paths.tentacle_drift == "'"$HOME"'/.local/state/flywheel/tentacle-drift.jsonl" and .receipt_paths.tentacle_drift_alerts == "'"$HOME"'/.local/state/flywheel/tentacle-drift-alerts.jsonl"' \
  "schema documents receipt paths"

cat >"$TMP/source-regen.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mode="dry-run"
key=""
now=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) mode="dry-run"; shift ;;
    --apply) mode="apply"; shift ;;
    --idempotency-key) key="${2:-}"; shift 2 ;;
    --idempotency-key=*) key="${1#--idempotency-key=}"; shift ;;
    --now) now="${2:-}"; shift 2 ;;
    --json) shift ;;
    *) shift ;;
  esac
done
if [[ "$mode" == "apply" && -z "$key" ]]; then
  jq -nc '{status:"refused", reason:"missing_idempotency_key"}'
  exit 3
fi
jq -nc --arg mode "$mode" --arg key "$key" --arg now "$now" \
  '{status:"pass", mode:$mode, dry_run:($mode == "dry-run"), idempotency_key:$key, now:$now}'
EOF
cat >"$TMP/daily-ingest.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
dry_run=false
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then dry_run=true; fi
done
jq -nc --argjson dry_run "$dry_run" '{status:"pass", dry_run:$dry_run, new_items:0}'
EOF
cat >"$TMP/jeff-philosophy.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
dry_run=false
command="daily-snapshot"
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then dry_run=true; fi
  if [[ "$arg" == "--deep-mine" ]]; then command="deep-mine"; fi
done
jq -nc --arg command "$command" --argjson dry_run "$dry_run" '{status:"pass", command:$command, dry_run:$dry_run, snapshot_path:"/tmp/fixture-jeff-philosophy.md", pattern_count:12, complete_pattern_count:12}'
EOF
chmod +x "$TMP/source-regen.sh" "$TMP/daily-ingest.sh" "$TMP/jeff-philosophy.sh"
cat >"$TMP/tentacle-drift.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
dry_run=false
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then dry_run=true; fi
done
jq -nc --argjson dry_run "$dry_run" '{status:"warn", dry_run:$dry_run, repo_count:2, alert_count:1, rows:[{repo:"fixture",local_head:"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",upstream_head:"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",commits_behind:51,status:"warn"}]}'
EOF
chmod +x "$TMP/tentacle-drift.sh"
JEFF_INTEL_STATE_DIR="$TMP/daily-state" FLYWHEEL_STATE_DIR="$TMP/flywheel-state" \
  JEFF_INTEL_SOURCE_REGEN_SCRIPT="$TMP/source-regen.sh" JEFF_INTEL_DAILY_SCRIPT="$TMP/daily-ingest.sh" \
  JEFF_PHILOSOPHY_SCRIPT="$TMP/jeff-philosophy.sh" \
  JEFF_INTEL_NOW="2026-05-04T00:00:00Z" \
  "$RUNNER" --mode daily --dry-run --json >"$TMP/daily-dry.json"
assert_jq "$TMP/daily-dry.json" '.status == "pass" and .dry_run == true and .exit_codes.source_regeneration == 0 and .exit_codes.daily_jeff_ingest == 0 and .exit_codes.jeff_philosophy_daily_snapshot == 0 and .jeff_philosophy_daily_snapshot.command == "daily-snapshot" and .jeff_philosophy_daily_snapshot.dry_run == true' \
  "daily dry-run runs intel and philosophy snapshot"
assert_jq "$TMP/daily-dry.json" '.source_regeneration.mode == "dry-run" and .source_regeneration.idempotency_key == "" and .source_regeneration.now == "2026-05-04T00:00:00Z"' \
  "daily dry-run keeps source regeneration non-mutating"
if [[ ! -e "$TMP/daily-state/scheduled-runs.jsonl" ]]; then
  pass "daily dry-run skips schedule ledger write"
else
  fail "daily dry-run skips schedule ledger write"
fi

JEFF_INTEL_STATE_DIR="$TMP/daily-apply-state" FLYWHEEL_STATE_DIR="$TMP/flywheel-apply-state" \
  JEFF_INTEL_SOURCE_REGEN_SCRIPT="$TMP/source-regen.sh" JEFF_INTEL_DAILY_SCRIPT="$TMP/daily-ingest.sh" \
  JEFF_PHILOSOPHY_SCRIPT="$TMP/jeff-philosophy.sh" \
  JEFF_INTEL_NOW="2026-05-04T00:00:00Z" \
  "$RUNNER" --mode daily --json >"$TMP/daily-apply.json"
assert_jq "$TMP/daily-apply.json" '.status == "pass" and .dry_run == false and .exit_codes.source_regeneration == 0 and .source_regeneration.mode == "apply" and .source_regeneration.idempotency_key == "daily-jeff-sources-2026-05-04" and .source_regeneration.now == "2026-05-04T00:00:00Z" and .daily_jeff_ingest.dry_run == false' \
  "daily apply regenerates sources with per-day idempotency key before ingest"
if [[ -s "$TMP/daily-apply-state/scheduled-runs.jsonl" ]]; then pass "daily apply writes schedule ledger"; else fail "daily apply writes schedule ledger"; fi

JEFF_INTEL_STATE_DIR="$TMP/monthly-state" FLYWHEEL_STATE_DIR="$TMP/flywheel-state" \
  JEFF_PHILOSOPHY_SCRIPT="$TMP/jeff-philosophy.sh" \
  JEFF_INTEL_NOW="2026-06-01T04:00:00Z" \
  "$RUNNER" --mode monthly-deep-mine --dry-run --json >"$TMP/monthly-dry.json"
assert_jq "$TMP/monthly-dry.json" '.status == "pass" and .dry_run == true and .cadence == "monthly" and .exit_codes.jeff_philosophy_deep_mine == 0 and .jeff_philosophy_deep_mine.command == "deep-mine" and .jeff_philosophy_deep_mine.dry_run == true' \
  "monthly dry-run runs philosophy deep mine"
if [[ ! -e "$TMP/monthly-state/scheduled-runs.jsonl" ]]; then
  pass "monthly dry-run skips schedule ledger write"
else
  fail "monthly dry-run skips schedule ledger write"
fi

JEFF_INTEL_STATE_DIR="$TMP/tentacle-state" FLYWHEEL_STATE_DIR="$TMP/flywheel-state" \
  TENTACLE_DRIFT_SCRIPT="$TMP/tentacle-drift.sh" \
  JEFF_INTEL_NOW="2026-05-11T03:30:00Z" \
  "$RUNNER" --mode tentacle-drift --dry-run --json >"$TMP/tentacle-drift-dry.json"
assert_jq "$TMP/tentacle-drift-dry.json" '.status == "pass" and .dry_run == true and .cadence == "weekly" and .exit_codes.tentacle_drift == 0 and .tentacle_drift.status == "warn" and .tentacle_drift.rows[0].commits_behind == 51' \
  "tentacle drift dry-run routes warning receipt"
if [[ ! -e "$TMP/tentacle-state/scheduled-runs.jsonl" ]]; then
  pass "tentacle drift dry-run skips schedule ledger write"
else
  fail "tentacle drift dry-run skips schedule ledger write"
fi

printf 'tweet one\nhttps://x.com/doodlestein/status/1\n' >"$TMP/x.md"
JEFF_INTEL_STATE_DIR="$TMP/state" JEFF_INTEL_X_FIXTURE="$TMP/x.md" JEFF_INTEL_NOW="2026-05-04T00:00:00Z" \
  "$RUNNER" --mode x-poll --dry-run --json >"$TMP/x-dry.json"
assert_jq "$TMP/x-dry.json" '.status == "pass" and .dry_run == true and .cadence == "hourly" and .snapshot_path == null' "x dry-run passes without writes"

JEFF_INTEL_STATE_DIR="$TMP/state" JEFF_INTEL_X_FIXTURE="$TMP/x.md" JEFF_INTEL_NOW="2026-05-04T00:00:00Z" \
  "$RUNNER" --mode x-poll --json >"$TMP/x-apply.json"
assert_jq "$TMP/x-apply.json" '.status == "pass" and .dry_run == false and (.latest_path | test("latest.md"))' "x apply writes latest path"
if [[ -s "$TMP/state/x-poll.jsonl" ]]; then pass "x receipt ledger written"; else fail "x receipt ledger written"; fi
if [[ -s "$TMP/state/scheduled-runs.jsonl" ]]; then pass "schedule receipt ledger written"; else fail "schedule receipt ledger written"; fi

cat >"$TMP/launchctl-list.txt" <<'EOF'
-	0	ai.zeststream.flywheel-daily-jeff-ingest
-	0	ai.zeststream.flywheel-jeff-x-poll
-	0	ai.zeststream.flywheel-jeff-philosophy-monthly
-	0	ai.zeststream.flywheel-tentacle-drift-sweep
EOF
JEFF_INTEL_STATE_DIR="$TMP/state" JEFF_INTEL_LAUNCHCTL_LIST_FIXTURE="$TMP/launchctl-list.txt" \
  "$RUNNER" --mode doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "pass" and .loaded.daily == true and .loaded.x_hourly == true and .loaded.monthly_deep_mine == true and .loaded.tentacle_drift == true and .plist_exists.daily == true and .plist_exists.x_hourly == true and .plist_exists.monthly_deep_mine == true and .plist_exists.tentacle_drift == true' "doctor validates loaded labels and plists"

if rg -q 'ai.zeststream.flywheel-daily-jeff-ingest' "$ROOT/.flywheel/canonical-paths.txt" "$DAILY_PLIST" "$RUNNER"; then
  pass "registry/launchd/runner mention daily label"
else
  fail "registry/launchd/runner mention daily label"
fi
if rg -q 'ai.zeststream.flywheel-jeff-x-poll' "$ROOT/.flywheel/canonical-paths.txt" "$X_PLIST" "$RUNNER"; then
  pass "registry/launchd/runner mention x label"
else
  fail "registry/launchd/runner mention x label"
fi
if rg -q 'ai.zeststream.flywheel-jeff-philosophy-monthly' "$MONTHLY_PLIST" "$RUNNER"; then
  pass "launchd/runner mention monthly philosophy label"
else
  fail "launchd/runner mention monthly philosophy label"
fi
if rg -q 'ai.zeststream.flywheel-tentacle-drift-sweep' "$ROOT/.flywheel/canonical-paths.txt" "$TENTACLE_DRIFT_PLIST" "$RUNNER"; then
  pass "registry/launchd/runner mention tentacle drift label"
else
  fail "registry/launchd/runner mention tentacle drift label"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL jeff-intel-schedule tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS jeff-intel-schedule tests pass=%s fail=%s\n' "$pass_count" "$fail_count"
