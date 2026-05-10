#!/usr/bin/env bash
# tests/autoloop-executor-known-silos-registry.sh
# Bead flywheel-mn870: regression coverage for the cross-link of
# autoloop-executor.jsonl into the canonical known-silos registry
# (filed by flywheel-2xdi.40 mechanism, populated for autoloop-
# executor by flywheel-2xdi.32).
#
# The "cross-link to monitoring/aggregation" surface is the
# .flywheel/gap-hunt-known-silos.jsonl allowlist consulted by
# gap-hunt-probe.sh's known_silos() function. This test asserts
# the registry row exists and the probe does not surface a
# cross-source-silos gap for autoloop-executor.jsonl.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REGISTRY="${KNOWN_SILOS_REGISTRY:-$ROOT/.flywheel/gap-hunt-known-silos.jsonl}"
PROBE="${GAP_HUNT_PROBE_PATH:-$ROOT/.flywheel/scripts/gap-hunt-probe.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: known-silos registry exists
if [[ -f "$REGISTRY" ]]; then
  pass "gap-hunt-known-silos.jsonl registry exists at $REGISTRY"
else
  fail "registry missing at $REGISTRY"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: autoloop-executor.jsonl row present in registry
ROW="$(jq -c 'select(.name == "autoloop-executor.jsonl")' "$REGISTRY" 2>/dev/null | head -1)"
if [[ -n "$ROW" ]]; then
  pass "autoloop-executor.jsonl row present in known-silos registry"
else
  fail "autoloop-executor.jsonl row missing from registry"
fi

# Test 3: row has class=self-instrumentation
if jq -e '.class == "self-instrumentation"' >/dev/null 2>&1 <<<"$ROW"; then
  pass "row class is self-instrumentation"
else
  fail "row class is not self-instrumentation; got: $(jq -r '.class // "<null>"' <<<"$ROW")"
fi

# Test 4: row cites the autoloop-executor.sh writer
if jq -e '.writer | test("autoloop-executor\\.sh")' >/dev/null 2>&1 <<<"$ROW"; then
  pass "row cites autoloop-executor.sh as writer"
else
  fail "row writer does not cite autoloop-executor.sh; got: $(jq -r '.writer // "<null>"' <<<"$ROW")"
fi

# Test 5: rationale cites flywheel-2xdi.32 (the source bead)
if jq -e '.rationale | test("flywheel-2xdi\\.32")' >/dev/null 2>&1 <<<"$ROW"; then
  pass "row rationale cites flywheel-2xdi.32 source bead"
else
  fail "row rationale does not cite flywheel-2xdi.32; got: $(jq -r '.rationale // "<null>"' <<<"$ROW")"
fi

# Test 6: probe consults the known-silos registry
if grep -qE 'known_silos\(\)|gap-hunt-known-silos\.jsonl' "$PROBE"; then
  pass "gap-hunt-probe consults known-silos registry"
else
  fail "gap-hunt-probe does not consult known-silos registry"
fi

# Test 7: live probe — autoloop-executor.jsonl is NOT in cross-source-silos gaps
LIVE_JSON="$("$PROBE" --dry-run --json 2>/dev/null || true)"
if [[ -n "$LIVE_JSON" ]]; then
  if jq -e '.gaps_by_class["cross-source-silos"] // [] | map(.name) | any(. | test("autoloop-executor\\.jsonl")) | not' >/dev/null 2>&1 <<<"$LIVE_JSON"; then
    pass "live probe: autoloop-executor.jsonl NOT flagged cross-source-silos"
  else
    fail "live probe still flags autoloop-executor.jsonl: $(jq -r '.gaps_by_class["cross-source-silos"] // [] | map(.name) | join(",")' <<<"$LIVE_JSON")"
  fi
else
  fail "live probe produced empty output"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
