#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-skill-scan-budget.py"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t codex-skill-scan-budget.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/root/a" "$TMP/root/b" "$TMP/root/c"
printf '# skill\n' >"$TMP/root/a/SKILL.md"
cat >"$TMP/config-with-mcp.toml" <<'EOF'
[mcp_servers.skill-search]
command = "/Users/josh/.claude/skills/skill-search-mcp/scripts/run-server.sh"
EOF
cat >"$TMP/config-without-mcp.toml" <<'EOF'
[mcp_servers.other]
command = "true"
EOF

if python3 -m py_compile "$SCRIPT" 2>/dev/null; then
  pass "python syntax"
else
  fail "python syntax"
fi

out="$(python3 "$SCRIPT" --root "$TMP/root" --config "$TMP/config-with-mcp.toml" --cap 2 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "pass" and .blocker_disposition == "not_blocking" and (.warning_codes | index("INTERNAL_SCAN_CAP_EXCEEDED_BUT_MCP_CONFIGURED"))' >/dev/null; then
  pass "over-cap root is non-blocking when skill-search MCP is configured"
else
  fail "configured MCP over-cap classification"
fi

set +e
out="$(python3 "$SCRIPT" --root "$TMP/root" --config "$TMP/config-without-mcp.toml" --cap 2 2>/dev/null)"
rc=$?
set -e
if [[ "$rc" -eq 1 ]] && printf '%s' "$out" | jq -e '.status == "fail" and .blocker_disposition == "blocking" and (.failure_codes | index("SKILL_SEARCH_MCP_NOT_CONFIGURED"))' >/dev/null; then
  pass "over-cap root blocks without skill-search MCP"
else
  fail "missing MCP should block"
fi

out="$(python3 "$SCRIPT" --root "$TMP/root" --config "$TMP/config-without-mcp.toml" --cap 50 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "pass" and .skill_search_mcp_configured == false and (.warning_codes | length == 0)' >/dev/null; then
  pass "under-cap root does not require MCP fallback"
else
  fail "under-cap root"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
