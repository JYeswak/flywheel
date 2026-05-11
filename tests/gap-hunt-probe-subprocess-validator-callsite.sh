#!/usr/bin/env bash
# Regression test for flywheel-2xdi.164: wired-but-cold classifier must
# recognize subprocess-validator-pattern scripts whose only callsite is
# another probe (e.g., loop-integrity-signals.sh called by gap-hunt-probe.sh).
#
# Before the fix: loop-integrity-signals.sh was flagged wired-but-cold
# because (a) gap-hunt-probe.sh is itself *-probe.sh so excluded from the
# flywheel_script_callers_corpus by design, (b) the script consumes the
# callee output in-memory and never writes to a JSONL ledger.
#
# After the fix: an 8th corpus (flywheel_script_bodies_corpus) scans ALL
# .flywheel/scripts/*.sh bodies (excluding gap-hunt-probe.sh itself for
# self-reference noise). loop-integrity-signals.sh now matches via this
# corpus and is no longer flagged.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "FAIL gap-hunt-probe.sh missing or not executable at $SCRIPT" >&2
  exit 2
fi

if [[ ! -x "$ROOT/.flywheel/scripts/loop-integrity-signals.sh" ]]; then
  echo "FAIL loop-integrity-signals.sh missing or not executable" >&2
  exit 2
fi

TMP="$(mktemp -d -t ghp-subv-callsite.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# Run gap-hunt-probe in dry-run + json mode and confirm loop-integrity-signals
# does NOT appear as wired-but-cold.
"$SCRIPT" --json --dry-run >"$TMP/gaps.json" 2>"$TMP/err"

if ! jq -e . "$TMP/gaps.json" >/dev/null 2>&1; then
  echo "FAIL gap-hunt-probe.sh produced non-JSON output" >&2
  cat "$TMP/err" >&2
  exit 1
fi

# AG1: loop-integrity-signals must NOT appear in any gap id
loop_integrity_hits="$(jq -r '.gap_ids[]?' "$TMP/gaps.json" | grep -c 'loop-integrity-signals' || true)"
if [[ "$loop_integrity_hits" != "0" ]]; then
  echo "FAIL loop-integrity-signals.sh flagged $loop_integrity_hits time(s) — classifier regression" >&2
  jq -r '.gap_ids[]?' "$TMP/gaps.json" | grep 'loop-integrity-signals' >&2
  exit 1
fi
echo "PASS AG1 loop-integrity-signals.sh not flagged wired-but-cold"

# AG2: gap_class_distribution.wired-but-cold field exists and is a number
cold_count="$(jq -r '.gap_class_distribution["wired-but-cold"] // empty' "$TMP/gaps.json")"
if [[ -z "$cold_count" ]] || ! [[ "$cold_count" =~ ^[0-9]+$ ]]; then
  echo "FAIL gap_class_distribution.wired-but-cold missing or non-numeric: '$cold_count'" >&2
  exit 1
fi
echo "PASS AG2 wired-but-cold distribution field present (count=$cold_count)"

# AG3: confirm the new corpus function is defined in the script
if ! grep -q 'flywheel_script_bodies_corpus' "$SCRIPT"; then
  echo "FAIL flywheel_script_bodies_corpus function not present in gap-hunt-probe.sh" >&2
  exit 1
fi
echo "PASS AG3 flywheel_script_bodies_corpus function present"

# AG4: confirm it is wired into probe_wired_but_cold (8th corpus check)
if ! grep -q 'in_script_bodies' "$SCRIPT"; then
  echo "FAIL in_script_bodies variable not present in probe_wired_but_cold" >&2
  exit 1
fi
echo "PASS AG4 in_script_bodies wired into probe_wired_but_cold"

echo "PASS gap-hunt-probe-subprocess-validator-callsite (4/4)"
