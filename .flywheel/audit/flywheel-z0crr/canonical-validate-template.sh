#!/usr/bin/env bash
# scripts/validate.sh — canonical skill self-validation template
#
# Per skill-builder doctrine + canonical-cli-scoping discipline:
# every JSM-managed skill ships a validate.sh that:
#  1. Confirms the skill's load-bearing CLI substrates are reachable.
#  2. Surfaces structured status via --json when invoked with --json.
#  3. Returns stable exit codes (0=ok, 2=substrate-missing, 3=substrate-degraded).
#  4. Fails fast on missing required fixtures rather than silently passing.
#
# Substitute every <SKILL_NAME>, <REQUIRED_BIN>, <DOCTOR_CMD> placeholder for
# the skill being stamped.

set -euo pipefail

SKILL_NAME="<SKILL_NAME>"
SCHEMA_VERSION="skill-validate/v1"
JSON_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=1; shift ;;
    --help)
      cat <<EOF
Usage: validate.sh [--json]
Canonical skill self-validation for $SKILL_NAME.

Exit codes:
  0  skill ready to use
  2  required substrate missing
  3  required substrate present but degraded
EOF
      exit 0 ;;
    *) printf 'unknown flag: %s\n' "$1" >&2; exit 64 ;;
  esac
done

emit_json() {
  local status="$1" reason="${2:-}" detail="${3:-}"
  printf '{"schema_version":"%s","skill":"%s","status":"%s","reason":"%s","detail":"%s"}\n' \
    "$SCHEMA_VERSION" "$SKILL_NAME" "$status" "$reason" "$detail"
}

emit_text() {
  local status="$1" reason="${2:-}" detail="${3:-}"
  if [[ "$status" == "ok" ]]; then
    printf '✓ %s ready: %s\n' "$SKILL_NAME" "${reason:-substrate present}"
  else
    printf '✗ %s %s: %s\n' "$SKILL_NAME" "$status" "${reason:-unknown}" >&2
    [[ -n "$detail" ]] && printf 'FIX: %s\n' "$detail" >&2
  fi
}

emit() {
  if [[ "$JSON_MODE" -eq 1 ]]; then
    emit_json "$@"
  else
    emit_text "$@"
  fi
}

# === SUBSTRATE PROBE (per-skill customization point) ===
# Replace the body of this section with the skill's actual probe.
# Examples:
#   - cass:    cass status --json | jq -e '.healthy'
#   - beads-br: br doctor --json
#   - ntm:      ntm --robot-health=<session> --json
#
# Default stub: check that the skill's <REQUIRED_BIN> exists on PATH.
REQUIRED_BIN="<REQUIRED_BIN>"

if ! command -v "$REQUIRED_BIN" >/dev/null 2>&1; then
  emit "substrate_missing" \
    "$REQUIRED_BIN not on PATH" \
    "install $REQUIRED_BIN before using this skill"
  exit 2
fi

# Optional: invoke the substrate's doctor/health probe.
DOCTOR_CMD="<DOCTOR_CMD>"
if [[ -n "$DOCTOR_CMD" ]] && [[ "$DOCTOR_CMD" != "<DOCTOR_CMD>" ]]; then
  if ! eval "$DOCTOR_CMD" >/dev/null 2>&1; then
    emit "substrate_degraded" \
      "$DOCTOR_CMD failed" \
      "run '$DOCTOR_CMD' manually to diagnose"
    exit 3
  fi
fi

emit "ok" "substrate ready" ""
exit 0
