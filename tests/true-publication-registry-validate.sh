#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/true-publication-registry-validate.py"
REGISTRY="$ROOT/.flywheel/PLANS/public-share-readiness-2026-05-12/19-TRUE-PUBLICATION-RELEASE-BLOCKER-REGISTRY.md"
PUBLIC_COVERAGE="$ROOT/docs/evidence/publication-blocker-coverage.md"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/true-publication-registry.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

expected_codes=(
  github_release_assets_missing
  github_release_missing_or_draft
  install_proxy_checksum_mismatch
  joshua_release_signoff_missing
  remote_green_runs_missing
  remote_repo_private
  remote_workflows_missing
)

if [[ ! -s "$REGISTRY" ]]; then
  if [[ -s "$PUBLIC_COVERAGE" ]]; then
    pass "private registry omitted from public export"
  else
    fail "public blocker coverage exists when private registry omitted"
  fi

  for code in "${expected_codes[@]}"; do
    if rg -qF "| \`$code\` |" "$PUBLIC_COVERAGE"; then
      pass "public blocker coverage includes $code"
    else
      fail "public blocker coverage includes $code"
    fi
  done

  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  [[ "$fail_count" -eq 0 ]]
  exit $?
fi

if python3 -m py_compile "$SCRIPT"; then pass "syntax"; else fail "syntax"; fi

if python3 "$SCRIPT" --registry "$REGISTRY" --json >"$TMP/default.json"; then
  if jq -e '.status == "pass" and .row_count == 20 and .open_count == 3 and (.warnings | length) == 3' "$TMP/default.json" >/dev/null; then
    pass "default registry shape passes with remaining open warnings"
  else
    fail "default registry envelope"
  fi
else
  fail "default registry command"
fi

if jq -e '
  (.open_rows | length) == 3
  and ([.open_rows[]?.id] | sort) == ["TP-005","TP-017","TP-018"]
  and all(.open_rows[]?; (.required_closure | length) > 0 and (.owner | length) > 0)
' "$TMP/default.json" >/dev/null; then
  pass "default registry exposes machine-readable open rows"
else
  fail "default registry exposes machine-readable open rows"
fi

if jq -e '
  (.expected_readiness_blockers | length) == 6
  and ([.expected_readiness_blockers[]?] | sort) == [
    "github_release_assets_missing",
    "github_release_missing_or_draft",
    "install_proxy_checksum_mismatch",
    "joshua_release_signoff_missing",
    "remote_green_runs_missing",
    "remote_workflows_missing"
  ]
  and ([.readiness_blocker_coverage[]?.code] | sort) == [
    "github_release_assets_missing",
    "github_release_missing_or_draft",
    "install_proxy_checksum_mismatch",
    "joshua_release_signoff_missing",
    "remote_green_runs_missing",
    "remote_repo_private",
    "remote_workflows_missing"
  ]
  and (([.readiness_blocker_coverage[]?.code] - ["remote_repo_private"]) | sort) == (.expected_readiness_blockers | sort)
  and all(.readiness_blocker_coverage[]?; .status == "open" and (.registry_rows | length) > 0)
' "$TMP/default.json" >/dev/null; then
  pass "default registry maps every live readiness blocker to open rows"
else
  fail "default registry maps every live readiness blocker to open rows"
fi

if python3 "$SCRIPT" --registry "$REGISTRY" --release --json >"$TMP/release.json"; then
  fail "release mode must fail while rows remain open"
else
  if jq -e '.status == "fail" and (.errors[]?.code == "release_blocked_open_row")' "$TMP/release.json" >/dev/null; then
    pass "release mode blocks open rows"
  else
    fail "release mode failure shape"
  fi
fi

cat >"$TMP/duplicate.md" <<'EOF'
# Fixture

| ID | Class | Severity | Status | Owner | Source evidence | Required closure |
|---|---|---:|---|---|---|---|
| TP-001 | one | P0 | open | Flywheel | fixture | close it |
| TP-001 | two | P0 | open | Flywheel | fixture | close it |
EOF

if python3 "$SCRIPT" --registry "$TMP/duplicate.md" --json >"$TMP/duplicate.json"; then
  fail "duplicate id fixture must fail"
else
  if jq -e '.status == "fail" and any(.errors[]?; .code == "duplicate_id")' "$TMP/duplicate.json" >/dev/null; then
    pass "duplicate ids fail"
  else
    fail "duplicate id failure shape"
  fi
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
