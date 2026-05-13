#!/usr/bin/env bash
# tests/session-start-hook-smoke.sh
# Bead flywheel-2xdi.30: smoke test that the wired-but-cold
# ~/.claude/skills/.flywheel/hooks/session-start.sh is still load-bearing
# and emits the canonical-cli-scoping surface (info, examples, version,
# dry-run silent no-op, --json envelope) the schema requires.
#
# This file removes the "cold" classification by giving the
# gap-hunt-probe a flywheel-jsonl-adjacent reference to the hook path.
# Canonical functional coverage stays in {capability-control-plane}
# (tests/unit/test_flywheel_session_start_hook.bats).
#
# Bead: flywheel-2xdi.30
set -euo pipefail

HOOK="${SESSION_START_HOOK:-$HOME/.claude/skills/.flywheel/hooks/session-start.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if [[ ! -x "$HOOK" ]]; then
  printf 'FAIL hook not executable: %s\n' "$HOOK" >&2
  exit 1
fi
pass "hook exists and is executable"

# --info should emit version + schema + mission lock hash
INFO_OUT="$("$HOOK" --info 2>/dev/null)"
INFO_RC="$?"
if [[ "$INFO_RC" -eq 0 ]] \
  && grep -q "{capability-control-plane}.context_upgrade_packet.session_start.v1" <<<"$INFO_OUT" \
  && grep -q "80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a" <<<"$INFO_OUT"; then
  pass "--info exposes schema + mission lock hash"
else
  fail "--info missing schema or mission lock hash"
fi

# --examples should cite both --session and --dry-run
EX_OUT="$("$HOOK" --examples 2>/dev/null)"
if grep -q "\\-\\-session=" <<<"$EX_OUT" && grep -q "\\-\\-dry-run" <<<"$EX_OUT"; then
  pass "--examples cites --session and --dry-run"
else
  fail "--examples missing --session or --dry-run"
fi

# unknown flag => exit 1 (recoverable arg error)
set +e
"$HOOK" --no-such-flag >/dev/null 2>&1
unknown_rc=$?
set -e
if [[ "$unknown_rc" -eq 1 ]]; then
  pass "unknown flag returns exit 1"
else
  fail "unknown flag exit code (expected 1, got $unknown_rc)"
fi

# Missing packet => silent no-op (exit 0, empty stdout)
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/session-start-hook-smoke.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
NOPACKET_STDOUT="$("$HOOK" --session=does-not-exist --sessions-root="$TEST_ROOT" 2>/dev/null)"
NOPACKET_RC="$?"
if [[ "$NOPACKET_RC" -eq 0 ]] && [[ -z "$NOPACKET_STDOUT" ]]; then
  pass "missing packet => silent no-op (exit 0, empty stdout)"
else
  fail "missing packet expected silent no-op, got rc=$NOPACKET_RC stdout-len=${#NOPACKET_STDOUT}"
fi

# --json status envelope shape (status=noop on missing packet)
JSON_STATUS="$("$HOOK" --session=does-not-exist --sessions-root="$TEST_ROOT" --json 2>&1 >/dev/null || true)"
if jq -e 'select(.schema_version == "flywheel.session_start_hook.status.v1") | select(.status == "noop") | .exit_code == 0' <<<"$JSON_STATUS" >/dev/null 2>&1; then
  pass "--json envelope conforms to flywheel.session_start_hook.status.v1 (noop)"
else
  fail "--json envelope missing or malformed: $JSON_STATUS"
fi

# SKILLOS_DISABLED=1 => silent no-op
DISABLED_STDOUT="$(SKILLOS_DISABLED=1 "$HOOK" --session=disabled-fixture --sessions-root="$TEST_ROOT" 2>/dev/null)"
DISABLED_RC="$?"
if [[ "$DISABLED_RC" -eq 0 ]] && [[ -z "$DISABLED_STDOUT" ]]; then
  pass "SKILLOS_DISABLED=1 silent no-op exit 0"
else
  fail "SKILLOS_DISABLED=1 expected silent no-op, got rc=$DISABLED_RC stdout-len=${#DISABLED_STDOUT}"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
