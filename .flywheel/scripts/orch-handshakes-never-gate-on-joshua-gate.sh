#!/usr/bin/env bash
set -euo pipefail

json=0
quiet=0
mode=check
check_text=""

usage() {
  cat <<'EOF'
usage:
  orch-handshakes-never-gate-on-joshua-gate.sh [--json] [--quiet]
  orch-handshakes-never-gate-on-joshua-gate.sh --check-text TEXT [--json]
  orch-handshakes-never-gate-on-joshua-gate.sh --info|--examples|--help

Advisory structural gate for the META-RULE:
orch-handshakes-never-gate-on-joshua.
EOF
}

examples() {
  cat <<'EOF'
WARN Agent Mail contact approval fallback Option C: ask Joshua
ALLOW Agent Mail contact approval fallback Option C: file-based sidechannel
ALLOW fleet-spawned orchestrators auto-trust other fleet-spawned orchestrators
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1 ;;
    --quiet) quiet=1 ;;
    --check-text) check_text="${2:-}"; shift ;;
    --check-text=*) check_text="${1#*=}" ;;
    --info) mode=info ;;
    --examples) mode=examples ;;
    --help|-h) mode=help ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

case "$mode" in
  help) usage; exit 0 ;;
  examples) examples; exit 0 ;;
  info)
    jq -nc '{
      name:"orch-handshakes-never-gate-on-joshua-gate.sh",
      version:"orch-handshakes-never-gate-on-joshua-gate/v1.0.0",
      rule_id:"orch-handshakes-never-gate-on-joshua",
      hook_event:"Stop",
      read_only:true,
      mode:"advisory",
      blocks:false,
      exits:{"0":"no violation or advisory emitted","2":"usage error"}
    }'
    exit 0 ;;
esac

payload=""
if [[ -n "$check_text" ]]; then
  payload="$check_text"
else
  payload="$(cat 2>/dev/null || true)"
fi

text="$(printf '%s\n' "$payload" | jq -r '.. | strings' 2>/dev/null || printf '%s\n' "$payload")"
[[ -n "${text//[[:space:]]/}" ]] || exit 0
lc="$(printf '%s\n' "$text" | tr '[:upper:]' '[:lower:]')"

has() { grep -Eiq "$1" <<<"$lc"; }

handshake='(agent[ -]?mail|fleet[ -]?mail|contact (approval|request|handshake)|trust (grant|approval)|peer[ -]?orch trust|orch(estra(tor)?)? handshake|intra[ -]?fleet)'
josh_gate='(joshua approval|josh approval|ask joshua|ask josh|manual approval from josh(ua)?|founder approval|option c.{0,80}josh(ua)?)'
allowed='(auto[ -]?trust|auto[ -]?approve|side[ -]?channel|file[ -]?based|flywheel[ -]?owned|never.{0,40}joshua|no joshua approval|not.{0,20}joshua[ -]?gated)'

if has "$handshake" && has "$josh_gate" && ! has "$allowed"; then
  reason="WARN [orch-handshakes-never-gate-on-joshua]: intra-fleet orchestrator handshakes are flywheel-owned coordination; use auto-trust or a file-based sidechannel, never Joshua approval."
  if [[ "$quiet" -eq 0 || "$json" -eq 1 ]]; then
    jq -nc --arg reason "$reason" '{
      decision:"warn",
      reason:$reason,
      hookSpecificOutput:{
        hookEventName:"Stop",
        additionalContext:("<system-reminder>"+$reason+"</system-reminder>")
      }
    }'
  fi
fi

exit 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
