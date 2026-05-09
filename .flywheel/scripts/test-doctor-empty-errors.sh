#!/usr/bin/env bash
# Synthetic regression test for flywheel-loop doctor status=fail errors[] contract.
set -euo pipefail

FLYWHEEL_LOOP="${FLYWHEEL_LOOP_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctor-empty-errors.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

repo="$TMP/not-a-git-repo"
fixture="$TMP/ntm-robot-health-mobile-eats.json"
legacy_fixture="$TMP/ntm-health-mobile-eats-legacy.json"
diagnose_fixture="$TMP/ntm-robot-diagnose-mobile-eats.json"
out="$TMP/doctor.json"
legacy_out="$TMP/doctor-legacy.json"
err="$TMP/doctor.err"
mkdir -p "$repo"

cat >"$fixture" <<'JSON'
{
  "success": true,
  "session": "mobile-eats",
  "checked_at": "2026-05-02T23:07:32Z",
  "agents": [
    {
      "pane": 0,
      "agent_type": "user",
      "health": "unhealthy",
      "last_error": "PID-based check: no living child process",
      "confidence": 1
    },
    {
      "pane": 1,
      "agent_type": "cod",
      "health": "unhealthy",
      "last_error": "PID-based check: no living child process",
      "confidence": 1
    },
    {
      "pane": 2,
      "agent_type": "cod",
      "health": "healthy",
      "confidence": 1
    }
  ],
  "summary": {
    "total": 3,
    "healthy": 1,
    "degraded": 0,
    "unhealthy": 2,
    "rate_limited": 0
  }
}
JSON

cat >"$diagnose_fixture" <<'JSON'
{
  "success": true,
  "session": "mobile-eats",
  "overall_health": "critical",
  "recommendations": [
    {
      "pane": 1,
      "status": "crashed",
      "action": "restart",
      "reason": "agent crashed"
    }
  ]
}
JSON

cat >"$legacy_fixture" <<'JSON'
{
  "session": "mobile-eats",
  "checked_at": "2026-05-02T23:07:32Z",
  "agents": [
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
FLYWHEEL_DOCTOR_NTM_ROBOT_HEALTH_JSON="$fixture" \
FLYWHEEL_DOCTOR_NTM_ROBOT_DIAGNOSE_JSON="$diagnose_fixture" \
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
    and (.message | contains("robot-health"))
    and ((.recommendations // []) | length == 1)
    and (all(.details[]; .health == "unhealthy"))
  )
' "$out" >/dev/null || {
  echo "FAIL: robot-health ntm_pane_error_unhealthy backfill missing or malformed" >&2
  cat "$out" >&2
  exit 1
}

FLYWHEEL_DOCTOR_NTM_HEALTH_JSON="$legacy_fixture" \
FLYWHEEL_DOCTOR_SESSION="mobile-eats" \
  bash -c 'source "$1"; doctor_ntm_health_json' _ \
    "$HOME/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh" \
    >"$legacy_out"

jq -e '
  any(.errors[]?;
    .code == "ntm_pane_error_unhealthy"
    and .session == "mobile-eats"
    and (.panes | sort) == [1]
  )
' "$legacy_out" >/dev/null || {
  echo "FAIL: legacy ntm health fallback fixture no longer works" >&2
  cat "$legacy_out" >&2
  exit 1
}

if jq -e 'any(.errors[]?; .code == "doctor_internal_empty_fail")' "$out" >/dev/null; then
  echo "FAIL: sentinel used despite concrete errors being available" >&2
  cat "$out" >&2
  exit 1
fi

echo "PASS: doctor status=fail carries concrete robot-health errors[] with legacy fallback"
