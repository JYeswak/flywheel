#!/usr/bin/env bash
set -euo pipefail

VERSION="hub-blocker-detect.v1.0.0"
SCHEMA_VERSION="hub-blocker-detect/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="${HUB_BLOCKER_REPO:-$REPO_DEFAULT}"
BR_BIN="${BR_BIN:-$HOME/.cargo/bin/br}"
LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
THRESHOLD="${HUB_BLOCKER_THRESHOLD:-3}"
APPLY=0
JSON_OUT=0
COMMAND="check"

usage() {
  cat <<'EOF'
usage:
  hub-blocker-detect.sh [check|doctor] [--repo PATH] [--threshold N] [--apply] [--json]
  hub-blocker-detect.sh --info|--examples|--help

Detects open beads that block more than N parent closures. In apply mode it
promotes hub blockers to P0, labels them hub_blocker, and logs one fuckup row
per detected occurrence.
EOF
}

examples() {
  cat <<'EOF'
examples:
  .flywheel/scripts/hub-blocker-detect.sh --json
  .flywheel/scripts/hub-blocker-detect.sh --threshold 3 --apply --json
  HUB_BLOCKER_THRESHOLD=5 .flywheel/scripts/hub-blocker-detect.sh doctor --json
EOF
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

json_bool() {
  [[ "${1:-0}" == "1" ]] && printf true || printf false
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    check|doctor)
      COMMAND="$1"
      shift
      ;;
    --repo)
      REPO="${2:?missing --repo value}"
      shift 2
      ;;
    --threshold)
      THRESHOLD="${2:?missing --threshold value}"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --info)
      jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_VERSION" --arg repo "$REPO" \
        '{name:"hub-blocker-detect.sh",version:$version,schema_version:$schema,repo:$repo,commands:["check","doctor","--repo","--threshold","--apply","--json","--info","--examples","--help"],exits:{"0":"probe completed","1":"hub blocker detected in doctor/check mode","2":"usage or substrate error"}}'
      exit 0
      ;;
    --examples)
      examples
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'ERR: unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

case "$THRESHOLD" in
  ''|*[!0-9]*)
    printf 'ERR: --threshold must be a non-negative integer\n' >&2
    exit 2
    ;;
esac

if ! command -v jq >/dev/null 2>&1; then
  printf '{"schema_version":"%s","status":"error","error":"jq_missing"}\n' "$SCHEMA_VERSION"
  exit 2
fi

if [[ ! -x "$BR_BIN" ]] && ! command -v "$BR_BIN" >/dev/null 2>&1; then
  printf '{"schema_version":"%s","status":"error","error":"br_missing"}\n' "$SCHEMA_VERSION"
  exit 2
fi

if [[ ! -d "$REPO/.beads" ]]; then
  jq -nc --arg schema "$SCHEMA_VERSION" --arg repo "$REPO" \
    '{schema_version:$schema,status:"error",signal:"GRAY",repo:$repo,error:"beads_workspace_missing",hub_blocker_count:0,hub_blockers:[]}'
  exit 2
fi

issues_json="$(cd "$REPO" && "$BR_BIN" list --all --json --limit 0)"
if ! jq -e . >/dev/null 2>&1 <<<"$issues_json"; then
  jq -nc --arg schema "$SCHEMA_VERSION" --arg repo "$REPO" \
    '{schema_version:$schema,status:"error",signal:"GRAY",repo:$repo,error:"br_list_invalid_json",hub_blocker_count:0,hub_blockers:[]}'
  exit 2
fi

hub_ids="$(
  jq -r --argjson threshold "$THRESHOLD" '
    (if type == "array" then . else (.issues // []) end)[]
    | select((.status // "" | ascii_downcase) != "closed")
    | select((.dependency_count // 0) > $threshold)
    | [.id, (.priority // 4), (.dependency_count // 0), (.title // ""), (.status // "")] | @tsv
  ' <<<"$issues_json"
)"

rows_file="$(mktemp "${TMPDIR:-/tmp}/hub-blocker-rows.XXXXXX")"
trap 'rm -f "$rows_file"' EXIT
: >"$rows_file"

promoted_count=0
fuckup_log_count=0
actions=()

while IFS=$'\t' read -r bead_id priority parent_count title status; do
  [[ -n "${bead_id:-}" ]] || continue
  deps_json="$(cd "$REPO" && "$BR_BIN" dep list "$bead_id" --json 2>/dev/null || printf '[]')"
  parent_ids="$(jq -r '[.[]? | select((.type // "") == "blocks") | .depends_on_id] | unique | join(",")' <<<"$deps_json")"
  parent_status_counts="$(jq -c '[.[]? | select((.type // "") == "blocks") | (.status // "unknown")] | group_by(.) | map({(.[0]): length}) | add // {}' <<<"$deps_json")"
  would_promote=false
  promoted=false
  labeled=false
  if [[ "${priority:-4}" != "0" ]]; then
    would_promote=true
  fi
  if [[ "$APPLY" -eq 1 ]]; then
    if [[ "${priority:-4}" != "0" ]]; then
      (cd "$REPO" && "$BR_BIN" update "$bead_id" --priority 0 --json >/dev/null)
      promoted=true
      promoted_count=$((promoted_count + 1))
    fi
    (cd "$REPO" && "$BR_BIN" label add "$bead_id" --label hub_blocker --json >/dev/null) || true
    labeled=true
    actions+=("promoted_or_labeled:$bead_id")
    if [[ -x "$LOOP_BIN" ]]; then
      if (cd "$REPO" && "$LOOP_BIN" fuckup log \
          --class hub-blocker \
          --severity high \
          --what-happened "Hub blocker $bead_id parent_block_count=$parent_count. Hub blockers are the ops-manager's bottleneck signal: when one child is blocking 5 parents, that is the queue depth metric you escalate before the storm hits." \
          --what-attempted "hub-blocker-detect.sh --apply" \
          --what-worked "auto-promoted to P0 and labeled hub_blocker" \
          --evidence "$bead_id,parent_block_count=$parent_count" \
          --should-become bead \
          --session flywheel \
          --pane 3 \
          --json >/dev/null); then
        fuckup_log_count=$((fuckup_log_count + 1))
      else
        actions+=("fuckup_log_failed:$bead_id")
      fi
    else
      actions+=("fuckup_log_skipped_loop_bin_missing:$bead_id")
    fi
  else
    actions+=("would_promote_or_label:$bead_id")
  fi

  jq -nc \
    --arg id "$bead_id" \
    --arg title "$title" \
    --arg status "$status" \
    --argjson priority "${priority:-4}" \
    --argjson parent_block_count "${parent_count:-0}" \
    --arg parent_ids "$parent_ids" \
    --argjson parent_status_counts "$parent_status_counts" \
    --argjson would_promote "$would_promote" \
    --argjson promoted "$promoted" \
    --argjson labeled "$labeled" \
    '{
      id:$id,
      title:$title,
      status:$status,
      priority:$priority,
      parent_block_count:$parent_block_count,
      parent_ids:($parent_ids | split(",") | map(select(length > 0))),
      parent_status_counts:$parent_status_counts,
      would_promote:$would_promote,
      promoted:$promoted,
      labeled:$labeled
    }' >>"$rows_file"
done <<<"$hub_ids"

hub_blocker_count="$(jq -s 'length' "$rows_file")"
max_parent_block_count="$(jq -s '[.[].parent_block_count] | max // 0' "$rows_file")"
top_hub_blocker_id="$(jq -rs 'sort_by(.parent_block_count) | reverse | .[0].id // "none"' "$rows_file")"
top_parent_ids="$(jq -cs 'sort_by(.parent_block_count) | reverse | .[0].parent_ids // []' "$rows_file")"
rows_json="$(jq -s -c 'sort_by(.parent_block_count) | reverse' "$rows_file")"
if [[ "${#actions[@]}" -eq 0 ]]; then
  actions_json="[]"
else
  actions_json="$(printf '%s\n' "${actions[@]}" | sed '/^$/d' | jq -R . | jq -s .)"
fi
signal="GREEN"
status="pass"
exit_code=0
if [[ "$hub_blocker_count" -gt 0 ]]; then
  signal="RED"
  status="fail"
  [[ "$COMMAND" == "doctor" || "$COMMAND" == "check" ]] && exit_code=1
fi
dashboard_line="Hub blockers: ${hub_blocker_count} active | top=${top_hub_blocker_id}:${max_parent_block_count} parents | promoted=${promoted_count} | fuckups_logged=${fuckup_log_count}"

payload="$(
  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg repo "$REPO" \
    --arg signal "$signal" \
    --arg status "$status" \
    --argjson threshold "$THRESHOLD" \
    --argjson apply "$(json_bool "$APPLY")" \
    --argjson hub_blocker_count "$hub_blocker_count" \
    --argjson max_parent_block_count "$max_parent_block_count" \
    --arg top_hub_blocker_id "$top_hub_blocker_id" \
    --argjson top_parent_ids "$top_parent_ids" \
    --argjson promoted_count "$promoted_count" \
    --argjson fuckup_log_count "$fuckup_log_count" \
    --arg dashboard_line "$dashboard_line" \
    --argjson rows "$rows_json" \
    --argjson actions "$actions_json" \
    '{
      schema_version:$schema,
      version:$version,
      audit_ts:$ts,
      repo:$repo,
      status:$status,
      signal:$signal,
      threshold:$threshold,
      apply:$apply,
      hub_blocker_count:$hub_blocker_count,
      max_parent_block_count:$max_parent_block_count,
      top_hub_blocker_id:$top_hub_blocker_id,
      top_parent_ids:$top_parent_ids,
      promoted_count:$promoted_count,
      fuckup_log_count:$fuckup_log_count,
      dashboard_line:$dashboard_line,
      operator_lens:"Hub blockers are the ops-manager bottleneck signal: when one child blocks more than three parent closures, queue depth escalates before the storm hits.",
      hub_blockers:$rows,
      actions:$actions
    }'
)"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  jq -r '.dashboard_line' <<<"$payload"
fi

exit "$exit_code"
