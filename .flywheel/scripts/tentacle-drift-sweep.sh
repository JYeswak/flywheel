#!/usr/bin/env bash
set -euo pipefail

VERSION="tentacle-drift-sweep.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
STATE_DIR="${FLYWHEEL_STATE_DIR:-$HOME/.local/state/flywheel}"
REPOS_JSONL="${TENTACLE_DRIFT_REPOS_JSONL:-$HOME/.local/state/jeff-intel/repos.jsonl}"
LEDGER="${TENTACLE_DRIFT_LEDGER:-$STATE_DIR/tentacle-drift.jsonl}"
ALERT_LEDGER="${TENTACLE_DRIFT_ALERT_LEDGER:-$STATE_DIR/tentacle-drift-alerts.jsonl}"
WARN_THRESHOLD="${TENTACLE_DRIFT_WARN_THRESHOLD:-50}"
FAIL_THRESHOLD="${TENTACLE_DRIFT_FAIL_THRESHOLD:-200}"
NOW="${TENTACLE_DRIFT_NOW:-}"
MODE="sweep"
JSON_OUT=0
DRY_RUN=1

usage() {
  cat <<'USAGE'
Usage:
  tentacle-drift-sweep.sh [--dry-run|--apply] [--json]
  tentacle-drift-sweep.sh --doctor [--json]
  tentacle-drift-sweep.sh --info [--json]
  tentacle-drift-sweep.sh --schema [--json]
  tentacle-drift-sweep.sh --examples

Options:
  --repos-jsonl PATH       Repo inventory. Default: ~/.local/state/jeff-intel/repos.jsonl.
  --ledger PATH            Append-only sweep ledger. Default: ~/.local/state/flywheel/tentacle-drift.jsonl.
  --alert-ledger PATH      Append-only alert ledger. Default: ~/.local/state/flywheel/tentacle-drift-alerts.jsonl.
  --warn-threshold N       Warn when commits_behind >= N. Default: 50.
  --fail-threshold N       Fail when commits_behind >= N. Default: 200.
  --now ISO                Deterministic timestamp for tests.

Exit codes:
  0 success, including drift warnings
  1 doctor or sweep failure
  2 usage error
USAGE
}

now_iso() {
  if [[ -n "$NOW" ]]; then printf '%s\n' "$NOW"; else date -u +%Y-%m-%dT%H:%M:%SZ; fi
}

bool_json() {
  if [[ "$1" -eq 1 ]]; then printf true; else printf false; fi
}

emit() {
  local payload="$1"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -c . <<<"$payload"
  else
    jq -r '"tentacle-drift status=\(.status) repos=\(.repo_count // 0) alerts=\(.alert_count // 0) ledger=\(.ledger_path // "none")"' <<<"$payload"
  fi
}

schema_json() {
  jq -n \
    --arg version "$VERSION" \
    --arg repos_jsonl "$REPOS_JSONL" \
    --arg ledger "$LEDGER" \
    --arg alert_ledger "$ALERT_LEDGER" \
    --argjson warn_threshold "$WARN_THRESHOLD" \
    --argjson fail_threshold "$FAIL_THRESHOLD" \
    '{
      schema_version:"tentacle-drift-sweep/v1",
      version:$version,
      repo_inventory:$repos_jsonl,
      ledger_path:$ledger,
      alert_ledger_path:$alert_ledger,
      thresholds:{warn_commits:$warn_threshold,fail_commits:$fail_threshold},
      row_required_fields:["repo","local_head","upstream_head","commits_behind","status"],
      modes:["sweep","doctor","info","schema"],
      mutation_policy:"read_only_git; never fetches, pulls, checks out, or writes inside target repos",
      dry_run_supported:true
    }'
}

info_json() {
  schema_json | jq '. + {name:"tentacle-drift-sweep.sh",owner:"flywheel",default_mode:"dry-run"}'
}

examples() {
  cat <<'EXAMPLES'
tentacle-drift-sweep.sh --dry-run --json
tentacle-drift-sweep.sh --apply --json
tentacle-drift-sweep.sh --doctor --json
TENTACLE_DRIFT_REPOS_JSONL=/tmp/repos.jsonl tentacle-drift-sweep.sh --ledger /tmp/tentacle-drift.jsonl --apply --json
EXAMPLES
}

require_deps() {
  command -v jq >/dev/null || { printf 'ERR: jq missing\n' >&2; exit 1; }
  command -v git >/dev/null || { printf 'ERR: git missing\n' >&2; exit 1; }
}

repo_rows() {
  jq -rc '
    select((.path // "") != "")
    | {
        repo:(.name // .repo // (.path | split("/")[-1])),
        path:.path,
        index_status:(.index_status // null)
      }
  ' "$REPOS_JSONL"
}

resolve_upstream_ref() {
  local path="$1" ref
  if ref="$(git -C "$path" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
    printf '%s\n' "$ref"
    return 0
  fi
  if ref="$(git -C "$path" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)"; then
    printf '%s\n' "$ref"
    return 0
  fi
  return 1
}

scan_repo() {
  local repo="$1" path="$2" ts="$3" local_head="" upstream_ref="" upstream_head="" commits_behind="" status="ok" detail=""
  if [[ ! -d "$path" ]]; then
    status="missing"
    detail="path_missing"
  elif ! git -C "$path" rev-parse --git-dir >/dev/null 2>&1; then
    status="not_git"
    detail="not_git_repository"
  else
    local_head="$(git -C "$path" rev-parse HEAD 2>/dev/null || true)"
    if upstream_ref="$(resolve_upstream_ref "$path")"; then
      upstream_head="$(git -C "$path" rev-parse "$upstream_ref" 2>/dev/null || true)"
      if [[ -n "$local_head" && -n "$upstream_head" ]]; then
        commits_behind="$(git -C "$path" rev-list --count "HEAD..$upstream_ref" 2>/dev/null || printf '')"
        if [[ "$commits_behind" =~ ^[0-9]+$ ]]; then
          if (( commits_behind >= FAIL_THRESHOLD )); then
            status="fail"
            detail="commits_behind_fail_threshold"
          elif (( commits_behind >= WARN_THRESHOLD )); then
            status="warn"
            detail="commits_behind_warn_threshold"
          else
            status="ok"
            detail="within_threshold"
          fi
        else
          status="unknown"
          detail="behind_count_unavailable"
        fi
      else
        status="unknown"
        detail="head_unavailable"
      fi
    else
      status="unknown_upstream"
      detail="upstream_ref_unavailable"
    fi
  fi

  jq -nc \
    --arg schema_version "tentacle-drift-row/v1" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg repo "$repo" \
    --arg path "$path" \
    --arg local_head "$local_head" \
    --arg upstream_ref "$upstream_ref" \
    --arg upstream_head "$upstream_head" \
    --arg status "$status" \
    --arg detail "$detail" \
    --argjson commits_behind "$(if [[ "$commits_behind" =~ ^[0-9]+$ ]]; then printf '%s' "$commits_behind"; else printf 'null'; fi)" \
    --argjson warn_threshold "$WARN_THRESHOLD" \
    --argjson fail_threshold "$FAIL_THRESHOLD" \
    '{schema_version:$schema_version,version:$version,ts:$ts,repo:$repo,path:$path,local_head:$local_head,upstream_ref:$upstream_ref,upstream_head:$upstream_head,commits_behind:$commits_behind,status:$status,detail:$detail,thresholds:{warn_commits:$warn_threshold,fail_commits:$fail_threshold}}'
}

run_doctor() {
  require_deps
  local repo_count=0 status="pass" warnings='[]' errors='[]'
  if [[ ! -s "$REPOS_JSONL" ]]; then
    status="fail"
    errors="$(jq -nc --arg path "$REPOS_JSONL" '[{code:"repos_jsonl_missing",path:$path}]')"
  else
    repo_count="$(jq -s 'length' "$REPOS_JSONL")"
  fi
  local payload
  payload="$(schema_json | jq \
    --arg status "$status" \
    --argjson repo_count "$repo_count" \
    --argjson warnings "$warnings" \
    --argjson errors "$errors" \
    '. + {mode:"doctor",status:$status,repo_count:$repo_count,warnings:$warnings,errors:$errors}')"
  emit "$payload"
  [[ "$status" == "pass" ]]
}

run_sweep() {
  require_deps
  if [[ ! -s "$REPOS_JSONL" ]]; then
    emit "$(jq -n --arg status "fail" --arg path "$REPOS_JSONL" '{schema_version:"tentacle-drift-sweep/v1",status:$status,error:{code:"repos_jsonl_missing",path:$path}}')"
    return 1
  fi

  local ts tmp rows alerts summary status
  ts="$(now_iso)"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/tentacle-drift.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  rows="$tmp/rows.jsonl"
  alerts="$tmp/alerts.jsonl"
  : >"$rows"
  : >"$alerts"

  while IFS= read -r row; do
    local repo path scanned row_status
    repo="$(jq -r '.repo' <<<"$row")"
    path="$(jq -r '.path' <<<"$row")"
    scanned="$(scan_repo "$repo" "$path" "$ts")"
    printf '%s\n' "$scanned" >>"$rows"
    row_status="$(jq -r '.status' <<<"$scanned")"
    if [[ "$row_status" != "ok" ]]; then
      printf '%s\n' "$scanned" >>"$alerts"
    fi
  done < <(repo_rows)

  local repo_count alert_count warn_count fail_count missing_count unknown_count max_behind
  repo_count="$(jq -s 'length' "$rows")"
  alert_count="$(jq -s 'length' "$alerts")"
  warn_count="$(jq -s '[.[] | select(.status == "warn")] | length' "$rows")"
  fail_count="$(jq -s '[.[] | select(.status == "fail")] | length' "$rows")"
  missing_count="$(jq -s '[.[] | select(.status == "missing" or .status == "not_git")] | length' "$rows")"
  unknown_count="$(jq -s '[.[] | select(.status == "unknown" or .status == "unknown_upstream")] | length' "$rows")"
  max_behind="$(jq -s 'map(.commits_behind // 0) | max // 0' "$rows")"

  if (( fail_count > 0 || missing_count > 0 || unknown_count > 0 )); then
    status="warn"
  elif (( warn_count > 0 )); then
    status="warn"
  else
    status="pass"
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    mkdir -p "$(dirname "$LEDGER")" "$(dirname "$ALERT_LEDGER")"
    cat "$rows" >>"$LEDGER"
    if [[ -s "$alerts" ]]; then
      cat "$alerts" >>"$ALERT_LEDGER"
    fi
  fi

  summary="$(jq -n \
    --arg schema_version "tentacle-drift-sweep/v1" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg status "$status" \
    --arg ledger "$LEDGER" \
    --arg alert_ledger "$ALERT_LEDGER" \
    --argjson dry_run "$(bool_json "$DRY_RUN")" \
    --argjson repo_count "$repo_count" \
    --argjson alert_count "$alert_count" \
    --argjson warn_count "$warn_count" \
    --argjson fail_count "$fail_count" \
    --argjson missing_count "$missing_count" \
    --argjson unknown_count "$unknown_count" \
    --argjson max_behind "$max_behind" \
    --slurpfile rows "$rows" \
    '{schema_version:$schema_version,version:$version,ts:$ts,mode:"sweep",status:$status,dry_run:$dry_run,repo_count:$repo_count,alert_count:$alert_count,warn_count:$warn_count,fail_count:$fail_count,missing_count:$missing_count,unknown_count:$unknown_count,max_commits_behind:$max_behind,ledger_path:$ledger,alert_ledger_path:$alert_ledger,rows:$rows}')"
  emit "$summary"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="${2:-}"; [[ -n "$MODE" ]] || { printf 'ERR: --mode requires value\n' >&2; exit 2; }; shift 2 ;;
    --doctor|doctor) MODE="doctor"; shift ;;
    --info|info) MODE="info"; shift ;;
    --schema|schema) MODE="schema"; shift ;;
    --examples|examples) examples; exit 0 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) DRY_RUN=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --repos-jsonl) REPOS_JSONL="${2:-}"; [[ -n "$REPOS_JSONL" ]] || { printf 'ERR: --repos-jsonl requires PATH\n' >&2; exit 2; }; shift 2 ;;
    --ledger) LEDGER="${2:-}"; [[ -n "$LEDGER" ]] || { printf 'ERR: --ledger requires PATH\n' >&2; exit 2; }; shift 2 ;;
    --alert-ledger) ALERT_LEDGER="${2:-}"; [[ -n "$ALERT_LEDGER" ]] || { printf 'ERR: --alert-ledger requires PATH\n' >&2; exit 2; }; shift 2 ;;
    --warn-threshold) WARN_THRESHOLD="${2:-}"; shift 2 ;;
    --fail-threshold) FAIL_THRESHOLD="${2:-}"; shift 2 ;;
    --now) NOW="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

case "$MODE" in
  sweep) run_sweep ;;
  doctor) run_doctor ;;
  info) info_json ;;
  schema) schema_json ;;
  *) printf 'ERR: unknown mode: %s\n' "$MODE" >&2; exit 2 ;;
esac
