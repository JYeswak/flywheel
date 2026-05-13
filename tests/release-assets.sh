#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-release-assets.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

tag="v0.2.0-test"
dist="$TMP/dist"
mkdir -p "$dist"

cp "$ROOT/install.sh" "$dist/install.sh"
git_root="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ "$git_root" == "$ROOT" ]]; then
  git -C "$ROOT" archive --format=tar.gz --output "$dist/flywheel-${tag}.tar.gz" HEAD
else
  (
    cd "$ROOT"
    tar --exclude=".git" --exclude=".flywheel/extraction" -czf "$dist/flywheel-${tag}.tar.gz" .
  )
fi
(
  cd "$dist"
  shasum -a 256 install.sh >install.sh.sha256
  shasum -a 256 "flywheel-${tag}.tar.gz" >"flywheel-${tag}.tar.gz.sha256"
  shasum -a 256 install.sh "flywheel-${tag}.tar.gz" >SHA256SUMS
)

for rel in install.sh install.sh.sha256 SHA256SUMS "flywheel-${tag}.tar.gz" "flywheel-${tag}.tar.gz.sha256"; do
  if [[ -s "$dist/$rel" ]]; then
    pass "release asset exists: $rel"
  else
    fail "release asset exists: $rel"
  fi
done

if (cd "$dist" && shasum -a 256 -c install.sh.sha256 >/dev/null); then
  pass "install.sh.sha256 verifies"
else
  fail "install.sh.sha256 verifies"
fi

if (cd "$dist" && shasum -a 256 -c "flywheel-${tag}.tar.gz.sha256" >/dev/null); then
  pass "tarball sha256 verifies"
else
  fail "tarball sha256 verifies"
fi

if (cd "$dist" && shasum -a 256 -c SHA256SUMS >/dev/null); then
  pass "SHA256SUMS verifies all release payloads"
else
  fail "SHA256SUMS verifies all release payloads"
fi

if [[ "$(wc -l <"$dist/install.sh.sha256" | tr -d ' ')" == "1" ]] \
  && [[ "$(wc -l <"$dist/flywheel-${tag}.tar.gz.sha256" | tr -d ' ')" == "1" ]] \
  && [[ "$(wc -l <"$dist/SHA256SUMS" | tr -d ' ')" == "2" ]]; then
  pass "checksum manifests contain expected row counts"
else
  fail "checksum manifests contain expected row counts"
fi

if [[ "$(awk '{print $2}' "$dist/SHA256SUMS" | sort | tr '\n' ' ')" == "flywheel-${tag}.tar.gz install.sh " ]]; then
  pass "SHA256SUMS covers exactly release payloads"
else
  fail "SHA256SUMS covers exactly release payloads"
fi

if ! (cd "$dist" && awk '{print $2}' install.sh.sha256 "flywheel-${tag}.tar.gz.sha256" SHA256SUMS | rg -q '/'); then
  pass "checksum manifests use artifact-relative filenames"
else
  fail "checksum manifests use artifact-relative filenames"
fi

if tar -tzf "$dist/flywheel-${tag}.tar.gz" | rg -q '(^|/)README\.md$' \
  && tar -tzf "$dist/flywheel-${tag}.tar.gz" | rg -q '(^|/)install\.sh$'; then
  pass "tarball contains README.md and install.sh"
else
  fail "tarball contains README.md and install.sh"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
