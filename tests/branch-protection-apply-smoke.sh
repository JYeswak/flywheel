#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/branch-protection-apply.sh"
FLEET="$ROOT/.flywheel/scripts/branch-protection-fleet-rollout.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/branch-protection-smoke.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok() {
  local name="$1"
  shift
  if "$@"; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name" >&2
  fi
}

ok_jq() {
  local name="$1" expr="$2" file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name" >&2
    [[ -s "$file" ]] && cat "$file" >&2
  fi
}

ok_jq_equal_desired() {
  local name="$1" left="$2" right="$3"
  if jq -e --slurpfile other "$right" '.desired == $other[0].desired' "$left" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name" >&2
    cat "$left" >&2
    cat "$right" >&2
  fi
}

repo="$TMP/repo"
mkdir -p "$repo/.github/workflows"
cat >"$repo/.github/workflows/ci.yml" <<'YAML'
name: CI
on: [pull_request]
jobs:
  shellcheck:
    name: Test / shellcheck
    runs-on: ubuntu-latest
    steps:
      - run: shellcheck script.sh
  smoke:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/smoke.sh
YAML

cat >"$TMP/gh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${GH_STUB_LOG:?}"
if [[ "$1" == "api" && "$2" == "repos/JYeswak/flywheel/branches/main/protection" ]]; then
  printf '{"required_status_checks":{"strict":false,"contexts":[]},"enforce_admins":true}\n'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "-X" && "$3" == "PUT" ]]; then
  cp "$6" "${GH_STUB_LAST_INPUT:?}"
  printf '{"ok":true}\n'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/JYeswak/flywheel/actions/runs" ]]; then
  printf 'CI\nSmoke\n'
  exit 0
fi
printf '{}\n'
STUB
chmod +x "$TMP/gh"
export GH_BIN="$TMP/gh"
export GH_STUB_LOG="$TMP/gh.log"
export GH_STUB_LAST_INPUT="$TMP/put.json"
: >"$GH_STUB_LOG"

overrides="$TMP/overrides.json"
cat >"$overrides" <<'JSON'
{
  "schema_version": "branch_protection_overrides.v1",
  "default_substrate": {"required_pull_request_reviews": null},
  "repos": {
    "JYeswak/flywheel": {
      "required_pull_request_reviews": {"required_approving_review_count": 1}
    }
  }
}
JSON

ok "apply script syntax" bash -n "$SCRIPT"
ok "fleet script syntax" bash -n "$FLEET"

"$SCRIPT" --repo JYeswak/flywheel --branch main --dry-run --repo-path "$repo" --json >"$TMP/dry.json"
ok_jq "dry-run emits valid envelope without mutation" '.schema_version == "branch_protection_apply.v1" and .outcome == "dry-run" and .mode == "dry-run"' "$TMP/dry.json"
ok "dry-run does not call PUT" test "$(grep -c -- '-X PUT' "$GH_STUB_LOG" || true)" -eq 0
ok_jq "workflow job names discovered" '.required_checks == ["Test / shellcheck","smoke"]' "$TMP/dry.json"
ok_jq "enforce_admins stays false" '.desired.enforce_admins == false' "$TMP/dry.json"

"$SCRIPT" --repo JYeswak/flywheel --branch main --dry-run --repo-path "$repo" --overrides-file "$overrides" --json >"$TMP/override.json"
ok_jq "override config respected" '.desired.required_pull_request_reviews.required_approving_review_count == 1' "$TMP/override.json"

"$SCRIPT" --repo JYeswak/flywheel --branch main --apply --repo-path "$repo" --check-names "ci,smoke,shellcheck" --json >"$TMP/apply.json"
ok_jq "mock apply reports applied" '.outcome == "applied" and .required_checks == ["ci","smoke","shellcheck"]' "$TMP/apply.json"
ok_jq "mock apply payload sets expected fields" '.required_status_checks.strict == true and .required_pull_request_reviews == null and .allow_force_pushes == false and .allow_deletions == false and .required_linear_history == true' "$GH_STUB_LAST_INPUT"

"$SCRIPT" --repo JYeswak/flywheel --branch main --apply --repo-path "$repo" --check-names "ci,smoke,shellcheck" --json >"$TMP/apply-again.json"
ok_jq_equal_desired "idempotent re-apply produces same desired state" "$TMP/apply.json" "$TMP/apply-again.json"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -ge 6 ]]
