#!/usr/bin/env bash
# Append a fleet roster lifecycle row for one session.
set -euo pipefail

TOPOLOGY="${FLYWHEEL_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
ROSTER="${FLYWHEEL_TEAM_ROSTER:-$HOME/.local/state/flywheel/team-roster.jsonl}"

SESSION="${SESSION:-$(tmux display-message -p '#S' 2>/dev/null || echo "unknown")}"
EVENT="session_active"
REPO=""
DOMAIN=""
CLIENT=""
MISSION=""
BORROW="false"

usage() {
    echo "usage: roster-register.sh --session NAME --event EVENT [--repo PATH] [--domain NAME] [--client NAME] [--mission TEXT] [--available-for-borrow true|false]"
}

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' '
}

while [ $# -gt 0 ]; do
    case "$1" in
        --session) [ -n "${2:-}" ] || { echo "ERROR: --session requires NAME" >&2; exit 64; }; SESSION="$2"; shift 2 ;;
        --event) [ -n "${2:-}" ] || { echo "ERROR: --event requires EVENT" >&2; exit 64; }; EVENT="$2"; shift 2 ;;
        --repo) [ -n "${2:-}" ] || { echo "ERROR: --repo requires PATH" >&2; exit 64; }; REPO="$2"; shift 2 ;;
        --domain) [ -n "${2:-}" ] || { echo "ERROR: --domain requires NAME" >&2; exit 64; }; DOMAIN="$2"; shift 2 ;;
        --client) [ -n "${2:-}" ] || { echo "ERROR: --client requires NAME" >&2; exit 64; }; CLIENT="$2"; shift 2 ;;
        --mission) [ -n "${2:-}" ] || { echo "ERROR: --mission requires TEXT" >&2; exit 64; }; MISSION="$2"; shift 2 ;;
        --available-for-borrow) [ -n "${2:-}" ] || { echo "ERROR: --available-for-borrow requires true|false" >&2; exit 64; }; BORROW="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown flag: $1" >&2; usage >&2; exit 64 ;;
    esac
done

case "$BORROW" in
    true|false) ;;
    *) echo "ERROR: --available-for-borrow must be true or false" >&2; exit 64 ;;
esac

mkdir -p "$(dirname "$ROSTER")"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if command -v jq >/dev/null 2>&1; then
    TOPO=$(jq -sr --arg s "$SESSION" 'map(select(.session == $s)) | sort_by(.effective_at) | last // empty' "$TOPOLOGY" 2>/dev/null || true)
    if [ -z "$TOPO" ] || [ "$TOPO" = "null" ]; then
        echo "ERROR: no session-topology row for $SESSION -- run flywheel-loop register-session first" >&2
        exit 65
    fi

    ORCH_PANE=$(printf '%s' "$TOPO" | jq -r '.orchestrator_pane // 1')
    ORCH_KIND=$(printf '%s' "$TOPO" | jq -r '.orchestrator_kind // "claude"')
    WORKER_PANES=$(printf '%s' "$TOPO" | jq -c '.worker_panes // []')
    WORKER_KINDS=$(printf '%s' "$TOPO" | jq -c '.worker_kinds // {}')
    WORKERS=$(printf '%s' "$TOPO" | jq -c '(.worker_panes // []) as $panes | (.worker_kinds // {}) as $kinds | $panes | map({pane: ., kind: ($kinds[(.|tostring)] // "unknown"), role: "worker"})')
    FLEET_MAIL=$(printf '%s' "$TOPO" | jq -r '.fleet_mail_identity // .agent_mail_identity // ""')

    ROW=$(jq -nc --arg ts "$NOW" --arg event "$EVENT" --arg session "$SESSION" \
      --arg repo "$REPO" --arg domain "$DOMAIN" --arg client "$CLIENT" --arg mission "$MISSION" \
      --argjson orch_pane "$ORCH_PANE" --arg orch_kind "$ORCH_KIND" \
      --argjson worker_panes "$WORKER_PANES" --argjson worker_kinds "$WORKER_KINDS" --argjson workers "$WORKERS" \
      --arg fleet_mail "$FLEET_MAIL" --argjson borrow "$BORROW" \
      '{ts:$ts,event:$event,session:$session,repo_path:$repo,domain:$domain,client:$client,
        orchestrator:{pane:$orch_pane,kind:$orch_kind},worker_panes:$worker_panes,
        worker_kinds:$worker_kinds,workers:$workers,fleet_mail_identity:$fleet_mail,
        agent_mail_identity:$fleet_mail,current_mission:$mission,available_for_borrow:$borrow}')
else
    TOPO_LINE=$(awk -v needle="\"session\":\"$SESSION\"" 'index($0, needle) { row=$0 } END { print row }' "$TOPOLOGY" 2>/dev/null || true)
    [ -n "$TOPO_LINE" ] || { echo "ERROR: no session-topology row for $SESSION -- run flywheel-loop register-session first" >&2; exit 65; }
    ORCH_PANE=$(printf '%s' "$TOPO_LINE" | sed -n 's/.*"orchestrator_pane":\([0-9][0-9]*\).*/\1/p'); ORCH_PANE="${ORCH_PANE:-1}"
    ORCH_KIND=$(printf '%s' "$TOPO_LINE" | sed -n 's/.*"orchestrator_kind":"\([^"]*\)".*/\1/p'); ORCH_KIND="${ORCH_KIND:-claude}"
    WORKER_PANES=$(printf '%s' "$TOPO_LINE" | sed -n 's/.*"worker_panes":\(\[[^]]*\]\).*/\1/p'); WORKER_PANES="${WORKER_PANES:-[]}"
    FLEET_MAIL=$(printf '%s' "$TOPO_LINE" | sed -n 's/.*"fleet_mail_identity":"\([^"]*\)".*/\1/p')
    ROW=$(printf '{"ts":"%s","event":"%s","session":"%s","repo_path":"%s","domain":"%s","client":"%s","orchestrator":{"pane":%s,"kind":"%s"},"worker_panes":%s,"worker_kinds":{},"workers":[],"fleet_mail_identity":"%s","agent_mail_identity":"%s","current_mission":"%s","available_for_borrow":%s}' \
        "$(json_escape "$NOW")" "$(json_escape "$EVENT")" "$(json_escape "$SESSION")" "$(json_escape "$REPO")" "$(json_escape "$DOMAIN")" "$(json_escape "$CLIENT")" \
        "$ORCH_PANE" "$(json_escape "$ORCH_KIND")" "$WORKER_PANES" "$(json_escape "$FLEET_MAIL")" "$(json_escape "$FLEET_MAIL")" "$(json_escape "$MISSION")" "$BORROW")
fi

LOCK_DIR="${ROSTER}.lock.d"
LOCK_HELD=0
for _ in 1 2 3 4 5; do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        LOCK_HELD=1
        break
    fi
    sleep 0.1
done
[ "$LOCK_HELD" -eq 1 ] || { echo "ERROR: could not acquire roster lock: $LOCK_DIR" >&2; exit 75; }
trap '/bin/rmdir "$LOCK_DIR" 2>/dev/null || rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

printf '%s\n' "$ROW" >> "$ROSTER"
echo "Roster row appended: $SESSION event=$EVENT"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
