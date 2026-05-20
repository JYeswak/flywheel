#!/usr/bin/env bash
# CANONICAL FLYWHEEL HOOK — pretooluse-bash-cross-repo-guard.sh
#
# Canonical source: /Users/josh/Developer/flywheel/.flywheel/hooks/pretooluse-bash-cross-repo-guard.sh
# Schema:           skillos.hook_manifest.v1
# Doctrine ref:     feedback_propagator_canonical_ownership_class_aware_gate.md, L159
# Purpose:          Block cross-repo Bash writes outside the active repo (closes the v38e1.5 shell-layer gap).
#
# Installed by:     /flywheel:sync-hooks (consumer-side pull from this canonical path).
# DO NOT EDIT IN CONSUMER REPOS. Patch this canonical copy in flywheel, then re-sync.
#
# PreToolUse hook for Bash — intercept shell-layer cross-repo writes
# (flywheel-16b53.4 sister-hook to pretooluse-write-edit-cross-repo-guard.sh).
#
# Background:
#   v38e1.5-class clobber trauma reached N=4 instances 2026-05-12T09:51Z
#   despite shipping the PreToolUse Write/Edit cross-repo guard at 09:57Z.
#   Skillos:1 verified live 2026-05-12T14:40Z that the Write/Edit hook DOES
#   work (correctly blocked their writes). The actual remaining gap is the
#   Bash-shell layer: redirect / tee / cp / install / rsync / dd /
#   sed-inplace / heredoc-redirect / programmatic-writers bypass the
#   tool-layer hook because they execute through the Bash tool.
#
#   This sister hook closes the shell-layer gap with the same default-deny
#   + authorize-list escape-hatch paradigm.
#
# Substrate class: protection (self-exempt per L162)
# L-rule anchor: L159 PROPAGATOR-CANONICAL-OWNERSHIP-CLASS-AWARE-GATE-MANDATORY
# Trauma anchor: v38e1.5-class N=4 (skillos:1 hypothesis correction 2026-05-12T14:40Z)
# Ledger: ~/.local/state/flywheel/cross-repo-write-block-ledger.jsonl (shared)

set -euo pipefail

INPUT=$(cat)

TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')
[[ "$TOOL" != "Bash" ]] && exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
[[ -z "$CMD" ]] && exit 0

# Determine session repo
SESSION_REPO=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[[ -z "$SESSION_REPO" ]] && exit 0

# ============================================================================
# STEP 1: Find any /Users/josh/{Developer,Code}/<repo>/ paths in the command
# ============================================================================
set +o pipefail
PEER_PATHS=$(echo "$CMD" | grep -oE '/Users/josh/(Developer|Code)/[a-zA-Z0-9_.-]+(/[^ "'"'"'`>|&;)]*)?' | sort -u)
set -o pipefail

[[ -z "$PEER_PATHS" ]] && exit 0

# ============================================================================
# STEP 2: Filter to peer-only paths (not session repo)
# ============================================================================
SESSION_REPO_BASE=$(basename "$SESSION_REPO")
PEER_HITS=""
DETECTED_PEER_REPO=""

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  repo_segment=$(echo "$path" | awk -F/ '{print $5}')
  [[ -z "$repo_segment" ]] && continue
  [[ "$repo_segment" == "$SESSION_REPO_BASE" ]] && continue
  parent_root=$(echo "$path" | awk -F/ '{print "/"$2"/"$3"/"$4"/"$5}')
  if [[ -d "$parent_root/.git" ]] || [[ -f "$parent_root/.git" ]]; then
    PEER_HITS+="$path "
    DETECTED_PEER_REPO="$parent_root"
  fi
done <<< "$PEER_PATHS"

[[ -z "$PEER_HITS" ]] && exit 0

# ============================================================================
# STEP 3: Determine if command contains write-class operators
# ============================================================================
WRITE_OPS=false

if echo "$CMD" | grep -qE '([^&|<]|^)(>>?|>\|)[[:space:]]*/Users/josh'; then
  WRITE_OPS=true
fi

if echo "$CMD" | grep -qE '\btee\b([[:space:]]+-a)?[[:space:]]+/Users/josh'; then
  WRITE_OPS=true
fi

if echo "$CMD" | grep -qE '\b(cp|install|rsync|ln|dd|touch)\b'; then
  WRITE_OPS=true
fi

if echo "$CMD" | grep -qE '\bsed\b[[:space:]]+(-i|--in-place)|\bawk\b[[:space:]]+(-i[[:space:]]+inplace|--in-place)|\bperl\b[[:space:]]+-i'; then
  WRITE_OPS=true
fi

if echo "$CMD" | grep -qE 'open\([^)]*[waxb+][^)]*\)|writeFileSync|appendFileSync|fs\.write|Path[[:space:]]*\([^)]+\)\.write_text'; then
  WRITE_OPS=true
fi

if echo "$CMD" | grep -qE '\b(python3?|node|ruby|perl)\b[[:space:]]+-c'; then
  if echo "$CMD" | grep -qE '\.write|\.dump|writeFile|write_text|os\.write|fputs|fprintf|>>>>'; then
    WRITE_OPS=true
  fi
fi

if echo "$CMD" | grep -qE '\bgit\b[[:space:]]+(-C[[:space:]]+/Users/josh/(Developer|Code)|--git-dir=/Users/josh/(Developer|Code))'; then
  if echo "$CMD" | grep -qE '\b(commit|push|add|reset|checkout|stash|merge|rebase|cherry-pick|revert|am|apply|tag|branch|filter-)'; then
    WRITE_OPS=true
  fi
fi

[[ "$WRITE_OPS" == "false" ]] && exit 0

# ============================================================================
# STEP 4: Check authorize-list for explicit exception
# ============================================================================
MANIFEST="${HOME}/.flywheel/cross-repo-authorized-writes.json"
if [[ -f "$MANIFEST" ]]; then
  AUTH=$(jq -r --arg session "$SESSION_REPO" --arg peer "$DETECTED_PEER_REPO" \
    '.authorizations[]? | select(.session_repo == $session and .peer_repo == $peer) | .expires_at // "permanent"' \
    "$MANIFEST" 2>/dev/null | head -1)
  if [[ -n "$AUTH" ]]; then
    if [[ "$AUTH" == "permanent" ]]; then
      exit 0
    fi
    NOW=$(date -u +%s)
    EXP=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$AUTH" "+%s" 2>/dev/null || echo 0)
    [[ "$NOW" -lt "$EXP" ]] && exit 0
  fi
fi

# ============================================================================
# STEP 5: BLOCK — log + emit decision
# ============================================================================
LEDGER="${HOME}/.local/state/flywheel/cross-repo-write-block-ledger.jsonl"
mkdir -p "$(dirname "$LEDGER")"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CMD_HEAD=$(printf '%s' "$CMD" | head -c 300)

jq -n --arg ts "$TS" --arg session "$SESSION" --arg tool "$TOOL" \
      --arg cmd "$CMD_HEAD" --arg peer "$DETECTED_PEER_REPO" \
      --arg session_repo "$SESSION_REPO" --arg peer_hits "$PEER_HITS" \
  '{schema_version:"flywheel.cross_repo_write_block/v1", ts:$ts, session_id:$session, tool:$tool, command:$cmd, peer_repo:$peer, session_repo:$session_repo, peer_hits:$peer_hits, blocked:true, layer:"shell"}' \
  >> "$LEDGER" 2>/dev/null || true

REASON="CROSS-REPO-SHELL-WRITE-BLOCKED. Bash command appears to write to peer repo ${DETECTED_PEER_REPO}; session repo is ${SESSION_REPO}. Authorize via ${MANIFEST}."

jq -n --arg reason "$REASON" '{decision:"block", reason:$reason, hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:"Shell-layer cross-repo write blocked."}}'
exit 0
