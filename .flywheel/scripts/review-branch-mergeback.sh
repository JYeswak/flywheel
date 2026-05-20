#!/usr/bin/env bash
set -euo pipefail

SCHEMA="review_branch_mergeback.v1"
STATE_DIR="${REVIEW_BRANCH_MERGEBACK_STATE_DIR:-$HOME/.local/state/flywheel/review-branch-mergeback}"
AUDIT_LOG="${REVIEW_BRANCH_MERGEBACK_AUDIT_LOG:-$STATE_DIR/runs.jsonl}"

usage() {
  cat >&2 <<'USAGE'
Usage:
  review-branch-mergeback.sh run --repo PATH --branch BRANCH (--dry-run|--apply) [--base main] [--remote origin] [--push] [--conflict-action none|issue] [--json]
  review-branch-mergeback.sh doctor --repo PATH [--branch BRANCH] [--base main] [--remote origin] [--json]
  review-branch-mergeback.sh health|audit|quickstart|--info|--schema|--examples [--json]
  review-branch-mergeback.sh validate repo|branch|clean-tree VALUE [--json]
  review-branch-mergeback.sh repair --scope state-dir (--dry-run|--apply) [--json]
  review-branch-mergeback.sh why RUN_ID [--json]
USAGE
}

json_escape() {
  local value=${1-}
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

json_string() { printf '"%s"' "$(json_escape "${1-}")"; }
bool_json() { [[ ${1:-0} -eq 1 ]] && printf true || printf false; }

json_array() {
  local first=1 item
  printf '['
  for item in "$@"; do
    [[ $first -eq 0 ]] && printf ','
    first=0
    json_string "$item"
  done
  printf ']'
}

emit_run_json() {
  printf '{'
  printf '"schema_version":'; json_string "$SCHEMA"
  printf ',"run_id":'; json_string "$run_id"
  printf ',"ts":'; json_string "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf ',"repo":'; json_string "$repo"
  printf ',"branch":'; json_string "$branch"
  printf ',"base":'; json_string "$base"
  printf ',"remote":'; json_string "$remote"
  printf ',"mode":'; json_string "$mode"
  printf ',"outcome":'; json_string "$outcome"
  printf ',"reason":'; json_string "$reason"
  printf ',"original_branch":'; json_string "$original_branch"
  printf ',"base_ref":'; json_string "$base_ref"
  printf ',"local_ahead":%s,"base_ahead":%s' "$local_ahead" "$base_ahead"
  printf ',"rebase_applied":'; bool_json "$rebase_applied"
  printf ',"pushed":'; bool_json "$pushed"
  printf ',"followup_filed":'; bool_json "$followup_filed"
  printf ',"followup_url":'; [[ -n $followup_url ]] && json_string "$followup_url" || printf null
  printf ',"planned_commands":'; json_array "${planned_commands[@]}"
  printf ',"executed_commands":'; json_array "${executed_commands[@]}"
  printf '}'
  printf '\n'
}

append_audit() {
  mkdir -p "$(dirname "$AUDIT_LOG")"
  emit_run_json >> "$AUDIT_LOG"
}

finish() {
  append_audit
  emit_run_json
  exit "$1"
}

normalize_repo() {
  [[ -n $repo ]] || { reason="repo-required"; finish 2; }
  if [[ ! -d $repo ]]; then
    repo=$(cd "$(dirname "$repo")" 2>/dev/null && pwd -P)/$(basename "$repo")
  else
    repo=$(cd "$repo" && pwd -P)
  fi
}

git_conflict_state() {
  local git_dir
  git_dir=$(git -C "$repo" rev-parse --git-dir)
  [[ $git_dir != /* ]] && git_dir="$repo/$git_dir"
  [[ -e "$git_dir/MERGE_HEAD" || -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]
}

count_ahead() {
  local ref=$1 counts
  if [[ -n $ref ]] && git -C "$repo" rev-parse --verify --quiet "$ref" >/dev/null; then
    counts=$(git -C "$repo" rev-list --left-right --count "HEAD...$ref")
    local_ahead=${counts%%[[:space:]]*}
    base_ahead=${counts##*[[:space:]]}
  else
    local_ahead=0
    base_ahead=0
  fi
}

run_git() {
  local label=$1 output
  shift
  if ! output=$("$@" 2>&1); then
    reason="$label failed: $output"
    outcome="error"
    finish 1
  fi
  executed_commands+=("$label")
  printf '%s' "$output"
}

repo=""
branch=""
base="main"
remote="origin"
mode=""
json=0
push=0
conflict_action="none"
command="run"
run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
outcome="dry-run"
reason=""
original_branch=""
base_ref=""
local_ahead=0
base_ahead=0
rebase_applied=0
pushed=0
followup_filed=0
followup_url=""
planned_commands=()
executed_commands=()

if [[ $# -gt 0 && $1 != --* ]]; then
  command=$1
  shift
fi

case "${command:-}" in
  --info) command="info" ;;
  --schema) command="schema" ;;
  --examples) command="examples" ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) command="info"; shift ;;
    --schema) command="schema"; shift ;;
    --examples) command="examples"; shift ;;
    --repo) repo=$2; shift 2 ;;
    --branch) branch=$2; shift 2 ;;
    --base) base=$2; shift 2 ;;
    --remote) remote=$2; shift 2 ;;
    --scope) positional=${positional:-}${positional:+$'\n'}$2; shift 2 ;;
    --dry-run) mode="dry-run"; shift ;;
    --apply) mode="apply"; shift ;;
    --push) push=1; shift ;;
    --conflict-action) conflict_action=$2; shift 2 ;;
    --json) json=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) positional=${positional:-}${positional:+$'\n'}$1; shift ;;
  esac
done
: "${json:=0}"

case "$command" in
  info)
    printf '{"schema_version":"%s","name":"review-branch-mergeback.sh","audit_log":' "$SCHEMA"
    json_string "$AUDIT_LOG"; printf ',"commands":["run","doctor","health","repair","validate","audit","why","quickstart"]}\n'
    exit 0
    ;;
  schema)
    printf '{"schema_version":"%s","required":["repo","branch","mode","outcome"],"outcomes":["dry-run","rebased","conflict","skipped","error"],"mutation_modes":["dry-run","apply"]}\n' "$SCHEMA"
    exit 0
    ;;
  examples|quickstart)
    cat <<'EXAMPLES'
review-branch-mergeback.sh run --repo /Users/josh/Developer/flywheel --branch review/flywheel-2.0-private-20260513 --dry-run --json
review-branch-mergeback.sh run --repo /Users/josh/Developer/flywheel --branch review/flywheel-2.0-private-20260513 --apply --push --conflict-action issue --json
review-branch-mergeback.sh doctor --repo /Users/josh/Developer/flywheel --branch review/flywheel-2.0-private-20260513 --json
EXAMPLES
    exit 0
    ;;
  health)
    if [[ -s $AUDIT_LOG ]]; then
      last=$(tail -1 "$AUDIT_LOG")
      printf '{"schema_version":"%s","command":"health","status":"pass","audit_log":' "$SCHEMA"
      json_string "$AUDIT_LOG"; printf ',"last_run":%s}\n' "$last"
    else
      printf '{"schema_version":"%s","command":"health","status":"warn","reason":"audit_log_missing","audit_log":' "$SCHEMA"
      json_string "$AUDIT_LOG"; printf '}\n'
    fi
    exit 0
    ;;
  audit)
    printf '{"schema_version":"%s","command":"audit","audit_log":' "$SCHEMA"
    json_string "$AUDIT_LOG"
    if [[ -s $AUDIT_LOG ]]; then printf ',"status":"pass","recent":['; tail -5 "$AUDIT_LOG" | paste -sd, -; printf ']}\n'; else printf ',"status":"missing","recent":[]}\n'; fi
    exit 0
    ;;
  why)
    id=${positional:-}
    [[ -n $id ]] || { usage; exit 2; }
    if [[ -s $AUDIT_LOG ]] && grep -F "\"run_id\":\"$id\"" "$AUDIT_LOG" >/dev/null; then
      printf '{"schema_version":"%s","command":"why","status":"pass","run":%s}\n' "$SCHEMA" "$(grep -F "\"run_id\":\"$id\"" "$AUDIT_LOG" | tail -1)"
    else
      printf '{"schema_version":"%s","command":"why","status":"missing","run_id":' "$SCHEMA"; json_string "$id"; printf '}\n'
    fi
    exit 0
    ;;
  repair)
    scope=${positional:-}
    [[ $scope == "state-dir" && -n $mode ]] || { usage; exit 2; }
    if [[ $mode == "dry-run" ]]; then
      printf '{"schema_version":"%s","command":"repair","mode":"dry-run","status":"ok","planned_actions":["mkdir-state-dir"],"actual_actions":[]}\n' "$SCHEMA"
    else
      mkdir -p "$STATE_DIR"
      printf '{"schema_version":"%s","command":"repair","mode":"apply","status":"ok","actual_actions":["mkdir-state-dir"],"state_dir":' "$SCHEMA"; json_string "$STATE_DIR"; printf '}\n'
    fi
    exit 0
    ;;
  validate)
    subject=${positional%%$'\n'*}
    value=${positional#*$'\n'}
    [[ -n $subject && -n $value ]] || { usage; exit 2; }
    status="reject"; reason="unsupported-subject"
    case "$subject" in
      repo) [[ -d $value/.git || -d $value ]] && status="ok" reason="" || reason="repo-missing" ;;
      branch) [[ $value =~ ^[A-Za-z0-9._/-]+$ ]] && status="ok" reason="" || reason="invalid-branch-name" ;;
      clean-tree) [[ -z $(git -C "$value" status --porcelain=v1 2>/dev/null || true) ]] && status="ok" reason="" || reason="dirty-tree" ;;
    esac
    printf '{"schema_version":"%s","command":"validate","subject":' "$SCHEMA"; json_string "$subject"; printf ',"value":'; json_string "$value"; printf ',"status":"%s","reason":' "$status"; [[ -n $reason ]] && json_string "$reason" || printf null; printf '}\n'
    [[ $status == ok ]]
    exit
    ;;
  doctor)
    normalize_repo
    status="pass"; checks=()
    if command -v git >/dev/null 2>&1; then
      checks+=('{"name":"git_available","status":"pass"}')
    else
      checks+=('{"name":"git_available","status":"fail"}')
      status="fail"
    fi
    if git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      checks+=('{"name":"repo_is_git","status":"pass"}')
    else
      checks+=('{"name":"repo_is_git","status":"fail"}')
      status="fail"
    fi
    if [[ -n $branch ]] && git -C "$repo" rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then checks+=('{"name":"branch_local","status":"pass"}'); elif [[ -n $branch ]]; then checks+=('{"name":"branch_local","status":"warn"}'); fi
    printf '{"schema_version":"%s","command":"doctor","status":"%s","checks":[%s]}\n' "$SCHEMA" "$status" "$(IFS=,; printf '%s' "${checks[*]}")"
    [[ $status != fail ]]
    exit
    ;;
  run) ;;
  *) usage; exit 2 ;;
esac

[[ -n $mode && -n $branch ]] || { usage; exit 2; }
[[ $conflict_action == "none" || $conflict_action == "issue" ]] || { usage; exit 2; }
normalize_repo

if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  outcome="error"; reason="not-a-git-worktree"; finish 1
fi

if git_conflict_state; then
  outcome="skipped"; reason="conflict-recovery-in-progress"; finish 0
fi

if [[ -n $(git -C "$repo" status --porcelain=v1) ]]; then
  outcome="skipped"; reason="dirty-tree"; finish 0
fi

original_branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD || true)
if [[ -z $original_branch ]]; then
  outcome="skipped"; reason="detached-head"; finish 0
fi

if git -C "$repo" rev-parse --verify --quiet "$remote/$base" >/dev/null; then
  base_ref="$remote/$base"
else
  base_ref="$base"
fi

planned_commands=("git fetch $remote --prune" "git switch $branch" "git rebase $base_ref")
[[ $push -eq 1 ]] && planned_commands+=("git push --force-with-lease $remote $branch")
count_ahead "$base_ref"

if [[ $mode == "dry-run" ]]; then
  outcome="dry-run"; reason="mergeback-planned"; finish 0
fi

run_git "git fetch $remote --prune" git -C "$repo" fetch "$remote" --prune >/dev/null
if ! git -C "$repo" rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
  if git -C "$repo" rev-parse --verify --quiet "$remote/$branch" >/dev/null; then
    run_git "git switch -c $branch --track $remote/$branch" git -C "$repo" switch -c "$branch" --track "$remote/$branch" >/dev/null
  else
    outcome="skipped"; reason="branch-missing"; finish 0
  fi
else
  run_git "git switch $branch" git -C "$repo" switch "$branch" >/dev/null
fi

set +e
rebase_output=$(git -C "$repo" rebase "$base_ref" 2>&1)
rebase_rc=$?
set -e
executed_commands+=("git rebase $base_ref")
if [[ $rebase_rc -ne 0 ]]; then
  git -C "$repo" rebase --abort >/dev/null 2>&1 || true
  [[ $original_branch != "$branch" ]] && git -C "$repo" switch "$original_branch" >/dev/null 2>&1 || true
  outcome="conflict"
  reason="rebase-conflict"
  if [[ $conflict_action == "issue" ]] && command -v gh >/dev/null 2>&1; then
    issue_body=$(printf "Daily merge-back failed while rebasing \`%s\` on \`%s\` in \`%s\`.\n\n\`\`\`text\n%s\n\`\`\`\n\nOpen a follow-up PR that resolves the conflict in a short-lived branch, then rerun this cadence." "$branch" "$base_ref" "$repo" "$rebase_output")
    if followup_url=$(cd "$repo" && gh issue create --title "Resolve merge-back conflict: $branch onto $base" --body "$issue_body" 2>/dev/null); then
      followup_filed=1
    fi
  fi
  finish 0
fi

rebase_applied=1
if [[ $push -eq 1 ]]; then
  run_git "git push --force-with-lease $remote $branch" git -C "$repo" push --force-with-lease "$remote" "$branch" >/dev/null
  pushed=1
fi
count_ahead "$base_ref"
[[ $original_branch != "$branch" ]] && run_git "git switch $original_branch" git -C "$repo" switch "$original_branch" >/dev/null
outcome="rebased"
reason="mergeback-complete"
finish 0
