#!/usr/bin/env bash
# OVERRIDE-HANDROLL: Layer-3 of agent-mail-fleet-pre-auth SLB. Calls set_contact_policy
#   (agent-mail native canonical surface per skillos:1 HYBRID recommendation).
#   No existing tool wraps this MCP call against a fleet identity registry.
# ~/.flywheel/scripts/agent-mail-fleet-bootstrap-contact-policies.sh
#
# Reads ~/.flywheel/agent-mail-pre-authorized-fleet-contacts.json and prints
# the set_contact_policy MCP calls that should be issued for every fleet-to-fleet
# pair. Intended to be executed by an agent (Claude Code or Codex worker) that
# has agent-mail MCP access - emits invocation plan; agent executes.
#
# This is INSTRUCTION-EMITTING, not direct-execution: the agent-mail MCP server
# requires the MCP client (Claude/Codex) to make the tool calls, not raw bash.
#
# Usage:
#   agent-mail-fleet-bootstrap-contact-policies.sh           # plan-only (dry-run)
#   agent-mail-fleet-bootstrap-contact-policies.sh --json    # JSON for agent consumption
#
# SLB: skillos:1 + flywheel:1 2026-05-21T00:34Z agent-mail-fleet-pre-auth-v1

set -euo pipefail

REGISTRY="${AGENT_MAIL_FLEET_REGISTRY:-$HOME/.flywheel/agent-mail-pre-authorized-fleet-contacts.json}"
[[ -f "$REGISTRY" ]] || { echo "ERROR: registry not found: $REGISTRY" >&2; exit 2; }

JSON_OUT=0
[[ "${1:-}" == "--json" ]] && JSON_OUT=1

if [[ "$JSON_OUT" -eq 1 ]]; then
  jq -c '
    .fleet_identities as $f
    | [$f[] as $from | $f[] as $to
       | select($from.identity != $to.identity)
       | {
           mcp_tool: "mcp__mcp-agent-mail__set_contact_policy",
           args: {
             from_identity: $from.identity,
             to_identity: $to.identity,
             policy: "auto_approve",
             reason: "Fleet pre-auth per ~/.flywheel/agent-mail-pre-authorized-fleet-contacts.json (Joshua-direct 2026-05-21T00:27Z Jeff-pattern solo-trust)"
           }
         }]
    | {schema_version:"flywheel.agent_mail_bootstrap_plan/v1",
       generated_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
       pair_count: length,
       pairs: .}
  ' "$REGISTRY"
else
  N=$(jq '[.fleet_identities[] | .identity] | length' "$REGISTRY")
  PAIRS=$(( N * (N - 1) ))
  echo "AGENT-MAIL FLEET BOOTSTRAP PLAN"
  echo "==============================="
  echo "Registry:    $REGISTRY"
  echo "Identities:  $N"
  echo "Pairs:       $PAIRS (directed N*(N-1))"
  echo ""
  echo "Plan: for each ordered pair (from, to), invoke MCP tool"
  echo "  mcp__mcp-agent-mail__set_contact_policy"
  echo "    from_identity=<from> to_identity=<to> policy=auto_approve"
  echo ""
  echo "Run with --json to get the structured invocation list for agent consumption."
  echo ""
  echo "First 5 pair previews:"
  jq -r '
    .fleet_identities as $f
    | [$f[] as $from | $f[] as $to
       | select($from.identity != $to.identity)
       | "  - \($from.identity) -> \($to.identity)"][0:5]
    | .[]
  ' "$REGISTRY"
fi
