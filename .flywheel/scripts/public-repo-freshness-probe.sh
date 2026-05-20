#!/usr/bin/env bash
# public-repo-freshness-probe.sh
#
# Probe staleness of origin/<default_branch> for every public repo owned by the
# fleet. Compares against each repo's declared .flywheel/PUBLISH-POLICY.json
# (schema: flywheel.publish_policy.v1) and emits a fleet-wide JSON envelope +
# one dashboard line.
#
# Authority:  .flywheel/PLANS/auto-publish-doctrine-2026-05-20/00-research.md
# Schema:     .flywheel/schemas/PUBLISH-POLICY.schema.json
# Bead:       flywheel-jrpfn
# Mission:    Duty 3 (substrate-published)
# Doctor key: public_repo_freshness
#
# Status semantics:
#   ok       — 100% of public repos within their declared max_main_staleness_hours
#   degraded — at least one repo over threshold but none over 2x threshold
#   critical — at least one repo over 2x threshold
#
# CLI surfaces (canonical-cli-scoping):
#   --info --json | --schema --json | --examples --json
#   --json   (default: emit envelope to stdout)
#   --quiet  (suppress dashboard line; envelope only)
#   --owner <gh-owner>   default: JYeswak
#   --policy-root <path> override per-repo policy lookup (default: ~/Developer/<name>/.flywheel/PUBLISH-POLICY.json)
#   --now-epoch <int>    override "now" for deterministic tests
#
# Exit codes:
#   0  ok|degraded
#   1  critical
#   2  usage error
#   3  no gh / network failure / unable to enumerate

set -euo pipefail

VERSION="public-repo-freshness-probe/v1"
SCHEMA_VERSION="flywheel.public_repo_freshness.v1"

OWNER="${FLYWHEEL_PUBLISH_OWNER:-JYeswak}"
POLICY_ROOT="${FLYWHEEL_DEV_ROOT:-$HOME/Developer}"
QUIET=0
NOW_EPOCH="$(date -u +%s)"
MODE="probe"

usage() {
  cat <<'USAGE'
usage:
  public-repo-freshness-probe.sh [--owner OWNER] [--policy-root DIR] [--json] [--quiet] [--now-epoch INT]
  public-repo-freshness-probe.sh --info|--schema|--examples [--json]

Probes origin/<default_branch> staleness for every public repo of OWNER
against each repo's .flywheel/PUBLISH-POLICY.json. Mutates nothing.

Doctor field: public_repo_freshness
Schema:       flywheel.public_repo_freshness.v1
Status:       ok=100% fresh | degraded=>threshold | critical=>2x threshold
Exit codes:   0=ok|degraded, 1=critical, 2=usage, 3=gh/network
USAGE
}

emit_info() {
  jq -nc \
    --arg name "public-repo-freshness-probe.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg owner "$OWNER" \
    '{
      name:$name,
      version:$version,
      schema_version:$schema_version,
      mutates:false,
      doctrine:".flywheel/PLANS/auto-publish-doctrine-2026-05-20/00-research.md",
      authority:"flywheel-jrpfn",
      mission_duty:["3"],
      doctor_field:"public_repo_freshness",
      dashboard_field:"public_repo_freshness_line",
      default_owner:$owner,
      commands:["probe","info","schema","examples"],
      capabilities:["fleet-enumeration","per-repo-policy-lookup","staleness-classification","dashboard-emit"],
      output:"json + dashboard text",
      dependencies:["gh","jq","git"],
      exit_codes:{"0":"ok|degraded","1":"critical","2":"usage","3":"gh_or_network_error"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '
    {
      schema_version:$sv,
      type:"object",
      required:["schema_version","ts","status","owner","per_repo","aggregate","dashboard_line"],
      properties:{
        schema_version:{const:$sv},
        ts:{type:"string",format:"date-time"},
        status:{enum:["ok","degraded","critical"]},
        owner:{type:"string"},
        per_repo:{
          type:"array",
          items:{
            type:"object",
            required:["name","slug","staleness_hours","threshold_hours","status","last_main_sha","policy_present"],
            properties:{
              name:{type:"string"},
              slug:{type:"string"},
              default_branch:{type:"string"},
              staleness_hours:{type:["number","null"]},
              threshold_hours:{type:"number"},
              status:{enum:["ok","degraded","critical","unknown"]},
              last_main_sha:{type:["string","null"]},
              last_main_ts:{type:["string","null"],format:"date-time"},
              policy_present:{type:"boolean"},
              policy_path:{type:["string","null"]},
              error:{type:["string","null"]}
            }
          }
        },
        aggregate:{
          type:"object",
          required:["total","fresh","stale","critical","worst_repo","worst_staleness_hours"],
          properties:{
            total:{type:"integer",minimum:0},
            fresh:{type:"integer",minimum:0},
            stale:{type:"integer",minimum:0},
            critical:{type:"integer",minimum:0},
            unknown:{type:"integer",minimum:0},
            worst_repo:{type:["string","null"]},
            worst_staleness_hours:{type:["number","null"]}
          }
        },
        dashboard_line:{type:"string"}
      }
    }'
}

emit_examples() {
  jq -nc '
    {
      examples:[
        {
          title:"Default fleet probe",
          command:"public-repo-freshness-probe.sh --json",
          notes:"Enumerates all public repos under JYeswak, looks up each repo policy under ~/Developer/<name>/.flywheel/PUBLISH-POLICY.json, emits envelope + dashboard line."
        },
        {
          title:"Quiet mode (envelope only)",
          command:"public-repo-freshness-probe.sh --json --quiet",
          notes:"Use in /flywheel:tick to consume JSON without console noise."
        },
        {
          title:"Override owner",
          command:"public-repo-freshness-probe.sh --owner JYeswak --json",
          notes:"Multi-owner fleets call with --owner per slice."
        }
      ]
    }'
}

# ---------- arg parsing ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --info)      MODE="info"; shift ;;
    --schema)    MODE="schema"; shift ;;
    --examples)  MODE="examples"; shift ;;
    --json)      shift ;;
    --quiet)     QUIET=1; shift ;;
    --owner)     OWNER="${2:?}"; shift 2 ;;
    --policy-root) POLICY_ROOT="${2:?}"; shift 2 ;;
    --now-epoch) NOW_EPOCH="${2:?}"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  info)     emit_info; exit 0 ;;
  schema)   emit_schema; exit 0 ;;
  examples) emit_examples; exit 0 ;;
esac

# ---------- dependency checks ----------
for bin in gh jq git; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    printf '{"schema_version":"%s","status":"error","error":"missing dependency: %s"}\n' "$SCHEMA_VERSION" "$bin"
    exit 3
  fi
done

# ---------- enumerate public repos ----------
REPOS_JSON="$(gh repo list "$OWNER" --json name,visibility,defaultBranchRef,pushedAt --limit 200 2>/dev/null || true)"
if [[ -z "$REPOS_JSON" ]] || ! printf '%s' "$REPOS_JSON" | jq -e 'type == "array"' >/dev/null 2>&1; then
  printf '{"schema_version":"%s","status":"error","error":"failed to enumerate repos for owner %s"}\n' "$SCHEMA_VERSION" "$OWNER"
  exit 3
fi

PUBLIC_REPOS_JSON="$(printf '%s' "$REPOS_JSON" | jq -c '[.[] | select(.visibility == "PUBLIC")]')"
TOTAL="$(printf '%s' "$PUBLIC_REPOS_JSON" | jq 'length')"

# ---------- per-repo probe ----------
PER_REPO="[]"
FRESH=0; STALE=0; CRITICAL=0; UNKNOWN=0
WORST_REPO="null"; WORST_HOURS=-1

while IFS= read -r repo_obj; do
  name="$(printf '%s' "$repo_obj" | jq -r '.name')"
  slug="$OWNER/$name"
  default_branch="$(printf '%s' "$repo_obj" | jq -r '.defaultBranchRef.name // "main"')"
  pushed_at="$(printf '%s' "$repo_obj" | jq -r '.pushedAt // ""')"

  # Locate per-repo PUBLISH-POLICY.json
  policy_path=""
  threshold_hours=24
  policy_present=false
  for candidate in \
    "$POLICY_ROOT/$name/.flywheel/PUBLISH-POLICY.json" \
    "$POLICY_ROOT/$(echo "$name" | tr '[:upper:]' '[:lower:]')/.flywheel/PUBLISH-POLICY.json"; do
    if [[ -r "$candidate" ]]; then
      policy_path="$candidate"
      policy_present=true
      threshold_hours="$(jq -r '.max_main_staleness_hours // 24' "$candidate" 2>/dev/null || echo 24)"
      default_branch="$(jq -r '.default_branch // "main"' "$candidate" 2>/dev/null || echo "$default_branch")"
      break
    fi
  done

  # Probe origin/<default_branch> via gh API
  last_main_ts=""
  last_main_sha=""
  error_msg="null"
  commit_json="$(gh api "repos/$slug/commits/$default_branch" 2>/dev/null || true)"
  if [[ -n "$commit_json" ]] && printf '%s' "$commit_json" | jq -e '.sha' >/dev/null 2>&1; then
    last_main_sha="$(printf '%s' "$commit_json" | jq -r '.sha')"
    last_main_ts="$(printf '%s' "$commit_json" | jq -r '.commit.committer.date // .commit.author.date')"
  else
    error_msg="\"failed to read $slug/commits/$default_branch\""
  fi

  # Compute staleness
  if [[ -n "$last_main_ts" ]]; then
    last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_main_ts" +%s 2>/dev/null || date -u -d "$last_main_ts" +%s 2>/dev/null || echo 0)"
    if [[ "$last_epoch" -gt 0 ]]; then
      staleness_hours="$(awk -v now="$NOW_EPOCH" -v then="$last_epoch" 'BEGIN { printf "%.2f", (now - then) / 3600.0 }')"
    else
      staleness_hours="null"
    fi
  else
    staleness_hours="null"
  fi

  # Classify
  if [[ "$staleness_hours" == "null" ]]; then
    repo_status="unknown"
    UNKNOWN=$((UNKNOWN + 1))
  else
    crit_threshold="$(awk -v t="$threshold_hours" 'BEGIN { printf "%.2f", t * 2.0 }')"
    if awk -v s="$staleness_hours" -v t="$threshold_hours" 'BEGIN { exit !(s <= t) }'; then
      repo_status="ok"
      FRESH=$((FRESH + 1))
    elif awk -v s="$staleness_hours" -v c="$crit_threshold" 'BEGIN { exit !(s <= c) }'; then
      repo_status="degraded"
      STALE=$((STALE + 1))
    else
      repo_status="critical"
      CRITICAL=$((CRITICAL + 1))
    fi
    # Track worst
    if awk -v s="$staleness_hours" -v w="$WORST_HOURS" 'BEGIN { exit !(s > w) }'; then
      WORST_HOURS="$staleness_hours"
      WORST_REPO="\"$name\""
    fi
  fi

  # last_main_ts and last_main_sha JSON-safe
  if [[ -z "$last_main_ts" ]]; then last_main_ts_json="null"; else last_main_ts_json="\"$last_main_ts\""; fi
  if [[ -z "$last_main_sha" ]]; then last_main_sha_json="null"; else last_main_sha_json="\"$last_main_sha\""; fi
  if [[ -z "$policy_path" ]]; then policy_path_json="null"; else policy_path_json="\"$policy_path\""; fi
  if [[ "$staleness_hours" == "null" ]]; then staleness_json="null"; else staleness_json="$staleness_hours"; fi

  entry="$(jq -nc \
    --arg name "$name" \
    --arg slug "$slug" \
    --arg branch "$default_branch" \
    --arg status "$repo_status" \
    --argjson staleness "$staleness_json" \
    --argjson threshold "$threshold_hours" \
    --argjson sha "$last_main_sha_json" \
    --argjson ts "$last_main_ts_json" \
    --argjson policy_present "$policy_present" \
    --argjson policy_path "$policy_path_json" \
    --argjson error "$error_msg" \
    '{
      name:$name,
      slug:$slug,
      default_branch:$branch,
      staleness_hours:$staleness,
      threshold_hours:$threshold,
      status:$status,
      last_main_sha:$sha,
      last_main_ts:$ts,
      policy_present:$policy_present,
      policy_path:$policy_path,
      error:$error
    }')"
  PER_REPO="$(jq -c --argjson e "$entry" '. + [$e]' <<<"$PER_REPO")"
done < <(printf '%s' "$PUBLIC_REPOS_JSON" | jq -c '.[]')

# ---------- aggregate ----------
if [[ "$CRITICAL" -gt 0 ]]; then
  AGG_STATUS="critical"
elif [[ "$STALE" -gt 0 ]] || [[ "$UNKNOWN" -gt 0 ]]; then
  AGG_STATUS="degraded"
else
  AGG_STATUS="ok"
fi

if [[ "$WORST_HOURS" == "-1" ]]; then
  WORST_HOURS_JSON="null"
else
  WORST_HOURS_JSON="$WORST_HOURS"
fi

WORST_REPO_DISPLAY="$(printf '%s' "$WORST_REPO" | jq -r '. // "n/a"')"
WORST_HOURS_DISPLAY="$(printf '%s' "$WORST_HOURS_JSON" | jq -r '. // "n/a"')"
DASHBOARD_LINE="Public repo freshness: ${FRESH}/${TOTAL} fresh, ${STALE} stale, ${CRITICAL} critical (worst=${WORST_REPO_DISPLAY}:${WORST_HOURS_DISPLAY}h)"

TS="$(date -u -r "$NOW_EPOCH" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

ENVELOPE="$(jq -nc \
  --arg sv "$SCHEMA_VERSION" \
  --arg ts "$TS" \
  --arg status "$AGG_STATUS" \
  --arg owner "$OWNER" \
  --argjson per_repo "$PER_REPO" \
  --argjson total "$TOTAL" \
  --argjson fresh "$FRESH" \
  --argjson stale "$STALE" \
  --argjson critical "$CRITICAL" \
  --argjson unknown "$UNKNOWN" \
  --argjson worst_repo "$WORST_REPO" \
  --argjson worst_hours "$WORST_HOURS_JSON" \
  --arg dashboard "$DASHBOARD_LINE" \
  '{
    schema_version:$sv,
    ts:$ts,
    status:$status,
    owner:$owner,
    per_repo:$per_repo,
    aggregate:{
      total:$total,
      fresh:$fresh,
      stale:$stale,
      critical:$critical,
      unknown:$unknown,
      worst_repo:$worst_repo,
      worst_staleness_hours:$worst_hours
    },
    dashboard_line:$dashboard
  }')"

printf '%s\n' "$ENVELOPE"
if [[ "$QUIET" -eq 0 ]]; then
  printf '%s\n' "$DASHBOARD_LINE" >&2
fi

case "$AGG_STATUS" in
  ok|degraded) exit 0 ;;
  critical) exit 1 ;;
esac
