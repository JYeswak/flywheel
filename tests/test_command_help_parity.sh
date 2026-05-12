#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/command-help-parity-audit.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/command-help-parity.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass() { printf 'PASS %s\n' "$1"; }

bash -n "$BIN"
pass "syntax"

"$BIN" --json >"$TMP/audit.json"
jq -e '.status == "pass" and (.commands | length == 6) and .parity_fixture.equivalent_receipt_fields == true' "$TMP/audit.json" >/dev/null
pass "audit_pass"

"$BIN" parity-fixture --json >"$TMP/parity.json"
jq -e '.command == "tick" and (.claude.receipt_fields == .codex.receipt_fields)' "$TMP/parity.json" >/dev/null
pass "tick_parity_fixture"

fixture="$TMP/commands"
mkdir -p "$fixture"
cp "$HOME"/.claude/commands/flywheel/{loop,cron,tick,worker-tick,deep-audit,adopt}.md "$fixture"/
perl -0pi -e 's/--help-best-for/--help-bestxfor/g' "$fixture/tick.md"
set +e
"$BIN" --command-dir "$fixture" --json >"$TMP/missing.json"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
jq -e '.status == "fail" and (.errors[] | select(.code == "command_help_sections_missing" and .command == "tick" and (.missing | index("--help-best-for"))))' "$TMP/missing.json" >/dev/null
pass "missing_help_best_for_fails"
