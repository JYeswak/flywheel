#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

SCHEMA_VERSION="gitguardian-pre-push-gate/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DEFAULT_LEDGER="$ROOT/.flywheel/runtime/secret-leak-detected.jsonl"
DEFAULT_SECRET_LOADER="${GITGUARDIAN_SECRET_LOADER:-cf-secret}"
DEFAULT_INFISICAL_STATUS="${INFISICAL_LOAD_BIN:-infisical-load}"
DEFAULT_GGSHIELD="${GGSHIELD_BIN:-ggshield}"

if [[ "$DEFAULT_SECRET_LOADER" == "cf-secret" && -x "$HOME/.local/bin/cf-secret" ]]; then
  DEFAULT_SECRET_LOADER="$HOME/.local/bin/cf-secret"
fi
if [[ "$DEFAULT_INFISICAL_STATUS" == "infisical-load" && -x "$HOME/.opencode/bin/infisical-load" ]]; then
  DEFAULT_INFISICAL_STATUS="$HOME/.opencode/bin/infisical-load"
fi
if [[ "$DEFAULT_GGSHIELD" == "ggshield" && -x "/opt/homebrew/bin/ggshield" ]]; then
  DEFAULT_GGSHIELD="/opt/homebrew/bin/ggshield"
fi

json=0
repo="$ROOT"
ledger="$DEFAULT_LEDGER"
secret_loader="$DEFAULT_SECRET_LOADER"
infisical_status="$DEFAULT_INFISICAL_STATUS"
ggshield_bin="$DEFAULT_GGSHIELD"
mode="commit-range"
commit_range=""
scan_path=""

usage() {
  cat <<'EOF'
usage: gitguardian-pre-push-gate.sh [--json] [--repo PATH] [--ledger PATH]
                                    [--mode commit-range|pre-push|changes|path]
                                    [--commit-range RANGE] [--scan-path PATH]
                                    [--secret-loader CMD] [--ggshield-bin CMD]

Tier 4.5 auto-push gate. Loads GITGUARDIAN_API_KEY just-in-time via the
Infisical/cf-secret discipline, runs ggshield, and fails closed on missing
credentials, missing ggshield, GitGuardian server errors, or detected leaks.

Exit codes:
  0  clean
  1  blocked or fail-closed
  2  usage error
EOF
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --repo) repo="${2:-}"; [[ -n "$repo" ]] || die_usage "--repo requires PATH"; shift 2 ;;
    --repo=*) repo="${1#--repo=}"; shift ;;
    --ledger) ledger="${2:-}"; [[ -n "$ledger" ]] || die_usage "--ledger requires PATH"; shift 2 ;;
    --ledger=*) ledger="${1#--ledger=}"; shift ;;
    --mode) mode="${2:-}"; [[ -n "$mode" ]] || die_usage "--mode requires value"; shift 2 ;;
    --mode=*) mode="${1#--mode=}"; shift ;;
    --commit-range) commit_range="${2:-}"; [[ -n "$commit_range" ]] || die_usage "--commit-range requires RANGE"; shift 2 ;;
    --commit-range=*) commit_range="${1#--commit-range=}"; shift ;;
    --scan-path) scan_path="${2:-}"; [[ -n "$scan_path" ]] || die_usage "--scan-path requires PATH"; shift 2 ;;
    --scan-path=*) scan_path="${1#--scan-path=}"; shift ;;
    --secret-loader) secret_loader="${2:-}"; [[ -n "$secret_loader" ]] || die_usage "--secret-loader requires CMD"; shift 2 ;;
    --secret-loader=*) secret_loader="${1#--secret-loader=}"; shift ;;
    --infisical-status) infisical_status="${2:-}"; [[ -n "$infisical_status" ]] || die_usage "--infisical-status requires CMD"; shift 2 ;;
    --infisical-status=*) infisical_status="${1#--infisical-status=}"; shift ;;
    --ggshield-bin) ggshield_bin="${2:-}"; [[ -n "$ggshield_bin" ]] || die_usage "--ggshield-bin requires CMD"; shift 2 ;;
    --ggshield-bin=*) ggshield_bin="${1#--ggshield-bin=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    *) die_usage "unknown option: $1" ;;
  esac
done

case "$mode" in
  commit-range|pre-push|changes|path) ;;
  *) die_usage "unknown mode: $mode" ;;
esac

iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

jq_json() {
  jq -nc "$@"
}

emit() {
  local status="$1" reason="$2" exit_code="$3" finding_count="$4" severity="$5" range="$6" branch="$7" scan_mode="$8"
  if [[ "$json" -eq 1 ]]; then
    jq_json \
      --arg schema "$SCHEMA_VERSION" \
      --arg ts "$(iso_now)" \
      --arg status "$status" \
      --arg reason "$reason" \
      --arg repo "$repo" \
      --arg branch "$branch" \
      --arg commit_range "$range" \
      --arg severity "$severity" \
      --arg mode "$scan_mode" \
      --arg ledger "$ledger" \
      --argjson exit_code "$exit_code" \
      --argjson finding_count "$finding_count" \
      '{
        schema_version:$schema,
        ts:$ts,
        status:$status,
        reason:$reason,
        repo:$repo,
        branch:$branch,
        commit_range:$commit_range,
        scan_mode:$mode,
        finding_count:$finding_count,
        severity:$severity,
        ledger:$ledger,
        exit_code:$exit_code
      }'
  else
    printf 'gitguardian-pre-push-gate status=%s reason=%s findings=%s severity=%s\n' \
      "$status" "$reason" "$finding_count" "$severity"
  fi
}

append_leak_ledger() {
  local branch="$1" range="$2" finding_count="$3" severity="$4" scan_mode="$5"
  mkdir -p "$(dirname "$ledger")"
  jq_json \
    --arg schema "$SCHEMA_VERSION" \
    --arg ts "$(iso_now)" \
    --arg event "secret_leak_detected" \
    --arg source "gitguardian-pre-push-gate" \
    --arg repo "$repo" \
    --arg branch "$branch" \
    --arg commit_range "$range" \
    --arg severity "$severity" \
    --arg mode "$scan_mode" \
    --argjson finding_count "$finding_count" \
    '{
      schema_version:$schema,
      ts:$ts,
      event:$event,
      source:$source,
      repo:$repo,
      branch:$branch,
      commit_range:$commit_range,
      scan_mode:$mode,
      finding_count:$finding_count,
      severity:$severity
    }' >>"$ledger"
}

branch_name() {
  git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown'
}

determine_range() {
  if [[ -n "$commit_range" ]]; then
    printf '%s\n' "$commit_range"
    return 0
  fi
  local upstream base
  upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
  if [[ -n "$upstream" ]]; then
    base="$(git -C "$repo" merge-base HEAD "$upstream" 2>/dev/null || true)"
    if [[ -n "$base" ]]; then
      printf '%s..HEAD\n' "$base"
      return 0
    fi
  fi
  base="$(git -C "$repo" rev-list --max-parents=0 HEAD 2>/dev/null | tail -1 || true)"
  [[ -n "$base" ]] || return 1
  printf '%s..HEAD\n' "$base"
}

load_api_key() {
  if ! command -v "$infisical_status" >/dev/null 2>&1; then
    return 10
  fi
  if ! "$infisical_status" --status >/dev/null 2>&1; then
    return 11
  fi
  if ! command -v "$secret_loader" >/dev/null 2>&1; then
    return 12
  fi
  "$secret_loader" GITGUARDIAN_API_KEY 2>/dev/null
}

finding_count_from_json() {
  local file="$1"
  jq 'def n:
        if type == "array" then length
        elif type == "object" and (.incidents? | type) == "array" then .incidents | length
        elif type == "object" and (.secrets? | type) == "array" then .secrets | length
        elif type == "object" and (.findings? | type) == "array" then .findings | length
        elif type == "object" and (.results? | type) == "array" then .results | length
        else 0 end;
      n' "$file" 2>/dev/null || printf '0\n'
}

severity_from_json() {
  local file="$1"
  jq -r '[.. | objects | .severity? // empty][0] // "high"' "$file" 2>/dev/null || printf 'high\n'
}

repo="$(cd "$repo" 2>/dev/null && pwd -P)" || {
  emit "blocked" "repo_not_found" 1 0 "unknown" "${commit_range:-unknown}" "unknown" "$mode"
  exit 1
}

branch="$(branch_name)"
range="not_applicable"
if [[ "$mode" == "commit-range" ]]; then
  if ! range="$(determine_range)"; then
    emit "blocked" "commit_range_unavailable" 1 0 "unknown" "unknown" "$branch" "$mode"
    exit 1
  fi
elif [[ "$mode" == "path" ]]; then
  scan_path="${scan_path:-$repo}"
  range="path:$scan_path"
elif [[ "$mode" == "changes" ]]; then
  range="changes"
elif [[ "$mode" == "pre-push" ]]; then
  range="pre-push-stdin"
fi

if [[ "$mode" == "commit-range" ]]; then
  outgoing_count="$(git -C "$repo" rev-list --count "$range" 2>/dev/null || printf '0')"
  if [[ "$outgoing_count" == "0" ]]; then
    emit "clean" "no_outgoing_commits" 0 0 "none" "$range" "$branch" "$mode"
    exit 0
  fi
fi

if ! command -v "$ggshield_bin" >/dev/null 2>&1; then
  emit "blocked" "ggshield_missing" 1 0 "unknown" "$range" "$branch" "$mode"
  exit 1
fi

if ! api_key="$(load_api_key)"; then
  api_key=""
fi
if [[ -z "$api_key" ]]; then
  unset api_key
  emit "blocked" "gitguardian_api_key_unavailable" 1 0 "unknown" "$range" "$branch" "$mode"
  exit 1
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/gitguardian-pre-push-gate.XXXXXX.json")"
trap 'rm -f "$tmp"; unset api_key GITGUARDIAN_API_KEY' EXIT

set +e
case "$mode" in
  commit-range)
    GITGUARDIAN_API_KEY="$api_key" GITGUARDIAN_EXIT_ZERO=0 GITGUARDIAN_FAIL_ON_SERVER_ERROR=1 \
      "$ggshield_bin" secret scan commit-range --format json -o "$tmp" "$range" >/dev/null 2>&1
    gg_rc=$?
    ;;
  changes)
    GITGUARDIAN_API_KEY="$api_key" GITGUARDIAN_EXIT_ZERO=0 GITGUARDIAN_FAIL_ON_SERVER_ERROR=1 \
      "$ggshield_bin" secret scan changes --format json -o "$tmp" >/dev/null 2>&1
    gg_rc=$?
    ;;
  path)
    GITGUARDIAN_API_KEY="$api_key" GITGUARDIAN_EXIT_ZERO=0 GITGUARDIAN_FAIL_ON_SERVER_ERROR=1 \
      "$ggshield_bin" secret scan path --recursive --yes --use-gitignore --format json -o "$tmp" "$scan_path" >/dev/null 2>&1
    gg_rc=$?
    ;;
  pre-push)
    GITGUARDIAN_API_KEY="$api_key" GITGUARDIAN_EXIT_ZERO=0 GITGUARDIAN_FAIL_ON_SERVER_ERROR=1 \
      "$ggshield_bin" secret scan pre-push --format json --fail-on-server-error -o "$tmp" "$@" >/dev/null 2>&1
    gg_rc=$?
    ;;
esac
set -e
unset api_key GITGUARDIAN_API_KEY

finding_count=0
severity="none"
if [[ -s "$tmp" ]]; then
  finding_count="$(finding_count_from_json "$tmp")"
  if [[ "$finding_count" -gt 0 ]]; then
    severity="$(severity_from_json "$tmp")"
  fi
fi

if [[ "$finding_count" -gt 0 ]]; then
  append_leak_ledger "$branch" "$range" "$finding_count" "$severity" "$mode"
  emit "blocked" "secret_leak_detected" 1 "$finding_count" "$severity" "$range" "$branch" "$mode"
  exit 1
fi

if [[ "$gg_rc" -ne 0 ]]; then
  emit "blocked" "ggshield_failed_closed" 1 0 "unknown" "$range" "$branch" "$mode"
  exit 1
fi

emit "clean" "no_findings" 0 0 "none" "$range" "$branch" "$mode"
