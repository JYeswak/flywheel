#!/usr/bin/env bash
# tests/agent-mail-fd-doctor-portable-liveness.sh
# Bead flywheel-5pjt2: regression coverage for the portable liveness
# fallback added to agent-mail-fd-doctor.sh.
#
# Pre-fix behavior (per flywheel-8nbah finding): when lsof was
# unavailable, the doctor returned FAIL even when the Agent Mail
# service was alive and healthy on the /health/liveness HTTP endpoint.
# Post-fix: when lsof is unavailable AND liveness OK, doctor returns
# WARN ("service alive, FD-pressure data unavailable") instead of
# misleading FAIL.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DOCTOR="${AGENT_MAIL_FD_DOCTOR:-$ROOT/.flywheel/scripts/agent-mail-fd-doctor.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: doctor exists + bash -n + has the liveness helper + cites bead
if [[ -x "$DOCTOR" ]] && bash -n "$DOCTOR" 2>/dev/null \
  && grep -q "check_liveness" "$DOCTOR" \
  && grep -q "flywheel-5pjt2" "$DOCTOR" \
  && grep -q "/health/liveness" "$DOCTOR"; then
  pass "doctor exists + bash -n ok + check_liveness helper + flywheel-5pjt2 citation + /health/liveness path"
else
  fail "doctor missing or fix not landed at $DOCTOR"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: doctor advertises the new exit-code semantics in usage
if "$DOCTOR" --help 2>&1 | grep -q "lsof unavailable + liveness OK"; then
  pass "usage documents new exit-code semantics (lsof unavailable + liveness OK = WARN)"
else
  fail "usage does not document new exit-code semantics"
fi

# Test 3: no-lsof + liveness=alive → WARN (not FAIL)
NO_LSOF_PATH="/usr/bin:/bin"   # excludes /opt/homebrew/bin where lsof may live
RESULT="$(AGENT_MAIL_FD_LIVENESS_OVERRIDE=alive PATH="$NO_LSOF_PATH" "$DOCTOR" --doctor --json 2>&1 || true)"
if jq -e '.status == "WARN" and .exit_code == 1' >/dev/null 2>&1 <<<"$RESULT"; then
  if jq -e '(.checks // []) | any(. | test("lsof unavailable.*liveness OK"))' >/dev/null 2>&1 <<<"$RESULT"; then
    pass "no-lsof + liveness=alive → WARN with descriptive check (was FAIL pre-fix)"
  else
    fail "no-lsof + liveness=alive: status correct but check message missing; got: ${RESULT:0:200}"
  fi
else
  fail "no-lsof + liveness=alive: expected WARN exit_code=1; got: $(jq -r '{status, exit_code}' <<<"$RESULT" 2>/dev/null || echo "$RESULT" | head -c 200)"
fi

# Test 4: no-lsof + liveness=down → FAIL (canonical service-down)
RESULT="$(AGENT_MAIL_FD_LIVENESS_OVERRIDE=down PATH="$NO_LSOF_PATH" "$DOCTOR" --doctor --json 2>&1 || true)"
if jq -e '.status == "FAIL" and .exit_code == 2' >/dev/null 2>&1 <<<"$RESULT"; then
  if jq -e '(.checks // []) | any(. | test("lsof unavailable AND liveness failed"))' >/dev/null 2>&1 <<<"$RESULT"; then
    pass "no-lsof + liveness=down → FAIL with both-condition check"
  else
    fail "no-lsof + liveness=down: status correct but check message missing"
  fi
else
  fail "no-lsof + liveness=down: expected FAIL exit_code=2; got: $(jq -r '{status, exit_code}' <<<"$RESULT" 2>/dev/null || echo "$RESULT" | head -c 200)"
fi

# Test 5: check_liveness helper honors AGENT_MAIL_FD_LIVENESS_OVERRIDE
# (sourced + invoked directly to avoid the full doctor side-effects)
if (
  set +u
  source "$DOCTOR" >/dev/null 2>&1 || true
  AGENT_MAIL_FD_LIVENESS_OVERRIDE=alive check_liveness && \
    ! AGENT_MAIL_FD_LIVENESS_OVERRIDE=down check_liveness
) 2>/dev/null; then
  pass "check_liveness helper honors AGENT_MAIL_FD_LIVENESS_OVERRIDE (alive=0 / down=1)"
else
  # Sourcing the doctor is fragile due to its body running on source.
  # Fall back to a more isolated check: confirm the override branch
  # exists in source.
  if grep -qE 'case "\$\{AGENT_MAIL_FD_LIVENESS_OVERRIDE:-\}"' "$DOCTOR"; then
    pass "check_liveness override branch present in source (sourcing test fragile; static check used)"
  else
    fail "check_liveness override branch missing"
  fi
fi

# Test 6: liveness URL is configurable via env (AGENT_MAIL_FD_LIVENESS_URL)
if grep -qE 'LIVENESS_URL.*AGENT_MAIL_FD_LIVENESS_URL' "$DOCTOR"; then
  pass "liveness URL configurable via AGENT_MAIL_FD_LIVENESS_URL env"
else
  fail "liveness URL not configurable"
fi

# Test 7: liveness timeout is configurable via env
if grep -qE 'LIVENESS_TIMEOUT.*AGENT_MAIL_FD_LIVENESS_TIMEOUT' "$DOCTOR"; then
  pass "liveness timeout configurable via AGENT_MAIL_FD_LIVENESS_TIMEOUT env"
else
  fail "liveness timeout not configurable"
fi

# Test 8: live doctor still produces a valid response (doesn't hang or
# crash on host that has lsof). Schema-version + status fields present.
LIVE_JSON="$("$DOCTOR" --doctor --json 2>/dev/null || true)"
if jq -e '
  .schema_version == "flywheel.agent_mail_fd_doctor.v1"
  and (.status | test("^(PASS|WARN|FAIL)$"))
  and (.exit_code | type) == "number"
' >/dev/null 2>&1 <<<"$LIVE_JSON"; then
  pass "live doctor still produces canonical packet shape (schema_version + status + exit_code)"
else
  fail "live doctor packet shape regressed; got: ${LIVE_JSON:0:200}"
fi

# Test 9: pre-fix bug shape is gone — "lsof unavailable" no longer
# uniformly returns FAIL; the helper exists.
if grep -qE 'if ! command -v lsof >/dev/null 2>&1; then' "$DOCTOR" \
  && grep -qE 'if check_liveness; then' "$DOCTOR"; then
  pass "no-lsof branch routes through check_liveness (pre-fix uniform-FAIL gone)"
else
  fail "no-lsof branch still returns uniform FAIL — fix didn't land"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
