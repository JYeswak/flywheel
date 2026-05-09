#!/usr/bin/env bash
# tests/doctor-cache-and-schema-postcheck-smoke.sh
# Bead flywheel-2xdi.34: smoke test that the wired-but-cold
# `~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh`
# module is, in fact, load-bearing on the live doctor surface.
#
# gap-hunt-probe classed this file cold because no recent flywheel
# jsonl ledger references it. That signal is misleading: every
# `flywheel-loop doctor --json` invocation runs through
# `doctor_schema_postcheck`, which itself calls
# `command_help_parity_doctor_json` (line 192) and conditionally
# `doctor_ntm_health_json` (line 195) — both defined in this same
# file. The doctor_cache_* helpers are called from
# `doctor_ntm_health_json`. So all 7 functions are reachable from the
# main doctor path.
#
# This smoke source-loads the module, asserts every public function
# is defined, and exercises the pure helpers (cache path/mtime/get/
# put) against an isolated tmp cache dir. Heavier surfaces
# (doctor_ntm_health_json, command_help_parity_doctor_json,
# doctor_schema_postcheck) get a "definition + signature" gate so
# we don't fork live ntm or audit subprocesses inside a smoke.
#
# Bead: flywheel-2xdi.34
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DOCTOR_SH="${FLYWHEEL_DOCTOR_LIB:-$HOME/.claude/skills/.flywheel/lib/doctor.sh}"
TARGET_PART="${FLYWHEEL_DOCTOR_PART_01:-$HOME/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh}"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctor-cache-smoke.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: target file exists + readable
if [[ -r "$TARGET_PART" ]]; then
  pass "target part-01 module exists and is readable"
else
  fail "target part-01 module missing at $TARGET_PART"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Source under bash -c so we don't pollute this test's shell with
# every flywheel-loop helper. The subshell sources doctor.sh which
# transitively sources all doctor.d/*.sh files.
DEFINED=$(bash -c '
source "'"$HOME"'/.claude/skills/.flywheel/lib/common.sh" 2>/dev/null || true
source "'"$DOCTOR_SH"'"
for fn in doctor_cache_path doctor_cache_mtime doctor_cache_get doctor_cache_put doctor_ntm_health_json command_help_parity_doctor_json doctor_schema_postcheck; do
  if declare -f "$fn" >/dev/null; then
    printf "%s=yes\n" "$fn"
  else
    printf "%s=no\n" "$fn"
  fi
done
')

# Test 2: every named function is defined post-source
for fn in doctor_cache_path doctor_cache_mtime doctor_cache_get doctor_cache_put doctor_ntm_health_json command_help_parity_doctor_json doctor_schema_postcheck; do
  if grep -q "^${fn}=yes$" <<<"$DEFINED"; then
    pass "$fn is defined after sourcing doctor.sh"
  else
    fail "$fn NOT defined after sourcing doctor.sh"
  fi
done

# Test 3: doctor_cache_path returns a path under FLYWHEEL_DOCTOR_CACHE_DIR
PATH_OUT=$(bash -c '
source "'"$DOCTOR_SH"'" 2>/dev/null
FLYWHEEL_DOCTOR_CACHE_DIR='"$TMP"'/cache doctor_cache_path my-key
')
EXPECTED_PATH="$TMP/cache/my-key.json"
if [[ "$PATH_OUT" == "$EXPECTED_PATH" ]]; then
  pass "doctor_cache_path honors FLYWHEEL_DOCTOR_CACHE_DIR + key.json shape"
else
  fail "doctor_cache_path output mismatch (expected=$EXPECTED_PATH actual=$PATH_OUT)"
fi

# Test 4: doctor_cache_put writes valid JSON, doctor_cache_get reads it back
mkdir -p "$TMP/cache"
PUT_GET_OUT=$(bash -c '
source "'"$DOCTOR_SH"'" 2>/dev/null
export FLYWHEEL_DOCTOR_CACHE_DIR='"$TMP"'/cache
doctor_cache_put smoke-key "$(printf "%s" "{\"smoke\":42}")"
doctor_cache_get smoke-key
')
if jq -e '.smoke == 42' >/dev/null 2>&1 <<<"$PUT_GET_OUT"; then
  pass "doctor_cache_put + doctor_cache_get round-trip preserves JSON shape"
else
  fail "cache round-trip failed (got: $PUT_GET_OUT)"
fi

# Test 5: doctor_cache_get respects FLYWHEEL_DOCTOR_CACHE_DISABLE=1
DISABLED_RC=$(bash -c '
source "'"$DOCTOR_SH"'" 2>/dev/null
export FLYWHEEL_DOCTOR_CACHE_DIR='"$TMP"'/cache
FLYWHEEL_DOCTOR_CACHE_DISABLE=1 doctor_cache_get smoke-key >/dev/null 2>&1
echo $?
')
if [[ "$DISABLED_RC" == "1" ]]; then
  pass "doctor_cache_get returns 1 when FLYWHEEL_DOCTOR_CACHE_DISABLE=1"
else
  fail "cache-disable did not return 1 (got rc=$DISABLED_RC)"
fi

# Test 6: doctor_cache_mtime returns 0 for missing file (cross-platform stat fallback)
MTIME_OUT=$(bash -c '
source "'"$DOCTOR_SH"'" 2>/dev/null
doctor_cache_mtime /tmp/this-path-does-not-exist-flywheel-2xdi-34
')
if [[ "$MTIME_OUT" == "0" ]]; then
  pass "doctor_cache_mtime returns 0 on missing file"
else
  fail "doctor_cache_mtime missing-file output mismatch (got: $MTIME_OUT)"
fi

# Test 7: command_help_parity_doctor_json returns valid JSON when probe is missing
HELP_PARITY_OUT=$(bash -c '
source "'"$DOCTOR_SH"'" 2>/dev/null
FLYWHEEL_COMMAND_HELP_PARITY_AUDIT=/nonexistent/probe-script command_help_parity_doctor_json
')
if jq -e '.schema_version == "flywheel-command-help-parity-audit/v1"' >/dev/null 2>&1 <<<"$HELP_PARITY_OUT"; then
  pass "command_help_parity_doctor_json emits schema-versioned JSON when probe is missing"
else
  fail "command_help_parity_doctor_json output not schema-versioned (got: $HELP_PARITY_OUT)"
fi

# Test 8: doctor_schema_postcheck mutates a packet, adds command_help_parity key
SCHEMA_POST_OUT=$(bash -c '
source "'"$DOCTOR_SH"'" 2>/dev/null
export REPO_ABS=/Users/josh/Developer/flywheel
export FLYWHEEL_COMMAND_HELP_PARITY_AUDIT=/nonexistent/probe-script
export FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1
doctor_schema_postcheck "$(printf "%s" "{\"status\":\"pass\",\"errors\":[],\"warnings\":[]}")"
')
if jq -e '.command_help_parity.schema_version == "flywheel-command-help-parity-audit/v1"' >/dev/null 2>&1 <<<"$SCHEMA_POST_OUT"; then
  pass "doctor_schema_postcheck adds command_help_parity to the packet"
else
  fail "doctor_schema_postcheck output missing command_help_parity (got first 200 chars: ${SCHEMA_POST_OUT:0:200})"
fi

# Test 9: portable_doctor wires doctor_schema_postcheck (ledger reference for gap-hunter)
WIRE_FILE="$HOME/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh"
if [[ -r "$WIRE_FILE" ]] && grep -q "doctor_schema_postcheck" "$WIRE_FILE"; then
  pass "portable_doctor invokes doctor_schema_postcheck (file is hot, not cold)"
else
  fail "portable_doctor does not wire doctor_schema_postcheck — file may be genuinely cold"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
