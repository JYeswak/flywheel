#!/usr/bin/env bash
# test-gap-hunt-probe-wired-but-cold-budget.sh
#
# flywheel-vmc7r regression: assert the wired-but-cold detector in
# gap-hunt-probe.sh stops false-flagging scripts whose only ledger
# reference is a ledger filename that sorts alphabetically late
# enough to be elided by the 4MB content budget.
#
# Fixture shape:
#   - GAP_HUNT_STATE_DIR/agents-md-junk-1.jsonl  (large, alphabetically first)
#   - GAP_HUNT_STATE_DIR/agents-md-junk-2.jsonl  (large)
#   - GAP_HUNT_STATE_DIR/agents-md-junk-3.jsonl  (large)
#   - GAP_HUNT_STATE_DIR/zzz-target-events.jsonl (small, references target)
#   - GAP_HUNT_CLAUDE_ROOT/skills/<target>.sh    (the script under test)
#
# OLD probe: alphabetical iteration consumes the 4MB budget on the three
# junk ledgers; zzz-target-events.jsonl never enters ledger_text. Target
# is flagged as wired-but-cold (false positive).
#
# NEW probe: name corpus always-complete; mtime-desc content. Target's
# stem appears in zzz-target-events.jsonl basename → not flagged.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="${GAP_HUNT_PROBE_BIN:-$ROOT/.flywheel/scripts/gap-hunt-probe.sh}"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if [[ ! -f "$PROBE" ]]; then
  printf 'SKIP gap-hunt-probe.sh missing at %s\n' "$PROBE"
  exit 77
fi

FIXTURE_ROOT="$(mktemp -d -t gap-hunt-vmc7r.XXXXXX)"
trap 'rm -f "$FIXTURE_ROOT"/state/*.jsonl "$FIXTURE_ROOT"/claude/skills/*.sh "$FIXTURE_ROOT"/repo/.flywheel/*.jsonl 2>/dev/null; rmdir "$FIXTURE_ROOT"/state "$FIXTURE_ROOT"/claude/skills "$FIXTURE_ROOT"/claude "$FIXTURE_ROOT"/repo/.flywheel "$FIXTURE_ROOT"/repo "$FIXTURE_ROOT" 2>/dev/null' EXIT

mkdir -p "$FIXTURE_ROOT/state" "$FIXTURE_ROOT/claude/skills" "$FIXTURE_ROOT/repo/.flywheel"

# Junk ledgers that consume the budget alphabetically first.
# Each is ~1.6MB (well under the 4MB cap individually, but cumulatively
# overflow it before any zzz- ledger is reached).
for n in 1 2 3; do
  yes '{"ts":"2026-05-09T12:00:00Z","note":"junk row to fill the recent_ledger_text budget so wired-but-cold has to fall back on the always-complete name corpus"}' \
    | head -n 12000 \
    > "$FIXTURE_ROOT/state/agents-md-junk-$n.jsonl"
done

# High-signal ledger named after the target script — alphabetically last
# so the OLD probe drops it.
TARGET_STEM="vmc7r-target"
TARGET_SH="$FIXTURE_ROOT/claude/skills/${TARGET_STEM}.sh"
cat <<'SH' > "$TARGET_SH"
#!/usr/bin/env bash
# Fixture target script: should NOT be flagged wired-but-cold by the
# patched gap-hunt-probe because its sibling ledger basename appears
# in the always-complete name corpus.
echo "vmc7r-target alive"
SH
chmod +x "$TARGET_SH"

# Sibling ledger (small, alphabetically last).
printf '{"ts":"2026-05-09T20:00:00Z","note":"target sibling"}\n' \
  > "$FIXTURE_ROOT/state/zzz-${TARGET_STEM}-events.jsonl"

# Repo dispatch-log proxy (mtime-fresh; included by the patched probe).
printf '{"ts":"2026-05-09T20:00:00Z","note":"empty"}\n' \
  > "$FIXTURE_ROOT/repo/.flywheel/dispatch-log.jsonl"

# T1: probe runs to completion against fixture
T1_OUT="$("$PROBE" --dry-run --json \
  GAP_HUNT_REPO_ROOT="$FIXTURE_ROOT/repo" \
  2>/dev/null \
  || true)"
T1_OUT="$(GAP_HUNT_REPO_ROOT="$FIXTURE_ROOT/repo" \
  GAP_HUNT_CLAUDE_ROOT="$FIXTURE_ROOT/claude" \
  GAP_HUNT_STATE_DIR="$FIXTURE_ROOT/state" \
  "$PROBE" --dry-run --json 2>/dev/null || true)"

if [[ -z "$T1_OUT" ]]; then
  fail "T1 probe produced no output against fixture"
else
  pass "T1 probe ran against fixture"
fi

# T2: target sibling ledger > content budget would have been
# consumed by junk ledgers in OLD probe. Confirm fixture sizing.
JUNK_BYTES_TOTAL=0
for n in 1 2 3; do
  size=$(wc -c < "$FIXTURE_ROOT/state/agents-md-junk-$n.jsonl")
  JUNK_BYTES_TOTAL=$((JUNK_BYTES_TOTAL + size))
done
if (( JUNK_BYTES_TOTAL > 4000000 )); then
  pass "T2 fixture junk ledgers exceed 4MB budget (have=$JUNK_BYTES_TOTAL)"
else
  fail "T2 fixture too small to exercise budget cap (have=$JUNK_BYTES_TOTAL, want>4000000)"
fi

# T3: target.sh is NOT in wired-but-cold (the actual regression assertion).
TARGET_FLAGGED=$(printf '%s' "$T1_OUT" \
  | jq -r --arg stem "$TARGET_STEM" '
      (.gaps_by_class["wired-but-cold"] // [])
      | map(.name)
      | any(test($stem))
    ' 2>/dev/null)

if [[ "$TARGET_FLAGGED" == "false" ]]; then
  pass "T3 target script ${TARGET_STEM}.sh NOT flagged wired-but-cold (regression for vmc7r/2xdi.41/2xdi.42)"
else
  fail "T3 target script ${TARGET_STEM}.sh STILL flagged wired-but-cold (regression!): $T1_OUT"
fi

# T4: live mission.sh and fuckup.sh checks — sanity from the actual
# bead evidence (live STATE_DIR, not fixture).
LIVE_OUT="$("$PROBE" --dry-run --json 2>/dev/null || true)"
LIVE_MISSION=$(printf '%s' "$LIVE_OUT" \
  | jq -r '(.gaps_by_class["wired-but-cold"] // []) | map(.name) | any(test("mission\\.sh"))' \
    2>/dev/null)
LIVE_FUCKUP=$(printf '%s' "$LIVE_OUT" \
  | jq -r '(.gaps_by_class["wired-but-cold"] // []) | map(.name) | any(test("fuckup\\.sh"))' \
    2>/dev/null)

if [[ "$LIVE_MISSION" == "false" ]]; then
  pass "T4a lib/mission.sh NOT flagged in live wired-but-cold (vmc7r DoD)"
else
  fail "T4a lib/mission.sh STILL flagged in live wired-but-cold"
fi

if [[ "$LIVE_FUCKUP" == "false" ]]; then
  pass "T4b lib/fuckup.sh NOT flagged in live wired-but-cold (2xdi.41 DoD)"
else
  fail "T4b lib/fuckup.sh STILL flagged in live wired-but-cold"
fi

# T5: triad still works (no regression to introspection).
"$PROBE" --info --json >/dev/null 2>&1 && pass "T5a --info still rc=0" || fail "T5a --info regressed"
"$PROBE" --schema >/dev/null 2>&1 && pass "T5b --schema still rc=0" || fail "T5b --schema regressed"

printf '\n=== test-gap-hunt-probe-wired-but-cold-budget.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
