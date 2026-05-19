#!/usr/bin/env bash
set -euo pipefail

SOURCE="${FLYWHEEL_REPO_LIB_SOURCE:-$HOME/.claude/skills/.flywheel/lib/repo.d/part-01-repo_dirty_count-to-repo_infisical_state.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/repo-local-floor-root.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# shellcheck source=/dev/null
source "$SOURCE"

# shellcheck disable=SC2034
REPO_ABS=/
out="$(repo_local_cli_floor_json)"
printf '%s\n' "$out" >"$TMP/out.json"

jq -e '
  .schema_version == "repo-local-cli-floor/v1"
  and .status == "warn-not-scan"
  and .reason == "bare_root_repo_abs"
  and .checked_count == 0
  and .repo_local_clis_below_canonical_floor == 0
  and (.warnings[0].code == "repo_local_cli_floor_refused_bare_root")
' "$TMP/out.json" >/dev/null

printf 'PASS repo_local_cli_floor_json refuses REPO_ABS=/ with warn-not-scan\n'
