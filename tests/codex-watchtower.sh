#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILL="$HOME/.claude/skills/codex-cli-tracker"
DAILY="$HOME/.local/bin/codex-watchtower-daily.sh"
PLIST="$HOME/Library/LaunchAgents/ai.zeststream.codex-watchtower-daily.plist"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-watchtower-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

check() {
  local label="$1"
  shift
  if "$@"; then pass "$label"; else fail "$label"; fi
}

check "daily script syntax" bash -n "$DAILY"
check "tracker probe syntax" bash -n "$SKILL/scripts/codex-tracker-probe.sh"
check "tick driver syntax" bash -n "$ROOT/.flywheel/flywheel-loop-tick"

for path in \
  "$SKILL/SKILL.md" \
  "$SKILL/data/sources.json" \
  "$SKILL/references/UPSTREAM-ISSUES.md" \
  "$SKILL/references/PINNED-VERSION-CONSTRAINTS.md" \
  "$SKILL/references/RECOVERY-PATTERNS.md" \
  "$SKILL/references/UPSTREAM-COMMENTS.md"
do
  check "skill artifact exists ${path#$SKILL/}" test -s "$path"
done

mkdir -p "$TMP/state"
printf '%s\n' '{"schema_version":"codex-watchtower.summary.v1","ts":"2026-05-04T00:00:00Z","kind":"summary","status":"CONFIRMED_CHANGED","codex_watchtower_status":"CONFIRMED_CHANGED","codex_new_issues_24h":1,"codex_relevant_issues":["#12645"],"codex_pinned_version":"codex-cli 0.125.0","codex_warnings":[],"ledger":"fixture"}' \
  >"$TMP/state/daily-2026-05-04.jsonl"

summary="$(CODEX_WATCHTOWER_STATE_DIR="$TMP/state" "$DAILY" --summary --json)"
if jq -e '.kind == "summary" and (.codex_relevant_issues | index("#12645"))' >/dev/null <<<"$summary"; then
  pass "daily summary fixture"
else
  fail "daily summary fixture"
fi

doctor="$(CODEX_WATCHTOWER_STATE_DIR="$TMP/state" "$DAILY" --doctor --json)"
if jq -e '.mode == "doctor" and .success == true' >/dev/null <<<"$doctor"; then
  pass "daily doctor fixture"
else
  fail "daily doctor fixture"
fi

probe="$(CODEX_WATCHTOWER_STATE_DIR="$TMP/state" "$SKILL/scripts/codex-tracker-probe.sh" --doctor --json)"
if jq -e '.mode == "doctor" and (.warnings | index("upstream_comments_missing") | not)' >/dev/null <<<"$probe"; then
  pass "tracker probe sees upstream comments"
else
  fail "tracker probe sees upstream comments"
fi

check "tick contains Step 4t log event" rg -q 'codex_watchtower_probe' "$ROOT/.flywheel/flywheel-loop-tick"
check "tick prompt contains codex watchtower section" rg -q 'Codex watchtower pre-tick' "$ROOT/.flywheel/flywheel-loop-tick"
check "tick receipt records codex watchtower" rg -q 'codex_watchtower' "$ROOT/.flywheel/flywheel-loop-tick"
check "incident cites openai codex 12645" rg -q 'openai/codex#12645|github.com/openai/codex/issues/12645' "$ROOT/INCIDENTS.md"
check "incident cross-references flywheel-3pko" rg -q 'flywheel-3pko' "$ROOT/INCIDENTS.md"
check "launchd plist label" plutil -extract Label raw "$PLIST"
check "launchd 09:00Z local schedule" sh -c 'plutil -extract StartCalendarInterval.Hour raw "$0" | grep -qx 3 && plutil -extract StartCalendarInterval.Minute raw "$0" | grep -qx 0' "$PLIST"

echo
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
