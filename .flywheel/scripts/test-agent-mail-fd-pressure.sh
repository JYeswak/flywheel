#!/usr/bin/env bash
# Synthetic regression test for agent-mail-fd-pressure-check.sh.
set -euo pipefail

ROOT="/Users/josh/Developer/flywheel"
CHECK="$ROOT/.flywheel/scripts/agent-mail-fd-pressure-check.sh"

run_case() {
  local name="$1" fd_count="$2" limit="$3" expected_status="$4" expected_code="${5:-}"
  local out rc status code

  rc=0
  out="$(FAKE_FD_COUNT="$fd_count" FAKE_ULIMIT="$limit" "$CHECK" --json 2>&1)" || rc=$?
  if ! jq -e . >/dev/null 2>&1 <<<"$out"; then
    printf 'FAIL: %s produced invalid JSON: %s\n' "$name" "$out" >&2
    exit 1
  fi

  status="$(jq -r '.status' <<<"$out")"
  if [[ "$status" != "$expected_status" ]]; then
    printf 'FAIL: %s expected status=%s got=%s\n%s\n' "$name" "$expected_status" "$status" "$out" >&2
    exit 1
  fi

  if [[ "$expected_status" == "error" && "$rc" -eq 0 ]]; then
    printf 'FAIL: %s expected non-zero exit for critical pressure\n' "$name" >&2
    exit 1
  fi
  if [[ "$expected_status" != "error" && "$rc" -ne 0 ]]; then
    printf 'FAIL: %s expected zero exit got rc=%s\n%s\n' "$name" "$rc" "$out" >&2
    exit 1
  fi

  if [[ -n "$expected_code" ]]; then
    code="$(jq -r '.errors[0].code // empty' <<<"$out")"
    if [[ "$code" != "$expected_code" ]]; then
      printf 'FAIL: %s expected code=%s got=%s\n%s\n' "$name" "$expected_code" "$code" "$out" >&2
      exit 1
    fi
  fi

  printf 'PASS: %s fd=%s limit=%s status=%s\n' "$name" "$fd_count" "$limit" "$status"
}

run_case "50pct-ok" 50 100 ok
run_case "85pct-warn" 85 100 warn agent_mail_fd_pressure_warn
run_case "97pct-error" 97 100 error agent_mail_fd_pressure_critical

printf 'PASS: synthetic fd-pressure guard cases passed\n'
