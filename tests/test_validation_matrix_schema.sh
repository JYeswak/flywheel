#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-surface-validation-driver.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/validation-matrix-schema.XXXXXX")"
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

mkdir -p "$TMP/repo/.flywheel/scripts" "$TMP/repo/tests" "$TMP/bin"

cat >"$TMP/bin/gh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'OPEN\n'
SH
chmod +x "$TMP/bin/gh"

cat >"$TMP/bin/br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '✓ %s [OPEN]\n' "${2:-flywheel-x}"
SH
chmod +x "$TMP/bin/br"

cat >"$TMP/matrix.yaml" <<'YAML'
schema_version: 1
generated_at: "2026-05-07T19:10:00Z"
coverage_summary:
  surfaces_total: 12
  coverage_avg: 5.83
  below_7_count: 7
surfaces:
  - name: activity
    decision: USE
    coverage_score: 8
    callsites:
      - path: .flywheel/scripts/use.sh
        line: 1
    tests:
      - path: tests/test-activity.sh
  - name: summary
    decision: USE
    coverage_score: 8
    callsites:
      - path: .flywheel/scripts/use.sh
        line: 2
    tests:
      - path: tests/test-summary.sh
  - name: dashboard
    decision: USE
    coverage_score: 4
    no_script_use_receipt: interactive operator surface; no script callsite expected
  - name: approve
    decision: WRAP
    coverage_score: 7
    wrapper_script: .flywheel/scripts/ntm-approve-wrapper.sh
    deletion_tripwire: delete when ntm approve emits wrapper-grade receipts
    tests:
      - path: tests/test-approve.sh
  - name: audit
    decision: WRAP
    coverage_score: 7
    wrapper_script: .flywheel/scripts/ntm-audit-wrapper.sh
    deletion_tripwire: delete when ntm audit covers canonical receipt parity
    tests:
      - path: tests/test-audit.sh
  - name: checkpoint
    decision: WRAP
    coverage_score: 7
    wrapper_script: .flywheel/scripts/ntm-checkpoint-wrapper.sh
    deletion_tripwire: delete when ntm checkpoint covers rollback stop conditions
    tests:
      - path: tests/test-checkpoint.sh
  - name: lock
    decision: ISSUE
    coverage_score: 5
    issue_url: https://github.com/Dicklesworthstone/ntm/issues/125
  - name: locks
    decision: ISSUE
    coverage_score: 5
    issue_url: https://github.com/Dicklesworthstone/ntm/issues/127
  - name: review-queue
    decision: ISSUE
    coverage_score: 4
    pending_file_note: pending native-gap proof before upstream filing
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

run_driver() {
  local matrix="$1" out="$2"
  "$SCRIPT" \
    --repo "$TMP/repo" \
    --matrix "$matrix" \
    --ledger "$TMP/ledger.jsonl" \
    --run-tests never \
    --gh-bin "$TMP/bin/gh" \
    --br-bin "$TMP/bin/br" \
    --dry-run \
    --json >"$out"
}

mutate() {
  local src="$1" dst="$2" mode="$3"
  python3 - "$src" "$dst" "$mode" <<'PY'
import sys
import yaml

src, dst, mode = sys.argv[1:4]
data = yaml.safe_load(open(src, encoding="utf-8"))
if mode == "typo":
    data["surfaces"][0]["name"] = "actvity"
elif mode == "wrap_without_tripwire":
    data["surfaces"][0]["decision"] = "WRAP"
    data["surfaces"][0]["wrapper_script"] = ".flywheel/scripts/ntm-activity-wrapper.sh"
    data["surfaces"][0].pop("deletion_tripwire", None)
elif mode == "issue_without_url":
    for row in data["surfaces"]:
        if row["name"] == "lock":
            row.pop("issue_url", None)
            row.pop("pending_file_note", None)
            break
elif mode == "coverage_mismatch":
    data["coverage_summary"]["coverage_avg"] = 9.9
else:
    raise SystemExit(f"unknown mode {mode}")
with open(dst, "w", encoding="utf-8") as handle:
    yaml.safe_dump(data, handle, sort_keys=False)
PY
}

bash -n "$SCRIPT" && pass "driver syntax" || fail "driver syntax"
"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.matrix_schema."$schema" == "https://json-schema.org/draft/2020-12/schema" and .matrix_schema_version == "ntm-surface-validation-matrix.schema.v1"' "driver exposes draft 2020-12 matrix schema"

run_driver "$TMP/matrix.yaml" "$TMP/valid.json"
assert_jq "$TMP/valid.json" '.matrix_validation.status == "pass" and .matrix_validation.schema.status == "pass" and .matrix_validation.semantic.status == "pass"' "valid matrix passes duo"
assert_jq "$TMP/valid.json" '.decision_counts.USE == 3 and .decision_counts.WRAP == 3 and .decision_counts.ISSUE == 3 and .decision_counts.EXCLUDED == 3' "fixture covers three surfaces per decision"

mutate "$TMP/matrix.yaml" "$TMP/typo.yaml" typo
run_driver "$TMP/typo.yaml" "$TMP/typo.json"
assert_jq "$TMP/typo.json" '.matrix_validation.status == "fail" and (.matrix_validation.schema.errors + .matrix_validation.semantic.errors | any(.code == "schema_validation_error" or .code == "unknown_surface_name"))' "typo in surface name fails"

mutate "$TMP/matrix.yaml" "$TMP/wrap.yaml" wrap_without_tripwire
run_driver "$TMP/wrap.yaml" "$TMP/wrap.json"
assert_jq "$TMP/wrap.json" '.matrix_validation.status == "fail" and (.matrix_validation.schema.errors + .matrix_validation.semantic.errors | any(.code == "schema_validation_error" or .code == "wrap_missing_deletion_tripwire"))' "USE to WRAP without tripwire fails"

mutate "$TMP/matrix.yaml" "$TMP/issue.yaml" issue_without_url
run_driver "$TMP/issue.yaml" "$TMP/issue.json"
assert_jq "$TMP/issue.json" '.matrix_validation.status == "fail" and (.matrix_validation.semantic.errors | any(.code == "issue_missing_url_or_pending_file_note"))' "ISSUE without URL or pending note fails"

mutate "$TMP/matrix.yaml" "$TMP/coverage.yaml" coverage_mismatch
run_driver "$TMP/coverage.yaml" "$TMP/coverage.json"
assert_jq "$TMP/coverage.json" '.matrix_validation.status == "fail" and (.matrix_validation.semantic.errors | any(.code == "coverage_avg_mismatch"))' "coverage summary mismatch fails"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
