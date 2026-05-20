#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: git-main-sync-fleet-rollout.sh (--dry-run|--apply) [--json]

Set GIT_MAIN_SYNC_REPOS to override the default fleet:
  name:/absolute/path;name2:/absolute/path2
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

mode=""
json=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|--apply)
      mode=${1#--}
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

if [[ -z $mode ]]; then
  usage
  exit 2
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
installer="$script_dir/install-git-main-sync-launchd.sh"
if [[ ! -x $installer ]]; then
  printf '{"schema":"git_main_sync_fleet_rollout.v1","outcome":"error","reason":"installer-not-executable"}\n'
  exit 1
fi

repo_specs=(
  "flywheel:/Users/josh/Developer/flywheel"
  "skillos:/Users/josh/Developer/skillos"
  "zesttube:/Users/josh/Developer/zesttube"
  "mobile-eats:/Users/josh/Developer/mobile-eats"
  "clutterfreespaces:/Users/josh/Developer/clutterfreespaces"
)

if [[ -n ${GIT_MAIN_SYNC_REPOS:-} ]]; then
  IFS=';' read -r -a repo_specs <<< "$GIT_MAIN_SYNC_REPOS"
fi

tmp_results=$(mktemp)
trap 'rm -f "$tmp_results"' EXIT

for spec in "${repo_specs[@]}"; do
  name=${spec%%:*}
  path=${spec#*:}
  if [[ ! -d $path ]]; then
    {
      printf '{"name":'
      json_string "$name"
      printf ',"repo":'
      json_string "$path"
      printf ',"outcome":"skipped","reason":"repo-missing"}\n'
    } >> "$tmp_results"
    continue
  fi
  if ! result=$("$installer" --repo "$path" "--$mode" --json); then
    {
      printf '{"name":'
      json_string "$name"
      printf ',"repo":'
      json_string "$path"
      printf ',"outcome":"error","reason":'
      json_string "$result"
      printf '}\n'
    } >> "$tmp_results"
    continue
  fi
  {
    printf '{"name":'
    json_string "$name"
    printf ',"repo":'
    json_string "$path"
    printf ',"installer":%s}\n' "$result"
  } >> "$tmp_results"
done

printf '{'
printf '"schema":"git_main_sync_fleet_rollout.v1"'
printf ',"ts":'
json_string "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf ',"mode":'
json_string "$mode"
printf ',"outcome":'
json_string "$mode"
printf ',"picoz_excluded":true'
printf ',"excluded":[{"name":"polymarket-pico-z","repo":"/Users/josh/Developer/polymarket-pico-z","reason":"explicit-joshua-gate"}]'
printf ',"repos":['
paste -sd, "$tmp_results"
printf ']}'
printf '\n'

if [[ $json -ne 1 ]]; then
  :
fi
