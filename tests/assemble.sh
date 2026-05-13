#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/assemble.py"
FIXTURE="$ROOT/fixtures/assemble/source"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-assemble.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if python3 -m py_compile "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

cp -R "$FIXTURE" "$TMP/source"
git -C "$TMP/source" init -q
git -C "$TMP/source" config user.email "fixture@example.invalid"
git -C "$TMP/source" config user.name "Fixture Operator"
printf '%s\n' '.flywheel/extraction/' >>"$TMP/source/.git/info/exclude"
git -C "$TMP/source" add README.md ARCHITECTURE.md docs scripts site rewrite templates private.env logs .flywheel
git -C "$TMP/source" commit -qm "fixture"

if python3 "$SCRIPT" --source "$TMP/source" --clean --json >"$TMP/assemble.json" \
  && jq -e '
    .status == "pass"
    and .classification_count == 12
    and .copied_count == 9
    and .overlay_count == 3
    and .denylist_excluded_count == 1
    and .manual_review_count == 4
    and .source_git_status_unchanged == true
  ' "$TMP/assemble.json" >/dev/null; then
  pass "assembly summary"
else
  fail "assembly summary"
fi

staging="$(jq -r '.staging' "$TMP/assemble.json")"
manual_review="$(jq -r '.manual_review_path' "$TMP/assemble.json")"
manifest="$(jq -r '.manifest_path' "$TMP/assemble.json")"

if [[ -f "$staging/docs/public-install.md" ]] \
  && [[ -f "$staging/README.md" ]] \
  && [[ -f "$staging/ARCHITECTURE.md" ]] \
  && [[ -f "$staging/site/assets/loop-map.svg" ]] \
  && [[ -f "$staging/scripts/doctor.sh" ]] \
  && [[ -f "$staging/rewrite/private-pattern.md" ]] \
  && [[ -f "$staging/templates/loop.json" ]] \
  && [[ -f "$staging/templates/loop.json.tmpl" ]] \
  && [[ ! -e "$staging/private.env" ]] \
  && [[ ! -e "$staging/.flywheel/PLANS/live-plan.md" ]] \
  && [[ ! -e "$staging/logs/dispatch-log.jsonl" ]]; then
  pass "staging contains engine artifacts only"
else
  fail "staging contains engine artifacts only"
fi

private_pattern="$(PYTHONPATH="$ROOT/scripts" python3 - <<'PY'
import re
from depersonalize import DEFAULT_TABLE, load_replacement_table, repo_root

row_ids = {
    "operator-home-path",
    "operator-full-name",
    "operator-email",
    "blackfoot-client",
}
rows = [row for row in load_replacement_table(repo_root() / DEFAULT_TABLE) if row.id in row_ids]
print("|".join(re.escape(row.private_value) for row in rows))
PY
)"

if ! rg -n "$private_pattern" "$staging" >/dev/null; then
  pass "staging depersonalized"
else
  fail "staging depersonalized"
fi

if jq -e '.schema_version == "flywheel.assembly.v0" and .copied_count == 9 and .manual_review_count == 4 and .denylist_excluded_count == 1 and .source_git_status_unchanged == true' "$manifest" >/dev/null \
  && [[ "$(wc -l <"$manual_review" | tr -d ' ')" == "4" ]] \
  && jq -e 'all(.signed_off_by; . == null)' "$manual_review" >/dev/null; then
  pass "manifest and manual-review queue"
else
  fail "manifest and manual-review queue"
fi

if [[ -z "$(git -C "$TMP/source" status --porcelain)" ]]; then
  pass "source tree remains clean"
else
  fail "source tree remains clean"
fi

if python3 "$ROOT/scripts/depersonalize.py" --scan-table --root "$staging" --json >"$TMP/depersonalize.json" \
  && jq -e '.status == "pass" and (.findings | length == 0)' "$TMP/depersonalize.json" >/dev/null; then
  pass "staging scan clean"
else
  fail "staging scan clean"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
