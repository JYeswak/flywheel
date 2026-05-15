#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/canonical-root-drift-fleet-check.sh"
SYNC="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/canonical-root-drift-fleet-check-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

BEGIN="<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->"
END="<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->"
pass_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

write_repo() {
  local repo="$1" source="$2"
  mkdir -p "$repo/.flywheel"
  cat >"$repo/.flywheel/ownership.json" <<'JSON'
{
  "schema_version": "flywheel.canonical_ownership.v1",
  "canonical_owner_class": "flywheel",
  "owned_canonical_paths": [
    {"path": "AGENTS.md", "owner_class": "flywheel"},
    {"path": ".flywheel/AGENTS-CANONICAL.md", "owner_class": "flywheel"}
  ]
}
JSON
  cp "$source" "$repo/.flywheel/AGENTS-CANONICAL.md"
  {
    printf '# Local repo\n\n'
    printf '%s\n' "$BEGIN"
    cat "$source"
    printf '%s\n' "$END"
  } >"$repo/AGENTS.md"
}

bash -n "$SCRIPT" && pass "script_syntax"
"$SCRIPT" --info --json | jq -e '.schema_version == "canonical-root-drift-fleet-check/v1" and .bounded == true' >/dev/null && pass "info_json"
"$SCRIPT" --examples >/dev/null && pass "examples"

source="$TMP/source/AGENTS.md"
mkdir -p "$(dirname "$source")"
printf '# Canonical\n\n## L61 - one\nbody\n\n## L70 - two\nbody\n' >"$source"
write_repo "$TMP/repos/repo-a" "$source"
write_repo "$TMP/repos/repo-b" "$source"

"$SCRIPT" --sync "$SYNC" --source "$source" --root "$TMP/repos" --timeout 5 --json >"$TMP/pass.json"
assert_jq "$TMP/pass.json" '.status == "pass" and .canonical_root_drift_count == 0 and .timed_out == false and .root_target_count == 2' "clean_roots_pass"

awk '/L70/{next} {print}' "$TMP/repos/repo-b/AGENTS.md" >"$TMP/repos/repo-b/AGENTS.tmp"
mv "$TMP/repos/repo-b/AGENTS.tmp" "$TMP/repos/repo-b/AGENTS.md"
set +e
"$SCRIPT" --sync "$SYNC" --source "$source" --root "$TMP/repos" --timeout 5 --json >"$TMP/drift.json"
drift_rc=$?
set -e
[[ "$drift_rc" -eq 1 ]] || fail "drift exits 1"
assert_jq "$TMP/drift.json" '.status == "fail" and .canonical_root_drift_count == 1 and (.drifted_repos[0].repo | endswith("repo-b"))' "drift_detected"

fake_sync="$TMP/fake-sync.sh"
cat >"$fake_sync" <<'EOF'
#!/usr/bin/env bash
sleep 2
printf '{"status":"ok","root_drifted_count":0}\n'
EOF
chmod +x "$fake_sync"
set +e
"$SCRIPT" --sync "$fake_sync" --source "$source" --root "$TMP/repos" --timeout 1 --json >"$TMP/timeout.json"
timeout_rc=$?
set -e
[[ "$timeout_rc" -eq 124 ]] || fail "timeout exits 124"
assert_jq "$TMP/timeout.json" '.status == "error" and .classification == "sync_helper_timeout" and .timed_out == true' "timeout_classified"

## Direct-repo-root short-circuit regression (flywheel-fppjx)
##
## When --root points DIRECTLY at a repo (not a parent dir), the sync
## helper must use the known .flywheel/AGENTS-CANONICAL.md path instead
## of recursing the repo tree. Recursion blows the dispatch timeout budget
## when many explicit roots are passed (g0qv9 receipt: 67 target repos).
##
## Regression strategy: build a repo whose tree contains decoy nested
## .flywheel/AGENTS-CANONICAL.md files. The short-circuit picks only the
## top-level file; the old recursive find would have grabbed decoys too
## and inflated root_target_count.
deep="$TMP/repos/repo-deep"
mkdir -p "$deep/.flywheel"
cat >"$deep/.flywheel/ownership.json" <<'JSON'
{
  "schema_version": "flywheel.canonical_ownership.v1",
  "canonical_owner_class": "flywheel",
  "owned_canonical_paths": [
    {"path": "AGENTS.md", "owner_class": "flywheel"},
    {"path": ".flywheel/AGENTS-CANONICAL.md", "owner_class": "flywheel"}
  ]
}
JSON
cp "$source" "$deep/.flywheel/AGENTS-CANONICAL.md"
{
  printf '# Local repo\n\n'
  printf '%s\n' "$BEGIN"
  cat "$source"
  printf '%s\n' "$END"
} >"$deep/AGENTS.md"
mkdir -p "$deep/sub1/.flywheel" "$deep/sub2/sub3/.flywheel"
printf 'decoy-1\n' >"$deep/sub1/.flywheel/AGENTS-CANONICAL.md"
printf 'decoy-2\n' >"$deep/sub2/sub3/.flywheel/AGENTS-CANONICAL.md"

"$SCRIPT" --sync "$SYNC" --source "$source" --root "$deep" --timeout 5 --json >"$TMP/direct-root.json"
assert_jq "$TMP/direct-root.json" '.status == "pass" and .root_target_count == 1 and .timed_out == false' "direct_repo_root_no_recursive_scan"

# Performance regression: with --root set to a direct repo path, the
# helper should complete well under a tight timeout because it does not
# run a recursive find.
"$SCRIPT" --sync "$SYNC" --source "$source" --root "$deep" --timeout 2 --json >"$TMP/perf.json"
assert_jq "$TMP/perf.json" '.status == "pass" and .timed_out == false' "direct_repo_root_completes_under_short_timeout"

printf 'PASS cases=4 assertions=%s failures=0\n' "$pass_count"
