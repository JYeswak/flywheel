#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/cross-repo-inheritance-audit.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
  exit 1
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

mkdir -p "$TMP/canonical" "$TMP/full/.flywheel/doctrine/meta-learnings" "$TMP/partial/.flywheel/doctrine/meta-learnings" "$TMP/partial/state/legal-house"

for id in 01 02 03; do
  printf '# MP-%s\n\ncanonical %s\n' "$id" "$id" >"$TMP/canonical/MP-$id-example.md"
  cp "$TMP/canonical/MP-$id-example.md" "$TMP/full/.flywheel/doctrine/meta-learnings/MP-$id-example.md"
done

cp "$TMP/canonical/MP-01-example.md" "$TMP/partial/.flywheel/doctrine/meta-learnings/MP-01-example.md"
printf '\nlocal divergence\n' >>"$TMP/partial/.flywheel/doctrine/meta-learnings/MP-01-example.md"
printf '# Adoption\n' >"$TMP/full/META-PATTERN-ADOPTION.md"
printf '# Discrepancies\n' >"$TMP/full/DISCREPANCIES.md"
printf 'legal fixture should be counted, not read\n' >"$TMP/partial/state/legal-house/fixture.md"

bash -n "$SCRIPT" && pass "script_syntax"

"$SCRIPT" --json --expected-count 3 --canonical-dir "$TMP/canonical" \
  --repo full="$TMP/full" \
  --repo partial="$TMP/partial" >"$TMP/run1.jsonl"
"$SCRIPT" --json --expected-count 3 --canonical-dir "$TMP/canonical" \
  --repo full="$TMP/full" \
  --repo partial="$TMP/partial" >"$TMP/run2.jsonl"

sed -E 's/"generated_at":"[^"]+"/"generated_at":"<ts>"/g' "$TMP/run1.jsonl" >"$TMP/run1.norm"
sed -E 's/"generated_at":"[^"]+"/"generated_at":"<ts>"/g' "$TMP/run2.jsonl" >"$TMP/run2.norm"
cmp "$TMP/run1.norm" "$TMP/run2.norm" >/dev/null && pass "json_idempotent"

jq -s '.' "$TMP/run1.jsonl" >"$TMP/run1.json"
assert_jq "$TMP/run1.json" 'length == 2' "two_repo_rows"
assert_jq "$TMP/run1.json" '.[] | select(.repo == "full") | .next_action == "OK" and .present_mp_count == 3 and .divergence_count == 0' "full_repo_ok"
assert_jq "$TMP/run1.json" '.[] | select(.repo == "partial") | .next_action == "PROPAGATE" and .present_mp_count == 1 and .missing_mps == ["MP-02","MP-03"] and .divergence_count == 1 and .skipped_track2_count == 1' "partial_repo_reports_gaps"

"$SCRIPT" --write-report --expected-count 3 --canonical-dir "$TMP/canonical" \
  --output-dir "$TMP/out" \
  --repo full="$TMP/full" \
  --repo partial="$TMP/partial"
test -f "$TMP/out/INHERITANCE.md" && test -f "$TMP/out/inheritance.jsonl" && pass "report_written"
grep -q 'skipped_track2_count: 1' "$TMP/out/INHERITANCE.md" && pass "track2_skip_count_reported"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
