#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-daily-rollup.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-rollup-doctor-score.XXXXXX")"
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
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

mkdir -p "$TMP/repos/steady/.flywheel/audit" "$TMP/repos/regressed/.flywheel/audit" "$TMP/out"

cat >"$TMP/enabled-repos.sh" <<EOF
#!/usr/bin/env bash
cat <<'JSON'
{
  "schema_version": "daily-report-enabled-repos/v1",
  "repos": [
    {
      "repo": "$TMP/repos/steady",
      "status": "generated",
      "result": {
        "quality_grade": {
          "callback_count": 1,
          "compliance_distribution": {"avg": 920, "median": 920},
          "mission_fitness_counts": {},
          "disposition_counts": {}
        },
        "doctor_mode_scorecard": {
          "schema_version": "flywheel.doctor_mode_scorecard.v1",
          "binary": "daily-report-enabled-repos.sh",
          "current_score": 5200,
          "previous_score": 5180,
          "baseline_score": 4900,
          "evidence_ref": "state/steady-scorecard.json"
        }
      }
    },
    {
      "repo": "$TMP/repos/regressed",
      "status": "generated",
      "result": {
        "quality_grade": {
          "callback_count": 1,
          "compliance_distribution": {"avg": 910, "median": 910},
          "mission_fitness_counts": {},
          "disposition_counts": {}
        },
        "doctor_mode": {
          "scorecard": {
            "schema_version": "flywheel.doctor_mode_scorecard.v1",
            "binary": "flywheel-loop",
            "current_score": 5140,
            "previous_score": 5201,
            "baseline_score": 4900,
            "evidence_ref": "state/regressed-scorecard.json"
          }
        }
      }
    }
  ]
}
JSON
EOF
chmod +x "$TMP/enabled-repos.sh"

if python3 -m py_compile "$SCRIPT"; then
  pass "python syntax"
else
  fail "python syntax"
fi

"$SCRIPT" run \
  --enabled-repos-bin "$TMP/enabled-repos.sh" \
  --output-dir "$TMP/out" \
  --date 2026-05-15 \
  --json >"$TMP/rollup.json"

assert_jq "$TMP/rollup.json" \
  '.fleet_summary.doctor_mode_scorecard.repos_with_scorecard == 2 and .fleet_summary.doctor_mode_scorecard.week_over_week_regression_gt_50_count == 1' \
  "fleet summary counts scorecards and gt50 regression"

assert_jq "$TMP/rollup.json" \
  'any(.red_flags[]; .code == "doctor_mode_scorecard_regressed_above_50" and (.detail | contains("flywheel-loop")))' \
  "regression red flag names binary"

assert_jq "$TMP/rollup.json" \
  'any(.per_repo[]; .doctor_mode_scorecard.binary == "daily-report-enabled-repos.sh" and .doctor_mode_scorecard.score_delta == 300)' \
  "per-repo score delta normalized"

if grep -q 'doctor_mode_scorecard: repos=2' "$TMP/out/fleet-daily-2026-05-15.md"; then
  pass "markdown rollup renders doctor scorecard"
else
  fail "markdown rollup renders doctor scorecard"
  cat "$TMP/out/fleet-daily-2026-05-15.md" >&2
fi

printf '%s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
