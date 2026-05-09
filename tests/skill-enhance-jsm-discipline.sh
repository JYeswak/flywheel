#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/skill-enhance-jsm-discipline.sh"
TMP="$(mktemp -d -t skill-enhance-jsm.XXXXXX)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; find "$TMP" -mindepth 1 -type f -delete 2>/dev/null || true; find "$TMP" -mindepth 1 -type d -delete 2>/dev/null || true; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

cat >"$TMP/jsm-list.json" <<'JSON'
{
  "skills": [
    {"name": "managed-skill", "version": 2, "is_saved": true, "is_jeffreys": true, "installed_at": "2026-05-08"},
    {"name": "local-skill", "version": 1, "is_saved": false, "is_jeffreys": false}
  ],
  "count": 2
}
JSON

bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

"$SCRIPT" --audit --skills managed-skill,local-skill,absent-skill --jsm-list-json "$TMP/jsm-list.json" --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.status == "pass" and .managed == ["managed-skill"] and (.unmanaged | index("local-skill")) and (.absent | index("absent-skill"))' "audit classifies managed and unmanaged"

cat >"$TMP/managed-direct.md" <<'MD'
# DISPATCH
Title: [skill-enhance-managed-skill] adopt pattern
Skill path: `/Users/josh/.claude/skills/managed-skill/SKILL.md`
Pre-flight: run `jsm status managed-skill --json`.
Edit /Users/josh/.claude/skills/managed-skill/SKILL.md directly.
MD

set +e
"$SCRIPT" --validate-packet "$TMP/managed-direct.md" --jsm-list-json "$TMP/jsm-list.json" --json >"$TMP/managed-direct.json"
rc=$?
set -e
[[ "$rc" -eq 1 ]] && pass "managed direct mutation refused rc" || fail "managed direct mutation refused rc=$rc"
assert_jq "$TMP/managed-direct.json" '.status == "refused" and (.errors[] | contains("JSM-managed"))' "managed direct mutation refused json"

cat >"$TMP/managed-patch.md" <<'MD'
# DISPATCH
Title: [skill-enhance-managed-skill] adopt pattern
Skill path: `/Users/josh/.claude/skills/managed-skill/SKILL.md`
Pre-flight: run `jsm status managed-skill --json`.
Direct mutation forbidden. Produce a jsm-push-ready patch artifact, do not mutate live.
MD
"$SCRIPT" --validate-packet "$TMP/managed-patch.md" --jsm-list-json "$TMP/jsm-list.json" --json >"$TMP/managed-patch.json"
assert_jq "$TMP/managed-patch.json" '.status == "pass" and .skills[0].managed == true and .skills[0].push_ready_patch_present == true' "managed patch artifact passes"

cat >"$TMP/unmanaged-missing-artifact.md" <<'MD'
# DISPATCH
Title: [skill-enhance-local-skill] adopt pattern
Skill path: `/Users/josh/.claude/skills/local-skill/SKILL.md`
Pre-flight: run `jsm status local-skill --json`.
Modify /Users/josh/.claude/skills/local-skill/SKILL.md directly.
MD
set +e
"$SCRIPT" --validate-packet "$TMP/unmanaged-missing-artifact.md" --jsm-list-json "$TMP/jsm-list.json" --json >"$TMP/unmanaged-missing-artifact.json"
rc=$?
set -e
[[ "$rc" -eq 1 ]] && pass "unmanaged missing artifact refused rc" || fail "unmanaged missing artifact refused rc=$rc"
assert_jq "$TMP/unmanaged-missing-artifact.json" '.status == "refused" and (.errors[] | contains("jsm-import-ready"))' "unmanaged missing import artifact refused"

cat >"$TMP/unmanaged-import.md" <<'MD'
# DISPATCH
Title: [skill-enhance-local-skill] adopt pattern
Skill path: `/Users/josh/.claude/skills/local-skill/SKILL.md`
Pre-flight: run `jsm status local-skill --json`.
May mutate directly after writing a jsm-import-ready artifact.
MD
"$SCRIPT" --validate-packet "$TMP/unmanaged-import.md" --jsm-list-json "$TMP/jsm-list.json" --json >"$TMP/unmanaged-import.json"
assert_jq "$TMP/unmanaged-import.json" '.status == "pass" and .skills[0].managed == false and .skills[0].import_ready_patch_present == true' "unmanaged import artifact passes"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
