#!/usr/bin/env bash
# Regression test for flywheel-2xdi.168:
# regenerate-dicklesworthstone-sources-runs.jsonl is a self-instrumentation
# ledger for the Dicklesworthstone source regenerator, so it belongs in the
# known-silos registry instead of being reported as cross-source-silos.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REGISTRY="$ROOT/.flywheel/gap-hunt-known-silos.jsonl"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"
LEDGER_NAME="regenerate-dicklesworthstone-sources-runs.jsonl"
TMP="$(mktemp -d -t regen-sources-known-silo.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
p() { pass=$((pass + 1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail + 1)); printf 'FAIL %s\n' "$1" >&2; }

row="$(jq -c --arg name "$LEDGER_NAME" 'select(.name == $name)' "$REGISTRY" | head -1)"
if [[ -n "$row" ]]; then
  p "known-silos row present"
else
  f "known-silos row missing"
fi

if jq -e '.class == "self-instrumentation"' >/dev/null 2>&1 <<<"$row"; then
  p "row class is self-instrumentation"
else
  f "row class mismatch"
fi

if jq -e '.writer | test("regenerate-dicklesworthstone-sources\\.sh")' >/dev/null 2>&1 <<<"$row"; then
  p "row cites writer script"
else
  f "row writer mismatch"
fi

if jq -e '.rationale | test("flywheel-2xdi\\.168")' >/dev/null 2>&1 <<<"$row"; then
  p "row cites bead id"
else
  f "row rationale missing bead id"
fi

if "$PROBE" --dry-run --json >"$TMP/gaps.json" 2>"$TMP/gaps.err"; then
  p "gap-hunt-probe dry-run emitted JSON"
else
  f "gap-hunt-probe dry-run failed"
  cat "$TMP/gaps.err" >&2
fi

gap_count="$(
  jq -r --arg name "$LEDGER_NAME" \
    '[.gap_ids[]? | select(startswith("cross-source-silos:") and contains($name))] | length' \
    "$TMP/gaps.json"
)"
if [[ "$gap_count" == "0" ]]; then
  p "ledger no longer emitted as cross-source-silos"
else
  f "ledger still emitted as cross-source-silos ($gap_count)"
fi

if [[ "$fail" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass"
