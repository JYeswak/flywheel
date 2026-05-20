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

ok_jq_equal_checks() {
  local name="$1" left="$2" right="$3"
  if jq -e --slurpfile other "$right" '.required_checks == $other[0].required_checks' "$left" >/dev/null; then
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
repo_one="$TMP/repo-one"
repo_two="$TMP/repo-two"
repo_matrix="$TMP/repo-matrix"
mkdir -p "$repo/.github/workflows" "$repo_one/.github/workflows" "$repo_two/.github/workflows" "$repo_matrix/.github/workflows"
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

cat >"$repo_one/.github/workflows/ci.yml" <<'YAML'
name: Repo One CI
on: [pull_request]
jobs:
  build:
    name: Repo One Build
    runs-on: ubuntu-latest
    steps:
      - run: echo one
  shared:
    name: Shared Check
    runs-on: ubuntu-latest
    steps:
      - run: echo shared
YAML

cat >"$repo_two/.github/workflows/ci.yml" <<'YAML'
name: Repo Two CI
on: [pull_request]
jobs:
  validate:
    name: Repo Two Validate
    runs-on: ubuntu-latest
    steps:
      - run: echo two
YAML

cat >"$repo_matrix/.github/workflows/matrix.yml" <<'YAML'
name: Matrix CI
on:
  pull_request:
jobs:
  install:
    name: Install Doctor Uninstall (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os:
          - macos-14
          - ubuntu-22.04
    steps:
      - run: echo install
  multi:
    name: Multi Axis
    runs-on: ubuntu-22.04
    strategy:
      matrix:
        os: [ubuntu-22.04]
        node: [20]
    steps:
      - run: echo multi
YAML

cat >"$repo_matrix/.github/workflows/schedule.yml" <<'YAML'
name: Scheduled Only
on:
  schedule:
    - cron: "0 9 * * *"
jobs:
  nightly:
    name: Nightly Only
    runs-on: ubuntu-22.04
    steps:
      - run: echo nightly
YAML

cat >"$repo_matrix/.github/workflows/pr.yml" <<'YAML'
name: Pull Request Only
on:
  pull_request:
jobs:
  pr_only:
    name: Pull Request Only
    runs-on: ubuntu-22.04
    steps:
      - run: echo pr
YAML

cat >"$repo_matrix/.github/workflows/mixed.yml" <<'YAML'
name: Mixed Events
on: [push, pull_request]
jobs:
  dual:
    name: Dual Event
    runs-on: ubuntu-22.04
    steps:
      - run: echo dual
YAML

cat >"$repo_matrix/.github/workflows/branch-miss.yml" <<'YAML'
name: Branch Miss
on:
  pull_request:
    branches: [release]
jobs:
  branch_miss:
    name: Branch Miss
    runs-on: ubuntu-22.04
    steps:
      - run: echo branch
YAML

cat >"$TMP/gh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${GH_STUB_LOG:?}"
if [[ "$1" == "repo" && "$2" == "view" ]]; then
  case "$3" in
    JYeswak/repo-one) printf '{"nameWithOwner":"JYeswak/repo-one","defaultBranchRef":{"name":"master"}}\n' ;;
    JYeswak/repo-two) printf '{"nameWithOwner":"JYeswak/repo-two","defaultBranchRef":{"name":"main"}}\n' ;;
    *) printf '{"nameWithOwner":"%s","defaultBranchRef":{"name":"main"}}\n' "$3" ;;
  esac
  exit 0
fi
if [[ "$1" == "api" && "$2" == repos/*/branches/main/protection ]]; then
  printf '{"required_status_checks":{"strict":false,"contexts":[]},"enforce_admins":true}\n'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "-X" && "$3" == "PUT" ]]; then
  safe="${4//\//__}"
  cp "$6" "${GH_STUB_PUT_DIR:?}/${safe}.json"
  cp "$6" "${GH_STUB_LAST_INPUT:?}"
  printf '{"ok":true}\n'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/JYeswak/flywheel/actions/runs" ]]; then
  printf 'CI\nSmoke\n'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/JYeswak/repo-one/actions/runs" ]]; then
  printf 'Repo One CI\nShared Workflow\n'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/JYeswak/repo-two/actions/runs" ]]; then
  printf 'Repo Two CI\n'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/JYeswak/repo-matrix/actions/runs" ]]; then
  printf 'Matrix CI\nPull Request Only\nMixed Events\n'
  exit 0
fi
printf '{}\n'
STUB
chmod +x "$TMP/gh"
export GH_BIN="$TMP/gh"
export GH_STUB_LOG="$TMP/gh.log"
export GH_STUB_LAST_INPUT="$TMP/put.json"
export GH_STUB_PUT_DIR="$TMP/puts"
mkdir -p "$GH_STUB_PUT_DIR"
: >"$GH_STUB_LOG"

overrides="$TMP/overrides.json"
cat >"$overrides" <<'JSON'
{
  "schema_version": "branch_protection_overrides.v1",
  "default_substrate": {"required_pull_request_reviews": null},
  "repos": {
    "JYeswak/flywheel": {
      "required_checks": ["Override Check"],
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
ok_jq "workflow discovery provenance emitted" '.discovery_source == "workflow_yml" and (.recent_run_names | length == 2)' "$TMP/dry.json"
ok_jq "enforce_admins stays false" '.desired.enforce_admins == false' "$TMP/dry.json"

"$SCRIPT" --repo JYeswak/flywheel --branch main --dry-run --repo-path "$repo" --overrides-file "$overrides" --json >"$TMP/override.json"
ok_jq "override config respected" '.desired.required_pull_request_reviews.required_approving_review_count == 1 and .required_checks == ["Override Check"] and .discovery_source == "override"' "$TMP/override.json"

"$SCRIPT" --repo JYeswak/flywheel --branch main --apply --repo-path "$repo" --check-names "ci,smoke,shellcheck" --json >"$TMP/apply.json"
ok_jq "mock apply reports applied" '.outcome == "applied" and .required_checks == ["ci","smoke","shellcheck"] and .discovery_source == "override"' "$TMP/apply.json"
ok_jq "mock apply payload sets expected fields" '.required_status_checks.strict == true and .required_pull_request_reviews == null and .allow_force_pushes == false and .allow_deletions == false and .required_linear_history == true' "$GH_STUB_LAST_INPUT"

"$SCRIPT" --repo JYeswak/flywheel --branch main --apply --repo-path "$repo" --check-names "ci,smoke,shellcheck" --json >"$TMP/apply-again.json"
ok_jq_equal_desired "idempotent re-apply produces same desired state" "$TMP/apply.json" "$TMP/apply-again.json"

"$SCRIPT" --repo JYeswak/repo-one --branch main --dry-run --repo-path "$repo_one" --json >"$TMP/repo-one-dry.json"
"$SCRIPT" --repo JYeswak/repo-one --branch main --apply --repo-path "$repo_one" --json >"$TMP/repo-one-apply.json"
ok_jq "repo one uses repo-specific workflow checks" '.required_checks == ["Repo One Build","Shared Check"]' "$TMP/repo-one-dry.json"
ok_jq_equal_checks "repo one dry-run and apply checks match" "$TMP/repo-one-dry.json" "$TMP/repo-one-apply.json"
ok_jq "repo one apply payload has repo-specific checks" '.required_status_checks.contexts == ["Repo One Build","Shared Check"]' "$GH_STUB_PUT_DIR/repos__JYeswak__repo-one__branches__main__protection.json"

"$SCRIPT" --repo JYeswak/repo-two --branch main --dry-run --repo-path "$repo_two" --json >"$TMP/repo-two-dry.json"
"$SCRIPT" --repo JYeswak/repo-two --branch main --apply --repo-path "$repo_two" --json >"$TMP/repo-two-apply.json"
ok_jq "repo two uses different workflow checks" '.required_checks == ["Repo Two Validate"]' "$TMP/repo-two-dry.json"
ok_jq_equal_checks "repo two dry-run and apply checks match" "$TMP/repo-two-dry.json" "$TMP/repo-two-apply.json"
ok_jq "repo two apply payload has repo-specific checks" '.required_status_checks.contexts == ["Repo Two Validate"]' "$GH_STUB_PUT_DIR/repos__JYeswak__repo-two__branches__main__protection.json"

"$SCRIPT" --repo JYeswak/repo-one --branch main --verify-parity --repo-path "$repo_one" --json >"$TMP/parity.json"
ok_jq "verify parity passes without mutation" '.mode == "verify-parity" and .outcome == "pass" and .dry_run_required_checks == .apply_required_checks' "$TMP/parity.json"
ok_jq_equal_checks "divergence detector asserts dry-run/apply equality" "$TMP/repo-two-dry.json" "$TMP/repo-two-apply.json"

"$SCRIPT" --repo JYeswak/repo-matrix --branch main --dry-run --repo-path "$repo_matrix" --json >"$TMP/matrix-dry.json"
ok_jq "matrix workflow emits expanded check names" '.required_checks | index("Install Doctor Uninstall (macos-14)") and index("Install Doctor Uninstall (ubuntu-22.04)")' "$TMP/matrix-dry.json"
# shellcheck disable=SC2016
ok_jq "matrix workflow omits unexpanded literal" '.required_checks | index("Install Doctor Uninstall (${{ matrix.os }})") | not' "$TMP/matrix-dry.json"
ok_jq "single-axis matrix emits two required checks" '([.required_checks[] | select(startswith("Install Doctor Uninstall ("))] | length) == 2' "$TMP/matrix-dry.json"
ok_jq "multi-axis matrix emits tuple suffix" '.required_checks | index("Multi Axis (ubuntu-22.04, 20)")' "$TMP/matrix-dry.json"
ok_jq "schedule-only workflow excluded" '.required_checks | index("Nightly Only") | not' "$TMP/matrix-dry.json"
ok_jq "pull-request workflow included" '.required_checks | index("Pull Request Only")' "$TMP/matrix-dry.json"
ok_jq "push-and-pull-request workflow included" '.required_checks | index("Dual Event")' "$TMP/matrix-dry.json"
ok_jq "branch-filtered pull-request workflow excluded from main" '.required_checks | index("Branch Miss") | not' "$TMP/matrix-dry.json"
ok_jq "discovery details include trigger reasons" '[.discovery_details[] | select(.check == "Nightly Only" and .included == false and .trigger_reason == "excluded:no_pull_request_trigger")] | length == 1' "$TMP/matrix-dry.json"
ok_jq "discovery details include matrix rows" '[.discovery_details[] | select(.check == "Install Doctor Uninstall (macos-14)" and .matrix.os == "macos-14")] | length == 1' "$TMP/matrix-dry.json"
ok_jq "canonical flywheel matrix regression shape represented" '.required_checks == ["Install Doctor Uninstall (macos-14)","Install Doctor Uninstall (ubuntu-22.04)","Multi Axis (ubuntu-22.04, 20)","Dual Event","Pull Request Only"]' "$TMP/matrix-dry.json"

BRANCH_PROTECTION_FLEET_REPOS=$'one|JYeswak/repo-one|'"$repo_one"$'\ntwo|JYeswak/repo-two|'"$repo_two" \
  "$FLEET" --dry-run --overrides-file "$TMP/empty-overrides.json" --json >"$TMP/fleet-default-branches.json"
ok_jq "fleet rollout uses live default branches" '[.results[] | {alias, branch}] == [{"alias":"one","branch":"master"},{"alias":"two","branch":"main"}]' "$TMP/fleet-default-branches.json"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -ge 20 ]]
