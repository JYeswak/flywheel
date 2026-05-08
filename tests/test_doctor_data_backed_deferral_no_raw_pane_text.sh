#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t doctor-deferral.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

source "$HOME/.claude/skills/.flywheel/lib/misc.sh"

jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg raw $'pane line 1\npane line 2\nSECRET-ish scrollback should not appear' '{ts:$ts,event:"data_backed_deferral_prevented",suggested_action:$raw}' >"$TMP/saves.jsonl"

FLYWHEEL_DATA_BACKED_DEFERRAL_SAVES_FILE="$TMP/saves.jsonl" \
FLYWHEEL_DATA_BACKED_DEFERRAL_OVERRIDES_FILE="$TMP/missing-overrides.jsonl" \
  doctor_check_data_backed_deferral >"$TMP/doctor.json"

assert_jq "$TMP/doctor.json" '.status == "ok"' "redaction_fixture_status_ok"
assert_jq "$TMP/doctor.json" '.last_suggested_action == null' "raw_multiline_suggested_action_redacted"
assert_jq "$TMP/doctor.json" '(tostring | contains("pane line 1") | not) and (tostring | contains("SECRET-ish") | not)' "raw_pane_text_absent"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 3 ]]
