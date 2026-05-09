#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LAUNCHCTL="${WATCHER_LAUNCHD_LAUNCHCTL:-launchctl}"
LEDGER="${WATCHER_DETECTOR_LEDGER:-$HOME/.local/state/flywheel/codex-stuck-detector.jsonl}"
TOPOLOGY="${WATCHER_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
MAX_AGE_SECONDS="${WATCHER_MAX_AGE_SECONDS:-90}"
DOMAIN="${WATCHER_LAUNCHD_DOMAIN:-gui/$(id -u)}"
PRIMARY_LOG="${WATCHER_PRIMARY_LOG:-$HOME/.local/logs/codex-template-stuck-detector-watchdog.out.log}"
SESSION_LOG_DIR="${WATCHER_SESSION_LOG_DIR:-$HOME/.local/state/flywheel}"
SUBCLASS="post_callback_reminder_template_with_stale_spinner"
PATTERN_TEST="$ROOT/.flywheel/tests/test-detector-pattern-bank-replay.sh"
DETECTOR="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"

DEFAULT_SPECS=(
  "ai.zeststream.codex-stuck-detector-watchdog:flywheel:primary"
  "ai.zeststream.flywheel-coordinator-daemon:flywheel:coordinator"
  "ai.zeststream.mobile-eats-codex-stuck-detector:mobile-eats:session"
  "ai.zeststream.skillos-codex-stuck-detector:skillos:session"
  "ai.zeststream.alps-codex-stuck-detector:alpsinsurance:session"
  "ai.zeststream.vrtx-codex-stuck-detector:vrtx:session"
)

fail() {
  printf 'FAIL: %s\n' "$1"
  exit 1
}

log_for_session() {
  if [[ "$1" == "flywheel" ]]; then
    printf '%s\n' "$PRIMARY_LOG"
  else
    printf '%s\n' "$SESSION_LOG_DIR/codex-stuck-detector.$1.log"
  fi
}

latest_for_session() {
  python3 -c 'import json, sys
from datetime import datetime, timezone
from pathlib import Path

ledger, log_path, session, max_age_raw = sys.argv[1:5]
max_age = int(float(max_age_raw))
latest = None
latest_source = None

def row_matches_session(row):
    if row.get("session") == session:
        return True
    panes = row.get("panes")
    if isinstance(panes, list):
        return any(isinstance(pane, dict) and pane.get("session") == session for pane in panes)
    return False

def parse_ts(raw):
    if not isinstance(raw, str):
        return None
    try:
        dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

for source, path_raw in (("ledger", ledger), ("launchd-log", log_path)):
    path = Path(path_raw)
    if not path.exists() or path.stat().st_size == 0:
        continue
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not row_matches_session(row):
                continue
            dt = parse_ts(row.get("ts"))
            if dt is None:
                continue
            if latest is None or dt > latest:
                latest = dt
                latest_source = source

if latest is None:
    raise SystemExit(f"no detector timestamp for session={session} sources={ledger},{log_path}")
age = (datetime.now(timezone.utc) - latest).total_seconds()
if age < 0:
    age = 0
latest_s = latest.isoformat().replace("+00:00", "Z")
if age > max_age:
    raise SystemExit(f"last-run-ts stale: session={session} ts={latest_s} age_seconds={int(age)} max_age_seconds={max_age}")
print(f"{latest_s} {latest_source} {int(age)}")' "$LEDGER" "$(log_for_session "$1")" "$1" "$MAX_AGE_SECONDS"
}

topology_has_session() {
  python3 -c 'import json, sys
path, wanted = sys.argv[1:3]
latest = {}
with open(path, encoding="utf-8") as handle:
    for line in handle:
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        session = row.get("session")
        if not session:
            continue
        prev = latest.get(session)
        if prev is None or str(row.get("effective_at") or "") >= str(prev.get("effective_at") or ""):
            latest[session] = row
row = latest.get(wanted)
if not row:
    raise SystemExit(f"missing latest topology row for session={wanted}")
if row.get("session_status") and "not_live" in str(row.get("session_status")):
    raise SystemExit(f"latest topology row is not live for session={wanted}")
' "$TOPOLOGY" "$1"
}

specs=("${DEFAULT_SPECS[@]}")
if [[ -n "${WATCHER_LAUNCHD_LABEL:-}" ]]; then
  specs=("${WATCHER_LAUNCHD_LABEL}:${WATCHER_LAUNCHD_SESSION:-flywheel}:primary")
fi

test -x "$DETECTOR" || fail "detector not executable: $DETECTOR"
test -f "$PATTERN_TEST" || fail "fixture-pinned subclass test missing: $PATTERN_TEST"
grep -q "$SUBCLASS" "$PATTERN_TEST" || fail "fixture-pinned subclass not referenced by pattern replay test"
test -s "$LEDGER" || fail "detector ledger missing or empty: $LEDGER"
test -s "$TOPOLOGY" || fail "session topology missing or empty: $TOPOLOGY"

max_observed_age=0
checked=0
for spec in "${specs[@]}"; do
  IFS=: read -r label session kind <<<"$spec"
  plist="${WATCHER_LAUNCHD_PLIST_DIR:-$HOME/Library/LaunchAgents}/${label}.plist"

  test -f "$plist" || fail "plist missing: $plist"
  grep -q "<string>${label}</string>" "$plist" || fail "installed plist label mismatch: $label"
  if [[ "$kind" == "coordinator" ]]; then
    grep -q "ntm-coordinator-pinned" "$plist" || fail "coordinator command missing from plist: $label"
    grep -q -- "--session=${session}" "$plist" || fail "coordinator session missing from plist: $label"
  else
    grep -q "codex-template-stuck-detector.sh" "$plist" || fail "scheduled detector path missing from plist: $label"
    grep -q -- "--worker-panes-from-topology" "$plist" || fail "scheduled topology path missing from plist: $label"
    grep -q -- "--apply" "$plist" || fail "scheduled apply path missing from plist: $label"
  fi
  if [[ "$kind" == "session" ]]; then
    grep -q -- "--auto-recover" "$plist" || fail "scheduled auto-recover missing from plist: $label"
    grep -q "select(.session==\"${session}\")" "$plist" || fail "session topology filter missing from plist: $label"
  fi
  "$LAUNCHCTL" print "$DOMAIN/$label" >/dev/null 2>&1 || fail "launchctl print failed: $DOMAIN/$label"
  topology_has_session "$session" || fail "topology latest-wins missing session=$session"
  if [[ "$kind" == "coordinator" ]]; then
    ps -axo command= | grep -F "ntm-coordinator-pinned" | grep -F -- "--session=${session}" >/dev/null || fail "coordinator process missing from ps: $label"
  fi

  if [[ "$kind" == "session" ]]; then
    latest="$(latest_for_session "$session")" || fail "$latest"
    age_seconds="${latest##* }"
    if [[ "$age_seconds" -gt "$max_observed_age" ]]; then
      max_observed_age="$age_seconds"
    fi
  fi
  checked=$((checked + 1))
done

printf 'OK_watcher_launchd_active labels_checked=%s gui_domain=%s last_run_max_age_seconds=%s\n' "$checked" "$DOMAIN" "$max_observed_age"
