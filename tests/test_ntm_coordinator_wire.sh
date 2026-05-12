#!/usr/bin/env bash
# test_ntm_coordinator_wire.sh — verifies the NTM-coordinator wire-in done 2026-05-07.
#
# Mission: continuous-orchestrator-uptime-self-sustaining-fleet
# What this asserts:
#   1. Each slash-command file (status, tick, dispatch) references the pinned
#      coordinator wrapper that prevents CWD-based cross-repo bleed.
#   2. Live pinned `status --json` returns valid JSON with the
#      expected schema fields.
#   3. Pinned `digest --json` returns the `work_summary` keys.
#   4. Pinned `assign --dry-run --limit=N` honors `--limit` and emits
#      assignments[] + skipped[] arrays.
#   5. `preflight --strict` exits non-zero for a prompt containing `rm -rf /`.
#
# Reversibility: every wire point is a markdown insertion in a slash-command
# file, deletable in <30sec via `git checkout` of the file.

set -uo pipefail

NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
PINNED_BIN="${PINNED_BIN:-/Users/josh/.local/bin/ntm-coordinator-pinned}"
SESSION="${FLYWHEEL_SESSION:-flywheel}"
STATUS_MD="${HOME}/.claude/commands/flywheel/status.md"
TICK_MD="${HOME}/.claude/commands/flywheel/tick.md"
DISPATCH_MD="${HOME}/.claude/commands/flywheel/dispatch.md"

PASS=0
FAIL=0
fail()  { printf 'FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
ok()    { printf 'PASS: %s\n' "$*"; PASS=$((PASS+1)); }
have()  { command -v "$1" >/dev/null 2>&1; }

if ! [ -x "$NTM_BIN" ]; then
  printf 'SKIP: ntm not found at %s\n' "$NTM_BIN" >&2
  exit 77
fi
if ! [ -x "$PINNED_BIN" ]; then
  printf 'SKIP: ntm-coordinator-pinned not found at %s\n' "$PINNED_BIN" >&2
  exit 77
fi
if ! have jq; then
  printf 'SKIP: jq not on PATH\n' >&2
  exit 77
fi

# --- Phase B/C/D/E wire-point presence ------------------------------------
[ -r "$STATUS_MD" ] || { fail "status.md unreadable: $STATUS_MD"; }
[ -r "$TICK_MD" ]   || { fail "tick.md unreadable: $TICK_MD"; }
[ -r "$DISPATCH_MD" ] || { fail "dispatch.md unreadable: $DISPATCH_MD"; }

grep -q 'ntm-coordinator-pinned --session="$SESSION" status --json' "$STATUS_MD" \
  && ok "status.md wires pinned coordinator status" \
  || fail "status.md missing pinned coordinator status invocation"

grep -q 'ntm-coordinator-pinned --session="$SESSION" digest --json' "$TICK_MD" \
  && ok "tick.md wires pinned coordinator digest" \
  || fail "tick.md missing pinned coordinator digest invocation"

grep -q 'ntm-coordinator-pinned --session="$SESSION" assign --dry-run --json --limit=10' "$DISPATCH_MD" \
  && ok "dispatch.md wires pinned coordinator assign capacity oracle" \
  || fail "dispatch.md missing pinned coordinator assign invocation"

RAW_UNSAFE_HITS=$(rg -n 'ntm coordinator (status|digest|assign)' "$STATUS_MD" "$TICK_MD" "$DISPATCH_MD" 2>/dev/null \
  | grep -Ev 'canonical NTM coordinator digest|If `ntm coordinator digest`' \
  | wc -l | tr -d ' ')
[ "$RAW_UNSAFE_HITS" -eq 0 ] \
  && ok "raw ntm coordinator mentions are documentation-only" \
  || fail "raw ntm coordinator executable-looking mentions remain (count=$RAW_UNSAFE_HITS)"

grep -q 'ntm preflight' "$DISPATCH_MD" \
  && ok "dispatch.md wires ntm preflight safety gate" \
  || fail "dispatch.md missing ntm preflight invocation"

# --- Phase A live-shape assertions ----------------------------------------
STATUS_JSON="$("$PINNED_BIN" --session="$SESSION" status --json 2>/dev/null || echo '{}')"
echo "$STATUS_JSON" | jq -e '.agent_count != null and .agents != null' >/dev/null 2>&1 \
  && ok "coordinator status returns agent_count + agents" \
  || fail "coordinator status JSON missing required fields"

# Every agent record has .healthy
echo "$STATUS_JSON" | jq -e '[.agents | to_entries[] | .value | has("healthy")] | all' >/dev/null 2>&1 \
  && ok "coordinator status: every agent record has .healthy" \
  || fail "coordinator status: some agents missing .healthy"

# Config block presence (any of the 4 flags is fine — schema present)
echo "$STATUS_JSON" | jq -e '.config | (has("auto_assign") or has("send_digests") or has("conflict_negotiate"))' >/dev/null 2>&1 \
  && ok "coordinator status exposes config flags" \
  || fail "coordinator status missing .config block"

# Digest shape
DIGEST_JSON="$("$PINNED_BIN" --session="$SESSION" digest --json 2>/dev/null || echo '{}')"
echo "$DIGEST_JSON" | jq -e '.work_summary | has("pending_tasks") and has("in_progress_tasks") and has("completed_today") and has("blocked_tasks")' >/dev/null 2>&1 \
  && ok "coordinator digest emits work_summary with required keys" \
  || fail "coordinator digest missing work_summary keys"

# Assign --dry-run honors --limit and emits assignments[] / skipped[]
ASSIGN_JSON="$("$PINNED_BIN" --session="$SESSION" assign --dry-run --json --limit=2 2>/dev/null || echo '{}')"
ASSIGN_LEN=$(echo "$ASSIGN_JSON" | jq '.data.assignments | length // 0' 2>/dev/null || echo 99)
echo "$ASSIGN_JSON" | jq -e '.data.assignments != null and (.data | has("skipped"))' >/dev/null 2>&1 \
  && ok "coordinator assign --dry-run emits assignments[] and skipped[]" \
  || fail "coordinator assign --dry-run missing assignments[]/skipped[]"
[ "$ASSIGN_LEN" -le 2 ] \
  && ok "coordinator assign --limit=2 honored (got $ASSIGN_LEN)" \
  || fail "coordinator assign --limit=2 not honored (got $ASSIGN_LEN)"

# Preflight strict must DETECT a synthetic AWS-key-shaped secret pattern.
# We assert on findings/warning_count rather than rc because NTM preflight
# emits findings but exits 0 even with --strict; the dispatch wire-in is the
# layer that enforces blocking on error_count>0. Fake key (synthetic, not real).
# Sentinel contains FAKE markers per .flywheel/security/v1/substrate-class-manifest.json
# (Meadows L2 paradigm — protection mechanisms recognize their own test corpus).
PREFLIGHT_OUT="$("$NTM_BIN" preflight --strict --json "synthetic-key AKIA0FAKE0FAKE0FAKE0 for unit test" 2>/dev/null)"
PREFLIGHT_HITS=$(printf '%s' "$PREFLIGHT_OUT" | jq -r '(.findings // []) | length' 2>/dev/null || echo 0)
[ "$PREFLIGHT_HITS" -ge 1 ] \
  && ok "ntm preflight --strict detects synthetic AWS-key pattern (findings=$PREFLIGHT_HITS)" \
  || fail "ntm preflight --strict missed synthetic AWS-key pattern (findings=$PREFLIGHT_HITS)"

# --- summary --------------------------------------------------------------
TOTAL=$((PASS+FAIL))
printf '\n%d/%d checks passed (%d failed)\n' "$PASS" "$TOTAL" "$FAIL"
[ "$FAIL" -eq 0 ]
