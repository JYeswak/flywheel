#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: review-branch-mergeback-fleet-rollout.sh (--dry-run|--apply) [--json]

Override REVIEW_BRANCH_MERGEBACK_REPOS as:
  name:/absolute/repo:review/branch:main;name2:/repo:review/branch:main
USAGE
}

json_escape() {
  local value=${1-}
  value=${value//\\/\\\\}; value=${value//\"/\\\"}; value=${value//$'\n'/\\n}; value=${value//$'\r'/\\r}; value=${value//$'\t'/\\t}
  printf '%s' "$value"
}
json_string() { printf '"%s"' "$(json_escape "${1-}")"; }

mode=""; json=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|--apply) mode=${1#--}; shift ;;
    --json) json=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
: "${json:=0}"
[[ -n $mode ]] || { usage; exit 2; }

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
installer="$script_dir/install-review-branch-mergeback-launchd.sh"
[[ -x $installer ]] || { printf '{"schema_version":"review_branch_mergeback_fleet_rollout.v1","outcome":"error","reason":"installer-not-executable"}\n'; exit 1; }

repo_specs=("flywheel:/Users/josh/Developer/flywheel:review/flywheel-2.0-private-20260513:main")
if [[ -n ${REVIEW_BRANCH_MERGEBACK_REPOS:-} ]]; then
  IFS=';' read -r -a repo_specs <<< "$REVIEW_BRANCH_MERGEBACK_REPOS"
fi

tmp_results=$(mktemp)
trap 'rm -f "$tmp_results"' EXIT
for spec in "${repo_specs[@]}"; do
  IFS=':' read -r name path branch base <<< "$spec"
  base=${base:-main}
  if [[ -z ${name:-} || -z ${path:-} || -z ${branch:-} ]]; then
    printf '{"name":'; json_string "${name:-unknown}"; printf ',"outcome":"skipped","reason":"invalid-spec"}\n' >> "$tmp_results"; continue
  fi
  if [[ ! -d $path ]]; then
    printf '{"name":'; json_string "$name"; printf ',"repo":'; json_string "$path"; printf ',"outcome":"skipped","reason":"repo-missing"}\n' >> "$tmp_results"; continue
  fi
  if result=$("$installer" --repo "$path" --branch "$branch" --base "$base" "--$mode" --json); then
    {
      printf '{"name":'; json_string "$name"; printf ',"repo":'; json_string "$path"; printf ',"branch":'; json_string "$branch"; printf ',"installer":%s}\n' "$result"
    } >> "$tmp_results"
  else
    {
      printf '{"name":'; json_string "$name"; printf ',"repo":'; json_string "$path"; printf ',"branch":'; json_string "$branch"; printf ',"outcome":"error","reason":'; json_string "$result"; printf '}\n'
    } >> "$tmp_results"
  fi
done

printf '{"schema_version":"review_branch_mergeback_fleet_rollout.v1","mode":'
json_string "$mode"; printf ',"outcome":'; json_string "$mode"; printf ',"repos":['
paste -sd, "$tmp_results"
printf ']}\n'
