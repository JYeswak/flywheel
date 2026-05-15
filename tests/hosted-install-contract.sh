#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_literal() {
  local file="$1" literal="$2" label="$3"
  if rg -qF "$literal" "$ROOT/$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_no_curl_pipe_install() {
  local file="$1"
  if rg -n 'curl[^\n]*flywheel\.zeststream\.ai/install\.sh[^\n]*\|[^\n]*(bash|sh)([[:space:]]|$)' "$ROOT/$file" >/dev/null; then
    fail "$file does not imply curl-pipe install"
  else
    pass "$file does not imply curl-pipe install"
  fi
}

require_literal "README.md" "not a curl-only standalone installer" "README names hosted endpoint boundary"
require_literal "README.md" "extract the release tarball first" "README names clone-or-tarball contract"
require_literal "docs/getting-started/first-run.md" "The public install contract is clone-or-release" "first-run names install contract"
require_literal "site/for-developers/index.html" "not a curl-only install path" "developer page names hosted endpoint boundary"
require_literal "site/index.html" "The first run starts from a clone or release tarball." "home page names first-run source"
require_literal "docs/runbooks/public-user-journey-pack.md" "Verify the checksum mirror; install from a clone or release tarball." "journey pack CTA matches contract"
require_literal "docs/runbooks/release-cutover-authorization.md" "The install proxy proof is checksum parity only." "cutover runbook separates checksum from install"
require_literal "scripts/publication_readiness.py" "public install remains clone or release tarball first" "readiness next action matches contract"
require_literal "site/site-deploy-manifest.json" "\"tag\":\"v0.2.1\"" "site deploy manifest names release tag"
require_literal "site/site-deploy-manifest.json" "\"install_sha256\"" "site deploy manifest names installer checksum"

for file in \
  README.md \
  docs/getting-started/first-run.md \
  site/index.html \
  site/for-developers/index.html \
  docs/runbooks/public-user-journey-pack.md \
  docs/runbooks/release-cutover-authorization.md; do
  require_no_curl_pipe_install "$file"
done

if [[ -s "$ROOT/site/install.sh" && -s "$ROOT/site/install.sh.sha256" ]]; then
  pass "site install proxy files exist"
else
  fail "site install proxy files exist"
fi

actual="$(shasum -a 256 "$ROOT/site/install.sh" | awk '{print $1}')"
expected="$(awk '{print $1}' "$ROOT/site/install.sh.sha256")"
if [[ "$actual" == "$expected" ]]; then
  pass "site install proxy checksum matches"
else
  fail "site install proxy checksum matches"
fi

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
