#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LABEL="${WATCHER_LAUNCHD_LABEL:-ai.zeststream.codex-stuck-detector-watchdog}"
PLIST="${WATCHER_LAUNCHD_PLIST:-$HOME/Library/LaunchAgents/${LABEL}.plist}"
LAUNCHCTL="${WATCHER_LAUNCHD_LAUNCHCTL:-launchctl}"
LEDGER="${WATCHER_DETECTOR_LEDGER:-$HOME/.local/state/flywheel/codex-stuck-detector.jsonl}"
MAX_AGE_SECONDS="${WATCHER_MAX_AGE_SECONDS:-90}"
DOMAIN="${WATCHER_LAUNCHD_DOMAIN:-gui/$(id -u)}"
SUBCLASS="post_callback_reminder_template_with_stale_spinner"
PATTERN_TEST="$ROOT/.flywheel/tests/test-detector-pattern-bank-replay.sh"
DETECTOR="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"

fail() {
  printf 'FAIL: %s\n' "$1"
  exit 1
}

test -f "$PLIST" || fail "plist missing: $PLIST"
grep -q "<string>${LABEL}</string>" "$PLIST" || fail "installed plist label mismatch"
grep -q "codex-template-stuck-detector.sh" "$PLIST" || fail "scheduled detector path missing from plist"
grep -q -- "--worker-panes-from-topology" "$PLIST" || fail "scheduled topology path missing from plist"
grep -q -- "--apply" "$PLIST" || fail "scheduled apply path missing from plist"
test -x "$DETECTOR" || fail "detector not executable: $DETECTOR"
test -f "$PATTERN_TEST" || fail "fixture-pinned subclass test missing: $PATTERN_TEST"
grep -q "$SUBCLASS" "$PATTERN_TEST" || fail "fixture-pinned subclass not referenced by pattern replay test"
"$LAUNCHCTL" print "$DOMAIN/$LABEL" >/dev/null 2>&1 || fail "launchctl print failed: $DOMAIN/$LABEL"
test -s "$LEDGER" || fail "detector ledger missing or empty: $LEDGER"

latest="$(
  python3 -c 'import json, sys
from datetime import datetime, timezone

ledger, max_age_raw = sys.argv[1], sys.argv[2]
max_age = int(float(max_age_raw))
latest = None
with open(ledger, encoding="utf-8") as handle:
    for line in handle:
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        ts = row.get("ts")
        if not isinstance(ts, str):
            continue
        try:
            dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
        except ValueError:
            continue
        if latest is None or dt > latest:
            latest = dt
if latest is None:
    raise SystemExit("no parseable detector ledger timestamp")
age = (datetime.now(timezone.utc) - latest).total_seconds()
if age < 0:
    age = 0
latest_s = latest.isoformat().replace("+00:00", "Z")
if age > max_age:
    raise SystemExit(f"last-run-ts stale: ts={latest_s} age_seconds={int(age)} max_age_seconds={max_age}")
print(f"{latest_s} {int(age)}")' "$LEDGER" "$MAX_AGE_SECONDS"
)" || fail "$latest"

last_ts="${latest%% *}"
age_seconds="${latest##* }"
printf 'OK_watcher_launchd_active label=%s last_run_ts=%s age_seconds=%s\n' "$LABEL" "$last_ts" "$age_seconds"
