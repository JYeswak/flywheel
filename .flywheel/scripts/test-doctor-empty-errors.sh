#!/usr/bin/env bash
# Synthetic regression test for flywheel-loop doctor status=fail errors[] contract.
set -euo pipefail

FLYWHEEL_LOOP="${FLYWHEEL_LOOP_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctor-empty-errors.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

repo="$TMP/not-a-git-repo"
fixture="$TMP/ntm-health-mobile-eats.json"
out="$TMP/doctor.json"
err="$TMP/doctor.err"
mkdir -p "$repo"

cat >"$fixture" <<'JSON'
{
  "session": "mobile-eats",
  "checked_at": "2026-05-02T23:07:32Z",
  "agents": [
    {
      "pane": 0,
      "agent_type": "user",
      "status": "error",
      "process_status": "exited",
      "activity": "idle",
      "last_activity": "2026-05-02T22:07:24Z",
      "issues": []
    },
    {
      "pane": 1,
      "agent_type": "cod",
      "status": "error",
      "process_status": "exited",
      "activity": "idle",
      "last_activity": "2026-05-02T22:07:24Z",
      "issues": []
    },
    {
      "pane": 2,
      "agent_type": "cod",
      "status": "ok",
      "process_status": "running",
      "activity": "idle",
      "last_activity": "2026-05-02T22:07:24Z",
      "issues": []
    }
  ],
  "summary": {
    "total": 3,
    "healthy": 1,
    "warning": 0,
    "error": 2,
    "unknown": 0
  },
  "overall_status": "error"
}
JSON

rc=0
FLYWHEEL_DOCTOR_NTM_HEALTH_JSON="$fixture" \
FLYWHEEL_DOCTOR_SESSION="mobile-eats" \
  "$FLYWHEEL_LOOP" doctor --repo "$repo" --json >"$out" 2>"$err" || rc=$?

if [[ "$rc" -eq 0 ]]; then
  echo "FAIL: synthetic fail path exited 0" >&2
  exit 1
fi

jq -e '.status == "fail" and ((.errors // []) | length > 0)' "$out" >/dev/null || {
  echo "FAIL: status=fail did not include non-empty errors[]" >&2
  cat "$out" >&2
  exit 1
}

jq -e 'any(.errors[]?; .code == "repo_not_git")' "$out" >/dev/null || {
  echo "FAIL: action-derived repo_not_git error missing" >&2
  cat "$out" >&2
  exit 1
}

jq -e '
  any(.errors[]?;
    .code == "ntm_pane_error_unhealthy"
    and .session == "mobile-eats"
    and (.panes | sort) == [0,1]
  )
' "$out" >/dev/null || {
  echo "FAIL: ntm_pane_error_unhealthy backfill missing or malformed" >&2
  cat "$out" >&2
  exit 1
}

if jq -e 'any(.errors[]?; .code == "doctor_internal_empty_fail")' "$out" >/dev/null; then
  echo "FAIL: sentinel used despite concrete errors being available" >&2
  cat "$out" >&2
  exit 1
fi

echo "PASS: doctor status=fail carries concrete errors[] including ntm_pane_error_unhealthy"
