#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/codex-hook-parity-probe.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-hook-parity.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

make_codex() {
  local dir="$1"
  mkdir -p "$dir/bin"
  cat >"$dir/bin/codex" <<'SH'
#!/usr/bin/env bash
case "$*" in
  "--version") printf 'codex-cli 0.128.0\n' ;;
  "features list") printf 'codex_hooks stable true\n' ;;
  *) exit 2 ;;
esac
SH
  chmod +x "$dir/bin/codex"
  printf '%s\n' "$dir/bin"
}

write_claude_settings() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": "dcg", "timeout": 3}
        ]
      }
    ]
  }
}
JSON
}

write_codex_config() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<'TOML'
[features]
codex_hooks = true
TOML
}

bin_dir="$(make_codex "$TMP")"
export PATH="$bin_dir:$PATH"

python3 -m py_compile "$PROBE" && pass "syntax"

write_claude_settings "$TMP/claude/settings.json"
write_codex_config "$TMP/codex/config.toml"

audit="$TMP/audit.json"
python3 "$PROBE" \
  --claude-settings "$TMP/claude/settings.json" \
  --codex-config "$TMP/codex/config.toml" \
  --codex-hooks "$TMP/codex/hooks.json" \
  --state-dir "$TMP/state" \
  --now 2026-05-04T00:00:30Z \
  --hook-change-source claude \
  --hook-change-path "$TMP/claude/settings.json" \
  --hook-change-ts 2026-05-04T00:00:00Z \
  --json >"$audit"

assert_jq "$audit" '.status == "pass" and .actions.would_write == true' "AG1 detects Codex hook gap and desired write"
assert_jq "$audit" '.codex.feature.enabled == true and .upstream_issue.needed == false' "AG1 confirms supported Codex hook surface"
assert_jq "$audit" '.hook_change.within_60s == true and .parity_probe_required_within_seconds == 60' "AG3 enforces 60s parity window"
assert_jq "$audit" '.desired_hooks.hooks.PreToolUse[0].hooks[] | select(.command == "dcg" and .timeout == 3)' "AG2 renders Codex dcg PreToolUse hook"

apply_out="$TMP/apply.json"
python3 "$PROBE" \
  --claude-settings "$TMP/claude/settings.json" \
  --codex-config "$TMP/codex/config.toml" \
  --codex-hooks "$TMP/codex/hooks.json" \
  --state-dir "$TMP/state" \
  --apply \
  --json >"$apply_out"

assert_jq "$apply_out" '.status == "pass" and .actions.wrote == true and .codex.dcg_pretooluse_count == 1' "AG2 writes Codex hook config"
test -s "$TMP/codex/hooks.json" && pass "AG2 hooks file exists" || fail "AG2 hooks file exists"
test -s "$TMP/state/receipts.jsonl" && pass "AG3 writes probe receipt" || fail "AG3 writes probe receipt"

late="$TMP/late.json"
if python3 "$PROBE" \
  --claude-settings "$TMP/claude/settings.json" \
  --codex-config "$TMP/codex/config.toml" \
  --codex-hooks "$TMP/codex/hooks.json" \
  --state-dir "$TMP/state" \
  --now 2026-05-04T00:02:00Z \
  --hook-change-source codex \
  --hook-change-path "$TMP/codex/hooks.json" \
  --hook-change-ts 2026-05-04T00:00:00Z \
  --json >"$late"; then
  fail "AG3 late parity probe fails"
else
  assert_jq "$late" '.status == "fail" and (.failure_classes | index("parity_probe_late"))' "AG3 late parity probe fails"
fi

unsupported_bin="$TMP/unsupported/bin"
mkdir -p "$unsupported_bin"
cat >"$unsupported_bin/codex" <<'SH'
#!/usr/bin/env bash
case "$*" in
  "--version") printf 'codex-cli 0.124.0\n' ;;
  "features list") printf 'codex_hooks stable false\n' ;;
  *) exit 2 ;;
esac
SH
chmod +x "$unsupported_bin/codex"
PATH="$unsupported_bin:$PATH" python3 "$PROBE" \
  --claude-settings "$TMP/claude/settings.json" \
  --codex-config "$TMP/missing-config.toml" \
  --codex-hooks "$TMP/unsupported/hooks.json" \
  --issue-draft "$TMP/upstream.md" \
  --json >"$TMP/unsupported.json" && unsupported_rc=0 || unsupported_rc=$?

if [[ "$unsupported_rc" -ne 0 ]]; then
  assert_jq "$TMP/unsupported.json" '.status == "unsupported" and .upstream_issue.needed == true and (.actions.issue_draft_path | test("upstream.md"))' "AG4 drafts upstream issue when unsupported"
else
  fail "AG4 drafts upstream issue when unsupported"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'FAILURES=%s PASSES=%s\n' "$fail_count" "$pass_count"
  exit 1
fi

printf 'PASS all codex hook parity tests (%s)\n' "$pass_count"
