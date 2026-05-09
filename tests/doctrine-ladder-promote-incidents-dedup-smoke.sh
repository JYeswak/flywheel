#!/usr/bin/env bash
# tests/doctrine-ladder-promote-incidents-dedup-smoke.sh
# Bead flywheel-qnkj2: prove `default_incident_paths()` in
# .flywheel/scripts/doctrine-ladder-promote.sh now searches the repo-local
# INCIDENTS.md, so a trauma class with substantive coverage there does NOT
# get re-filed as a duplicate promotion-candidate bead.
#
# Pre-fix bug: dedup search only walked
#   ~/.claude/skills/.flywheel/INCIDENTS.md
#   ~/.claude/skills/*/references/INCIDENTS.md
#   $REPO/AGENTS.md
# but missed $REPO/INCIDENTS.md where the canonical coverage lives. That
# caused the script to file `flywheel-qnkj2` for `agent-mail-reservation-
# timeout` even though sister bead `flywheel-2tgl` had already promoted
# the class to repo-local INCIDENTS.md on 2026-05-08.
#
# This smoke uses a SYNTHETIC fuckup-log + isolated INCIDENTS_SEARCH_PATHS
# so it never touches the real beads-DB or filesystem state.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/doctrine-ladder-promote.sh"

TMP="$(mktemp -d -t doctrine-ladder-dedup-smoke.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: script exists + bash -n ok
if [[ -x "$SCRIPT" ]] && bash -n "$SCRIPT" 2>/dev/null; then
  pass "doctrine-ladder-promote.sh exists + bash -n ok"
else
  fail "doctrine-ladder-promote.sh missing or syntax-broken"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: source-level guard — default_incident_paths() now lists $REPO/INCIDENTS.md
if grep -q '"$REPO/INCIDENTS.md"' "$SCRIPT" \
  && grep -q '"$REPO/AGENTS.md"' "$SCRIPT"; then
  pass "default_incident_paths includes \$REPO/INCIDENTS.md (post-fix) and \$REPO/AGENTS.md"
else
  fail "\$REPO/INCIDENTS.md OR \$REPO/AGENTS.md missing from default_incident_paths"
fi

# Test 3: synthetic INCIDENTS-coverage path catches a class
mkdir -p "$TMP/incidents-paths"
SYNTH_INCIDENTS="$TMP/incidents-paths/INCIDENTS.md"
cat >"$SYNTH_INCIDENTS" <<'EOF'
# Synthetic INCIDENTS

## smoke-class-already-promoted

This class has substantive doctrine coverage. The dedup MUST honor it.
EOF

# Synthetic fuckup-log with 3 events of the covered class plus 3 of an uncovered class
SYNTH_FUCKUP="$TMP/fuckup-log.jsonl"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  for _ in 1 2 3; do
    printf '{"ts":"%s","trauma_class":"smoke-class-already-promoted"}\n' "$NOW"
  done
  for _ in 1 2 3; do
    printf '{"ts":"%s","trauma_class":"smoke-class-uncovered-fresh-x9q7"}\n' "$NOW"
  done
} >"$SYNTH_FUCKUP"

# Synthetic repo with no AGENTS.md so we don't accidentally hit real coverage
SYNTH_REPO="$TMP/repo"
mkdir -p "$SYNTH_REPO/.beads"
cd "$SYNTH_REPO"

# Stub br so the script doesn't spawn real bead creation
cat >"$TMP/fake-br" <<'BR'
#!/usr/bin/env bash
# Stub br: list returns empty issues; create echoes a synthetic ID; rest no-op.
case "$1" in
  list) echo '[]'; exit 0 ;;
  create) echo "smoke-bead-$(date +%s%N | tail -c 6)"; exit 0 ;;
  *) exit 0 ;;
esac
BR
chmod +x "$TMP/fake-br"

# Run the script with the SYNTHETIC INCIDENTS path (and no AGENTS.md fall-through)
OUT_JSON="$TMP/out.json"
set +e
INCIDENTS_SEARCH_PATHS="$SYNTH_INCIDENTS" \
  FUCKUP_LOG="$SYNTH_FUCKUP" \
  BR_BIN="$TMP/fake-br" \
  bash "$SCRIPT" "$SYNTH_REPO" >"$OUT_JSON" 2>"$TMP/out.err"
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
  fail "script exited rc=$rc; stderr: $(head -3 "$TMP/out.err")"
else
  pass "script exited rc=0 under synthetic fuckup-log"
fi

# Test 4: covered class is SKIPPED with reason incidents_covered
if jq -e '.skipped | any(. == "smoke-class-already-promoted:incidents_covered")' >/dev/null 2>&1 <"$OUT_JSON"; then
  pass "covered class skipped with reason=incidents_covered"
else
  fail "covered class did not surface as incidents_covered"
  jq . "$OUT_JSON" >&2 || cat "$OUT_JSON" >&2
fi

# Test 5: uncovered class IS created (proves the heuristic still fires when
# coverage truly absent)
if jq -e '.created | any(. | startswith("smoke-class-uncovered-fresh-x9q7:"))' >/dev/null 2>&1 <"$OUT_JSON"; then
  pass "uncovered class created (heuristic still active)"
else
  fail "uncovered class did NOT get filed (heuristic too aggressive)"
  jq . "$OUT_JSON" >&2 || cat "$OUT_JSON" >&2
fi

# Test 6: live regression — agent-mail-reservation-timeout (covered in
# repo-local INCIDENTS.md by sister bead flywheel-2tgl) MUST NOT be in the
# created list of a real run with default paths. We do NOT mutate beads-DB
# state; we just inspect the JSON output. This is the whole-system gate.
LIVE_OUT="$TMP/live.json"
set +e
"$SCRIPT" >"$LIVE_OUT" 2>"$TMP/live.err"
live_rc=$?
set -e
if [[ "$live_rc" -eq 0 ]] && jq -e '.action == "completed"' >/dev/null 2>&1 <"$LIVE_OUT"; then
  pass "live default-path run completed"
  if jq -e '.skipped | any(. == "agent-mail-reservation-timeout:incidents_covered")' >/dev/null 2>&1 <"$LIVE_OUT"; then
    pass "agent-mail-reservation-timeout is now skipped via repo-local INCIDENTS.md (canonical regression gate)"
  else
    fail "agent-mail-reservation-timeout was NOT skipped — dedup fix did not apply"
    jq '.skipped, .created' "$LIVE_OUT" >&2 || cat "$LIVE_OUT" >&2
  fi
else
  fail "live run failed (rc=$live_rc)"
  cat "$TMP/live.err" >&2
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
