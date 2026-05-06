#!/usr/bin/env bash
set -uo pipefail

VERSION="orchestrator-callback-artifact-fix-bead.v1.0.0"
REPO="$PWD"
LEDGER="${ORCH_CALLBACK_ARTIFACT_FIX_BEAD_LEDGER:-$HOME/.local/state/flywheel/orchestrator-callback-artifact-fix-beads.jsonl}"
TASK_ID="" BEAD="" REASON="" DISPATCH_FILE="" ARTIFACT_LIST="" JSON_OUT=0

usage() { cat <<'EOF'
usage:
  orchestrator-callback-artifact-fix-bead.sh --task-id ID --reason REASON --dispatch-file PATH --artifact-list TEXT [--bead ID] [--repo PATH] [--json]
  orchestrator-callback-artifact-fix-bead.sh --info|--help|--examples
EOF
}
info() { jq -nc --arg version "$VERSION" --arg ledger "$LEDGER" '{name:"orchestrator-callback-artifact-fix-bead.sh",version:$version,ledger:$ledger,purpose:"idempotently open acceptance-artifact fix beads via JSONL fallback"}'; }
examples() { cat <<'EOF'
orchestrator-callback-artifact-fix-bead.sh --task-id task-a --reason artifact_missing --dispatch-file /tmp/dispatch.md --artifact-list 'a.sh' --json
ORCH_CALLBACK_ARTIFACT_FIX_BEAD_LEDGER=/tmp/fix-ledger.jsonl orchestrator-callback-artifact-fix-bead.sh --repo /tmp/repo --task-id task-a --reason artifact_subthreshold --dispatch-file /tmp/dispatch.md --artifact-list $'a.sh\nb.json' --json
EOF
}
fail_usage() { printf 'ERR: %s\n' "$1" >&2; usage >&2; exit 2; }
now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
safe_part() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-' | sed 's/--*/-/g; s/^-//; s/-$//'; }
append_ledger() { mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1; jq -c . <<<"$1" >>"$LEDGER" 2>/dev/null; }
dedupe_lookup() { [[ -f "$LEDGER" ]] || return 1; jq -r --arg key "$1" 'select(.dedupe_key == $key) | .fix_bead_id' "$LEDGER" 2>/dev/null | head -1; }
emit() { [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$1" || jq -r '"status=\(.status) action=\(.action) fix_bead_id=\(.fix_bead_id)"' <<<"$1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --bead) BEAD="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --dispatch-file) DISPATCH_FILE="${2:-}"; shift 2 ;;
    --artifact-list) ARTIFACT_LIST="${2:-}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
done

REPO="$(cd "$REPO" 2>/dev/null && pwd -P)" || fail_usage "repo not found: $REPO"
[[ -n "$TASK_ID" ]] || fail_usage "missing --task-id"
[[ -n "$REASON" ]] || fail_usage "missing --reason"
[[ -n "$DISPATCH_FILE" ]] || fail_usage "missing --dispatch-file"

safe_task="$(safe_part "$TASK_ID")"; [[ -n "$safe_task" ]] || safe_task="unknown"
dedupe_hash="$(printf '%s:%s:%s' "$TASK_ID" "$REASON" "$ARTIFACT_LIST" | shasum -a 256 | awk '{print substr($1,1,12)}')"
dedupe_key="${TASK_ID}:${REASON}:${dedupe_hash}"
existing="$(dedupe_lookup "$dedupe_key" || true)"
if [[ -n "$existing" ]]; then
  row="$(jq -nc --arg ts "$(now_iso)" --arg task "$TASK_ID" --arg reason "$REASON" --arg dedupe "$dedupe_key" --arg fix "$existing" '{schema_version:"orchestrator-callback-artifact-fix-bead/v1",ts:$ts,status:"pass",action:"reused",task_id:$task,reason:$reason,dedupe_key:$dedupe,fix_bead_id:$fix}')"
  emit "$row"; exit 0
fi

fix_id="flywheel-fix-${dedupe_hash}"
title="fix-${safe_task}-acceptance-artifacts"
desc="$(jq -Rs . <<EOF
Acceptance artifact validation failed for ${TASK_ID}.

reason=${REASON}
parent_bead=${BEAD:-unknown}
dispatch_file=${DISPATCH_FILE}

Missing or malformed artifacts:
${ARTIFACT_LIST:-<none>}
EOF
)"
jsonl="$REPO/.beads/issues.jsonl"
mkdir -p "$(dirname "$jsonl")"
if ! jq -e --arg id "$fix_id" 'select(.id == $id)' "$jsonl" >/dev/null 2>&1; then
  jq -nc --arg id "$fix_id" --arg title "$title" --argjson description "$desc" --arg now "$(now_iso)" --arg repo "$REPO" \
    '{id:$id,title:$title,description:$description,status:"open",priority:0,issue_type:"bug",created_at:$now,created_by:"orchestrator-callback-artifact-validator",updated_at:$now,source_repo:$repo,labels:["orchestrator-callback-artifact-validator","auto-fix"],compaction_level:0,original_size:0}' >>"$jsonl"
fi

row="$(jq -nc --arg ts "$(now_iso)" --arg task "$TASK_ID" --arg bead "$BEAD" --arg reason "$REASON" --arg dispatch "$DISPATCH_FILE" --arg artifacts "$ARTIFACT_LIST" --arg dedupe "$dedupe_key" --arg fix "$fix_id" '{schema_version:"orchestrator-callback-artifact-fix-bead/v1",ts:$ts,status:"pass",action:"jsonl_fallback",task_id:$task,bead:$bead,reason:$reason,dispatch_file:$dispatch,artifact_list:($artifacts | split("\n") | map(select(length > 0))),dedupe_key:$dedupe,fix_bead_id:$fix}')"
append_ledger "$row" || true
emit "$row"
