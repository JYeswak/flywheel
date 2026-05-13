#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/depersonalize.py"
FIXTURE="$ROOT/fixtures/depersonalize/source"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-depersonalize-table.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }
operator_first_name="Josh""ua"
operator_full_name="$operator_first_name Nowak"
telecom_client="Black""foot Telecom"
insurance_client_acronym="AL""PS"
insurance_client_slug="alps-insurance"
insurance_session_short="alps"
operator_company="Zest""Stream"
repo_private_path="$HOME/Developer/flywheel"

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  local rc=$?
  set +e
  return "$rc"
}

if python3 -m py_compile "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

cp -R "$FIXTURE" "$TMP/work"

run_capture "$TMP/scan-before.out" "$TMP/scan-before.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/work" --json
scan_before_rc=$?
if [[ "$scan_before_rc" -eq 40 ]] && jq -e '.status == "fail" and .exit_code == 40 and (.findings[] | select(.row_ids | index("operator-full-name"))) and (.findings[] | select(.row_ids | index("source-repo-path")))' "$TMP/scan-before.out" >/dev/null; then
  pass "scan finds table values"
else
  fail "scan finds table values rc=${scan_before_rc}"
fi

if ! rg -Fq "$operator_full_name" "$TMP/scan-before.out" \
  && ! rg -Fq "$telecom_client" "$TMP/scan-before.out" \
  && ! rg -Fq "$repo_private_path" "$TMP/scan-before.out"; then
  pass "scan omits matched content"
else
  fail "scan omits matched content"
fi

run_capture "$TMP/dry-run.out" "$TMP/dry-run.err" \
  python3 "$SCRIPT" --dry-run --root "$TMP/work" --json
dry_run_rc=$?
if [[ "$dry_run_rc" -eq 0 ]] && jq -e '.status == "pass" and .changed_files == 1 and (.changes[] | select(.path == "public.md" and (.row_ids | index("operator-full-name")) and (.row_ids | index("source-repo-path")) and (.row_ids | index("blackfoot-client")) and (.row_ids | index("alps-client")))) and (.diff | contains("<flywheel-repo>"))' "$TMP/dry-run.out" >/dev/null; then
  pass "dry-run emits reviewable patch"
else
  fail "dry-run emits reviewable patch rc=${dry_run_rc}"
fi

run_capture "$TMP/apply.out" "$TMP/apply.err" \
  python3 "$SCRIPT" --apply --root "$TMP/work" --json
apply_rc=$?
if [[ "$apply_rc" -eq 0 ]] && jq -e '.status == "pass" and .changed_files == 1 and (.changes[] | select(.path == "public.md"))' "$TMP/apply.out" >/dev/null; then
  pass "apply rewrites fixture"
else
  fail "apply rewrites fixture rc=${apply_rc}"
fi

if rg -q '<flywheel-repo>' "$TMP/work/public.md" && ! rg -q '\$HOME/Developer/flywheel' "$TMP/work/public.md"; then
  pass "specific path wins before home path"
else
  fail "specific path wins before home path"
fi

if rg -qF '{insurance-client}' "$TMP/work/public.md" && ! rg -Fq "$insurance_client_acronym Insurance" "$TMP/work/public.md"; then
  pass "full insurance client name rewritten"
else
  fail "full insurance client name rewritten"
fi

run_capture "$TMP/scan-after.out" "$TMP/scan-after.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/work" --json
scan_after_rc=$?
if [[ "$scan_after_rc" -eq 0 ]] && jq -e '.status == "pass" and (.findings | length == 0)' "$TMP/scan-after.out" >/dev/null; then
  pass "post-apply scan clean"
else
  fail "post-apply scan clean rc=${scan_after_rc}"
fi

cp -R "$FIXTURE" "$TMP/filtered"
run_capture "$TMP/filtered.out" "$TMP/filtered.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/filtered" --row-id operator-full-name --json
filtered_rc=$?
if [[ "$filtered_rc" -eq 40 ]] && jq -e '.status == "fail" and ([.findings[].row_ids[]] | unique == ["operator-full-name"])' "$TMP/filtered.out" >/dev/null; then
  pass "row-id filter limits scan scope"
else
  fail "row-id filter limits scan scope rc=${filtered_rc}"
fi

cp "$FIXTURE/public.md" "$TMP/single.md"
run_capture "$TMP/single-file.out" "$TMP/single-file.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/single.md" --json
single_file_rc=$?
if [[ "$single_file_rc" -eq 40 ]] && jq -e '.status == "fail" and (.findings[] | select(.path == "single.md" and (.row_ids | index("operator-full-name"))))' "$TMP/single-file.out" >/dev/null; then
  pass "single-file root scans table values"
else
  fail "single-file root scans table values rc=${single_file_rc}"
fi

mkdir -p "$TMP/allowlisted/brand" "$TMP/unallowlisted"
printf '%s public brand surface\n' "$operator_company" >"$TMP/allowlisted/brand/naming-conventions.md"
printf '%s unreviewed surface\n' "$operator_company" >"$TMP/unallowlisted/other.md"
run_capture "$TMP/allowlisted.out" "$TMP/allowlisted.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/allowlisted" --json
allowlisted_rc=$?
run_capture "$TMP/unallowlisted.out" "$TMP/unallowlisted.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/unallowlisted" --json
unallowlisted_rc=$?
if [[ "$allowlisted_rc" -eq 0 ]] && [[ "$unallowlisted_rc" -eq 40 ]] && jq -e '.status == "pass"' "$TMP/allowlisted.out" >/dev/null && jq -e '.status == "fail" and (.findings[] | select(.row_ids | index("zeststream-company")))' "$TMP/unallowlisted.out" >/dev/null; then
  pass "reviewed allowlist is path scoped"
else
  fail "reviewed allowlist is path scoped allowlisted_rc=${allowlisted_rc} unallowlisted_rc=${unallowlisted_rc}"
fi

mkdir -p "$TMP/deny-fixtures"
: >"$TMP/deny-fixtures/agents-md-fleet-propagator.sh"
: >"$TMP/deny-fixtures/cost-telemetry-token-burn-probe-canonical-cli.sh"
: >"$TMP/deny-fixtures/pane-capture-provenance.sh"
: >"$TMP/deny-fixtures/test_pane_state_dispatch_raw_capture_blocked.sh"
run_capture "$TMP/deny-fixtures.out" "$TMP/deny-fixtures.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/deny-fixtures" --json
deny_fixtures_rc=$?
if [[ "$deny_fixtures_rc" -eq 0 ]] && jq -e '.status == "pass" and (.findings | length == 0)' "$TMP/deny-fixtures.out" >/dev/null; then
  pass "reviewed denylist fixtures are path scoped"
else
  fail "reviewed denylist fixtures are path scoped rc=${deny_fixtures_rc}"
fi

mkdir -p "$TMP/tests" "$TMP/not-tests"
fixture_timestamp="2026-01-02T03:04:05Z"
fixture_bead="flywheel-a1b"
fixture_pane="pane 12"
printf '%s %s %s\n' "$fixture_timestamp" "$fixture_bead" "$fixture_pane" >"$TMP/tests/fixture.md"
printf '%s %s %s\n' "$fixture_timestamp" "$fixture_bead" "$fixture_pane" >"$TMP/not-tests/fixture.md"
run_capture "$TMP/tests-fixtures.out" "$TMP/tests-fixtures.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/tests" --json
tests_fixtures_rc=$?
run_capture "$TMP/not-tests-fixtures.out" "$TMP/not-tests-fixtures.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/not-tests" --json
not_tests_fixtures_rc=$?
if [[ "$tests_fixtures_rc" -eq 0 ]] && [[ "$not_tests_fixtures_rc" -eq 40 ]] \
  && jq -e '.status == "pass" and (.findings | length == 0)' "$TMP/tests-fixtures.out" >/dev/null \
  && jq -e '.status == "fail" and ([.findings[].row_ids[]] | unique == ["bead-id", "iso-timestamp", "pane-number"])' "$TMP/not-tests-fixtures.out" >/dev/null; then
  pass "reviewed runtime fixtures are root scoped"
else
  fail "reviewed runtime fixtures are root scoped tests_rc=${tests_fixtures_rc} not_tests_rc=${not_tests_fixtures_rc}"
fi

mkdir -p "$TMP/apply-tests/tests" "$TMP/apply-tests/docs"
printf '%s %s %s\n' "$fixture_timestamp" "$fixture_bead" "$fixture_pane" >"$TMP/apply-tests/tests/fixture.md"
printf '%s %s %s\n' "$fixture_timestamp" "$fixture_bead" "$fixture_pane" >"$TMP/apply-tests/docs/fixture.md"
run_capture "$TMP/apply-tests.out" "$TMP/apply-tests.err" \
  python3 "$SCRIPT" --apply --root "$TMP/apply-tests" --json
apply_tests_rc=$?
if [[ "$apply_tests_rc" -eq 0 ]] \
  && rg -qF "$fixture_timestamp" "$TMP/apply-tests/tests/fixture.md" \
  && rg -qF "$fixture_bead" "$TMP/apply-tests/tests/fixture.md" \
  && rg -qF "$fixture_pane" "$TMP/apply-tests/tests/fixture.md" \
  && rg -qF "<timestamp>" "$TMP/apply-tests/docs/fixture.md" \
  && rg -qF "{bead-id}" "$TMP/apply-tests/docs/fixture.md" \
  && rg -qF "<pane-id>" "$TMP/apply-tests/docs/fixture.md"; then
  pass "apply preserves reviewed runtime test fixtures"
else
  fail "apply preserves reviewed runtime test fixtures rc=${apply_tests_rc}"
fi

mkdir -p "$TMP/claude-slug"
printf '%s\n' "\$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory/example.md" >"$TMP/claude-slug/path.md"
printf '%s\n' "\$HOME/.claude/projects/-Users-josh-Developer-{session}/memory/example.md" >>"$TMP/claude-slug/path.md"
run_capture "$TMP/claude-slug.out" "$TMP/claude-slug.err" \
  python3 "$SCRIPT" --apply --root "$TMP/claude-slug" --json
claude_slug_rc=$?
if [[ "$claude_slug_rc" -eq 0 ]] \
  && rg -qF '<claude-project-slug>' "$TMP/claude-slug/path.md" \
  && rg -qF '<claude-project-prefix>-{session}' "$TMP/claude-slug/path.md" \
  && ! rg -qF -- '-Users-josh-Developer-flywheel' "$TMP/claude-slug/path.md"; then
  pass "claude project slug rewritten"
else
  fail "claude project slug rewritten rc=${claude_slug_rc}"
fi

mkdir -p "$TMP/client-acronym"
printf '%s root domain appears in a client workflow.\n' "$insurance_client_acronym" >"$TMP/client-acronym/public.md"
run_capture "$TMP/client-acronym-before.out" "$TMP/client-acronym-before.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/client-acronym" --row-id alps-client-acronym --json
client_acronym_before_rc=$?
run_capture "$TMP/client-acronym-apply.out" "$TMP/client-acronym-apply.err" \
  python3 "$SCRIPT" --apply --root "$TMP/client-acronym" --json
client_acronym_apply_rc=$?
if [[ "$client_acronym_before_rc" -eq 40 ]] \
  && [[ "$client_acronym_apply_rc" -eq 0 ]] \
  && jq -e '.status == "fail" and (.findings[] | select(.row_ids | index("alps-client-acronym")))' "$TMP/client-acronym-before.out" >/dev/null \
  && rg -qF '{insurance-client}' "$TMP/client-acronym/public.md" \
  && ! rg -Fq "$insurance_client_acronym" "$TMP/client-acronym/public.md"; then
  pass "insurance client acronym rewritten"
else
  fail "insurance client acronym rewritten scan_rc=${client_acronym_before_rc} apply_rc=${client_acronym_apply_rc}"
fi

mkdir -p "$TMP/lowercase-client-slugs"
{
  printf 'Peer handoff references %s:1 and flywheel/%s/{proof-product}.\n' "$insurance_session_short" "$insurance_session_short"
  printf 'Plain session alias %s should not survive public export.\n' "$insurance_session_short"
  printf 'Legacy path mentions Desktop/Projects/clients/%s.\n' "$insurance_client_slug"
  printf 'Identifier alps_fixture should remain readable as a synthetic variable.\n'
} >"$TMP/lowercase-client-slugs/public.md"
run_capture "$TMP/lowercase-client-slugs-before.out" "$TMP/lowercase-client-slugs-before.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/lowercase-client-slugs" --row-id alps-client-slug --row-id alps-session-label-colon --row-id alps-session-path-fragment --row-id alps-session-standalone --json
lowercase_client_slugs_before_rc=$?
run_capture "$TMP/lowercase-client-slugs-apply.out" "$TMP/lowercase-client-slugs-apply.err" \
  python3 "$SCRIPT" --apply --root "$TMP/lowercase-client-slugs" --json
lowercase_client_slugs_apply_rc=$?
if [[ "$lowercase_client_slugs_before_rc" -eq 40 ]] \
  && [[ "$lowercase_client_slugs_apply_rc" -eq 0 ]] \
  && jq -e '.status == "fail" and ([.findings[].row_ids[]] | unique | contains(["alps-client-slug","alps-session-label-colon","alps-session-path-fragment","alps-session-standalone"]))' "$TMP/lowercase-client-slugs-before.out" >/dev/null \
  && rg -qF '{session}:1' "$TMP/lowercase-client-slugs/public.md" \
  && rg -qF 'flywheel/{session}/{proof-product}' "$TMP/lowercase-client-slugs/public.md" \
  && rg -qF 'Plain session alias {session}' "$TMP/lowercase-client-slugs/public.md" \
  && rg -qF 'Desktop/Projects/clients/{insurance-client}' "$TMP/lowercase-client-slugs/public.md" \
  && rg -qF 'alps_fixture' "$TMP/lowercase-client-slugs/public.md" \
  && ! rg -Fq "$insurance_client_slug" "$TMP/lowercase-client-slugs/public.md" \
  && ! rg -q '(^|[^[:alnum:]_-])alps([^[:alnum:]_-]|$)' "$TMP/lowercase-client-slugs/public.md"; then
  pass "lowercase insurance client slugs rewritten"
else
  fail "lowercase insurance client slugs rewritten scan_rc=${lowercase_client_slugs_before_rc} apply_rc=${lowercase_client_slugs_apply_rc}"
fi

mkdir -p "$TMP/blocked/.ntm"
printf '{}\n' >"$TMP/blocked/.ntm/rate_limits.json"
printf '%s %s\n' "$operator_full_name" "$operator_first_name" >"$TMP/blocked/public.md"
run_capture "$TMP/blocked.out" "$TMP/blocked.err" \
  python3 "$SCRIPT" --dry-run --root "$TMP/blocked" --json
blocked_rc=$?
if [[ "$blocked_rc" -eq 30 ]] && jq -e '.status == "fail" and .exit_code == 30 and (.findings[] | select(.id == "repo-ntm-runtime"))' "$TMP/blocked.out" >/dev/null; then
  pass "denylist blocks codemod"
else
  fail "denylist blocks codemod rc=${blocked_rc}"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$PASS"
