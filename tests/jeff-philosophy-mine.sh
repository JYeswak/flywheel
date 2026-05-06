#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-philosophy-mine.sh"
CHECK_CLI="$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-philosophy-mine.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

if bash -n "$SCRIPT"; then pass "script_syntax"; else fail "script_syntax"; fi
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck "$SCRIPT"; then pass "script_shellcheck"; else fail "script_shellcheck"; fi
fi

repo_root="$TMP/jeff-corpus"
state_dir="$TMP/state"
mkdir -p "$repo_root/repo_alpha/docs" "$repo_root/repo_beta/docs" "$repo_root/repo_gamma/docs" "$state_dir"

cat >"$TMP/patterns.md" <<'EOF'
doctor health repair substrate triad
idempotency fail-closed replay conflict handling
schema_version migration compatibility contract
callback receipt evidence envelope
audit jsonl provenance append log
frontmatter validation schema parser
fixture golden deterministic replay tests
lock ttl stale owner metadata
state machine transition invariant proof
failure taxonomy reason code typed errors
structured logging contract event envelope
why audit provenance trace command
EOF

cp "$TMP/patterns.md" "$repo_root/repo_alpha/docs/patterns.md"
cp "$TMP/patterns.md" "$repo_root/repo_beta/docs/patterns.md"
cp "$TMP/patterns.md" "$repo_root/repo_gamma/docs/patterns.md"

"$SCRIPT" --info --json --repo-root "$repo_root" --state-dir "$state_dir" >"$TMP/info.json"
assert_jq "$TMP/info.json" '.schema_version == "jeff-philosophy-info/v1" and .status == "pass" and (.commands | index("deep-mine"))' "info_json"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "jeff-philosophy/schema/v1" and (.commands | index("daily-snapshot")) and (.deep_mine_required_fields | index("pattern_class"))' "schema_json"

"$SCRIPT" --doctor --json --repo-root "$repo_root" --state-dir "$state_dir" >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.schema_version == "jeff-philosophy-doctor/v1" and .status == "pass" and .checks.repo_root_exists == true' "doctor_json"

"$SCRIPT" --deep-mine --json --repo-root "$repo_root" --state-dir "$state_dir" --report-path "$TMP/deep-report.md" --search-timeout 5 >"$TMP/deep.json"
assert_jq "$TMP/deep.json" '.schema_version == "jeff-philosophy-deep-mine-run/v1" and .status == "pass" and .pattern_count >= 10 and .complete_pattern_count >= 10' "deep_mine_json"
if test -s "$state_dir/patterns.jsonl"; then pass "patterns_jsonl_written"; else fail "patterns_jsonl_written"; fi
if jq -s 'length >= 10 and all(.[]; .evidence_repo_count >= 3 and (.evidence | length) >= 3)' "$state_dir/patterns.jsonl" >/dev/null; then pass "patterns_have_three_repo_evidence"; else fail "patterns_have_three_repo_evidence"; fi
if test -s "$TMP/deep-report.md"; then pass "deep_mine_report_written"; else fail "deep_mine_report_written"; fi

"$SCRIPT" validate patterns --json --repo-root "$repo_root" --state-dir "$state_dir" >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.status == "pass" and .rows >= 10 and .complete_rows == .rows' "validate_patterns"

"$SCRIPT" why doctor-health-repair-triad --json --repo-root "$repo_root" --state-dir "$state_dir" >"$TMP/why.json"
assert_jq "$TMP/why.json" '.status == "pass" and .pattern.pattern_class == "doctor-health-repair-triad"' "why_pattern"

"$SCRIPT" --pattern schema-version-migration --json --repo-root "$repo_root" --state-dir "$TMP/pattern-state" --report-path "$TMP/pattern-report.md" --search-timeout 5 >"$TMP/pattern.json"
assert_jq "$TMP/pattern.json" '.status == "pass" and .pattern_count == 1 and .patterns[0].pattern_class == "schema-version-migration"' "focused_pattern"

cat >"$TMP/fake-report.md" <<'EOF'
# Jeff Daily Report

## Aggregate "What can we learn" digest
Verdict: YES_ADOPT
EOF
cat >"$TMP/fake-daily.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
jq -n --arg report "$TMP/fake-report.md" '{status:"pass", report_path:\$report}'
EOF
chmod +x "$TMP/fake-daily.sh"

JEFF_PHILOSOPHY_DAILY_DIFF_BIN="$TMP/fake-daily.sh" "$SCRIPT" --daily-snapshot --json --repo-root "$repo_root" --state-dir "$state_dir" --now 2026-05-05T06:00:00Z >"$TMP/daily.json"
assert_jq "$TMP/daily.json" '.status == "pass" and (.snapshot_path | endswith("2026-05-05.md"))' "daily_snapshot_json"
if test -s "$state_dir/daily-snapshots/2026-05-05.md"; then pass "daily_snapshot_written"; else fail "daily_snapshot_written"; fi

"$SCRIPT" repair --dry-run --json --repo-root "$repo_root" --state-dir "$state_dir" >"$TMP/repair.json"
assert_jq "$TMP/repair.json" '.status == "pass" and .dry_run == true' "repair_dry_run"

if "$SCRIPT" completion bash >/dev/null; then pass "completion_bash"; else fail "completion_bash"; fi
if "$SCRIPT" doctor --help >/dev/null; then pass "doctor_help"; else fail "doctor_help"; fi
if "$SCRIPT" health --help >/dev/null; then pass "health_help"; else fail "health_help"; fi
if "$SCRIPT" completion --help >/dev/null; then pass "completion_help"; else fail "completion_help"; fi

if [[ -x "$CHECK_CLI" ]]; then
  if "$CHECK_CLI" "$SCRIPT" >/dev/null; then pass "canonical_cli_scoping_probe"; else fail "canonical_cli_scoping_probe"; fi
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL jeff-philosophy-mine tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS jeff-philosophy-mine tests pass=%s fail=%s\n' "$pass_count" "$fail_count"
