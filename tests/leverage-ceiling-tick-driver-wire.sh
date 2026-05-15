#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
MANIFEST="$ROOT/.flywheel/scripts/tick-driver-manifest.json"
PROBE="$ROOT/.flywheel/scripts/leverage-ceiling-probe.sh"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if jq -e '.schema_version == "tick-driver-manifest.v1"' "$MANIFEST" >/dev/null; then
  pass "manifest_schema"
else
  fail "manifest_schema"
fi

entry_count="$(jq -r '[.primitives[] | select(.name == "leverage-ceiling-probe")] | length' "$MANIFEST")"
if [[ "$entry_count" == "1" ]]; then
  pass "single_leverage_ceiling_entry"
else
  fail "single_leverage_ceiling_entry"
fi

if jq -e '
  .primitives[]
  | select(.name == "leverage-ceiling-probe")
  | .path == ".flywheel/scripts/leverage-ceiling-probe.sh"
    and .args == ["--json"]
    and (.timeout_sec <= 45)
    and (.ledger | contains("leverage-ceiling.jsonl"))
' "$MANIFEST" >/dev/null; then
  pass "entry_contract"
else
  fail "entry_contract"
fi

if [[ -x "$PROBE" ]]; then
  pass "probe_executable"
else
  fail "probe_executable"
fi

if "$PROBE" --info | jq -e '.ledger_jsonl == true and .read_only == true' >/dev/null; then
  pass "probe_info_contract"
else
  fail "probe_info_contract"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL leverage-ceiling tick-driver wire pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'OK leverage-ceiling tick-driver wire pass=%d\n' "$pass_count"
