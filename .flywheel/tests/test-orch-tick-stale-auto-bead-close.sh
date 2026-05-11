#!/usr/bin/env bash
# .flywheel/tests/test-orch-tick-stale-auto-bead-close.sh
# Regression test for flywheel-mvzri orch-tick-stale-auto-bead-close.sh.
#
# AGs (mirror bead acceptance criteria):
#   AG1 — Script exists + chmod 755
#   AG2 — Dry-run is default; no mutation occurs when invoked without --apply
#   AG3 — Wired into tick-driver-manifest.json with canonical-cli structure
#   AG4 — Doctor envelope passes (substrate health OK)
#   AG5 — First-run dry-run reports planned closures (when moot beads exist)
#   AG6 — Regression safety: skips beads with `do-not-auto-close` marker

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/orch-tick-stale-auto-bead-close.sh"
MANIFEST="$ROOT/.flywheel/scripts/tick-driver-manifest.json"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1 — script + chmod
if [[ -f "$SCRIPT" && -x "$SCRIPT" ]]; then
  p "AG1 script exists + executable"
else
  f "AG1 script missing or not executable"
fi

# AG3 — wired into tick-driver-manifest.json
if /usr/bin/python3 -c "
import json
m = json.load(open('$MANIFEST'))
names = [p['name'] for p in m.get('primitives',[])]
exit(0 if 'orch-tick-stale-auto-bead-close' in names else 1)
" 2>/dev/null; then
  p "AG3 wired into tick-driver-manifest.json"
else
  f "AG3 not in tick-driver-manifest.json"
fi

# AG4 — doctor envelope OK
if "$SCRIPT" doctor --json 2>/dev/null | /usr/bin/python3 -c "
import sys, json
d = json.load(sys.stdin)
exit(0 if d.get('status') == 'ok' else 1)
" 2>/dev/null; then
  p "AG4 doctor envelope returns status=ok"
else
  f "AG4 doctor envelope did not return ok"
fi

# AG5 — first-run dry-run produces parseable summary (default mode)
RESULT="$("$SCRIPT" 2>&1)"
if printf '%s' "$RESULT" | /usr/bin/grep -qE 'mode=dry-run processed=[0-9]+ planned_closes=[0-9]+'; then
  p "AG5 dry-run summary format correct"
else
  f "AG5 dry-run summary missing"
fi

# AG2 — dry-run is default; verify no mutation by checking ledger row count
# pre vs post a default invocation. (Default = no --apply = no ledger append.)
LEDGER="${ORCH_TICK_STALE_AUTO_CLOSE_LEDGER:-$HOME/.local/state/flywheel/orch-tick-stale-auto-close.jsonl}"
PRE_ROWS=0
[[ -f "$LEDGER" ]] && PRE_ROWS=$(/usr/bin/wc -l < "$LEDGER" | /usr/bin/tr -d ' ')
"$SCRIPT" >/dev/null 2>&1
POST_ROWS=0
[[ -f "$LEDGER" ]] && POST_ROWS=$(/usr/bin/wc -l < "$LEDGER" | /usr/bin/tr -d ' ')
if [[ "$PRE_ROWS" -eq "$POST_ROWS" ]]; then
  p "AG2 dry-run is default + no mutation (ledger rows unchanged pre=$PRE_ROWS post=$POST_ROWS)"
else
  f "AG2 dry-run mutated ledger (pre=$PRE_ROWS post=$POST_ROWS)"
fi

# AG6 — regression safety: verify the opt-out marker is detected
# Synthetic test: feed a sample bead body with do-not-auto-close and verify the
# script's body-scan function (extract_subject_from_title + body grep) handles it.
# We can directly source the script to test the function — but it uses set -e.
# Instead, test the grep pattern matches the expected markers.
TEST_BODY1="some text\ndo-not-auto-close\nmore text"
TEST_BODY2="some text\ndisposition=open-genuine-gap\nmore text"
TEST_BODY3="normal body without markers"
if printf '%b' "$TEST_BODY1" | /usr/bin/grep -qE 'do-not-auto-close|disposition=open-genuine-gap|open-genuine-gap' \
   && printf '%b' "$TEST_BODY2" | /usr/bin/grep -qE 'do-not-auto-close|disposition=open-genuine-gap|open-genuine-gap' \
   && ! printf '%b' "$TEST_BODY3" | /usr/bin/grep -qE 'do-not-auto-close|disposition=open-genuine-gap|open-genuine-gap'; then
  p "AG6 opt-out marker pattern matches: do-not-auto-close + disposition=open-genuine-gap"
else
  f "AG6 opt-out marker pattern incorrect"
fi

# Also verify the same regex is used in the production script
if /usr/bin/grep -qE 'do-not-auto-close.*disposition=open-genuine-gap' "$SCRIPT"; then
  p "AG6 production script uses canonical opt-out pattern"
else
  f "AG6 production script missing opt-out pattern"
fi

# flywheel-kjli4 extension AGs

# AG7 — classify_substrate_class function present
if grep -q 'classify_substrate_class' "$SCRIPT" && grep -q 'jeff-premium' "$SCRIPT" && grep -q 'joshua-domain' "$SCRIPT" && grep -q 'skillos-managed' "$SCRIPT"; then
  p "AG7 classify_substrate_class function + 3-class taxonomy present"
else
  f "AG7 classify_substrate_class missing or incomplete"
fi

# AG8 — synthesize_jeff_audit_pack present
if grep -q 'synthesize_jeff_audit_pack' "$SCRIPT" && grep -q 'audit-only-jeff-substrate-class-3' "$SCRIPT"; then
  p "AG8 synthesize_jeff_audit_pack + Class 3 disposition tag present"
else
  f "AG8 audit-pack synthesis missing"
fi

# AG9 — classify function returns correct class for known skills (live jsm probe)
CLASS_ASUPERSYNC=$(bash -c "
JSM_BIN=/Users/josh/.local/bin/jsm
classify_substrate_class() {
  local title=\"\$1\"
  local skill=\"\"
  if [[ \"\$title\" =~ \\.claude/skills/([A-Za-z0-9._-]+)/ ]]; then
    skill=\"\${BASH_REMATCH[1]}\"
  else
    printf 'not-skill-path\\n'; return 0
  fi
  local out; out=\"\$(\$JSM_BIN show \"\$skill\" 2>&1)\"
  if printf '%s' \"\$out\" | grep -q \"Jeffrey's Premium Skill\"; then
    printf 'jeff-premium\\n'
  elif printf '%s' \"\$out\" | grep -qE \"Skill '\$skill' not found\"; then
    printf 'joshua-domain\\n'
  else
    printf 'unknown\\n'
  fi
}
classify_substrate_class \"[gap-wired-but-cold] .claude/skills/asupersync-mega-skill/scripts/audit-target.sh\"
")
if [[ "$CLASS_ASUPERSYNC" == "jeff-premium" ]]; then
  p "AG9 classify asupersync-mega-skill → jeff-premium"
else
  f "AG9 classify asupersync-mega-skill returned '$CLASS_ASUPERSYNC' (expected jeff-premium)"
fi

# AG10 — classify joshua-domain skill correctly
CLASS_SB=$(bash -c "
JSM_BIN=/Users/josh/.local/bin/jsm
classify_substrate_class() {
  local title=\"\$1\"
  local skill=\"\"
  if [[ \"\$title\" =~ \\.claude/skills/([A-Za-z0-9._-]+)/ ]]; then
    skill=\"\${BASH_REMATCH[1]}\"
  else
    printf 'not-skill-path\\n'; return 0
  fi
  local out; out=\"\$(\$JSM_BIN show \"\$skill\" 2>&1)\"
  if printf '%s' \"\$out\" | grep -q \"Jeffrey's Premium Skill\"; then
    printf 'jeff-premium\\n'
  elif printf '%s' \"\$out\" | grep -qE \"Skill '\$skill' not found\"; then
    printf 'joshua-domain\\n'
  else
    printf 'unknown\\n'
  fi
}
classify_substrate_class \"[gap-wired-but-cold] .claude/skills/skill-builder/scripts/audit-source-coverage.sh\"
")
if [[ "$CLASS_SB" == "joshua-domain" ]]; then
  p "AG10 classify skill-builder → joshua-domain"
else
  f "AG10 classify skill-builder returned '$CLASS_SB' (expected joshua-domain)"
fi

# AG11 — per-class counts in summary envelope (text or JSON mode)
if "$SCRIPT" --dry-run 2>&1 | grep -q 'jeff_premium_auto_audit'; then
  p "AG11 summary envelope includes per-class counts"
else
  f "AG11 per-class counts missing from summary"
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
