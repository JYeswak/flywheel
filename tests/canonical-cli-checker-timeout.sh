#!/usr/bin/env bash
set -euo pipefail

SOURCE="${FLYWHEEL_REPO_LIB_SOURCE:-$HOME/.claude/skills/.flywheel/lib/repo.d/part-01-repo_dirty_count-to-repo_infisical_state.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/canonical-cli-checker-timeout.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/home/.claude/skills/canonical-cli-scoping/scripts" "$TMP/repo/bin"
git -C "$TMP/repo" init -q

cat >"$TMP/home/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh" <<'EOF'
#!/usr/bin/env bash
sleep 5
EOF
chmod +x "$TMP/home/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh"

cat >"$TMP/repo/bin/hanging-cli" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMP/repo/bin/hanging-cli"

# shellcheck source=/dev/null
source "$SOURCE"

HOME="$TMP/home"
# shellcheck disable=SC2034
REPO_ABS="$TMP/repo"
# shellcheck disable=SC2034
FLYWHEEL_REPO_LOCAL_CLI_CHECK_TIMEOUT_SECONDS=0.1
out="$(repo_local_cli_floor_json)"
printf '%s\n' "$out" >"$TMP/out.json"

jq -e '
  .status == "fail"
  and .check_timeout_seconds == 0.1
  and .rows[0].name == "hanging-cli"
  and .rows[0].exit_code == 124
  and .rows[0].reason == "canonical_cli_checker_timeout"
' "$TMP/out.json" >/dev/null

printf 'PASS repo_local_cli_floor_json times out hanging canonical checker and classifies rc=124\n'
