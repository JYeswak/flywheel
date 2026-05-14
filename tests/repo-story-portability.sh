#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/repo-story-portability.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_file() {
  local rel="$1"
  if [[ -s "$ROOT/$rel" ]]; then
    pass "file exists: $rel"
  else
    fail "file exists: $rel"
  fi
}

require_file "scripts/probe_repo_story_portability.py"
require_file "docs/evidence/repo-story-portability.json"

if python3 "$ROOT/scripts/probe_repo_story_portability.py" --write-json "$TMP/current.json" >/dev/null; then
  pass "repo story portability probe runs"
else
  fail "repo story portability probe runs"
fi

if python3 - "$TMP/current.json" "$ROOT/docs/evidence/repo-story-portability.json" <<'PY'
import json
import sys
from pathlib import Path

current = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
saved = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

for payload in (current, saved):
    if payload.get("schema_version") != "zeststream.repo_story_portability_probe.v0":
        raise SystemExit("schema mismatch")
    if payload.get("required_frontend_schema") != "zeststream.repo_frontend_story.v0":
        raise SystemExit("frontend schema missing")
    if payload.get("status") != "pass":
        raise SystemExit("probe did not pass")
    if payload.get("public_safety", {}).get("absolute_paths_in_receipt") is not False:
        raise SystemExit("absolute path safety missing")
    if payload.get("public_safety", {}).get("sibling_repos_edited") is not False:
        raise SystemExit("sibling edit safety missing")

saved_rows = {row["repo_id"]: row for row in saved.get("rows", [])}
for repo_id in ("flywheel", "home_services_proof_product", "food_ordering_proof_product"):
    row = saved_rows.get(repo_id)
    if not row or row.get("status") != "pass":
        raise SystemExit(f"saved row missing or not pass: {repo_id}")
    if row.get("frontend_schema") != "zeststream.repo_frontend_story.v0":
        raise SystemExit(f"frontend schema missing: {repo_id}")
    if row.get("frontend_component_count") != 9:
        raise SystemExit(f"component count mismatch: {repo_id}")
    if row.get("primary_cta") != "Map my workflow":
        raise SystemExit(f"primary CTA mismatch: {repo_id}")
    if not row.get("commit_count") or row["commit_count"] <= 0:
        raise SystemExit(f"commit count missing: {repo_id}")

current_rows = {row["repo_id"]: row for row in current.get("rows", [])}
for repo_id in ("flywheel", "home_services_proof_product", "food_ordering_proof_product"):
    row = current_rows.get(repo_id)
    if row and row.get("local_repo_present") and row.get("status") != "pass":
        raise SystemExit(f"present local repo did not pass: {repo_id}")
PY
then
  pass "repo story portability receipt contract"
else
  fail "repo story portability receipt contract"
fi

if python3 "$ROOT/scripts/depersonalize.py" --scan-table --root "$ROOT/docs/evidence/repo-story-portability.json" --json >/dev/null; then
  pass "repo story portability depersonalization scan"
else
  fail "repo story portability depersonalization scan"
fi

if ! rg -q "/Users/josh|/Developer/" "$ROOT/docs/evidence/repo-story-portability.json"; then
  pass "repo story portability omits absolute local paths"
else
  fail "repo story portability omits absolute local paths"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
