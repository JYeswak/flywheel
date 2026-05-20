#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="flywheel.auto_push.v0_1"
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
POLICY_PATH="${FLYWHEEL_AUTO_PUSH_POLICY_PATH:-$REPO/.flywheel/auto-push-policy.yaml}"
DEFAULT_LEDGER="$REPO/.flywheel/runtime/auto-push-ledger.jsonl"
GITGUARDIAN_GATE="${FLYWHEEL_AUTO_PUSH_GITGUARDIAN_GATE:-$REPO/.flywheel/scripts/gitguardian-pre-push-gate.sh}"
SUPABASE_MIRROR_GATE="${FLYWHEEL_AUTO_PUSH_SUPABASE_MIRROR_GATE:-$REPO/.flywheel/scripts/supabase-prepush-mirror-gate.sh}"
ACT_BIN="${FLYWHEEL_AUTO_PUSH_ACT_BIN:-act}"
GIT_BIN="${FLYWHEEL_AUTO_PUSH_GIT_BIN:-git}"
REMOTE="${FLYWHEEL_AUTO_PUSH_REMOTE:-origin}"
SOURCE="manual"
DRY_RUN=0
JSON_OUT=0
SINCE=""

ENABLED="true"
UPSTREAM_REQUIRED="true"
LOCAL_CI_GATE="true"
GITGUARDIAN_GATE_ENABLED="true"
SUPABASE_MIRROR_GATE_ENABLED="true"
POST_COMMIT_FIRE="true"
PUSH_CADENCE="post-commit"
ALLOWED_BRANCHES_REGEX=""
FORBIDDEN_BRANCHES_REGEX=""
LEDGER_PATH="$DEFAULT_LEDGER"
ON_FAILURE="block_next_commit"
AUTO_SWEEP_ON_DIRTY_TREE="false"
AUTO_SWEEP_COMMIT_MESSAGE="chore(state): auto-sweep accreting substrate paths [auto-push]"
AUTO_SWEEP_PLANNED="false"
AUTO_SWEPT="false"
SWEEP_COMMIT_SHA=""
PRIVATE_BLOCKLIST=()
KNOWN_DIRTY_PATHS_ALLOW_LIST=()
CURRENT_DIRTY_PATHS=()
ALLOWED_DIRTY_PATHS=()
BLOCKING_DIRTY_PATHS=()
SWEPT_PATHS=()
NON_SWEPT_PATHS=()

usage() {
  cat <<'USAGE'
Usage: auto-push.sh [--json] [--dry-run] [--source NAME] [--since DURATION]

Dogfood adoption of the SkillOS auto-push v0.1 substrate for flywheel:
clean-tree gate, branch policy, local act CI, Tier 4.5 gates, then push.
USAGE
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

strip_quotes() {
  local value="$1"
  if [[ "$value" == \"*\" && "$value" == *\" ]]; then
    value="${value#\"}"
    value="${value%\"}"
  elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
    value="${value#\'}"
    value="${value%\'}"
  fi
  printf '%s' "$value"
}

load_policy() {
  [[ -f "$POLICY_PATH" ]] || return 0
    local line key value in_blocklist=0 in_allowlist=0 item
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    [[ -n "$(trim "$line")" ]] || continue
    if [[ "$line" =~ ^[[:space:]]*private_paths_blocklist[[:space:]]*:[[:space:]]*$ ]]; then
      in_blocklist=1
      in_allowlist=0
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]*known_dirty_paths_allow_list[[:space:]]*:[[:space:]]*$ ]]; then
      in_blocklist=0
      in_allowlist=1
      continue
    fi
    if [[ "$in_blocklist" -eq 1 && "$line" =~ ^[[:space:]]*-[[:space:]]*(.*)$ ]]; then
      item="$(strip_quotes "$(trim "${BASH_REMATCH[1]}")")"
      [[ -n "$item" ]] && PRIVATE_BLOCKLIST+=("$item")
      continue
    fi
    if [[ "$in_allowlist" -eq 1 && "$line" =~ ^[[:space:]]*-[[:space:]]*(.*)$ ]]; then
      item="$(strip_quotes "$(trim "${BASH_REMATCH[1]}")")"
      [[ -n "$item" ]] && KNOWN_DIRTY_PATHS_ALLOW_LIST+=("$item")
      continue
    fi
    in_blocklist=0
    in_allowlist=0
    [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$ ]] || continue
    key="${BASH_REMATCH[1]//-/_}"
    value="$(strip_quotes "$(trim "${BASH_REMATCH[2]}")")"
    case "$key" in
      enabled) ENABLED="$value" ;;
      upstream_required) UPSTREAM_REQUIRED="$value" ;;
      local_ci_gate) LOCAL_CI_GATE="$value" ;;
      gitguardian_gate) GITGUARDIAN_GATE_ENABLED="$value" ;;
      supabase_mirror_gate|supabase_rls_gate) SUPABASE_MIRROR_GATE_ENABLED="$value" ;;
      post_commit_fire) POST_COMMIT_FIRE="$value" ;;
      push_cadence) PUSH_CADENCE="$value" ;;
      allowed_branches_regex) ALLOWED_BRANCHES_REGEX="$value" ;;
      forbidden_branches_regex) FORBIDDEN_BRANCHES_REGEX="$value" ;;
      ledger_path) LEDGER_PATH="$value" ;;
      on_failure) ON_FAILURE="$value" ;;
      auto_sweep_on_dirty_tree) AUTO_SWEEP_ON_DIRTY_TREE="$value" ;;
      auto_sweep_commit_message) [[ -n "$value" ]] && AUTO_SWEEP_COMMIT_MESSAGE="$value" ;;
    esac
  done <"$POLICY_PATH"
  [[ "$LEDGER_PATH" = /* ]] || LEDGER_PATH="$REPO/$LEDGER_PATH"
}

iso_now() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

current_commit() { "$GIT_BIN" -C "$REPO" rev-parse HEAD 2>/dev/null || printf 'unknown'; }

current_branch() {
  "$GIT_BIN" -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown'
}

json_bool() {
  [[ "$1" == "true" ]] && printf 'true' || printf 'false'
}

upstream_ref() {
  "$GIT_BIN" -C "$REPO" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true
}

append_ledger() {
  local status="$1" reason="$2" exit_code="$3" push_attempted="$4" push_success="$5" local_ci="$6" gitguardian="$7" supabase_mirror="$8"
  mkdir -p "$(dirname "$LEDGER_PATH")"
  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg ts "$(iso_now)" \
    --arg source "$SOURCE" \
    --arg repo "$REPO" \
    --arg commit "$(current_commit)" \
    --arg branch "$(current_branch)" \
    --arg upstream "$(upstream_ref)" \
    --arg status "$status" \
    --arg reason "$reason" \
    --arg local_ci_status "$local_ci" \
    --arg gitguardian_status "$gitguardian" \
    --arg supabase_mirror_status "$supabase_mirror" \
    --arg push_cadence "$PUSH_CADENCE" \
    --arg on_failure "$ON_FAILURE" \
    --arg since "$SINCE" \
    --arg sweep_commit_sha "$SWEEP_COMMIT_SHA" \
    --argjson dirty_paths "$(printf '%s\n' "${CURRENT_DIRTY_PATHS[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
    --argjson dirty_allow_list "$(printf '%s\n' "${KNOWN_DIRTY_PATHS_ALLOW_LIST[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
    --argjson dirty_allowed_paths "$(printf '%s\n' "${ALLOWED_DIRTY_PATHS[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
    --argjson dirty_blocking_paths "$(printf '%s\n' "${BLOCKING_DIRTY_PATHS[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
    --argjson auto_sweep_on_dirty_tree "$(json_bool "$AUTO_SWEEP_ON_DIRTY_TREE")" \
    --argjson auto_sweep_planned "$(json_bool "$AUTO_SWEEP_PLANNED")" \
    --argjson auto_swept "$(json_bool "$AUTO_SWEPT")" \
    --argjson swept_paths "$(printf '%s\n' "${SWEPT_PATHS[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
    --argjson non_swept_paths "$(printf '%s\n' "${NON_SWEPT_PATHS[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
    --argjson exit_code "$exit_code" \
    --argjson dry_run "$DRY_RUN" \
    --argjson push_attempted "$push_attempted" \
    --argjson push_success "$push_success" \
    '{schema_version:$schema,ts:$ts,source:$source,repo:$repo,commit:$commit,branch:$branch,upstream:$upstream,status:$status,reason:$reason,exit_code:$exit_code,dry_run:$dry_run,push_attempted:$push_attempted,push_success:$push_success,local_ci_status:$local_ci_status,gitguardian_status:$gitguardian_status,supabase_mirror_status:$supabase_mirror_status,push_cadence:$push_cadence,on_failure:$on_failure,since:$since,dirty_paths:$dirty_paths,known_dirty_paths_allow_list:$dirty_allow_list,dirty_allowed_paths:$dirty_allowed_paths,dirty_blocking_paths:$dirty_blocking_paths,auto_sweep_on_dirty_tree:$auto_sweep_on_dirty_tree,auto_sweep_planned:$auto_sweep_planned,auto_swept:$auto_swept,swept_paths:$swept_paths,non_swept_paths:$non_swept_paths,sweep_commit_sha:($sweep_commit_sha | if length > 0 then . else null end)}' >>"$LEDGER_PATH"
}

emit() {
  local status="$1" reason="$2" exit_code="$3" push_attempted="$4" push_success="$5" local_ci="$6" gitguardian="$7" supabase_mirror="$8"
  append_ledger "$status" "$reason" "$exit_code" "$push_attempted" "$push_success" "$local_ci" "$gitguardian" "$supabase_mirror"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    tail -1 "$LEDGER_PATH"
  else
    printf 'auto-push status=%s reason=%s push_attempted=%s\n' "$status" "$reason" "$push_attempted"
  fi
  exit "$exit_code"
}

run_local_ci_gate() {
  [[ "$LOCAL_CI_GATE" == "true" ]] || { printf 'skipped'; return 0; }
  if ! command -v "$ACT_BIN" >/dev/null 2>&1; then
    printf 'act_missing'
    return 20
  fi
  if [[ ! -f "$REPO/.github/workflows/ci.yml" ]]; then
    printf 'ci_workflow_missing'
    return 21
  fi
  if "$ACT_BIN" -W "$REPO/.github/workflows/ci.yml" --container-daemon-socket /var/run/docker.sock >/dev/null 2>&1; then
    printf 'pass'
    return 0
  fi
  printf 'failed'
  return 22
}

run_gitguardian_gate() {
  [[ "$GITGUARDIAN_GATE_ENABLED" == "true" ]] || { printf 'skipped'; return 0; }
  if [[ ! -x "$GITGUARDIAN_GATE" ]]; then
    printf 'gate_missing'
    return 30
  fi
  if "$GITGUARDIAN_GATE" --json --repo "$REPO" --mode commit-range >/dev/null; then
    printf 'pass'
    return 0
  fi
  printf 'blocked'
  return 31
}

outgoing_range() {
  local upstream base
  upstream="$(upstream_ref)"
  [[ -n "$upstream" ]] || return 1
  base="$("$GIT_BIN" -C "$REPO" merge-base HEAD "$upstream" 2>/dev/null || true)"
  [[ -n "$base" ]] || return 1
  printf '%s..HEAD\n' "$base"
}

run_supabase_mirror_gate() {
  [[ "$SUPABASE_MIRROR_GATE_ENABLED" == "true" ]] || { printf 'skipped'; return 0; }
  if [[ ! -x "$SUPABASE_MIRROR_GATE" ]]; then
    printf 'gate_missing'
    return 32
  fi
  local range
  range="$(outgoing_range)" || { printf 'range_missing'; return 33; }
  if "$SUPABASE_MIRROR_GATE" --json --repo "$REPO" --commit-range "$range" >/dev/null; then
    printf 'pass'
    return 0
  fi
  printf 'blocked'
  return 34
}

glob_to_regex() {
  local glob="$1"
  glob="${glob//./\\.}"
  glob="${glob//\*\*/.*}"
  glob="${glob//\*/[^/]*}"
  printf '^%s$' "$glob"
}

dirty_path_allowed() {
  [[ "${#KNOWN_DIRTY_PATHS_ALLOW_LIST[@]}" -gt 0 ]] || return 1
  local path="$1" pattern regex
  for pattern in "${KNOWN_DIRTY_PATHS_ALLOW_LIST[@]}"; do
    regex="$(glob_to_regex "$pattern")"
    [[ "$path" =~ $regex ]] && return 0
  done
  return 1
}

classify_dirty_paths() {
  local status_out="$1" path
  CURRENT_DIRTY_PATHS=()
  ALLOWED_DIRTY_PATHS=()
  BLOCKING_DIRTY_PATHS=()
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    CURRENT_DIRTY_PATHS+=("$path")
    if dirty_path_allowed "$path"; then
      ALLOWED_DIRTY_PATHS+=("$path")
    else
      BLOCKING_DIRTY_PATHS+=("$path")
    fi
  done < <(printf '%s\n' "$status_out" | sed -E 's/^.. //' | sed -E 's/^.* -> //')
}

prepare_auto_sweep_paths() {
  SWEPT_PATHS=("${ALLOWED_DIRTY_PATHS[@]}")
  NON_SWEPT_PATHS=("${BLOCKING_DIRTY_PATHS[@]}")
}

auto_sweep_dirty_paths() {
  [[ "${#SWEPT_PATHS[@]}" -gt 0 ]] || return 1
  AUTO_SWEEP_PLANNED="true"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  "$GIT_BIN" -C "$REPO" add -- "${SWEPT_PATHS[@]}"
  if "$GIT_BIN" -C "$REPO" diff --cached --quiet -- "${SWEPT_PATHS[@]}"; then
    return 1
  fi
  "$GIT_BIN" -C "$REPO" -c core.hooksPath=/dev/null commit -m "$AUTO_SWEEP_COMMIT_MESSAGE" >/dev/null
  SWEEP_COMMIT_SHA="$(current_commit)"
  AUTO_SWEPT="true"
}

private_path_blocked() {
  [[ "${#PRIVATE_BLOCKLIST[@]}" -gt 0 ]] || return 1
  local range path pattern regex
  range="$(upstream_ref)"
  [[ -n "$range" ]] || return 1
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    for pattern in "${PRIVATE_BLOCKLIST[@]}"; do
      regex="$(glob_to_regex "$pattern")"
      [[ "$path" =~ $regex ]] && return 0
    done
  done < <("$GIT_BIN" -C "$REPO" diff --name-only "$range"..HEAD 2>/dev/null || true)
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --source) SOURCE="${2:-}"; shift 2 ;;
    --source=*) SOURCE="${1#--source=}"; shift ;;
    --since) SINCE="${2:-}"; shift 2 ;;
    --since=*) SINCE="${1#--since=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) shift ;;
  esac
done

load_policy

[[ "$ENABLED" == "true" ]] || emit clean policy_disabled 0 false false skipped skipped skipped
[[ "$SOURCE" != "post-commit" || "$POST_COMMIT_FIRE" == "true" ]] || emit clean post_commit_disabled 0 false false skipped skipped skipped

unmerged="$("$GIT_BIN" -C "$REPO" ls-files -u 2>&1)"
[[ -z "$unmerged" ]] || emit blocked unmerged_paths 10 false false skipped skipped skipped
[[ ! -f "$REPO/.git/MERGE_HEAD" && ! -d "$REPO/.git/rebase-merge" && ! -d "$REPO/.git/rebase-apply" ]] || emit blocked git_operation_in_progress 11 false false skipped skipped skipped
status_out="$("$GIT_BIN" -C "$REPO" status --porcelain -uall 2>&1)"
if [[ -n "$status_out" ]]; then
  classify_dirty_paths "$status_out"
  if [[ "${#BLOCKING_DIRTY_PATHS[@]}" -gt 0 ]]; then
    if [[ "$AUTO_SWEEP_ON_DIRTY_TREE" == "true" ]]; then
      prepare_auto_sweep_paths
      emit blocked non_allowlist_dirty 12 false false skipped skipped skipped
    fi
    emit blocked dirty_tree 12 false false skipped skipped skipped
  fi
  if [[ "$AUTO_SWEEP_ON_DIRTY_TREE" == "true" && "${#ALLOWED_DIRTY_PATHS[@]}" -gt 0 ]]; then
    prepare_auto_sweep_paths
    auto_sweep_dirty_paths || emit blocked auto_sweep_failed 18 false false skipped skipped skipped
  fi
fi

branch="$(current_branch)"
[[ "$branch" != "HEAD" && -n "$branch" ]] || emit blocked detached_head 13 false false skipped skipped skipped
if [[ "$UPSTREAM_REQUIRED" != "false" && -z "$(upstream_ref)" ]]; then
  emit blocked upstream_missing 14 false false skipped skipped skipped
fi
if [[ -n "$FORBIDDEN_BRANCHES_REGEX" && "$branch" =~ $FORBIDDEN_BRANCHES_REGEX ]]; then
  emit blocked forbidden_branch 15 false false skipped skipped skipped
fi
if [[ -n "$ALLOWED_BRANCHES_REGEX" && ! "$branch" =~ $ALLOWED_BRANCHES_REGEX ]]; then
  emit blocked branch_not_allowed 16 false false skipped skipped skipped
fi
if private_path_blocked; then
  emit blocked private_path_blocked 17 false false skipped skipped skipped
fi

local_ci_status="$(run_local_ci_gate)" || local_ci_rc=$?
local_ci_rc="${local_ci_rc:-0}"
[[ "$local_ci_rc" -eq 0 ]] || emit blocked "local_ci_${local_ci_status}" "$local_ci_rc" false false "$local_ci_status" skipped skipped

gitguardian_status="$(run_gitguardian_gate)" || gitguardian_rc=$?
gitguardian_rc="${gitguardian_rc:-0}"
[[ "$gitguardian_rc" -eq 0 ]] || emit blocked "gitguardian_${gitguardian_status}" "$gitguardian_rc" false false "$local_ci_status" "$gitguardian_status" skipped

supabase_mirror_status="$(run_supabase_mirror_gate)" || supabase_mirror_rc=$?
supabase_mirror_rc="${supabase_mirror_rc:-0}"
[[ "$supabase_mirror_rc" -eq 0 ]] || emit blocked "supabase_mirror_${supabase_mirror_status}" "$supabase_mirror_rc" false false "$local_ci_status" "$gitguardian_status" "$supabase_mirror_status"

if [[ "$DRY_RUN" -eq 1 ]]; then
  emit clean dry_run 0 false false "$local_ci_status" "$gitguardian_status" "$supabase_mirror_status"
fi

if "$GIT_BIN" -C "$REPO" push "$REMOTE" "$branch" >/dev/null 2>&1; then
  emit clean pushed 0 true true "$local_ci_status" "$gitguardian_status" "$supabase_mirror_status"
fi
emit blocked push_failed 40 true false "$local_ci_status" "$gitguardian_status" "$supabase_mirror_status"
