#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/bin/flywheel"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-reduced-first-run.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  local rc=$?
  set +e
  return "$rc"
}

repo="$TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q

if bash -n "$BIN"; then pass "syntax"; else fail "syntax"; fi

if "$BIN" init --repo "$repo" --json >"$TMP/init.json" \
  && jq -e '.status == "initialized" and .private_state_scan.status == "pass" and (.created_paths | index(".flywheel/GOAL.md"))' "$TMP/init.json" >/dev/null; then
  pass "init"
else
  fail "init"
fi

if "$BIN" doctor --repo "$repo" --json >"$TMP/doctor.json" \
  && jq -e '.status == "pass" and .next_action.kind == "continue"' "$TMP/doctor.json" >/dev/null; then
  pass "doctor"
else
  fail "doctor"
fi

if "$BIN" tick --repo "$repo" --dry-run --json >"$TMP/tick.json" \
  && jq -e '.status == "pass" and .dry_run == true and .next_action.kind == "simulate-dispatch"' "$TMP/tick.json" >/dev/null; then
  pass "tick dry-run"
else
  fail "tick dry-run"
fi

if "$BIN" dispatch --repo "$repo" --simulate --json >"$TMP/dispatch.json" \
  && jq -e '.status == "pass" and .real_dispatch == false and .callback_contract.simulated == true' "$TMP/dispatch.json" >/dev/null; then
  pass "dispatch simulate"
else
  fail "dispatch simulate"
fi

if "$BIN" validate-receipt --repo "$repo" --file .flywheel/last_closeout_receipt.json --json >"$TMP/validate.json" \
  && jq -e '.status == "pass" and (.failure_classes | length == 0)' "$TMP/validate.json" >/dev/null; then
  pass "validate receipt"
else
  fail "validate receipt"
fi

if "$BIN" inspect --repo "$repo" --json >"$TMP/inspect.json" \
  && jq -e '.status == "pass" and .receipt.status == "present" and .next_action.kind == "inspect"' "$TMP/inspect.json" >/dev/null; then
  pass "inspect"
else
  fail "inspect"
fi

private_home_pattern='/Users''/josh'
if ! rg -n "${private_home_pattern}|sk-[A-Za-z0-9_-]{12,}|ghp_[A-Za-z0-9_]{20,}|pane scrollback|agent-mail archive" "$repo/.flywheel" >/dev/null; then
  pass "no private state material"
else
  fail "no private state material"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
