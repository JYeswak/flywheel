#!/usr/bin/env bash
set -uo pipefail

VERSION="callback-fix-bead-opener.v1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="$REPO_DEFAULT"
LEDGER="${CALLBACK_FIX_BEAD_LEDGER:-$HOME/.local/state/flywheel/callback-fix-beads.jsonl}"
BR_BIN="${CALLBACK_FIX_BEAD_BR_BIN:-br}"
JSON_OUT=0 TASK_ID="" BEAD="" REASON="" EXPECTED="" ACTUAL=""

usage() { cat <<'EOF'
usage:
  callback-fix-bead-opener.sh --task-id ID --reason REASON [--bead ID] [--expected TEXT] [--actual TEXT] [--repo PATH] [--json]
  callback-fix-bead-opener.sh --info|--help|--examples
EOF
}
info() { jq -nc --arg version "$VERSION" --arg repo "$REPO_DEFAULT" --arg ledger "$LEDGER" '{name:"callback-fix-bead-opener.sh",version:$version,repo:$repo,ledger:$ledger,purpose:"idempotently open callback L112 verification fix beads"}'; }
examples() { cat <<'EOF'
callback-fix-bead-opener.sh --task-id task-a --bead flywheel-a --reason l112_output_mismatch --expected OK --actual NO --json
CALLBACK_FIX_BEAD_BR_BIN=/tmp/fake-br callback-fix-bead-opener.sh --task-id task-a --reason l112_verify_failed --json
EOF
}
fail_usage() { printf 'ERR: %s\n' "$1" >&2; usage >&2; exit 2; }
now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
safe_id_part() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-' | sed 's/--*/-/g; s/^-//; s/-$//'; }
append_ledger() { mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1; jq -c . <<<"$1" >>"$LEDGER" 2>/dev/null; }
dedupe_lookup() { [[ -f "$LEDGER" ]] || return 1; jq -r --arg key "$1" 'select(.dedupe_key == $key) | .fix_bead_id' "$LEDGER" 2>/dev/null | head -1; }
emit() { if [[ "$JSON_OUT" -eq 1 ]]; then printf '%s\n' "$1"; else printf 'status=%s fix_bead_id=%s action=%s\n' "$(jq -r '.status' <<<"$1")" "$(jq -r '.fix_bead_id' <<<"$1")" "$(jq -r '.action' <<<"$1")"; fi; }

append_jsonl_fallback() {
  local id="$1" title="$2" desc="$3" jsonl="$REPO/.beads/issues.jsonl" now row
  mkdir -p "$(dirname "$jsonl")"
  now="$(now_iso)"
  row="$(jq -nc --arg id "$id" --arg title "$title" --arg description "$desc" --arg now "$now" --arg repo "$REPO" '{id:$id,title:$title,description:$description,status:"open",priority:0,issue_type:"bug",created_at:$now,created_by:"callback-receipt-validator",updated_at:$now,source_repo:$repo,labels:["callback-receipt-validator","auto-fix"],compaction_level:0,original_size:0}')"
  [[ -f "$jsonl" ]] && jq -e --arg id "$id" 'select(.id == $id)' "$jsonl" >/dev/null 2>&1 && return 0
  printf '%s\n' "$row" >>"$jsonl"
}

run_open() {
  local safe_task title desc dedupe existing output rc fix_id action row hash
  [[ -n "$TASK_ID" ]] || fail_usage "missing --task-id"
  [[ -n "$REASON" ]] || fail_usage "missing --reason"
  safe_task="$(safe_id_part "$TASK_ID")"; [[ -n "$safe_task" ]] || safe_task="unknown"
  title="fix-${safe_task}-l112-mismatch"; dedupe="${TASK_ID}:${REASON}"
  existing="$(dedupe_lookup "$dedupe" || true)"
  if [[ -n "$existing" ]]; then
    row="$(jq -nc --arg ts "$(now_iso)" --arg task_id "$TASK_ID" --arg bead "$BEAD" --arg reason "$REASON" --arg dedupe "$dedupe" --arg fix "$existing" '{schema_version:"callback-fix-bead-opener/v1",ts:$ts,status:"pass",action:"reused",task_id:$task_id,bead:$bead,reason:$reason,dedupe_key:$dedupe,fix_bead_id:$fix}')"
    emit "$row"; return 0
  fi
  desc="Callback L112 verification failed for ${TASK_ID}. Worker reported ${EXPECTED:-<missing>} but verify returned ${ACTUAL:-<missing>}. Re-author task or fix gap. Parent: ${BEAD:-unknown}. reason=${REASON}."
  set +e
  output="$(cd "$REPO" && "$BR_BIN" create "$title" --type bug --priority p0 --status open --description "$desc" --json 2>&1)"
  rc=$?
  set +e
  if [[ "$rc" -eq 0 ]]; then
    fix_id="$(jq -r 'if type == "array" then (.[0].id // empty) else (.id // .issue.id // empty) end' 2>/dev/null <<<"$output" || true)"
    [[ -n "$fix_id" ]] || fix_id="created_unparsed"; action="created"
  else
    hash="$(printf '%s' "$dedupe" | shasum -a 256 | awk '{print substr($1,1,8)}')"
    fix_id="flywheel-fix-${hash}"; append_jsonl_fallback "$fix_id" "$title" "$desc"; action="jsonl_fallback"
  fi
  row="$(jq -nc --arg ts "$(now_iso)" --arg task_id "$TASK_ID" --arg bead "$BEAD" --arg reason "$REASON" --arg expected "$EXPECTED" --arg actual "$ACTUAL" --arg dedupe "$dedupe" --arg fix "$fix_id" --arg action "$action" --arg br_output "$output" --argjson br_rc "$rc" '{schema_version:"callback-fix-bead-opener/v1",ts:$ts,status:"pass",action:$action,task_id:$task_id,bead:$bead,reason:$reason,expected:$expected,actual:$actual,dedupe_key:$dedupe,fix_bead_id:$fix,br_rc:$br_rc,br_output:$br_output}')"
  append_ledger "$row" || true
  emit "$row"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --bead) BEAD="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --expected) EXPECTED="${2:-}"; shift 2 ;;
    --actual) ACTUAL="${2:-}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
done

REPO="$(cd "$REPO" 2>/dev/null && pwd -P)" || fail_usage "repo not found: $REPO"
run_open
