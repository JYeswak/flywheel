#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RUNNER="$ROOT/.flywheel/scripts/jeff-intel-scheduled-runner.sh"
DAILY_PLIST="$HOME/Library/LaunchAgents/ai.zeststream.flywheel-daily-jeff-ingest.plist"
X_PLIST="$HOME/Library/LaunchAgents/ai.zeststream.flywheel-jeff-x-poll.plist"
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

bash -n "$RUNNER" && pass "runner shell syntax" || fail "runner shell syntax"
plutil -lint "$DAILY_PLIST" >/dev/null && pass "daily launchd plist lint" || fail "daily launchd plist lint"
plutil -lint "$X_PLIST" >/dev/null && pass "x launchd plist lint" || fail "x launchd plist lint"

"$RUNNER" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" \
  '.launchd_labels.daily == "ai.zeststream.flywheel-daily-jeff-ingest" and .launchd_labels.x_hourly == "ai.zeststream.flywheel-jeff-x-poll" and .source_cadence.github_git and .source_cadence.website_rss and .source_cadence.x' \
  "schema documents labels and source cadences"
assert_jq "$TMP/schema.json" \
  '.receipt_paths.schedule == "'$HOME'/.local/state/jeff-intel/scheduled-runs.jsonl" and .receipt_paths.x_poll == "'$HOME'/.local/state/jeff-intel/x-poll.jsonl"' \
  "schema documents receipt paths"

printf 'tweet one\nhttps://x.com/doodlestein/status/1\n' >"$TMP/x.md"
JEFF_INTEL_STATE_DIR="$TMP/state" JEFF_INTEL_X_FIXTURE="$TMP/x.md" JEFF_INTEL_NOW="2026-05-04T00:00:00Z" \
  "$RUNNER" --mode x-poll --dry-run --json >"$TMP/x-dry.json"
assert_jq "$TMP/x-dry.json" '.status == "pass" and .dry_run == true and .cadence == "hourly" and .snapshot_path == null' "x dry-run passes without writes"

JEFF_INTEL_STATE_DIR="$TMP/state" JEFF_INTEL_X_FIXTURE="$TMP/x.md" JEFF_INTEL_NOW="2026-05-04T00:00:00Z" \
  "$RUNNER" --mode x-poll --json >"$TMP/x-apply.json"
assert_jq "$TMP/x-apply.json" '.status == "pass" and .dry_run == false and (.latest_path | test("latest.md"))' "x apply writes latest path"
test -s "$TMP/state/x-poll.jsonl" && pass "x receipt ledger written" || fail "x receipt ledger written"
test -s "$TMP/state/scheduled-runs.jsonl" && pass "schedule receipt ledger written" || fail "schedule receipt ledger written"

cat >"$TMP/launchctl-list.txt" <<'EOF'
-	0	ai.zeststream.flywheel-daily-jeff-ingest
-	0	ai.zeststream.flywheel-jeff-x-poll
EOF
JEFF_INTEL_STATE_DIR="$TMP/state" JEFF_INTEL_LAUNCHCTL_LIST_FIXTURE="$TMP/launchctl-list.txt" \
  "$RUNNER" --mode doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "pass" and .loaded.daily == true and .loaded.x_hourly == true and .plist_exists.daily == true and .plist_exists.x_hourly == true' "doctor validates loaded labels and plists"

rg -q 'ai.zeststream.flywheel-daily-jeff-ingest' "$ROOT/README.md" "$ROOT/AGENTS.md" \
  && pass "README/AGENTS mention daily label" || fail "README/AGENTS mention daily label"
rg -q 'ai.zeststream.flywheel-jeff-x-poll' "$ROOT/README.md" "$ROOT/AGENTS.md" \
  && pass "README/AGENTS mention x label" || fail "README/AGENTS mention x label"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL jeff-intel-schedule tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS jeff-intel-schedule tests pass=%s fail=%s\n' "$pass_count" "$fail_count"
