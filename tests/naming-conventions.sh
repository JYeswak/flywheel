#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DOC="$ROOT/docs/brand/naming-conventions.md"
public_company="Zest""Stream"
operator_placeholder="{operator-company}"
public_surfaces=(
  README.md
  CHARTER.md
  CONTRIBUTING.md
  SECURITY.md
  SUPPORT.md
  CODE_OF_CONDUCT.md
  CHANGELOG.md
  ARCHITECTURE.md
  docs/brand/naming-conventions.md
  docs/getting-started/first-run.md
  docs/runbooks/public-release-runbook.md
  docs/runbooks/context-and-model-routing.md
  docs/runbooks/agent-lane-compatibility.md
  docs/stories/public-journey-and-redaction.md
  .github/PULL_REQUEST_TEMPLATE.md
  .github/ISSUE_TEMPLATE/bug.md
  .github/ISSUE_TEMPLATE/feature.md
  .github/ISSUE_TEMPLATE/trauma.md
  .github/workflows/ci.yml
  .github/workflows/installer-smoke.yml
  .github/workflows/release.yml
  install.sh
  uninstall.sh
  bin/flywheel
  scripts/preflight.sh
  scripts/journey-smoke.sh
  scripts/agent-lane-probe.sh
)
publication_plan_surfaces=(
  .flywheel/PLANS/public-share-readiness-2026-05-12/05-INSTALLABILITY-COVERAGE-AUDIT.md
  .flywheel/PLANS/public-share-readiness-2026-05-12/09-SUBSTRATE-PREFLIGHT-INVENTORY.md
  .flywheel/PLANS/public-share-readiness-2026-05-12/10-HARNESS-SUPPORT-MATRIX.md
  .flywheel/PLANS/public-share-readiness-2026-05-12/11-FIRST-RUN-JOURNEY-SPEC.md
  .flywheel/PLANS/public-share-readiness-2026-05-12/14-PREFLIGHT-IMPLEMENTATION-SPEC.md
  .flywheel/PLANS/public-share-readiness-2026-05-12/15-JOURNEY-SMOKE-MATRIX-SPEC.md
)
scan_files=()
plan_scan_files=()

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL %s\n' "$1" >&2
}

require_literal() {
  local file="$1" literal="$2" label="$3"
  if rg -qF "$literal" "$ROOT/$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

reject_pattern() {
  local pattern="$1" label="$2" hits
  if hits="$(rg --case-sensitive -n "$pattern" "${scan_files[@]}" 2>/dev/null)"; then
    fail "$label"
    printf '%s\n' "$hits" >&2
  else
    pass "$label"
  fi
}

if [[ -s "$DOC" ]]; then
  pass "doc exists"
else
  fail "doc exists"
fi

if rg -qF "$public_company" "$DOC"; then
  pass "canonical term present: $public_company"
elif rg -qF "$operator_placeholder" "$DOC"; then
  pass "canonical term present: operator-company placeholder"
else
  fail "canonical term present: $public_company or operator-company placeholder"
fi

for term in "Flywheel" "Yuzu Method" "SkillOS" "ZestTube" "Jeff / Dicklesworthstone substrate" "NTM, Beads, Agent Mail"; do
  if rg -qF "$term" "$DOC"; then
    pass "canonical term present: $term"
  else
    fail "canonical term present: $term"
  fi
done

for doctrine in \
  ".flywheel/doctrine/naming-convention-distinguishable-ownership.md" \
  ".flywheel/doctrine/naming-rename-cross-repo-wire-or-explain.md" \
  ".flywheel/doctrine/scope-aware-rename-domain-collision-protection.md"; do
  if rg -qF "$doctrine" "$DOC" && [[ -s "$ROOT/$doctrine" ]]; then
    pass "doctrine reference live: $doctrine"
  else
    fail "doctrine reference live: $doctrine"
  fi
done

for collision in doctor ledger worker dispatch tick reap; do
  if rg -q "\`${collision}\`" "$DOC"; then
    pass "domain-collision term documented: $collision"
  else
    fail "domain-collision term documented: $collision"
  fi
done

for surface in "${public_surfaces[@]}"; do
  if [[ -s "$ROOT/$surface" ]]; then
    pass "public naming surface exists: $surface"
    scan_files+=("$ROOT/$surface")
  else
    fail "public naming surface exists: $surface"
  fi
done

missing_publication_plan_surfaces=0
for surface in "${publication_plan_surfaces[@]}"; do
  if [[ -s "$ROOT/$surface" ]]; then
    pass "publication plan support surface exists: $surface"
    plan_scan_files+=("$ROOT/$surface")
  else
    missing_publication_plan_surfaces=$((missing_publication_plan_surfaces + 1))
  fi
done

if [[ "$missing_publication_plan_surfaces" -eq 0 ]]; then
  pass "publication plan support surfaces available for source scan"
elif [[ "$missing_publication_plan_surfaces" -eq "${#publication_plan_surfaces[@]}" ]]; then
  pass "publication plan support surfaces omitted from public export"
else
  fail "publication plan support surfaces are partially present"
fi

require_literal "docs/brand/naming-conventions.md" "github.com/JYeswak/flywheel" "canonical repo selected"
require_literal "docs/brand/naming-conventions.md" "flywheel.zeststream.ai" "canonical SMB site selected"
require_literal "docs/brand/naming-conventions.md" "docs.flywheel.zeststream.ai" "canonical docs site selected"
require_literal "docs/brand/naming-conventions.md" "flywheel.zeststream.ai/install.sh" "canonical install endpoint selected"
require_literal "docs/getting-started/first-run.md" "git clone https://github.com/JYeswak/flywheel.git" "first-run clone URL canonical"
require_literal "bin/flywheel" 'VERSION="flywheel-public-spine/v0"' "public CLI namespace remains flywheel"

if [[ "${#scan_files[@]}" -gt 0 ]]; then
  reject_pattern "PROMOTION-PENDING|chiefzester@gmail\\.com|/Users/josh|\\.ntm/pids" \
    "public surfaces reject stale private operator markers"
  reject_pattern "github\\.com/JYeswak/zeststream-flywheel|Yum Yum" \
    "public surfaces reject superseded product names"
  reject_pattern "alpsinsurance|picoz|vrtx|mobile-eats|skillos" \
    "public surfaces reject private lowercase fleet slugs"
  reject_pattern "(^|[^[:alnum:]_])yuzu[-_:/\\.]" \
    "public surfaces do not use yuzu as command/package prefix"
  reject_pattern "(^|[^[:alnum:]_])bin/yuzu([^[:alnum:]_]|$)" \
    "public surfaces do not expose bin/yuzu"
else
  fail "public naming surfaces available for scan"
fi

if [[ "${#plan_scan_files[@]}" -gt 0 ]]; then
  if hits="$(rg --case-sensitive -n 'supported-first|supported first|supported-first harness|supported-first target' "${plan_scan_files[@]}" 2>/dev/null)"; then
    fail "publication plan harness support copy stays receipt-bound"
    printf '%s\n' "$hits" >&2
  else
    pass "publication plan harness support copy stays receipt-bound"
  fi
else
  pass "publication plan harness support copy scan skipped for public export"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
