#!/usr/bin/env bash
# mobile-eats-path-a-validator.sh
#
# flywheel-dwmb.1: split mobile-eats Path A receipt-mirror validation from
# full flywheel-loop doctor health.
#
# Path A success contract:
#   1. mobile-eats-receipt-bridge.sh --doctor --json returns status=ok
#      (this is the NARROW canonical gate — the only must-pass signal)
#   2. Full flywheel-loop doctor is captured as an ADVISORY field with
#      bounded timeout. Failure or timeout there does NOT mark Path A
#      rollback-worthy.
#
# This validator codifies the contract so workers do not invent their own
# gate and accidentally conflate the two surfaces (the trauma class
# documented in flywheel-dwmb evidence at
# .flywheel/audit/flywheel-dwmb/evidence.md).

set -uo pipefail

VERSION="mobile-eats-path-a-validator.v1"
BRIDGE="${MOBILE_EATS_RECEIPT_BRIDGE:-/Users/josh/Developer/flywheel/.flywheel/scripts/mobile-eats-receipt-bridge.sh}"
LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
REPO="${MOBILE_EATS_REPO:-/Users/josh/Developer/mobile-eats}"
ADVISORY_DOCTOR_TIMEOUT_SECONDS="${MOBILE_EATS_PATH_A_ADVISORY_TIMEOUT_SECONDS:-15}"
JSON_MODE=0

usage() {
  cat <<USAGE
Usage:
  mobile-eats-path-a-validator.sh [--json]
  mobile-eats-path-a-validator.sh --info [--json]
  mobile-eats-path-a-validator.sh --schema [--json]

Path A receipt-mirror validator. Returns 0 iff the canonical receipt bridge
reports status=ok. Full repo doctor is captured as advisory only.

Exit codes:
  0  Path A passes (bridge doctor ok)
  2  Path A fails (bridge doctor failed/missing — true rollback signal)
  3  bridge invocation error (substrate unavailable)
USAGE
}

info_json() {
  jq -nc --arg version "$VERSION" --arg bridge "$BRIDGE" --arg loop_bin "$LOOP_BIN" \
    --arg repo "$REPO" --arg advisory_timeout "$ADVISORY_DOCTOR_TIMEOUT_SECONDS" '{
    version:$version,
    bridge:$bridge,
    loop_bin:$loop_bin,
    repo:$repo,
    advisory_timeout_seconds:$advisory_timeout,
    contract:"Path A success = bridge doctor ok; full doctor is advisory only",
    canonical_cli_scoping:{
      doctor:"--doctor mode delegates to bridge",
      json:true,
      stable_exit_codes:[0,2,3]
    }
  }'
}

schema_json() {
  jq -nc --arg version "$VERSION" '{
    version:$version,
    fields:[
      "version",
      "path_a_status",
      "path_a_pass",
      "primary_gate",
      "primary_gate_evidence",
      "advisory",
      "advisory.full_doctor_status",
      "advisory.full_doctor_timeout_seconds",
      "advisory.full_doctor_exit_code",
      "rollback_recommended",
      "ts"
    ],
    rollback_rule:"rollback_recommended is true iff primary_gate failed; advisory failures are NOT rollback-worthy"
  }'
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Parse args
MODE="validate"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=1; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown flag: %s\n' "$1" >&2; exit 64 ;;
  esac
done

case "$MODE" in
  info)
    if [[ "$JSON_MODE" -eq 1 ]]; then info_json; else usage; fi
    exit 0
    ;;
  schema)
    schema_json
    exit 0
    ;;
esac

# === Primary gate: bridge --doctor --json ===
if [[ ! -x "$BRIDGE" ]] && [[ ! -f "$BRIDGE" ]]; then
  if [[ "$JSON_MODE" -eq 1 ]]; then
    jq -nc --arg ts "$(now_iso)" --arg bridge "$BRIDGE" '{
      version:"mobile-eats-path-a-validator.v1",
      ts:$ts,
      path_a_status:"bridge_unavailable",
      path_a_pass:false,
      primary_gate:"bridge --doctor --json",
      primary_gate_evidence:{error:"bridge script missing or not readable", path:$bridge},
      advisory:null,
      rollback_recommended:false
    }'
  else
    printf 'ERROR: bridge missing at %s\n' "$BRIDGE" >&2
  fi
  exit 3
fi

bridge_output="$(bash "$BRIDGE" --doctor --json 2>&1)"
bridge_rc=$?

bridge_status="$(printf '%s' "$bridge_output" | jq -r '.status // "unknown"' 2>/dev/null || echo unknown)"
bridge_ts="$(printf '%s' "$bridge_output" | jq -r '.ts // "unknown"' 2>/dev/null || echo unknown)"

if [[ "$bridge_rc" -ne 0 ]] || [[ "$bridge_status" != "ok" ]]; then
  PATH_A_PASS=false
  PATH_A_STATUS="bridge_failed"
  ROLLBACK=true
else
  PATH_A_PASS=true
  PATH_A_STATUS="ok"
  ROLLBACK=false
fi

# === Advisory: full doctor with bounded timeout ===
ADVISORY_DOCTOR_STATUS="unavailable"
ADVISORY_DOCTOR_RC=null
ADVISORY_DOCTOR_REASON="loop_bin_missing"

if [[ -x "$LOOP_BIN" ]]; then
  timeout_bin="$(command -v gtimeout || command -v timeout || true)"
  if [[ -n "$timeout_bin" ]]; then
    advisory_output="$("$timeout_bin" "$ADVISORY_DOCTOR_TIMEOUT_SECONDS" "$LOOP_BIN" doctor --repo "$REPO" --json 2>&1)"
    ADVISORY_DOCTOR_RC=$?
    case "$ADVISORY_DOCTOR_RC" in
      0)
        ADVISORY_DOCTOR_STATUS="$(printf '%s' "$advisory_output" | jq -r '.status // "ok"' 2>/dev/null || echo ok)"
        ADVISORY_DOCTOR_REASON="ran_within_timeout"
        ;;
      124)
        ADVISORY_DOCTOR_STATUS="timeout"
        ADVISORY_DOCTOR_REASON="exceeded_${ADVISORY_DOCTOR_TIMEOUT_SECONDS}s_advisory_budget"
        ;;
      *)
        ADVISORY_DOCTOR_STATUS="failed"
        ADVISORY_DOCTOR_REASON="exit_code_${ADVISORY_DOCTOR_RC}"
        ;;
    esac
  else
    ADVISORY_DOCTOR_STATUS="no_timeout_binary"
    ADVISORY_DOCTOR_REASON="cannot_safely_invoke_loop_doctor_without_timeout"
  fi
else
  ADVISORY_DOCTOR_REASON="loop_bin_missing_at_${LOOP_BIN}"
fi

# === Emit result ===
if [[ "$JSON_MODE" -eq 1 ]]; then
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg path_a_status "$PATH_A_STATUS" \
    --argjson path_a_pass "$PATH_A_PASS" \
    --arg bridge_status "$bridge_status" \
    --arg bridge_ts "$bridge_ts" \
    --argjson bridge_rc "$bridge_rc" \
    --arg advisory_status "$ADVISORY_DOCTOR_STATUS" \
    --argjson advisory_rc "${ADVISORY_DOCTOR_RC:-null}" \
    --arg advisory_reason "$ADVISORY_DOCTOR_REASON" \
    --arg advisory_timeout "$ADVISORY_DOCTOR_TIMEOUT_SECONDS" \
    --argjson rollback "$ROLLBACK" \
    '{
      version:"mobile-eats-path-a-validator.v1",
      ts:$ts,
      path_a_status:$path_a_status,
      path_a_pass:$path_a_pass,
      primary_gate:"bridge --doctor --json",
      primary_gate_evidence:{
        bridge_status:$bridge_status,
        bridge_ts:$bridge_ts,
        bridge_exit_code:$bridge_rc
      },
      advisory:{
        full_doctor_status:$advisory_status,
        full_doctor_exit_code:$advisory_rc,
        full_doctor_reason:$advisory_reason,
        full_doctor_timeout_seconds:($advisory_timeout|tonumber)
      },
      rollback_recommended:$rollback
    }'
else
  if [[ "$PATH_A_PASS" == "true" ]]; then
    printf '✓ Path A pass: bridge=%s ts=%s; advisory=%s (%s)\n' \
      "$bridge_status" "$bridge_ts" "$ADVISORY_DOCTOR_STATUS" "$ADVISORY_DOCTOR_REASON"
  else
    printf '✗ Path A FAIL: bridge=%s; advisory=%s; rollback=%s\n' \
      "$bridge_status" "$ADVISORY_DOCTOR_STATUS" "$ROLLBACK" >&2
  fi
fi

if [[ "$PATH_A_PASS" == "true" ]]; then
  exit 0
else
  exit 2
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
