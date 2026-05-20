#!/usr/bin/env bash
# CANONICAL FLYWHEEL HOOK — pretooluse-bash-respawn-max-context-guard.sh
#
# Canonical source: /Users/josh/Developer/flywheel/.flywheel/hooks/pretooluse-bash-respawn-max-context-guard.sh
# Schema:           skillos.hook_manifest.v1
# Doctrine ref:     feedback_never_respawn_worker_at_max_context_cardinal_sin.md, SLB-1 2026-05-20
# Purpose:          Block 'ntm respawn' when target pane shows 100% context / auto-compact / context-limit markers.
#
# Installed by:     /flywheel:sync-hooks (consumer-side pull).
# DO NOT EDIT IN CONSUMER REPOS. Patch this canonical copy and re-sync.
#
# Background (2026-05-20 SLB lock skillos:1 + flywheel:1):
#   zesttube:2 raw-`ntm respawn`-ed claude pane 1 at "100% context used" state,
#   destroying auto-compact-pending work. Joshua-direct: "WORKERS AUTO COMPACT
#   - this is NOT ALLOWED." Memory pin:
#   feedback_never_respawn_worker_at_max_context_cardinal_sin.md
#
# Logic:
#   1. Parse Bash command. If no `ntm respawn`, exit 0.
#   2. Extract target session + panes.
#   3. Probe last-20-lines scrollback for each pane via `ntm --robot-tail`.
#   4. Match patterns: 100% context used | compacting | auto-compact | context limit
#   5. If match → EXIT 2 (BLOCK) with redirect to /flywheel:respawn.
#   6. Override: --force-max-context-override="<reason>" allows + logs.
#   7. Probe failure → fail-open (don't block legitimate respawn).
#
# Substrate class: protection (self-exempt — does not write project files).
# Ledger: ~/.local/state/flywheel/respawn-max-context-overrides.jsonl

set -euo pipefail

INPUT=$(cat)

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')
[[ "$TOOL" != "Bash" ]] && exit 0

CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')
[[ -z "$CMD" ]] && exit 0

if ! printf '%s' "$CMD" | grep -qE '(^|[[:space:];&|`(])ntm[[:space:]]+respawn([[:space:]]|$)'; then
  exit 0
fi

NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
[[ -x "$NTM_BIN" ]] || NTM_BIN="$(command -v ntm 2>/dev/null || true)"
if [[ -z "$NTM_BIN" || ! -x "$NTM_BIN" ]]; then
  exit 0
fi

LEDGER_DIR="$HOME/.local/state/flywheel"
LEDGER_PATH="$LEDGER_DIR/respawn-max-context-overrides.jsonl"
mkdir -p "$LEDGER_DIR" 2>/dev/null || true

OVERRIDE_REASON=""
if printf '%s' "$CMD" | grep -qE -- '--force-max-context-override='; then
  OVERRIDE_REASON=$(printf '%s' "$CMD" | sed -nE 's/.*--force-max-context-override=("([^"]*)"|'\''([^'\'']*)'\''|([^[:space:]]+)).*/\2\3\4/p' | head -1)
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  printf '{"ts":"%s","reason":%s,"command":%s}\n' \
    "$TS" \
    "$(printf '%s' "$OVERRIDE_REASON" | jq -Rs .)" \
    "$(printf '%s' "$CMD" | jq -Rs .)" \
    >> "$LEDGER_PATH" 2>/dev/null || true
  exit 0
fi

TAIL=$(printf '%s' "$CMD" | sed -E 's/.*ntm[[:space:]]+respawn([[:space:]]+|$)//')
SESSION=""
PANES_RAW=""
ALL_PANES=0
# shellcheck disable=SC2206
TOKENS=($TAIL)
for tok in "${TOKENS[@]}"; do
  case "$tok" in
    --panes=*) PANES_RAW="${tok#--panes=}" ;;
    --all|--all=*) ALL_PANES=1 ;;
    --*) : ;;
    -*) : ;;
    *)
      if [[ -z "$SESSION" ]]; then
        SESSION="$tok"
      fi
      ;;
  esac
done

SESSION="${SESSION%%[;|&<>]*}"
SESSION="${SESSION//\"/}"
SESSION="${SESSION//\'/}"

if [[ -z "$SESSION" ]]; then
  exit 0
fi

PANES_TO_PROBE=()
if [[ $ALL_PANES -eq 1 || -z "$PANES_RAW" ]]; then
  PANES_TO_PROBE=("")
else
  IFS=',' read -ra PANES_TO_PROBE <<< "$PANES_RAW"
fi

PATTERN='100% context used|compacting|auto-compact|context limit|approaching context limit|context left until auto-compact'

HIT_PANE=""
HIT_LINE=""

probe_one() {
  local pane="$1"
  local out
  if [[ -n "$pane" ]]; then
    out=$(timeout 4 "$NTM_BIN" "--robot-tail=$SESSION" "--panes=$pane" --lines=20 2>/dev/null || true)
  else
    out=$(timeout 4 "$NTM_BIN" "--robot-tail=$SESSION" --lines=20 2>/dev/null || true)
  fi
  [[ -z "$out" ]] && return 0
  local lines
  lines=$(printf '%s' "$out" | jq -r '.panes // {} | to_entries[] | .key as $p | .value.lines[]? | "\($p)\t\(.)"' 2>/dev/null || true)
  [[ -z "$lines" ]] && return 0
  local match
  match=$(printf '%s' "$lines" | grep -iE "$PATTERN" | head -1 || true)
  if [[ -n "$match" ]]; then
    HIT_PANE=$(printf '%s' "$match" | cut -f1)
    HIT_LINE=$(printf '%s' "$match" | cut -f2- | head -c 200)
    return 1
  fi
  return 0
}

for p in "${PANES_TO_PROBE[@]}"; do
  if ! probe_one "$p"; then
    cat >&2 <<EOF
[respawn-max-context-guard] BLOCKED — cardinal-sin trauma class.

Target session: $SESSION
Target pane:    ${HIT_PANE:-<unknown>}
Detected:       ${HIT_LINE:-<context-limit pattern>}

Raw \`ntm respawn\` against a pane in max-context / auto-compact / context-limit
state destroys auto-compact-pending work.

REDIRECT: use \`/flywheel:respawn\` (canonical path).

Override (logged):  --force-max-context-override="<one-line reason>"
Ledger: $LEDGER_PATH
EOF
    exit 2
  fi
done

exit 0
