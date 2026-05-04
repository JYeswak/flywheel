#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLI="$ROOT/.flywheel/scripts/jeff-intel-network.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-intel-network-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

HOME_FIX="$TMP/home"
STATE="$TMP/state/jeff-intel"
FW_STATE="$TMP/state/flywheel"
mkdir -p "$HOME_FIX/Library/LaunchAgents" "$TMP/bin" "$STATE" "$FW_STATE"
touch "$HOME_FIX/Library/LaunchAgents/ai.zeststream.flywheel-daily-jeff-ingest.plist"
touch "$HOME_FIX/Library/LaunchAgents/ai.zeststream.flywheel-jeff-x-poll.plist"
printf '0\tai.zeststream.flywheel-daily-jeff-ingest\n0\tai.zeststream.flywheel-jeff-x-poll\n' >"$TMP/launchctl.txt"
printf 'github:Dicklesworthstone/ntm\nx:@doodlestein\n' >"$TMP/sources.txt"
cat >"$TMP/storage-probe.sh" <<'EOF'
#!/usr/bin/env bash
jq -nc '{status:"pass",disk_free_pct:90,disk_free_gb:900,warnings:[],errors:[]}'
EOF
chmod +x "$TMP/storage-probe.sh"

export HOME="$HOME_FIX"
export JEFF_INTEL_STATE_DIR="$STATE"
export FLYWHEEL_STATE_DIR="$FW_STATE"
export JEFF_INTEL_LAUNCHCTL_LIST_FIXTURE="$TMP/launchctl.txt"
export DAILY_JEFF_STATE_DIR="$FW_STATE"
export DAILY_JEFF_SOURCES_FILE="$TMP/sources.txt"
export DAILY_JEFF_STORAGE_PROBE="$TMP/storage-probe.sh"

if bash -n "$CLI"; then pass "helper bash syntax"; else fail "helper bash syntax"; fi
if shellcheck "$CLI"; then pass "helper shellcheck"; else fail "helper shellcheck"; fi
if "$CLI" --help | grep -q 'jeff-intel-network.sh doctor'; then pass "help names canonical helper"; else fail "help names canonical helper"; fi
if "$CLI" --info | jq -e '.schema_version == "jeff-intel-network/info/v1"' >/dev/null; then pass "info json"; else fail "info json"; fi
if "$CLI" --examples --json | jq -e '.examples | length >= 4' >/dev/null; then pass "examples json"; else fail "examples json"; fi
"$CLI" schema doctor --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.canonical_paths.helper == ".flywheel/scripts/jeff-intel-network.sh"' "schema names helper"
if "$CLI" quickstart >/dev/null; then pass "quickstart"; else fail "quickstart"; fi
if "$CLI" completion bash | grep -q 'jeff-intel-network.sh'; then pass "completion"; else fail "completion"; fi
"$CLI" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "pass" and .success == true and .scheduled_runner.loaded.daily == true and .daily_ingest.success == true' "doctor passes with fixtures"
"$CLI" health --json >"$TMP/health.json"
assert_jq "$TMP/health.json" '.mode == "health" and .status == "pass"' "health json"
"$CLI" repair --scope state --dry-run --json >"$TMP/repair-dry.json"
assert_jq "$TMP/repair-dry.json" '.status == "dry_run" and (.actual_actions | length) == 0' "repair dry-run"
"$CLI" repair --scope state --apply --idempotency-key fixture --json >"$TMP/repair-apply.json"
assert_jq "$TMP/repair-apply.json" '.status == "applied" and (.actual_actions | length) >= 3 and .idempotency_key == "fixture"' "repair apply"
"$CLI" validate --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.status == "pass" and .checks.helper_executable and .checks.slash_exists and .checks.tick_names_canonical' "validate docs agree"
if "$CLI" audit --json | jq empty; then pass "audit json"; else fail "audit json"; fi
"$CLI" why L63 --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.provenance.doctrine == "AGENTS.md L63"' "why provenance"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
