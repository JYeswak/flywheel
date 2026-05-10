#!/usr/bin/env bash
# scripts/audit.sh — canonical skill self-audit template
#
# Per canonical-cli-scoping triad (validate / audit / why):
# validate.sh = "is the skill ready to use right now?" (binary)
# audit.sh    = "what does the skill see in its substrate?" (descriptive)
#
# audit.sh output is read by:
#  - flywheel orch tick (skill substrate health rollup)
#  - skill-builder fleet-rollup (cross-skill substrate dashboards)
#  - operators triaging "why is this skill behaving weirdly?"
#
# audit.sh must be SAFE to run repeatedly with no side effects (read-only).
# It is NOT for repair; that's a separate `repair.sh` or `doctor.sh --fix`
# concern.
#
# Substitute every <SKILL_NAME>, <SUBSTRATE_PROBE> placeholder for the skill.

set -euo pipefail

SKILL_NAME="<SKILL_NAME>"
SCHEMA_VERSION="skill-audit/v1"
JSON_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=1; shift ;;
    --help)
      cat <<EOF
Usage: audit.sh [--json]
Canonical skill self-audit for $SKILL_NAME.

Read-only inspection of the skill's substrate state. Does not mutate.
Exit codes:
  0  audit completed (substrate may be healthy or degraded)
  2  audit could not run (e.g. substrate binary unreachable)
EOF
      exit 0 ;;
    *) printf 'unknown flag: %s\n' "$1" >&2; exit 64 ;;
  esac
done

now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

emit() {
  local payload="$1"
  if [[ "$JSON_MODE" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    # Human-readable form: pretty-print with jq if available
    if command -v jq >/dev/null 2>&1; then
      printf '%s\n' "$payload" | jq .
    else
      printf '%s\n' "$payload"
    fi
  fi
}

# === SUBSTRATE PROBE (per-skill customization point) ===
# Replace this section with the skill's actual audit probe.
# The probe must be READ-ONLY and emit a stable JSON shape.
#
# Example shapes by skill class:
#   - cli-aggregator skill:    capture <bin> doctor --json output
#   - file-pattern skill:      count matching files + report newest mtime
#   - service-integration:     hit health endpoint + capture latency
#
# Default stub: report skill name + timestamp + presence of the substrate
# binary plus any environment indicators. Returns exit 0 even if substrate
# is degraded (audit reports state; validate enforces it).

SUBSTRATE_PROBE="<SUBSTRATE_PROBE>"

substrate_present="false"
substrate_version="unknown"

# Default probe: check for the substrate binary on PATH.
# Customize per skill — most skills will replace this with a real probe.
if [[ "$SUBSTRATE_PROBE" != "<SUBSTRATE_PROBE>" ]] && [[ -n "$SUBSTRATE_PROBE" ]]; then
  if command -v "$SUBSTRATE_PROBE" >/dev/null 2>&1; then
    substrate_present="true"
    substrate_version=$("$SUBSTRATE_PROBE" --version 2>/dev/null \
      | head -1 \
      | awk '{print $NF}' || echo "unknown")
  fi
fi

# Build the audit payload. Skills can append their own fields by sourcing
# this template and post-processing $payload before emit.
payload=$(printf '{"schema_version":"%s","skill":"%s","ts":"%s","substrate_present":%s,"substrate_version":"%s"}' \
  "$SCHEMA_VERSION" \
  "$SKILL_NAME" \
  "$(now_iso)" \
  "$substrate_present" \
  "$substrate_version")

emit "$payload"
exit 0
