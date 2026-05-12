#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-surface-validation-driver.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-validation-driver.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

mkdir -p "$TMP/repo/.flywheel/scripts" "$TMP/repo/tests" "$TMP/bin" "$TMP/state"

cat >"$TMP/repo/.flywheel/scripts/use-surfaces.sh" <<'SH'
#!/usr/bin/env bash
ntm activity --json >/dev/null
ntm summary --json >/dev/null
ntm health --json >/dev/null
SH
chmod +x "$TMP/repo/.flywheel/scripts/use-surfaces.sh"

for name in activity summary health approve audit checkpoint; do
  cat >"$TMP/repo/tests/test-$name.sh" <<SH
#!/usr/bin/env bash
set -euo pipefail
printf 'fixture $name\\n'
SH
  chmod +x "$TMP/repo/tests/test-$name.sh"
done

for wrapper in approve audit checkpoint; do
  cat >"$TMP/repo/.flywheel/scripts/ntm-$wrapper-wrapper.sh" <<SH
#!/usr/bin/env bash
set -euo pipefail
ntm $wrapper --json >/dev/null
SH
  chmod +x "$TMP/repo/.flywheel/scripts/ntm-$wrapper-wrapper.sh"
done

cat >"$TMP/bin/gh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_GH_LOG:?}"
printf 'OPEN\n'
SH
chmod +x "$TMP/bin/gh"

cat >"$TMP/bin/br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_BR_LOG:?}"
printf '✓ %s [OPEN]\n' "${2:-flywheel-x}"
SH
chmod +x "$TMP/bin/br"

cat >"$TMP/matrix.yaml" <<'YAML'
schema_version: 1
coverage_summary:
  coverage_avg: 7.6
surfaces:
  - name: activity
    decision: USE
    coverage_score: 8
    tests:
      - path: tests/test-activity.sh
  - name: summary
    decision: USE
    coverage_score: 8
    tests:
      - path: tests/test-summary.sh
  - name: health
    decision: USE
    coverage_score: 8
    tests:
      - path: tests/test-health.sh
  - name: approve
    decision: WRAP
    coverage_score: 7
    wrapper_script: .flywheel/scripts/ntm-approve-wrapper.sh
    tests:
      - path: tests/test-approve.sh
  - name: audit
    decision: WRAP
    coverage_score: 7
    wrapper_script: .flywheel/scripts/ntm-audit-wrapper.sh
    tests:
      - path: tests/test-audit.sh
  - name: checkpoint
    decision: WRAP
    coverage_score: 7
    wrapper_script: .flywheel/scripts/ntm-checkpoint-wrapper.sh
    tests:
      - path: tests/test-checkpoint.sh
  - name: lock
    decision: ISSUE
    coverage_score: 6
    jeff_issue: 124
    tracking_bead: flywheel-lock
  - name: unlock
    decision: ISSUE
    coverage_score: 6
    jeff_issue: 125
    tracking_bead: flywheel-unlock
  - name: redact
    decision: ISSUE
    coverage_score: 6
    jeff_issue: 126
    tracking_bead: flywheel-redact
  - name: add
    decision: EXCLUDED
    coverage_score: 5
    receipt: no-fit fixture
  - name: tutorial
    decision: EXCLUDED
    coverage_score: 5
    receipt: interactive fixture
  - name: zoom
    decision: EXCLUDED
    coverage_score: 5
    receipt: visual fixture
YAML

chmod +x "$SCRIPT"
bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "ntm-surface-validation-driver" and (.doctor_fields | index("ntm_surface_coverage_avg")) and .dry_run == true' "info exposes doctor field"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "ntm-surface-validation-driver.v1" and (.required | index("ntm_surface_coverage_avg"))' "schema exposes coverage field"

"$SCRIPT" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 4' "examples surface"

FAKE_GH_LOG="$TMP/gh.log" FAKE_BR_LOG="$TMP/br.log" "$SCRIPT" \
  --repo "$TMP/repo" \
  --matrix "$TMP/matrix.yaml" \
  --ledger "$TMP/ledger.jsonl" \
  --run-tests always \
  --gh-bin "$TMP/bin/gh" \
  --br-bin "$TMP/bin/br" \
  --json >"$TMP/out.json"

assert_jq "$TMP/out.json" '.status == "pass" and .surfaces_total == 12 and .status_counts.PASS == 12 and .ntm_surface_coverage_avg == 6.5 and .ledger_written == true' "fixture matrix all decisions pass"
assert_jq "$TMP/out.json" '.decision_counts.USE == 3 and .decision_counts.WRAP == 3 and .decision_counts.ISSUE == 3 and .decision_counts.EXCLUDED == 3' "three surfaces per decision class"
assert_jq "$TMP/out.json" 'all(.surfaces[]; .status == "PASS")' "all fixture surfaces pass"
test "$(wc -l <"$TMP/ledger.jsonl" | tr -d ' ')" = "1" && pass "ledger appended once" || fail "ledger appended once"
grep -q 'issue view 124' "$TMP/gh.log" && pass "gh issue probe invoked" || fail "gh issue probe invoked"
grep -q 'show flywheel-lock' "$TMP/br.log" && pass "br tracking bead probe invoked" || fail "br tracking bead probe invoked"

FAKE_GH_LOG="$TMP/gh2.log" FAKE_BR_LOG="$TMP/br2.log" "$SCRIPT" \
  --repo "$TMP/repo" \
  --matrix "$TMP/matrix.yaml" \
  --ledger "$TMP/dry.jsonl" \
  --run-tests always \
  --gh-bin "$TMP/bin/gh" \
  --br-bin "$TMP/bin/br" \
  --dry-run \
  --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.ledger_written == false' "dry run suppresses ledger append"
test ! -e "$TMP/dry.jsonl" && pass "dry ledger absent" || fail "dry ledger absent"

cat >>"$TMP/matrix.yaml" <<'YAML'
  - name: missing-use
    decision: USE
    coverage_score: 1
    tests:
      - path: tests/test-health.sh
YAML

set +e
FAKE_GH_LOG="$TMP/gh3.log" FAKE_BR_LOG="$TMP/br3.log" "$SCRIPT" \
  --repo "$TMP/repo" \
  --matrix "$TMP/matrix.yaml" \
  --ledger "$TMP/strict.jsonl" \
  --run-tests always \
  --gh-bin "$TMP/bin/gh" \
  --br-bin "$TMP/bin/br" \
  --strict \
  --json >"$TMP/strict.json"
strict_rc=$?
set -e
if [[ "$strict_rc" == "1" ]]; then pass "strict exits nonzero on fail"; else fail "strict exits nonzero on fail rc=$strict_rc"; fi
assert_jq "$TMP/strict.json" '.status == "fail" and any(.surfaces[]; .name == "missing-use" and .status == "FAIL")' "strict reports failing use surface"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
