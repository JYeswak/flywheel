#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/parity-contract-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/parity-contract-validator.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

pass_case() {
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$1"
}

fail_case() {
  fail=$((fail + 1))
  printf 'not ok %d - %s\n' "$((pass + fail))" "$1" >&2
}

assert_jq() {
  local file="$1" expr="$2" name="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass_case "$name"
  else
    fail_case "$name"
    cat "$file" >&2
  fi
}

assert_file_contains() {
  local file="$1" pattern="$2" name="$3"
  if grep -qE "$pattern" "$file"; then
    pass_case "$name"
  else
    fail_case "$name"
    [[ -f "$file" ]] && cat "$file" >&2
  fi
}

mkdir -p "$TMP/repo/.flywheel/scripts" "$TMP/repo/.flywheel/audits" "$TMP/repo/tests"

cat >"$TMP/repo/.flywheel/scripts/no-fixture.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --dry-run) printf '{"computation":{"value":1}}\n' ;;
  --apply) printf '{"computation":{"value":1}}\n' ;;
esac
SH

cat >"$TMP/repo/.flywheel/scripts/missing-parity.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --dry-run) printf '{"plan":["a"]}\n' ;;
  --apply) printf '{"plan":["a"]}\n' ;;
esac
SH

cat >"$TMP/repo/tests/missing-parity-smoke.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "only checks syntax"
SH

cat >"$TMP/repo/.flywheel/scripts/has-parity.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --dry-run) printf '{"computation":{"value":2}}\n' ;;
  --apply) printf '{"computation":{"value":2}}\n' ;;
esac
SH

cat >"$TMP/repo/tests/has-parity-smoke.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
# parity_assertion: dry-run and apply envelopes must match.
test_parity_dry_run_apply_envelope() { :; }
SH

cat >"$TMP/repo/.flywheel/scripts/plan-execute.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --plan) printf '{"plan":["x"]}\n' ;;
  --execute) printf '{"plan":["x"]}\n' ;;
esac
SH

cat >"$TMP/repo/tests/plan-execute-smoke.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
# parity_assertion: plan and execute compare the same .computation.
SH

chmod +x "$TMP/repo/.flywheel/scripts/"*.sh "$TMP/repo/tests/"*.sh

"$VALIDATOR" \
  --root "$TMP/repo" \
  --timestamp 2026-05-20T03:00:00Z \
  --json >"$TMP/out1.json"

assert_jq "$TMP/out1.json" '.rows[] | select(.path == ".flywheel/scripts/no-fixture.sh" and .status == "NO-FIXTURE")' "detect synthetic dual-mode script"
assert_jq "$TMP/out1.json" '.rows[] | select(.path == ".flywheel/scripts/missing-parity.sh" and .status == "FAIL")' "identify missing parity assertion"
assert_jq "$TMP/out1.json" '.rows[] | select(.path == ".flywheel/scripts/has-parity.sh" and .status == "PASS")' "identify present parity assertion"
assert_jq "$TMP/out1.json" '.rows[] | select(.path == ".flywheel/scripts/plan-execute.sh" and (.mode_groups | index("plan_execute")) and .status == "PASS")' "classify equivalent mode pair"
assert_jq "$TMP/out1.json" '.summary.total == 4 and .summary.pass == 2 and .summary.fail == 1 and .summary.no_fixture == 1 and .status == "fail"' "emit classifications correctly"

report_path="$TMP/repo/$(jq -r '.report_path' "$TMP/out1.json")"
assert_file_contains "$report_path" '^# Dry-Run/Apply Parity Contract Conformance$' "audit report markdown header"
# shellcheck disable=SC2016
sed -n '/^```json$/,/^```$/p' "$report_path" | sed '1d;$d' >"$TMP/report-envelope.json"
assert_jq "$TMP/report-envelope.json" '.schema_version == "parity-contract-conformance.v1" and (.rows | length == 4)' "audit report embeds valid JSON envelope"

sha1="$(shasum -a 256 "$report_path" | awk '{print $1}')"
"$VALIDATOR" \
  --root "$TMP/repo" \
  --timestamp 2026-05-20T03:00:00Z \
  --json >"$TMP/out2.json"
sha2="$(shasum -a 256 "$report_path" | awk '{print $1}')"
if [[ "$sha1" == "$sha2" ]] && diff -u "$TMP/out1.json" "$TMP/out2.json" >/dev/null; then
  pass_case "idempotent re-scan produces same report"
else
  fail_case "idempotent re-scan produces same report"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -ge 8 ]]
