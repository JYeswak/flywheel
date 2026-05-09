#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLI="$ROOT/.flywheel/scripts/jeff-shadow-socraticode.sh"
DAILY="$ROOT/.flywheel/scripts/daily-jeff-ingest.sh"
STATUS_MD="$HOME/.claude/commands/flywheel/status.md"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-shadow-socraticode-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

mkdir -p "$TMP/bin" "$TMP/state" "$TMP/shadow"
cat >"$TMP/bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = "-C" ]; then
  dir="$2"
  shift 2
  case "${1:-}" in
    fetch) exit 0 ;;
    rev-parse) basename "$dir" | shasum -a 1 | awk '{print substr($1,1,12)}'; exit 0 ;;
  esac
fi
if [ "${1:-}" = "clone" ]; then
  target="${@: -1}"
  mkdir -p "$target/.git"
  exit 0
fi
exit 1
EOF
chmod +x "$TMP/bin/git"
export PATH="$TMP/bin:$PATH"
export JEFF_SHADOW_ROOT="$TMP/shadow"
export JEFF_SHADOW_STATE_DIR="$TMP/state"

bash -n "$CLI" && pass "helper bash syntax" || fail "helper bash syntax"
bash -n "$DAILY" && pass "daily bash syntax" || fail "daily bash syntax"

"$CLI" info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '(.canonical_repos | length == 8) and (.canonical_repos | index("ntm")) and (.canonical_repos | index("frankensqlite"))' "info lists canonical repos"

"$CLI" refresh --apply --json >"$TMP/refresh.json"
assert_jq "$TMP/refresh.json" '.status == "pass" and .repo_count == 8 and .cloned_count == 8 and .failed_count == 0' "refresh clones canonical repos"
[ -s "$TMP/shadow/README.md" ] && pass "readonly marker exists" || fail "readonly marker exists"

for repo in ntm beads_rust destructive_command_guard cass_memory_system meta_skill mcp_agent_mail mcp_agent_mail_rust frankensqlite; do
  "$CLI" record-index --repo "$repo" --chunks 1 --json >/dev/null
done
"$CLI" status --json >"$TMP/status.json"
assert_jq "$TMP/status.json" '.status == "pass" and .indexed_count == 8 and .repo_count == 8 and (.dashboard_line | startswith("jeff-shadow: 8/8 repos indexed"))' "status dashboard line"

DAILY_JEFF_SHADOW_SOCRATICODE_SCRIPT="$CLI" "$DAILY" --info --json >"$TMP/daily-info.json"
assert_jq "$TMP/daily-info.json" '.jeff_shadow_script == "'$CLI'" and (.mutates | index("jeff-shadow clone/fetch refresh"))' "daily ingest names jeff-shadow helper"

grep -q 'jeff-shadow:' "$STATUS_MD" \
  && pass "status command renders jeff-shadow line" \
  || fail "status command renders jeff-shadow line"
grep -q 'jeff-shadow-socraticode.sh status --json' "$STATUS_MD" \
  && pass "status command names helper" \
  || fail "status command names helper"

if [ "$fail_count" -gt 0 ]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
