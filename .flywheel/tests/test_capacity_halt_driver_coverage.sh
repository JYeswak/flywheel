#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/capacity-halt-driver-coverage.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/capacity-halt-driver-coverage.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0; fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" || true; fi
}

write_plist() {
  local path="$1" label="$2" arg="$3" log="$4"
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>$label</string>
<key>ProgramArguments</key><array><string>/bin/bash</string><string>-lc</string><string>$arg</string></array>
<key>StartInterval</key><integer>60</integer>
<key>StandardOutPath</key><string>$log</string>
</dict></plist>
XML
}

LA="$TMP/LaunchAgents"; mkdir -p "$LA" "$TMP/logs"
detector='exec /Users/josh/Developer/flywheel/.flywheel/scripts/codex-template-stuck-detector.sh --session flywheel --worker-panes-from-topology --apply --auto-recover --json'
queued='exec /Users/josh/Developer/flywheel/.flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh --session flywheel --pane 2 --digest c --apply --json'
monitor='exec /Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector.sh --session all --json'
unrelated='exec /Users/josh/.claude/skills/storage-health/scripts/health-probe.sh --json'
watchdog='exec /Users/josh/Developer/flywheel/.flywheel/scripts/worker-auto-respawn-watchdog.sh --apply --json --quiet'

jq -nc '{ts:"2026-05-06T13:00:00Z",event:"launchd_fire"}' >"$TMP/logs/flywheel.log"
write_plist "$LA/ai.zeststream.flywheel-codex-stuck-detector.plist" "ai.zeststream.flywheel-codex-stuck-detector" "$detector" "$TMP/logs/flywheel.log"
write_plist "$LA/ai.zeststream.queued-direct.plist" "ai.zeststream.queued-direct" "$queued" "$TMP/logs/queued.log"
write_plist "$LA/ai.zeststream.frozen-pane-detector-fleet.plist" "ai.zeststream.frozen-pane-detector-fleet" "$monitor" "$TMP/logs/monitor.log"
write_plist "$LA/ai.zeststream.storage-health.plist" "ai.zeststream.storage-health" "$unrelated" "$TMP/logs/storage.log"
write_plist "$LA/ai.zeststream.worker-auto-respawn-watchdog.plist" "ai.zeststream.worker-auto-respawn-watchdog" "$watchdog" "$TMP/logs/watchdog.log"

bash -n "$SCRIPT" && pass "probe_syntax" || fail "probe_syntax"
"$SCRIPT" --info >/dev/null && pass "info_valid" || fail "info_valid"
"$SCRIPT" --help >/dev/null && pass "help_valid" || fail "help_valid"
"$SCRIPT" --examples >/dev/null && pass "examples_valid" || fail "examples_valid"
"$SCRIPT" --launch-agents-dir "$LA" --quiet >/dev/null && pass "quiet_valid" || fail "quiet_valid"
"$SCRIPT" --launch-agents-dir "$LA" --json >"$TMP/out.json"

assert_jq "$TMP/out.json" '.plists_audited_count == 5 and .classification_counts.drives_capacity_halt == 2 and .classification_counts.drives_queued_not_submitted == 1 and .classification_counts.monitors_only == 1 and .classification_counts.unrelated == 1' "four_category_matrix_counts"
assert_jq "$TMP/out.json" '(.capacity_halt_driver_sessions | index("flywheel")) and (.capacity_halt_driver_sessions | index("all"))' "known_capacity_halt_sessions_covered"
assert_jq "$TMP/out.json" '(.queued_not_submitted_driver_sessions | index("flywheel"))' "known_queued_sessions_covered"
assert_jq "$TMP/out.json" 'all(.plists[] | select(.category=="monitors_only"); (.capabilities|length)==0 and ((.invocation_chain|join(" ")) | test("capacity-halt-auto-continue|codex-queued-not-submitted") | not))' "monitors_only_no_recovery_primitive"

"$SCRIPT" --schema >"$TMP/schema.json"
python3 - "$TMP/schema.json" "$TMP/out.json" <<'PY' && pass "coverage_json_schema_validates" || fail "coverage_json_schema_validates"
import json, sys
from jsonschema import Draft7Validator
schema = json.load(open(sys.argv[1], encoding="utf-8"))
data = json.load(open(sys.argv[2], encoding="utf-8"))
Draft7Validator.check_schema(schema)
Draft7Validator(schema).validate(data)
PY

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
