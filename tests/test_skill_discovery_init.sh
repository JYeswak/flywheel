#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/skill-discovery-init.XXXXXX")"
export TMP
trap 'python3 -c "import os, shutil; shutil.rmtree(os.environ[\"TMP\"], ignore_errors=True)"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

ledger="$TMP/state/skill-discoveries.jsonl"
export FLYWHEEL_SKILL_DISCOVERY_PATH="$ledger"
export APPEND_SAFE_WRITE="$ROOT/.flywheel/scripts/append-safe-write.sh"

bash -n "$BIN" && pass "01_bin_syntax" || fail "01_bin_syntax"
"$BIN" skill-discovery init --json >"$TMP/init1.json"
test -f "$ledger" && pass "02_file_created" || fail "02_file_created"
test -w "$ledger" && pass "03_file_appendable" || fail "03_file_appendable"
jq -e '.schema_version=="skill-discovery/v1" and .status=="ok" and (.path|endswith("skill-discoveries.jsonl"))' "$TMP/init1.json" >/dev/null \
  && pass "04_init_json_shape" || fail "04_init_json_shape"
printf '%s\n' '{"preexisting":true}' >>"$ledger"
"$BIN" skill-discovery init --json >"$TMP/init2.json"
if [[ "$(wc -l <"$ledger" | tr -d ' ')" == "1" ]] && jq -e 'select(.preexisting==true)' "$ledger" >/dev/null; then
  pass "05_idempotent_no_truncate"
else
  fail "05_idempotent_no_truncate"
  cat "$ledger" >&2 || true
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 5 && "$fail_count" -eq 0 ]]
