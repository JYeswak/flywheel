#!/usr/bin/env bash
# pre-push-validate.sh — run the CI test suite locally before pushing.
#
# Why this exists:
#   PR #7 (2026-05-15) burned 3 CI iterations on tests that are local-runnable:
#     - publication-goal-completion-audit.sh
#     - true-publication-registry-validate.sh
#     - public-surface-gap-scanner.sh
#   Each CI iteration costs ~5-10 min wall-clock + GitHub Actions minutes.
#   Running these locally pre-push fails fast at ~10-30s.
#
# Usage:
#   bash scripts/pre-push-validate.sh                # run all CI tests
#   bash scripts/pre-push-validate.sh --fast         # skip slow tests (network, install)
#   bash scripts/pre-push-validate.sh --only=publication-readiness  # filter
#   bash scripts/pre-push-validate.sh --list         # list tests + exit
#
# Exit codes:
#   0   all tests passed
#   1   at least one test failed
#   2   usage/setup error
#
# Wiring as a git pre-push hook (optional):
#   ln -sf ../../scripts/pre-push-validate.sh .git/hooks/pre-push
#
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Test list — keep aligned with .github/workflows/ci.yml.
# Order: fastest classes first so failures surface quickly.
CI_TESTS=(
  # quick scanners (1-3s each)
  "tests/public-top-level-files.sh"
  "tests/public-surface-gap-scanner.sh"
  "tests/public-evidence-fingerprints.sh"
  "tests/changelog.sh"
  "tests/github-workflows.sh"
  "tests/naming-conventions.sh"
  "tests/context-routing-discipline.sh"

  # docs + content (5-15s each)
  "tests/public-docs.sh"
  "tests/public-links.sh"
  "tests/website-static.sh"
  "tests/website-accessibility.sh"
  "tests/contact-routing.sh"

  # publication readiness (the PR #7 killers)
  "tests/publication-goal-completion-audit.sh"
  "tests/publication-readiness.sh"
  "tests/true-publication-registry-validate.sh"
  "tests/external-review-gate.sh"
  "tests/cutover-receipts.sh"

  # packages + assets
  "tests/release-assets.sh"
  "tests/story-system-package.sh"
  "tests/zeststream-ui-package.sh"
  "tests/zeststream-motion-package.sh"
  "tests/repo-story-portability.sh"
  "tests/repo-owner-brief.sh"

  # journeys + adoption
  "tests/public-user-journey-pack.sh"
  "tests/upstream-substrate-adoption.sh"

  # contracts
  "tests/hosted-install-contract.sh"
  "tests/preflight-fixtures.sh"
)

# Tests that require network / external services — skip with --fast.
SLOW_TESTS=(
  "tests/live-site-probe.sh"
  "tests/agent-lane-probe.sh"
  "tests/journey-smoke.sh"
)

# Python scans that gate workflows (treated like tests but called via python3).
# Format: "label|command"
PYTHON_GATES=(
  "depersonalize-site|python3 scripts/depersonalize.py --scan-table --root site --json"
)

mode="all"
filter=""
list_only=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fast) mode="fast"; shift ;;
    --only=*) filter="${1#--only=}"; shift ;;
    --list) list_only=1; shift ;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ $list_only -eq 1 ]]; then
  printf '=== CI tests run by pre-push-validate ===\n'
  for t in "${CI_TESTS[@]}"; do
    printf '  %s\n' "$t"
  done
  if [[ "$mode" != "fast" ]]; then
    printf '=== slow tests (skip with --fast) ===\n'
    for t in "${SLOW_TESTS[@]}"; do
      printf '  %s\n' "$t"
    done
  fi
  exit 0
fi

declare -a tests_to_run=()
for t in "${CI_TESTS[@]}"; do
  if [[ -n "$filter" && "$t" != *"$filter"* ]]; then continue; fi
  tests_to_run+=("$t")
done
if [[ "$mode" != "fast" ]]; then
  for t in "${SLOW_TESTS[@]}"; do
    if [[ -n "$filter" && "$t" != *"$filter"* ]]; then continue; fi
    tests_to_run+=("$t")
  done
fi

total=${#tests_to_run[@]}
pass=0
fail=0
failed=()
start_ts=$(date +%s)

total=$((${#tests_to_run[@]} + ${#PYTHON_GATES[@]}))
printf '=== pre-push-validate: running %d tests + %d python-gates ===\n' "${#tests_to_run[@]}" "${#PYTHON_GATES[@]}"

# Python gates run first since they are the cheapest (site.yml gate ~1s)
for gate in "${PYTHON_GATES[@]}"; do
  label="${gate%%|*}"
  cmd="${gate#*|}"
  g_start=$(date +%s)
  if eval "$cmd" >/tmp/pre-push-validate-last.out 2>&1; then
    g_elapsed=$(( $(date +%s) - g_start ))
    if grep -q '"status": *"pass"' /tmp/pre-push-validate-last.out 2>/dev/null || grep -q '"exit_code": *0' /tmp/pre-push-validate-last.out 2>/dev/null; then
      printf '  PASS  python-gate:%s (%ds)\n' "$label" "$g_elapsed"
      pass=$((pass + 1))
    else
      printf '  FAIL  python-gate:%s (%ds) — exit 0 but status not pass\n' "$label" "$g_elapsed"
      fail=$((fail + 1))
      failed+=("python-gate:$label")
      tail -5 /tmp/pre-push-validate-last.out | sed 's/^/        | /'
    fi
  else
    g_elapsed=$(( $(date +%s) - g_start ))
    printf '  FAIL  python-gate:%s (%ds)\n' "$label" "$g_elapsed"
    fail=$((fail + 1))
    failed+=("python-gate:$label")
    tail -10 /tmp/pre-push-validate-last.out | sed 's/^/        | /'
  fi
done

for t in "${tests_to_run[@]}"; do
  if [[ ! -f "$t" ]]; then
    printf '  SKIP  %s (not found)\n' "$t"
    continue
  fi
  if [[ ! -x "$t" ]] && ! head -1 "$t" 2>/dev/null | grep -q '#!'; then
    printf '  SKIP  %s (not runnable)\n' "$t"
    continue
  fi
  t_start=$(date +%s)
  if bash "$t" >/tmp/pre-push-validate-last.out 2>&1; then
    t_elapsed=$(( $(date +%s) - t_start ))
    printf '  PASS  %s (%ds)\n' "$t" "$t_elapsed"
    pass=$((pass + 1))
  else
    t_elapsed=$(( $(date +%s) - t_start ))
    printf '  FAIL  %s (%ds)\n' "$t" "$t_elapsed"
    fail=$((fail + 1))
    failed+=("$t")
    printf '        last 10 lines of output:\n'
    tail -10 /tmp/pre-push-validate-last.out | sed 's/^/        | /'
  fi
done

elapsed=$(( $(date +%s) - start_ts ))
printf '\n=== summary ===\n'
printf '  total:   %d\n' "$total"
printf '  passed:  %d\n' "$pass"
printf '  failed:  %d\n' "$fail"
printf '  elapsed: %ds\n' "$elapsed"

if [[ $fail -gt 0 ]]; then
  printf '\n  failed tests:\n'
  for t in "${failed[@]}"; do
    printf '    - %s\n' "$t"
  done
  printf '\n  block: do not push until these are green.\n'
  exit 1
fi

printf '\n  all green. safe to push.\n'
exit 0
