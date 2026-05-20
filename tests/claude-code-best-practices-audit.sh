#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/claude-code-best-practices-audit.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ccbp-audit.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
}

fixture="$TMP/repo"
skills="$TMP/skills"
hooks="$TMP/hooks"
settings="$TMP/settings.json"
mkdir -p "$fixture/.flywheel/scripts" "$fixture/.flywheel/doctrine" "$fixture/.flywheel/audits" "$fixture/tests" "$fixture/bin"
mkdir -p "$fixture/.beads" "$fixture/docs" "$fixture/scripts"
mkdir -p "$skills/narrow" "$skills/broad"
mkdir -p "$hooks"

cat >"$fixture/.claudeignore" <<'EOF'
.flywheel/jeff-corpus/qdrant-data/
.flywheel/runtime/
.flywheel/state.db*
.flywheel/logs/
.flywheel/**/inventory*.jsonl
node_modules/
__pycache__/
.repo_janitor_workspace/
.flywheel/audits/**/*.jsonl
EOF

{
  printf '# Fixture Map\n\n'
  for dir in $(find "$fixture" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort); do
    printf '| `%s` | fixture |\n' "$dir"
  done
} >"$fixture/REPO-MAP.md"

for file in \
  "$fixture/.flywheel/scripts/CLAUDE.md" \
  "$fixture/.flywheel/doctrine/CLAUDE.md" \
  "$fixture/.flywheel/audits/CLAUDE.md" \
  "$fixture/tests/CLAUDE.md" \
  "$fixture/bin/CLAUDE.md"; do
  cat >"$file" <<'EOF'
# Fixture

## Conventions

- Fixture convention.
EOF
done

cat >"$skills/narrow/SKILL.md" <<'EOF'
---
name: narrow
description: Use when editing payments paths.
applies_to:
  - packages/payments/**
---
# Narrow
Trigger keywords: payments, invoices.
EOF

cat >"$skills/broad/SKILL.md" <<'EOF'
---
name: broad
description: General helper.
---
# Broad
EOF

cat >"$hooks/pretooluse-example.sh" <<'EOF'
#!/usr/bin/env bash
# Fixture hook blocks unsafe writes.
exit 0
EOF
chmod +x "$hooks/pretooluse-example.sh"
cat >"$hooks/flywheel-orch-handshakes-never-gate-on-joshua-gate.sh" <<'EOF'
#!/usr/bin/env bash
exec /tmp/nonexistent "$@"
EOF
chmod +x "$hooks/flywheel-orch-handshakes-never-gate-on-joshua-gate.sh"

jq -n \
  --arg pre "$hooks/pretooluse-example.sh" \
  --arg stop "$hooks/flywheel-orch-handshakes-never-gate-on-joshua-gate.sh" \
  '{
    hooks: {
      PreToolUse: [{matcher: "Bash", hooks: [{type: "command", command: $pre}]}],
      PostToolUse: [],
      Stop: [{matcher: "", hooks: [{type: "command", command: $stop}]}]
    }
  }' >"$settings"

bash -n "$SCRIPT" && pass "script syntax"

json="$TMP/out.json"
"$SCRIPT" --repo "$fixture" --skills-root "$skills" --hooks-root "$hooks" --settings "$settings" --date 2026-05-19 --write-reports --json >"$json"
assert_jq "$json" '.status == "PASS"' "audit passes fixture"
assert_jq "$json" '.pass == 5 and .fail == 0' "five top-level checks pass"
test -f "$fixture/.flywheel/audits/skill-scoping-2026-05-19/REPORT.md" && pass "skill report written" || fail "skill report written"
test -f "$fixture/.flywheel/audits/hooks-inventory-2026-05-19/HOOKS.md" && pass "hooks report written" || fail "hooks report written"
test -f "$fixture/.flywheel/audits/claude-code-best-practices-2026-05-19/SCORECARD.md" && pass "scorecard written" || fail "scorecard written"
grep -q '| SKILL.md files | 2 |' "$fixture/.flywheel/audits/skill-scoping-2026-05-19/REPORT.md" && pass "skill count real" || fail "skill count real"
grep -q '| Potentially broad activation | 1 |' "$fixture/.flywheel/audits/skill-scoping-2026-05-19/REPORT.md" && pass "broad skill flagged" || fail "broad skill flagged"
grep -q 'Retirement Candidates' "$fixture/.flywheel/audits/hooks-inventory-2026-05-19/HOOKS.md" && pass "retirement section present" || fail "retirement section present"
if grep -q 'thin wrapper' "$fixture/.flywheel/audits/hooks-inventory-2026-05-19/HOOKS.md"; then
  pass "retirement candidate flagged"
else
  fail "retirement candidate flagged"
fi

bad="$TMP/bad.json"
rm "$fixture/REPO-MAP.md"
if "$SCRIPT" --repo "$fixture" --skills-root "$skills" --hooks-root "$hooks" --settings "$settings" --date 2026-05-19 --json >"$bad"; then
  fail "missing repo map fails"
else
  pass "missing repo map fails"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
