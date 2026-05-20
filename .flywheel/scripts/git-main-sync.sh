#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: git-main-sync.sh --repo PATH (--dry-run|--apply) [--rebase-feature] [--json]
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

json_string() {
  printf '"%s"' "$(json_escape "${1-}")"
}

json_string_array() {
  local first=1
  printf '['
  for item in "$@"; do
    if [[ $first -eq 0 ]]; then
      printf ','
    fi
    first=0
    json_string "$item"
  done
  printf ']'
}

bool_json() {
  if [[ ${1:-0} -eq 1 ]]; then
    printf 'true'
  else
    printf 'false'
  fi
}

emit_json() {
  printf '{'
  printf '"schema":"git_main_sync.v1"'
  printf ',"ts":'
  json_string "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf ',"repo":'
  json_string "$repo"
  printf ',"mode":'
  json_string "$mode"
  printf ',"outcome":'
  json_string "$outcome"
  printf ',"reason":'
  json_string "$reason"
  printf ',"branch":'
  if [[ -n ${branch:-} ]]; then json_string "$branch"; else printf 'null'; fi
  printf ',"clean_tree":'
  bool_json "$clean_tree"
  printf ',"local_ahead":%s' "$local_ahead"
  printf ',"remote_ahead":%s' "$remote_ahead"
  printf ',"fetched_refs":%s' "$fetched_refs"
  printf ',"rebase_applied":'
  bool_json "$rebase_applied"
  printf ',"planned_commands":'
  json_string_array "${planned_commands[@]}"
  printf ',"executed_commands":'
  json_string_array "${executed_commands[@]}"
  printf '}'
  printf '\n'
}

fail_json() {
  outcome="error"
  reason=$1
  emit_json
  exit 1
}

count_ahead() {
  local remote_ref=$1
  local counts
  if [[ -n $remote_ref ]] && git -C "$repo" rev-parse --verify --quiet "$remote_ref" >/dev/null; then
    counts=$(git -C "$repo" rev-list --left-right --count "HEAD...$remote_ref")
    local_ahead=${counts%%[[:space:]]*}
    remote_ahead=${counts##*[[:space:]]}
  else
    local_ahead=0
    remote_ahead=0
  fi
}

run_git() {
  local label=$1
  shift
  local output
  if ! output=$("$@" 2>&1); then
    reason="$label failed: $output"
    fail_json "$reason"
  fi
  executed_commands+=("$label")
  printf '%s' "$output"
}

repo=""
mode=""
rebase_feature=0
json=0
branch=""
clean_tree=0
local_ahead=0
remote_ahead=0
fetched_refs=0
rebase_applied=0
outcome="dry-run"
reason=""
planned_commands=()
executed_commands=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      repo=$2
      shift 2
      ;;
    --dry-run)
      mode="dry-run"
      shift
      ;;
    --apply)
      mode="apply"
      shift
      ;;
    --rebase-feature)
      rebase_feature=1
      shift
      ;;
    --json)
      json=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z $repo || -z $mode ]]; then
  usage
  exit 2
fi

if [[ ! -d $repo ]]; then
  repo=$(cd "$(dirname "$repo")" 2>/dev/null && pwd -P)/$(basename "$repo")
else
  repo=$(cd "$repo" && pwd -P)
fi

if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  reason="not-a-git-worktree"
  fail_json "$reason"
fi

git_dir=$(git -C "$repo" rev-parse --git-dir)
if [[ $git_dir != /* ]]; then
  git_dir="$repo/$git_dir"
fi

status_porcelain=$(git -C "$repo" status --porcelain=v1)
if [[ -z $status_porcelain ]]; then
  clean_tree=1
fi

if [[ -e "$git_dir/MERGE_HEAD" || -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]; then
  outcome="skipped"
  reason="conflict-recovery-in-progress"
  emit_json
  exit 0
fi

if ! branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD); then
  outcome="skipped"
  reason="conflict-recovery-in-progress"
  emit_json
  exit 0
fi

case "$branch" in
  main|master)
    remote_ref="origin/$branch"
    planned_commands=("git fetch --all --prune" "git pull --rebase --autostash origin $branch")
    count_ahead "$remote_ref"
    if [[ $mode == "dry-run" ]]; then
      outcome="dry-run"
      reason="main-sync-planned"
      emit_json
      exit 0
    fi
    fetch_output=$(run_git "git fetch --all --prune" git -C "$repo" fetch --all --prune)
    fetched_refs=$(printf '%s\n' "$fetch_output" | grep -Ec '(\->|\[new|\[deleted|\[forced)' || true)
    run_git "git pull --rebase --autostash origin $branch" git -C "$repo" -c rebase.autoStash=true pull --rebase --autostash origin "$branch" >/dev/null
    rebase_applied=1
    count_ahead "$remote_ref"
    outcome="synced"
    reason="main-synced"
    ;;
  review/*|arc/*|feat/*)
    planned_commands=("git fetch --all --prune")
    remote_ref="origin/$branch"
    if [[ $rebase_feature -eq 1 ]]; then
      if git -C "$repo" rev-parse --verify --quiet origin/main >/dev/null; then
        remote_ref="origin/main"
      elif git -C "$repo" rev-parse --verify --quiet origin/master >/dev/null; then
        remote_ref="origin/master"
      else
        remote_ref=""
      fi
      planned_commands+=("git rebase ${remote_ref:-origin/main}")
    fi
    count_ahead "$remote_ref"
    if [[ $mode == "dry-run" ]]; then
      outcome="dry-run"
      reason="feature-fetch-planned"
      emit_json
      exit 0
    fi
    fetch_output=$(run_git "git fetch --all --prune" git -C "$repo" fetch --all --prune)
    fetched_refs=$(printf '%s\n' "$fetch_output" | grep -Ec '(\->|\[new|\[deleted|\[forced)' || true)
    if [[ $rebase_feature -eq 1 ]]; then
      if [[ -z $remote_ref ]]; then
        reason="feature-rebase-target-missing"
        fail_json "$reason"
      fi
      run_git "git rebase $remote_ref" git -C "$repo" -c rebase.autoStash=true rebase "$remote_ref" >/dev/null
      rebase_applied=1
      count_ahead "$remote_ref"
      outcome="rebased"
      reason="feature-rebased"
    else
      count_ahead "$remote_ref"
      outcome="fetched"
      reason="feature-branch-fetch-only"
    fi
    ;;
  *)
    planned_commands=("git fetch --all --prune")
    count_ahead "origin/$branch"
    if [[ $mode == "dry-run" ]]; then
      outcome="dry-run"
      reason="non-main-fetch-planned"
      emit_json
      exit 0
    fi
    fetch_output=$(run_git "git fetch --all --prune" git -C "$repo" fetch --all --prune)
    fetched_refs=$(printf '%s\n' "$fetch_output" | grep -Ec '(\->|\[new|\[deleted|\[forced)' || true)
    count_ahead "origin/$branch"
    outcome="fetched"
    reason="non-main-fetch-only"
    ;;
esac

if [[ $json -eq 1 ]]; then
  emit_json
else
  emit_json
fi
