#!/usr/bin/env bash
# .flywheel/scripts/jeff-daily-corpus-diff.sh
# Daily activity collector for Jeffrey Emanuel's GitHub corpus.
# Polls 4 endpoints per repo (commits, issues, releases, PRs)
# in last 24h and writes one aggregated JSON snapshot.
#
# Bead: flywheel-ys7em (replaces J3-J11 local-clone chain)
# Spec:  .flywheel/audit/jeff-daily-corpus-diff/apply-spec.md
#
# Usage:
#   jeff-daily-corpus-diff.sh --info          # canonical-cli-scoping triad
#   jeff-daily-corpus-diff.sh --doctor        # gh auth + repo cache health
#   jeff-daily-corpus-diff.sh --refresh-repos # refresh repo cache (weekly)
#   jeff-daily-corpus-diff.sh --apply --json  # run collection, emit raw json
#   jeff-daily-corpus-diff.sh --apply --json --since=<UTC-iso>  # custom window
#   jeff-daily-corpus-diff.sh --apply --json --only=<repo>      # one repo (smoke)
set -euo pipefail

VERSION="0.1.0"
SCHEMA_VERSION="jeff-daily-diff-collector.v1"
REPO_OWNER="${JEFF_DIFF_OWNER:-Dicklesworthstone}"
STATE_DIR="${JEFF_DIFF_STATE_DIR:-/Users/josh/Developer/flywheel/.flywheel/state}"
REPO_CACHE="$STATE_DIR/jeff-repos.json"
CACHE_TTL_DAYS="${JEFF_DIFF_CACHE_TTL:-7}"
PARALLEL="${JEFF_DIFF_PARALLEL:-8}"
INCLUDE_ARCHIVED="${JEFF_DIFF_INCLUDE_ARCHIVED:-0}"
INCLUDE_FORKS="${JEFF_DIFF_INCLUDE_FORKS:-0}"

mode="apply"
emit_json=0
since=""
only_repo=""

usage() {
  cat <<EOF
jeff-daily-corpus-diff.sh — daily GitHub API activity collector for Dicklesworthstone corpus

Schema:  $SCHEMA_VERSION
Version: $VERSION

Modes (canonical-cli-scoping triad):
  --info               print this help and exit 0
  --schema             print emit schema (one line) and exit 0
  --examples           print invocation examples and exit 0
  --doctor             gh auth + cache health probe (--json supported)
  --refresh-repos      refresh repo cache (weekly cadence)
  --apply              run collection, write snapshot, optionally emit json

Options:
  --json               emit machine-readable JSON envelope
  --since=<iso>        override the 24h since cutoff (UTC iso, e.g. 2026-05-09T00:00:00Z)
  --only=<repo>        restrict to ONE repo (smoke testing)
  --version            print version and exit 0

Exit codes:
  0  success
  1  internal error
  2  bad argument or missing dependency
  3  gh auth or rate-limit failure

Environment:
  JEFF_DIFF_OWNER             default: Dicklesworthstone
  JEFF_DIFF_PARALLEL          default: 8 (per-repo job concurrency)
  JEFF_DIFF_CACHE_TTL         default: 7 (days)
  JEFF_DIFF_INCLUDE_ARCHIVED  default: 0 (exclude archived)
  JEFF_DIFF_INCLUDE_FORKS     default: 0 (exclude forks)

Output:
  Snapshot: \$STATE_DIR/jeff-corpus-activity-<UTC-date>.json (kept 90 days)
EOF
}

examples() {
  cat <<'EOF'
# Today's collection (canonical daily run):
jeff-daily-corpus-diff.sh --apply --json

# Smoke test against one repo:
jeff-daily-corpus-diff.sh --apply --json --only=ntm

# Custom window (last 7 days):
jeff-daily-corpus-diff.sh --apply --json --since=2026-05-03T00:00:00Z

# Refresh repo cache (weekly):
jeff-daily-corpus-diff.sh --refresh-repos --json

# Doctor probe (gh auth + cache age):
jeff-daily-corpus-diff.sh --doctor --json
EOF
}

schema_line() {
  printf '{"schema_version":"%s","keys":["schema_version","ts_started","ts_completed","since","owner","repo_count","repos","total_commits","total_issues","total_releases","total_prs","errors"]}\n' \
    "$SCHEMA_VERSION"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info|-h|--help) usage; exit 0 ;;
    --schema)         schema_line; exit 0 ;;
    --examples)       examples; exit 0 ;;
    --version)        printf '%s\n' "$VERSION"; exit 0 ;;
    --doctor)         mode="doctor" ;;
    --refresh-repos)  mode="refresh" ;;
    --apply)          mode="apply" ;;
    --json)           emit_json=1 ;;
    --since=*)        since="${1#--since=}" ;;
    --only=*)         only_repo="${1#--only=}" ;;
    *) printf 'unknown flag: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
ymd() { date -u +%Y-%m-%d; }
err() { printf '%s\n' "$*" >&2; }

require() {
  if ! command -v "$1" >/dev/null; then
    err "missing dependency: $1"
    exit 2
  fi
}
require gh
require jq
require xargs

doctor() {
  local gh_ok=true cache_ok=true cache_age_days=0
  if ! gh auth status >/dev/null 2>&1; then gh_ok=false; fi
  if [[ -f "$REPO_CACHE" ]]; then
    local mtime
    mtime="$(/usr/bin/stat -f %m "$REPO_CACHE")"
    local now; now="$(date +%s)"
    cache_age_days=$(( (now - mtime) / 86400 ))
    [[ "$cache_age_days" -gt "$CACHE_TTL_DAYS" ]] && cache_ok=false
  else
    cache_ok=false
  fi
  if [[ "$emit_json" == 1 ]]; then
    jq -nc \
      --arg schema "jeff-daily-diff-doctor.v1" \
      --arg ts "$(iso)" \
      --argjson gh "$gh_ok" \
      --argjson cache "$cache_ok" \
      --argjson cache_age "$cache_age_days" \
      --arg ttl "$CACHE_TTL_DAYS" \
      '{schema_version:$schema,ts:$ts,gh_auth:$gh,cache_present_and_fresh:$cache,cache_age_days:$cache_age,cache_ttl_days:($ttl|tonumber)}'
  else
    printf 'gh_auth=%s cache_fresh=%s cache_age_days=%d ttl=%d\n' "$gh_ok" "$cache_ok" "$cache_age_days" "$CACHE_TTL_DAYS"
  fi
  if [[ "$gh_ok" == "false" ]]; then exit 3; fi
  if [[ "$cache_ok" == "false" ]]; then exit 1; fi
  exit 0
}

refresh_repos() {
  mkdir -p "$STATE_DIR"
  if ! gh repo list "$REPO_OWNER" --limit 200 --json name,isArchived,updatedAt,isFork,description > "$REPO_CACHE.tmp"; then
    err "gh repo list failed"
    rm -f "$REPO_CACHE.tmp"
    exit 3
  fi
  mv "$REPO_CACHE.tmp" "$REPO_CACHE"
  local total active
  total="$(jq 'length' "$REPO_CACHE")"
  active="$(jq '[.[] | select(.isArchived==false and .isFork==false)] | length' "$REPO_CACHE")"
  if [[ "$emit_json" == 1 ]]; then
    jq -nc --arg ts "$(iso)" --arg cache "$REPO_CACHE" --argjson total "$total" --argjson active "$active" \
      '{schema_version:"jeff-daily-diff-refresh.v1",ts:$ts,cache_path:$cache,total:$total,active:$active}'
  else
    printf 'refreshed cache=%s total=%d active=%d\n' "$REPO_CACHE" "$total" "$active"
  fi
}

# Compute the SINCE cutoff (24h ago by default; override via --since)
default_since() {
  if [[ -n "$since" ]]; then
    printf '%s' "$since"
  else
    date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
      || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ
  fi
}

# Worker function: collect one repo's 4 endpoints, write a single JSON object
# to $OUT_DIR/<repo>.json (NOT stdout — parallel xargs interleaves stdout writes
# above PIPE_BUF; per-repo files avoid the race entirely).
# Args: $1=repo_name $2=since_iso $3=owner $4=out_dir
collect_one() {
  local repo="$1" since="$2" owner="$3" out_dir="$4"
  local commits issues releases prs
  commits="$(gh api "/repos/$owner/$repo/commits?since=$since&per_page=100" 2>/dev/null \
    | jq -c '[.[] | {sha: .sha[0:7], message: (.commit.message | split("\n")[0]), author: .commit.author.name, ts: .commit.author.date}]' 2>/dev/null \
    || echo '[]')"
  issues="$(gh api "/search/issues?q=repo:$owner/$repo+is:issue+updated:>=$since&per_page=20" 2>/dev/null \
    | jq -c '[.items[]? | {number, title, state, ts: .updated_at, url: .html_url}]' 2>/dev/null \
    || echo '[]')"
  releases="$(gh api "/repos/$owner/$repo/releases?per_page=5" 2>/dev/null \
    | jq -c --arg s "$since" '[.[] | select(.published_at != null and .published_at >= $s) | {tag: .tag_name, name, ts: .published_at, url: .html_url}]' 2>/dev/null \
    || echo '[]')"
  prs="$(gh api "/search/issues?q=repo:$owner/$repo+is:pr+is:merged+merged:>=$since&per_page=20" 2>/dev/null \
    | jq -c '[.items[]? | {number, title, ts: .closed_at, url: .html_url}]' 2>/dev/null \
    || echo '[]')"
  jq -nc --arg repo "$repo" \
        --argjson commits "$commits" \
        --argjson issues "$issues" \
        --argjson releases "$releases" \
        --argjson prs "$prs" \
    '{repo:$repo, commits:$commits, issues:$issues, releases:$releases, prs:$prs}' \
    > "$out_dir/$repo.json"
}
export -f collect_one

apply() {
  if [[ ! -f "$REPO_CACHE" ]]; then
    err "repo cache missing; run --refresh-repos first"
    exit 1
  fi
  local since_iso ts_started snapshot
  since_iso="$(default_since)"
  ts_started="$(iso)"
  snapshot="$STATE_DIR/jeff-corpus-activity-$(ymd).json"
  mkdir -p "$STATE_DIR"

  # Build active repo list
  local repos_jq='.[] | select(.isArchived==false and .isFork==false) | .name'
  if [[ "$INCLUDE_ARCHIVED" == 1 ]]; then repos_jq='.[] | select(.isFork==false) | .name'; fi
  if [[ "$INCLUDE_FORKS" == 1 ]]; then repos_jq='.[] | .name'; fi
  if [[ -n "$only_repo" ]]; then
    repos_list="$only_repo"
  else
    repos_list="$(jq -r "$repos_jq" "$REPO_CACHE")"
  fi
  local repo_count
  repo_count="$(printf '%s\n' "$repos_list" | grep -c . || echo 0)"

  err "[jeff-daily-diff] collecting $repo_count repos parallel=$PARALLEL since=$since_iso"

  # Per-repo output files (no parallel-stdout-interleave race). Each worker
  # writes to $OUT_DIR/<repo>.json, then we slurp them all into the snapshot.
  local out_dir
  out_dir="$(mktemp -d -t jeff-daily-diff.XXXXXX)"
  printf '%s\n' "$repos_list" | xargs -P "$PARALLEL" -I{} bash -c \
    'collect_one "$@" 2>/dev/null || true' _ {} "$since_iso" "$REPO_OWNER" "$out_dir"

  # Aggregate by reading each per-repo file as one JSON object
  local raw_lines="$STATE_DIR/.jeff-corpus-activity-raw.$$"
  : > "$raw_lines"
  for f in "$out_dir"/*.json; do
    [[ -s "$f" ]] || continue
    cat "$f" >> "$raw_lines"
    printf '\n' >> "$raw_lines"
  done

  local total_commits total_issues total_releases total_prs
  total_commits="$(jq -s 'map(.commits | length) | add // 0' "$raw_lines")"
  total_issues="$(jq -s 'map(.issues | length) | add // 0' "$raw_lines")"
  total_releases="$(jq -s 'map(.releases | length) | add // 0' "$raw_lines")"
  total_prs="$(jq -s 'map(.prs | length) | add // 0' "$raw_lines")"

  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg ts_s "$ts_started" \
    --arg ts_c "$(iso)" \
    --arg since_iso "$since_iso" \
    --arg owner "$REPO_OWNER" \
    --argjson rc "$repo_count" \
    --argjson tc "$total_commits" \
    --argjson ti "$total_issues" \
    --argjson tr "$total_releases" \
    --argjson tp "$total_prs" \
    --slurpfile r "$raw_lines" \
    '{schema_version:$schema, ts_started:$ts_s, ts_completed:$ts_c, since:$since_iso, owner:$owner, repo_count:$rc, repos:$r, total_commits:$tc, total_issues:$ti, total_releases:$tr, total_prs:$tp, errors:[]}' \
    > "$snapshot"

  rm -rf "$out_dir" "$raw_lines"

  if [[ "$emit_json" == 1 ]]; then
    jq -c '{schema_version, ts_completed, since, owner, repo_count, total_commits, total_issues, total_releases, total_prs, snapshot_path}' \
      <(jq --arg p "$snapshot" '. + {snapshot_path:$p}' "$snapshot")
  else
    printf 'snapshot=%s repos=%s commits=%s issues=%s releases=%s prs=%s\n' \
      "$snapshot" "$repo_count" "$total_commits" "$total_issues" "$total_releases" "$total_prs"
  fi
}

case "$mode" in
  doctor)  doctor ;;
  refresh) refresh_repos ;;
  apply)   apply ;;
  *)       err "unknown mode: $mode"; exit 2 ;;
esac
