#!/usr/bin/env bash
# fleet-git-inventory.sh
# Authority: .flywheel/PLANS/git-workflow-foundation-2026-05-20/00-research.md
#            .flywheel/docs/git-workflow-runbook.md
# Bead: flywheel-m9yxr
#
# Read-only fleet-wide audit of git assets per repo: worktrees, stashes,
# branches (with upstream-track state), and tags. Aggregates into a fleet
# JSON envelope and emits a single dashboard line for /flywheel:status.
#
# Doctor JSON key: fleet_git_hygiene
# Mission Duty: 3 (substrate-published), 5a (auto-push, via last_pushed_at)
#
# CLI envelope (per canonical-cli-scoping skill):
#   --info --json | --schema --json | --examples --json
#   --json (default audit)
#   --repo <path>          probe a single repo instead of the fleet
#   --roster <path>        fleet roster JSON (default $HOME/.flywheel/fleet-roster.json)
#   --dashboard            emit just the dashboard line (text)
#   --thresholds <yaml>    override default tiered thresholds
#
# Exit codes:
#   0  clean | notable
#   1  one-or-more repos at halt threshold (P0)
#   2  usage error
#   3  no git / no roster

set -euo pipefail

VERSION="fleet-git-inventory/v1"
SCHEMA_VERSION="flywheel.fleet_git_inventory.v1"
REPO=""
ROSTER="${FLYWHEEL_FLEET_ROSTER:-$HOME/.flywheel/fleet-roster.json}"
JSON_OUT=1
DASHBOARD_ONLY=0
MODE="audit"

# Tiered thresholds (mirrors repo-hygiene-tick defaults; see tests/repo-hygiene-tick-smoke.sh)
T_WORKTREE_P2=4
T_WORKTREE_P1=10
T_WORKTREE_P0=20
T_STASH_P2=5
T_STASH_P1=10
T_STASH_P0=20
T_UNPUSHED_P2=10
T_UNPUSHED_P1=25
T_UNPUSHED_P0=50

usage() {
  cat <<'USAGE'
usage:
  fleet-git-inventory.sh [--repo PATH | --roster PATH] [--json] [--dashboard]
  fleet-git-inventory.sh --info|--schema|--examples [--json]

Read-only multi-repo audit of git worktrees, stashes, branches (with upstream
track state), and tags. Emits JSON envelope + dashboard line. Mutates nothing.

Exit codes: 0=clean|notable, 1=halt (P0 in any repo), 2=usage, 3=git/roster err.
USAGE
}

info() {
  jq -nc \
    --arg name "fleet-git-inventory.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    '{
      name:$name,
      version:$version,
      schema_version:$schema_version,
      mutates:false,
      doctrine:".flywheel/docs/git-workflow-runbook.md",
      authority:"flywheel-m9yxr research (2026-05-20)",
      mission_duty:["3","5a"],
      doctor_field:"fleet_git_hygiene",
      dashboard_field:"fleet_git_hygiene_line",
      commands:["audit","info","schema","examples"],
      modes:["fleet","single-repo"],
      output:"json + dashboard text",
      thresholds:{
        worktree:{p2:4,p1:10,p0:20},
        stash:{p2:5,p1:10,p0:20},
        unpushed:{p2:10,p1:25,p0:50}
      },
      exit_codes:{"0":"clean|notable","1":"halt(P0)","2":"usage","3":"git_or_roster_error"}
    }'
}

schema() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" '{
    schema_version:$schema_version,
    type:"object",
    required:["schema_version","generated_at","repos","aggregate","dashboard_line"],
    properties:{
      schema_version:{const:$schema_version},
      generated_at:{type:"string",format:"date-time"},
      repos:{type:"array",items:{
        type:"object",
        required:["repo","repo_path","worktree_count","stash_count","unpushed_count","tag_count","tier"],
        properties:{
          repo:{type:"string"},
          repo_path:{type:"string"},
          worktree_count:{type:"integer",minimum:0},
          stash_count:{type:"integer",minimum:0},
          unpushed_count:{type:"integer",minimum:0,description:"branches with upstream ahead OR gone"},
          gone_branch_count:{type:"integer",minimum:0,description:"branches whose upstream is deleted"},
          tag_count:{type:"integer",minimum:0},
          tier:{enum:["clean","notable","P2","P1","P0"]},
          worktrees:{type:"array",items:{type:"object"}},
          stashes:{type:"array",items:{type:"object"}},
          unpushed:{type:"array",items:{type:"object"}}
        }
      }},
      aggregate:{type:"object",required:["repos_total","repos_clean","worktrees_total","stashes_total","unpushed_total","worst_tier","fleet_git_hygiene_score"],properties:{
        repos_total:{type:"integer"},
        repos_clean:{type:"integer"},
        worktrees_total:{type:"integer"},
        stashes_total:{type:"integer"},
        unpushed_total:{type:"integer"},
        worst_tier:{enum:["clean","notable","P2","P1","P0"]},
        fleet_git_hygiene_score:{type:"integer",minimum:0,maximum:100}
      }},
      dashboard_line:{type:"string"}
    }
  }'
}

examples() {
  jq -nc '{examples:[
    "fleet-git-inventory.sh --json",
    "fleet-git-inventory.sh --repo /Users/josh/Developer/flywheel --json",
    "fleet-git-inventory.sh --dashboard",
    "fleet-git-inventory.sh --roster /custom/roster.json --json"
  ]}'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; usage >&2; exit 2; }

# -------------------------------------------------------------- arg parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --info)        info; exit 0 ;;
    --schema)      schema; exit 0 ;;
    --examples)    examples; exit 0 ;;
    --help|-h)     usage; exit 0 ;;
    --repo)        REPO="${2:?--repo requires PATH}"; shift 2 ;;
    --roster)      ROSTER="${2:?--roster requires PATH}"; shift 2 ;;
    --json)        JSON_OUT=1; shift ;;
    --dashboard)   DASHBOARD_ONLY=1; shift ;;
    *)             die_usage "unknown arg: $1" ;;
  esac
done

# -------------------------------------------------------------- per-repo probe
probe_repo() {
  local path="$1"
  local name
  name="$(basename "$path")"
  if [[ ! -d "$path/.git" && ! -f "$path/.git" ]]; then
    jq -nc --arg name "$name" --arg path "$path" \
      '{repo:$name,repo_path:$path,error:"not_a_git_repo",tier:"clean",worktree_count:0,stash_count:0,unpushed_count:0,gone_branch_count:0,tag_count:0}'
    return
  fi

  # Worktrees (excluding the main checkout itself — we count EXTRA)
  local wt_lines wt_count wt_json
  wt_lines="$(git -C "$path" worktree list --porcelain 2>/dev/null || true)"
  wt_count="$(printf '%s\n' "$wt_lines" | grep -c '^worktree ' || true)"
  wt_count=$((wt_count > 0 ? wt_count - 1 : 0))   # subtract main
  wt_json="$(git -C "$path" worktree list 2>/dev/null | tail -n +2 | jq -R -s 'split("\n")|map(select(length>0)|{raw:.})')"

  # Stashes
  local stash_count stash_json
  stash_count="$(git -C "$path" stash list 2>/dev/null | wc -l | tr -d ' ')"
  stash_json="$(git -C "$path" stash list 2>/dev/null | jq -R -s 'split("\n")|map(select(length>0)|{raw:.})')"

  # Branches with upstream-track issues (ahead, gone) → unpushed
  local unpushed_lines unpushed_count gone_count unpushed_json
  unpushed_lines="$(git -C "$path" for-each-ref --format='%(refname:short)|%(upstream:track)' refs/heads/ 2>/dev/null | awk -F'|' '$2 ~ /(ahead|gone)/ {print}' || true)"
  unpushed_count="$(printf '%s\n' "$unpushed_lines" | grep -c . || true)"
  gone_count="$(printf '%s\n' "$unpushed_lines" | grep -c 'gone' || true)"
  unpushed_json="$(printf '%s\n' "$unpushed_lines" | jq -R -s 'split("\n")|map(select(length>0)|split("|")|{branch:.[0],track:.[1]})')"

  # Tags
  local tag_count
  tag_count="$(git -C "$path" tag --list 2>/dev/null | wc -l | tr -d ' ')"

  # Tier classification (worst of three axes)
  local tier="clean"
  classify() {
    local n="$1" p2="$2" p1="$3" p0="$4" cur="$5"
    local out="$cur"
    if   (( n >= p0 )); then out="P0"
    elif (( n >= p1 )); then out="P1"
    elif (( n >= p2 )); then out="P2"
    elif (( n > 0 ));   then [[ "$cur" == "clean" ]] && out="notable" || out="$cur"
    fi
    # rank ordering: P0>P1>P2>notable>clean
    local rank_cur rank_out
    case "$cur" in clean) rank_cur=0;; notable) rank_cur=1;; P2) rank_cur=2;; P1) rank_cur=3;; P0) rank_cur=4;; esac
    case "$out" in clean) rank_out=0;; notable) rank_out=1;; P2) rank_out=2;; P1) rank_out=3;; P0) rank_out=4;; esac
    if (( rank_out > rank_cur )); then printf '%s' "$out"; else printf '%s' "$cur"; fi
  }
  tier="$(classify "$wt_count" "$T_WORKTREE_P2" "$T_WORKTREE_P1" "$T_WORKTREE_P0" "$tier")"
  tier="$(classify "$stash_count" "$T_STASH_P2" "$T_STASH_P1" "$T_STASH_P0" "$tier")"
  tier="$(classify "$unpushed_count" "$T_UNPUSHED_P2" "$T_UNPUSHED_P1" "$T_UNPUSHED_P0" "$tier")"

  jq -nc \
    --arg name "$name" --arg path "$path" \
    --argjson wt "$wt_count" --argjson stash "$stash_count" \
    --argjson unpushed "$unpushed_count" --argjson gone "$gone_count" \
    --argjson tag "$tag_count" --arg tier "$tier" \
    --argjson wt_json "${wt_json:-[]}" \
    --argjson stash_json "${stash_json:-[]}" \
    --argjson unpushed_json "${unpushed_json:-[]}" \
    '{
      repo:$name,repo_path:$path,
      worktree_count:$wt,stash_count:$stash,
      unpushed_count:$unpushed,gone_branch_count:$gone,
      tag_count:$tag,tier:$tier,
      worktrees:$wt_json,stashes:$stash_json,unpushed:$unpushed_json
    }'
}

# -------------------------------------------------------------- fleet aggregate
collect_repos() {
  if [[ -n "$REPO" ]]; then
    printf '%s\n' "$REPO"
    return
  fi
  if [[ ! -f "$ROSTER" ]]; then
    printf 'ERR: roster not found at %s\n' "$ROSTER" >&2
    exit 3
  fi
  jq -r '.members[]?.repo_realpath // empty' "$ROSTER"
}

generated_at="$(date -u +%FT%TZ)"
repo_rows="$(mktemp)"
trap 'rm -f "$repo_rows"' EXIT

while IFS= read -r p; do
  [[ -z "$p" ]] && continue
  probe_repo "$p" >>"$repo_rows"
done < <(collect_repos)

# Aggregate
fleet_json="$(jq -s --arg ts "$generated_at" --arg schema "$SCHEMA_VERSION" '
  {
    schema_version:$schema,
    generated_at:$ts,
    repos:.,
    aggregate:{
      repos_total:length,
      repos_clean:(map(select(.tier == "clean")) | length),
      worktrees_total:(map(.worktree_count // 0) | add // 0),
      stashes_total:(map(.stash_count // 0) | add // 0),
      unpushed_total:(map(.unpushed_count // 0) | add // 0),
      worst_tier:(
        map(.tier // "clean") |
        (if any(. == "P0") then "P0"
         elif any(. == "P1") then "P1"
         elif any(. == "P2") then "P2"
         elif any(. == "notable") then "notable"
         else "clean" end)
      )
    }
  } |
  .aggregate.fleet_git_hygiene_score = (
    if .aggregate.repos_total == 0 then 100
    else ((.aggregate.repos_clean * 100) / .aggregate.repos_total | floor)
    end
  ) |
  .dashboard_line = (
    "Git hygiene: " + (.aggregate.repos_clean | tostring) + "/" +
    (.aggregate.repos_total | tostring) +
    " | worktrees=" + (.aggregate.worktrees_total | tostring) +
    " | stashes=" + (.aggregate.stashes_total | tostring) +
    " | unpushed=" + (.aggregate.unpushed_total | tostring) +
    " | tier=" + .aggregate.worst_tier
  )
' "$repo_rows")"

worst_tier="$(jq -r '.aggregate.worst_tier' <<<"$fleet_json")"

if [[ "$DASHBOARD_ONLY" -eq 1 ]]; then
  jq -r '.dashboard_line' <<<"$fleet_json"
else
  printf '%s\n' "$fleet_json"
fi

case "$worst_tier" in
  P0) exit 1 ;;
  *)  exit 0 ;;
esac
