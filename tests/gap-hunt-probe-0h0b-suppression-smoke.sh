#!/usr/bin/env bash
# tests/gap-hunt-probe-0h0b-suppression-smoke.sh
# Bead flywheel-2xdi.37: prove the new
# `upstream-issue-draft-or-comment-decision` suppression in
# .flywheel/scripts/gap-hunt-probe.sh suppresses bead flywheel-0h0b
# without over-matching. Closed bead 0h0b is upstream-issue draft work
# (drafting an ntm#114 comment-or-new decision under {operator} signoff)
# whose body mentions "doctrine" only via AG1 boilerplate and
# "canonical" only via skill-name reference — not a local
# INCIDENTS/AGENTS promotion event. Same suppression-list pattern as
# the 4 prior false-positive entries (plan-space-cross-link-design,
# mkdir-lock-fallback-plan, external-issue-reply-draft,
# recover-pane-command-spec).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="${GAP_HUNT_PROBE:-$ROOT/.flywheel/scripts/gap-hunt-probe.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: probe is executable
if [[ -x "$PROBE" ]]; then
  pass "gap-hunt-probe.sh is executable"
else
  fail "gap-hunt-probe.sh missing or not executable at $PROBE"
fi

# Test 2: bash -n on the wrapper
if bash -n "$PROBE" 2>/dev/null; then
  pass "gap-hunt-probe.sh bash syntax ok"
else
  fail "gap-hunt-probe.sh bash syntax error"
fi

# Test 3: suppression entry is present in source (sanity grep)
if grep -q '"upstream-issue-draft-or-comment-decision"' "$PROBE" \
  && grep -q '"\[upstream-issue\]"' "$PROBE" \
  && grep -q '"comment-on-114"' "$PROBE" \
  && grep -q '"joshua signoff"' "$PROBE"; then
  pass "suppression entry + 3 needles present in source"
else
  fail "suppression entry or one of its 3 needles missing in source"
fi

# Test 4: --info still emits valid JSON (script integrity)
INFO_JSON="$("$PROBE" --info --json 2>/dev/null || true)"
if jq -e '.success == true and .version == "gap-hunt-probe.v1"' >/dev/null 2>&1 <<<"$INFO_JSON"; then
  pass "gap-hunt-probe --info --json still emits valid envelope"
else
  fail "gap-hunt-probe --info envelope malformed: ${INFO_JSON:0:200}"
fi

# Test 5: --dry-run shows flywheel-0h0b is NOT a bead-without-followup gap
# (the canonical suppression assertion). The --dry-run pass takes ~30s; we
# accept that latency for a substrate-tier integration test.
DRY_JSON="$("$PROBE" --json --dry-run 2>/dev/null || true)"
# --dry-run envelope shape: {auto_beads_filed, dry_run:true, gap_ids:[...], gap_class_distribution:{...}}.
# It does NOT carry a top-level `success` field (that's --info-only); the
# canonical "envelope landed" gate is `dry_run == true` plus a non-empty
# `gap_class_distribution` map.
if [[ -n "$DRY_JSON" ]] && jq -e '.dry_run == true and (.gap_class_distribution | length) >= 1' >/dev/null 2>&1 <<<"$DRY_JSON"; then
  pass "gap-hunt-probe --dry-run produced a valid envelope"
  if jq -re '.gap_ids[]' <<<"$DRY_JSON" 2>/dev/null \
    | grep -q "bead-without-followup:flywheel-0h0b"; then
    fail "flywheel-0h0b is still surfaced as bead-without-followup (suppression not firing)"
  else
    pass "flywheel-0h0b is suppressed in --dry-run gap_ids"
  fi
  if [[ "$(jq -r '.gap_class_distribution["bead-without-followup"] // 0' <<<"$DRY_JSON")" =~ ^[0-9]+$ ]]; then
    pass "gap_class_distribution.bead-without-followup is a number"
  else
    fail "gap_class_distribution.bead-without-followup not a number"
  fi
else
  fail "gap-hunt-probe --dry-run failed or returned no JSON"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
