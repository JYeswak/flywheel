#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/gap-wired-receivers.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

cross_session="$ROOT/.flywheel/scripts/cross-session-presence.sh"
trap_inventory="$ROOT/.flywheel/scripts/trap-rollback-inventory.sh"
trauma_handoff="$ROOT/.flywheel/scripts/trauma-handoff.sh"

for script in "$cross_session" "$trap_inventory" "$trauma_handoff"; do
  if bash -n "$script"; then
    pass "$(basename "$script") syntax"
  else
    fail "$(basename "$script") syntax"
  fi
done

"$cross_session" --info --json >"$TMP/cross-info.json"
assert_jq "$TMP/cross-info.json" '.name == "cross-session-presence" and (.canonical_truth_source | test("tmux capture-pane"))' "cross-session-presence.sh info receiver"
FLYWHEEL_CROSS_SESSION_PRESENCE=0 "$cross_session" probe --json >"$TMP/cross-disabled.json" || cross_rc=$?
if [[ "${cross_rc:-0}" == "3" ]] && jq -e '.status == "disabled"' "$TMP/cross-disabled.json" >/dev/null; then
  pass "cross-session-presence.sh disabled probe is bounded"
else
  fail "cross-session-presence.sh disabled probe is bounded"
fi

"$trap_inventory" --info --json >"$TMP/trap-info.json"
assert_jq "$TMP/trap-info.json" '.name == "trap-rollback-inventory.sh" and .read_only == true and .mutates_state == false' "trap-rollback-inventory.sh info receiver"
"$trap_inventory" doctor --json >"$TMP/trap-doctor.json"
assert_jq "$TMP/trap-doctor.json" '.command == "doctor" and .status == "pass"' "trap-rollback-inventory.sh doctor receiver"

mkdir -p "$TMP/repo/.flywheel/evidence" "$TMP/repo/.flywheel/state"
cat >"$TMP/repo/.flywheel/evidence/trauma-candidates.jsonl" <<'JSONL'
{"schema_version":"flywheel.trauma_candidate.v0","class":"fixture","fuckup_log_ref":"fixture#L1","recommended_skillos_loop":{"name":"fixture","version":"v1"}}
JSONL
TRAUMA_HANDOFF_REPO="$TMP/repo" "$trauma_handoff" --info --json >"$TMP/trauma-info.json"
assert_jq "$TMP/trauma-info.json" '.name == "trauma-handoff" and (.default_mode | test("prepare"))' "trauma-handoff.sh info receiver"
TRAUMA_HANDOFF_REPO="$TMP/repo" "$trauma_handoff" doctor --json >"$TMP/trauma-doctor.json"
assert_jq "$TMP/trauma-doctor.json" '.command == "doctor" and .status == "ok"' "trauma-handoff.sh doctor receiver"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
