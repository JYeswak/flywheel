#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-links.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

mkdir -p "$TMP/docs" "$TMP/site"
cat >"$TMP/docs/a.md" <<'MD'
# Alpha Page

See [beta](b.md#beta-heading), [self](#alpha-page), and [external](https://example.com).
MD
cat >"$TMP/docs/b.md" <<'MD'
# Beta Heading
MD
cat >"$TMP/site/index.html" <<'HTML'
<!doctype html><html lang="en"><body><a href="./about.html#team">About</a></body></html>
HTML
cat >"$TMP/site/about.html" <<'HTML'
<!doctype html><html lang="en"><body><h1 id="team">Team</h1></body></html>
HTML

valid="$(python3 "$ROOT/scripts/check_links.py" --repo "$TMP" --file docs/a.md --file site/index.html --json)"
if jq -e '.status == "pass" and .checked_count == 3 and .skipped_external_count == 1 and .failure_count == 0' <<<"$valid" >/dev/null; then
  pass "valid fixture links pass with external URL skipped"
else
  fail "valid fixture links pass with external URL skipped"
  jq -c . <<<"$valid" >&2
fi

cat >"$TMP/docs/broken.md" <<'MD'
# Broken

See [missing file](missing.md), [missing anchor](a.md#not-here).
MD

if broken="$(python3 "$ROOT/scripts/check_links.py" --repo "$TMP" --file docs/broken.md --json 2>/dev/null)"; then
  fail "broken fixture exits non-zero"
else
  if jq -e '.status == "fail" and .failure_count == 2 and ([.failures[].reason] | sort == ["missing_anchor","missing_target"])' <<<"$broken" >/dev/null; then
    pass "broken fixture reports missing target and missing anchor"
  else
    fail "broken fixture reports missing target and missing anchor"
    jq -c . <<<"$broken" >&2
  fi
fi

live="$(python3 "$ROOT/scripts/check_links.py" --repo "$ROOT" --json)"
if jq -e '.status == "pass" and .failure_count == 0 and .source_count >= 34 and .checked_count > 20 and .skipped_external_count > 0' <<<"$live" >/dev/null; then
  pass "live public docs and site links pass"
else
  fail "live public docs and site links pass"
  jq -c '{status, source_count, checked_count, skipped_external_count, failure_count, missing_sources, failures}' <<<"$live" >&2
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
