#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CI="$ROOT/.github/workflows/ci.yml"
INSTALLER="$ROOT/.github/workflows/installer-smoke.yml"
RELEASE="$ROOT/.github/workflows/release.yml"
SITE="$ROOT/.github/workflows/site.yml"
TAG_CHECKOUT_LITERAL="git checkout --detach \"\$tag\""
TARBALL_SHA_LITERAL="shasum -a 256 \"flywheel-\${tag}.tar.gz\" >\"flywheel-\${tag}.tar.gz.sha256\""

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

for file in "$CI" "$INSTALLER" "$RELEASE" "$SITE"; do
  if [[ -s "$file" ]]; then
    pass "$(basename "$file") exists"
  else
    fail "$(basename "$file") exists"
  fi
done

if grep -q 'actions/checkout@[a-f0-9]\{40\}' "$CI" \
  && grep -q 'actions/checkout@[a-f0-9]\{40\}' "$INSTALLER" \
  && grep -q 'actions/checkout@[a-f0-9]\{40\}' "$RELEASE" \
  && grep -q 'actions/checkout@[a-f0-9]\{40\}' "$SITE"; then
  pass "checkout actions pinned to SHA"
else
  fail "checkout actions pinned to SHA"
fi

if grep -q 'actions/upload-artifact@[a-f0-9]\{40\}' "$INSTALLER"; then
  pass "installer upload-artifact action pinned to SHA"
else
  fail "installer upload-artifact action pinned to SHA"
fi

if grep -q 'pull_request:' "$CI" \
  && grep -q 'branches:' "$CI" \
  && grep -q 'main' "$CI" \
  && grep -q 'master' "$CI"; then
  pass "ci triggers include PR and both public default branch candidates"
else
  fail "ci triggers include PR and both public default branch candidates"
fi

if grep -q 'pull_request:' "$INSTALLER" && grep -q 'cron: "0 9 \* \* \*"' "$INSTALLER"; then
  pass "installer triggers"
else
  fail "installer triggers"
fi

if grep -q 'tags:' "$RELEASE" && grep -q 'v\[0-9\]' "$RELEASE" && grep -q 'workflow_dispatch:' "$RELEASE"; then
  pass "release triggers"
else
  fail "release triggers"
fi

if grep -q 'tags:' "$SITE" && grep -q 'v\[0-9\]' "$SITE" && grep -q 'workflow_dispatch:' "$SITE"; then
  pass "site triggers"
else
  fail "site triggers"
fi

if grep -qF 'fetch-depth: 0' "$RELEASE" && grep -qF "$TAG_CHECKOUT_LITERAL" "$RELEASE"; then
  pass "release workflow packages resolved tag"
else
  fail "release workflow packages resolved tag"
fi

if grep -qF 'fetch-depth: 0' "$SITE" && grep -qF "$TAG_CHECKOUT_LITERAL" "$SITE"; then
  pass "site workflow publishes resolved tag"
else
  fail "site workflow publishes resolved tag"
fi

if grep -qF 'shasum -a 256 install.sh >install.sh.sha256' "$RELEASE" \
  && grep -qF "$TARBALL_SHA_LITERAL" "$RELEASE"; then
  pass "release checksum manifests use artifact-relative filenames"
else
  fail "release checksum manifests use artifact-relative filenames"
fi

if grep -qF 'cd site-dist' "$SITE" \
  && grep -qF 'shasum -a 256 install.sh >install.sh.sha256' "$SITE"; then
  pass "site checksum manifest uses artifact-relative filename"
else
  fail "site checksum manifest uses artifact-relative filename"
fi

for token in shellcheck ripgrep 'ruff check' markdownlint tests/public-top-level-files.sh tests/public-surface-gap-scanner.sh tests/naming-conventions.sh tests/context-routing-discipline.sh tests/agent-lane-probe.sh tests/isolated-agent-lane-smoke.sh scripts/agent-lane-probe.sh scripts/isolated-agent-lane-smoke.sh scripts/local-actions-preflight.sh tests/public-docs.sh tests/public-links.sh tests/website-static.sh tests/website-accessibility.sh tests/live-site-probe.sh tests/contact-routing.sh tests/upstream-substrate-adoption.sh tests/release-assets.sh tests/cutover-receipts.sh tests/external-review-gate.sh tests/public-user-journey-pack.sh tests/story-system-package.sh tests/publication-goal-completion-audit.sh tests/publication-readiness.sh tests/true-publication-registry-validate.sh tests/journey-smoke.sh; do
  if grep -q "$token" "$CI"; then
    pass "ci includes $token"
  else
    fail "ci includes $token"
  fi
done

for token in scripts/assemble.py scripts/classify.py scripts/depersonalize.py scripts/review_queue.py scripts/validate_external_review.py scripts/website_accessibility.py scripts/live_site_probe.py scripts/check_links.py scripts/contact_route_probe.py scripts/publication_readiness.py scripts/validate_cutover_receipts.py scripts/validate_user_journey_pack.py scripts/validate_story_system_package.py; do
  if grep -q "$token" "$CI"; then
    pass "ci python lint includes $token"
  else
    fail "ci python lint includes $token"
  fi
done

for token in docs/getting-started/first-run.md docs/runbooks/public-release-runbook.md docs/runbooks/release-cutover-authorization.md docs/runbooks/context-and-model-routing.md docs/runbooks/local-actions-preflight.md docs/runbooks/isolated-agent-lane-testing.md docs/runbooks/agent-lane-compatibility.md docs/runbooks/upstream-substrate-adoption.md docs/runbooks/public-user-journey-pack.md docs/runbooks/public-site-smb-journey-wireframe.md docs/stories/public-journey-and-redaction.md docs/evidence/publication-evidence.md docs/evidence/publication-goal-completion-audit.md packages/zeststream-story-system/README.md; do
  if grep -q "$token" "$CI"; then
    pass "ci markdownlint includes $token"
  else
    fail "ci markdownlint includes $token"
  fi
done

for token in 'docs/concepts/*.md' 'docs/reference/*.md'; do
  if grep -qF "$token" "$CI"; then
    pass "ci markdownlint includes $token"
  else
    fail "ci markdownlint includes $token"
  fi
done

for token in ubuntu-22.04 macos-14 ripgrep tests/installer-smoke.sh tests/journey-smoke.sh FLYWHEEL_INSTALLER_SMOKE_ARTIFACT_DIR installer-smoke-artifacts 'Upload installer smoke receipts' 'if-no-files-found: error'; do
  if grep -q "$token" "$INSTALLER"; then
    pass "installer includes $token"
  else
    fail "installer includes $token"
  fi
done

for token in 'git archive' 'install.sh.sha256' SHA256SUMS 'gh release' 'tests/release-assets.sh' 'tests/cutover-receipts.sh' 'tests/public-links.sh' 'tests/website-accessibility.sh' 'tests/story-system-package.sh' 'scripts/validate_external_review.py --log docs/evidence/external-review-log.jsonl --release --json'; do
  if grep -q "$token" "$RELEASE"; then
    pass "release includes $token"
  else
    fail "release includes $token"
  fi
done

for token in \
  'actions/configure-pages@983d7736d9b0ae728b81ab479565c72886d7745b' \
  'actions/upload-pages-artifact@56afc609e74202658d3ffba0e8f6dda462b719fa' \
  'actions/deploy-pages@d6db90164ac5ed86f2b6aed7e0febac5b3c0c03e' \
  tests/website-static.sh \
  tests/story-system-package.sh \
  'site-dist/install.sh.sha256' \
  'flywheel.zeststream.ai' \
  'site-deploy-manifest.json'; do
  if grep -q "$token" "$SITE"; then
    pass "site includes $token"
  else
    fail "site includes $token"
  fi
done

if grep -q 'timeout-minutes:' "$CI" && grep -q 'timeout-minutes:' "$INSTALLER" && grep -q 'timeout-minutes:' "$RELEASE" && grep -q 'timeout-minutes:' "$SITE"; then
  pass "timeouts set"
else
  fail "timeouts set"
fi

if grep -q 'concurrency:' "$CI" && grep -q 'concurrency:' "$INSTALLER" && grep -q 'concurrency:' "$RELEASE" && grep -q 'concurrency:' "$SITE"; then
  pass "concurrency set"
else
  fail "concurrency set"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
