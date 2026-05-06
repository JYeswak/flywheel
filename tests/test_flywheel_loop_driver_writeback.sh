#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_LOOP_DRIVER_WRITEBACK_BIN:-$HOME/.local/bin/flywheel-loop-driver-writeback}"
REPO="${FLYWHEEL_TEST_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/loop-driver-writeback.XXXXXX")"
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

expect_rc() {
  local label="$1" expected="$2"
  shift 2
  set +e
  "$@" >/dev/null 2>"$TMP/$label.err"
  local rc=$?
  set -e
  if [[ "$rc" -eq "$expected" ]]; then
    pass "$label"
  else
    fail "$label rc=$rc expected=$expected"
    cat "$TMP/$label.err" >&2 || true
  fi
}

HOME_FIX="$TMP/home"
LOOPS="$HOME_FIX/.flywheel/loops"
STATE="$HOME_FIX/.local/state/flywheel"
LOGS="$HOME_FIX/.local/logs"
LAUNCH_AGENTS="$HOME_FIX/Library/LaunchAgents"
FAKE_BIN="$TMP/bin"
mkdir -p "$LOOPS" "$STATE" "$LOGS" "$LAUNCH_AGENTS" "$FAKE_BIN"

cat >"$FAKE_BIN/launchctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
state="${FLYWHEEL_LOOP_DRIVER_FAKE_LAUNCHCTL_LIST:?}"
case "${1:-list}" in
  list)
    cat "$state" 2>/dev/null || true
    ;;
  load)
    shift
    [[ "${1:-}" == "-w" ]] && shift
    plist="${1:?plist required}"
    label="$(python3 - "$plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as fh:
    print(plistlib.load(fh).get("Label", ""))
PY
)"
    grep -F "$label" "$state" >/dev/null 2>&1 || printf -- '-\t0\t%s\n' "$label" >>"$state"
    ;;
  *)
    printf 'unsupported fake launchctl verb: %s\n' "${1:-}" >&2
    exit 9
    ;;
esac
SH
chmod +x "$FAKE_BIN/launchctl"
: >"$TMP/launchctl-list.txt"

cat >"$TMP/registry.json" <<JSON
[
  {
    "orch": "alpha",
    "aliases": ["alpha"],
    "loop_file": "alpha.json",
    "project": "alpha",
    "repo": "$TMP/repo-alpha",
    "session": "alpha",
    "orchestrator_pane": 1,
    "interval": "5m",
    "plist_label": "ai.zeststream.alpha-flywheel-loop",
    "plist": "$LAUNCH_AGENTS/ai.zeststream.alpha-flywheel-loop.plist",
    "tick_script": "$BIN",
    "managed_plist": true,
    "launchd_interval_seconds": 300
  },
  {
    "orch": "beta",
    "aliases": ["beta"],
    "loop_file": "beta.json",
    "project": "beta",
    "repo": "$TMP/repo-beta",
    "session": "beta",
    "orchestrator_pane": 1,
    "interval": "5m",
    "plist_label": "ai.zeststream.beta-flywheel-loop",
    "plist": "$LAUNCH_AGENTS/ai.zeststream.beta-flywheel-loop.plist",
    "tick_script": "$BIN",
    "managed_plist": false
  },
  {
    "orch": "gamma",
    "aliases": ["gamma"],
    "loop_file": "gamma.json",
    "project": "gamma",
    "repo": "$TMP/repo-gamma",
    "session": "gamma",
    "orchestrator_pane": 1,
    "interval": "5m",
    "plist_label": "ai.zeststream.gamma-flywheel-loop",
    "plist": "$LAUNCH_AGENTS/ai.zeststream.gamma-flywheel-loop.plist",
    "tick_script": "$BIN",
    "managed_plist": false
  }
]
JSON

cat >"$LOOPS/alpha.json" <<'JSON'
{"active":true,"project":"alpha","repo":"/tmp/repo-alpha","interval":"5m"}
JSON
cat >"$LOOPS/beta.json" <<'JSON'
{"active":true,"project":"beta","repo":"/tmp/repo-beta","interval":"5m"}
JSON
cat >"$LOOPS/gamma.json" <<'JSON'
{"active":true,"project":"gamma","repo":"/tmp/repo-gamma","interval":"5m","last_tick":"2000-01-01T00:00:00Z","driver":"other","driver_status":"UNKNOWN","plist":"missing","plist_label":"ai.zeststream.wrong","last_run_ledger":"/tmp/missing","last_run_exit_code":7}
JSON
cat >"$LAUNCH_AGENTS/ai.zeststream.beta-flywheel-loop.plist" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>Label</key><string>ai.zeststream.beta-flywheel-loop</string></dict></plist>
XML

env_base=(
  "FLYWHEEL_LOOP_DRIVER_HOME=$HOME_FIX"
  "FLYWHEEL_LOOP_DRIVER_LOOPS_DIR=$LOOPS"
  "FLYWHEEL_LOOP_DRIVER_STATE_DIR=$STATE"
  "FLYWHEEL_LOOP_DRIVER_LOGS_DIR=$LOGS"
  "FLYWHEEL_LOOP_DRIVER_LAUNCH_AGENTS_DIR=$LAUNCH_AGENTS"
  "FLYWHEEL_LOOP_DRIVER_LEDGER=$STATE/loop-driver-runs.jsonl"
  "FLYWHEEL_LOOP_DRIVER_LAUNCHCTL=$FAKE_BIN/launchctl"
  "FLYWHEEL_LOOP_DRIVER_FAKE_LAUNCHCTL_LIST=$TMP/launchctl-list.txt"
  "FLYWHEEL_LOOP_DRIVER_ORCHS_JSON=$TMP/registry.json"
)

bash -n "$BIN" && pass "shell_syntax" || fail "shell_syntax"
env "${env_base[@]}" "$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "flywheel-loop-driver-writeback"' "info_surface"
env "${env_base[@]}" "$BIN" schema doctor --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.required | index("truths.launchctl_loaded")' "schema_surface"
env "${env_base[@]}" "$BIN" why l57 --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.explanation | contains("Loop telemetry")' "why_surface"
env "${env_base[@]}" "$BIN" quickstart --json >"$TMP/quickstart.json"
assert_jq "$TMP/quickstart.json" '.steps | length >= 4' "quickstart_surface"
env "${env_base[@]}" "$BIN" completion bash >/tmp/loop-driver-completion.txt
grep -q 'flywheel-loop-driver-writeback' /tmp/loop-driver-completion.txt && pass "completion_surface" || fail "completion_surface"

env "${env_base[@]}" "$BIN" repair --scope plists --orch alpha --dry-run --json >"$TMP/repair-dry.json"
assert_jq "$TMP/repair-dry.json" '.dry_run == true and (.actions[] | select(.status=="planned"))' "repair_dry_run_plans_only"
[[ ! -e "$LAUNCH_AGENTS/ai.zeststream.alpha-flywheel-loop.plist" ]] && pass "dry_run_no_plist_write" || fail "dry_run_no_plist_write"
expect_rc "apply_gate_requires_approval" 64 env "${env_base[@]}" "$BIN" repair --scope plists --orch alpha --apply --json

env "${env_base[@]}" APPROVE=yes "$BIN" repair --scope plists --orch alpha --apply --json >"$TMP/repair-plists.json"
assert_jq "$TMP/repair-plists.json" '.status == "pass" and (.actions[] | select(.action=="write_plist" and .status=="written"))' "repair_writes_managed_plist"
grep -q 'ai.zeststream.alpha-flywheel-loop' "$TMP/launchctl-list.txt" && pass "repair_loads_launchagent" || fail "repair_loads_launchagent"

expect_rc "doctor_catches_missing_last_tick" 1 env "${env_base[@]}" "$BIN" doctor --orch alpha --json
env "${env_base[@]}" "$BIN" run --orch alpha --json >"$TMP/run-alpha.json"
assert_jq "$TMP/run-alpha.json" '.status == "pass" and .results[0].ledger_line == 1' "run_writes_ledger"
assert_jq "$LOOPS/alpha.json" '.last_tick != null and .last_run_exit_code == 0' "run_writes_last_tick"
assert_jq "$LOOPS/alpha.json" '.plist_label == "ai.zeststream.alpha-flywheel-loop"' "plist_label_written"
[[ -z "$(find "$LOOPS" -name '.*.tmp' -print -quit)" ]] && pass "atomic_write_no_tmp_left" || fail "atomic_write_no_tmp_left"
env "${env_base[@]}" "$BIN" doctor --orch alpha --json >"$TMP/doctor-alpha.json"
assert_jq "$TMP/doctor-alpha.json" '.status == "pass" and .orchestrators[0].truths.loop_json_populated == true and .orchestrators[0].truths.launchctl_loaded == true and .orchestrators[0].truths.last_tick_fresh_lt_5m == true' "doctor_three_truths_pass"

env "${env_base[@]}" "$BIN" validate ledger --json >"$TMP/validate-good.json"
assert_jq "$TMP/validate-good.json" '.status == "pass" and .valid_rows >= 1' "validate_ledger_good"
printf '{bad json\n' >>"$STATE/loop-driver-runs.jsonl"
env "${env_base[@]}" "$BIN" validate ledger --json >"$TMP/validate-warn.json"
assert_jq "$TMP/validate-warn.json" '.status == "warn" and .invalid_rows == 1' "validate_ledger_malformed_warns"

env "${env_base[@]}" "$BIN" run --orch beta --json >/dev/null
expect_rc "doctor_catches_plist_not_loaded" 1 env "${env_base[@]}" "$BIN" doctor --orch beta --json
env "${env_base[@]}" "$BIN" doctor --orch beta --json >"$TMP/doctor-beta.json" || true
assert_jq "$TMP/doctor-beta.json" '.violations[] | select(.class=="loop_plist_not_loaded")' "plist_not_loaded_violation"

jq '.last_tick = "2000-01-01T00:00:00Z"' "$LOOPS/alpha.json" >"$TMP/alpha-stale.json"
mv "$TMP/alpha-stale.json" "$LOOPS/alpha.json"
env "${env_base[@]}" "$BIN" doctor --orch alpha --json >"$TMP/doctor-stale.json" || true
assert_jq "$TMP/doctor-stale.json" '.violations[] | select(.class=="loop_last_tick_stale_or_missing")' "stale_last_tick_violation"
env "${env_base[@]}" APPROVE=yes "$BIN" repair --scope last-tick-stale --orch alpha --apply --json >"$TMP/repair-last-tick.json"
assert_jq "$TMP/repair-last-tick.json" '.status == "pass" and .writebacks[0].ledger_line >= 1' "repair_last_tick_apply"
env "${env_base[@]}" APPROVE=yes "$BIN" repair --scope last-tick-stale --orch alpha --apply --json >"$TMP/repair-idempotent.json"
assert_jq "$TMP/repair-idempotent.json" '.status == "pass"' "repair_idempotent"

env "${env_base[@]}" "$BIN" doctor --orch gamma --json >"$TMP/doctor-gamma.json" || true
assert_jq "$TMP/doctor-gamma.json" '[.violations[].class] | index("loop_plist_missing") and index("loop_plist_not_loaded") and index("loop_last_tick_stale_or_missing")' "doctor_all_three_disagree"

jq -e '.primitives[] | select(.name=="loop-driver-writeback" and .path=="/Users/josh/.local/bin/flywheel-loop-driver-writeback")' "$REPO/.flywheel/scripts/tick-driver-manifest.json" >/dev/null \
  && pass "tick_driver_manifest_registration" || fail "tick_driver_manifest_registration"

if [[ "$fail_count" -eq 0 ]]; then
  printf 'OK loop-driver-writeback tests pass_count=%s\n' "$pass_count"
else
  printf 'FAIL loop-driver-writeback tests fail_count=%s pass_count=%s\n' "$fail_count" "$pass_count" >&2
  exit 1
fi
