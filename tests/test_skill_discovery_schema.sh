#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/skill-discovery-schema.XXXXXX")"
export TMP
trap 'python3 -c "import os, shutil; shutil.rmtree(os.environ[\"TMP\"], ignore_errors=True)"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

export FLYWHEEL_SKILL_DISCOVERY_PATH="$TMP/skill-discoveries.jsonl"
export APPEND_SAFE_WRITE="$ROOT/.flywheel/scripts/append-safe-write.sh"

"$BIN" skill-discovery --schema --json >"$TMP/schema.json"
jq -e '.schema_version == "skill-discovery/v1" and (.discovery_kinds | length == 7)' "$TMP/schema.json" >/dev/null \
  && pass "01_bead_schema_predicate" || fail "01_bead_schema_predicate"
jq -e '.discovery_kinds == ["pattern-emerged","pattern-recurrence","skill-search-miss","skill-found-but-incomplete","skill-broken-yaml","cross-repo-shared-pattern","anti-pattern"]' "$TMP/schema.json" >/dev/null \
  && pass "02_discovery_kind_enum_exact" || fail "02_discovery_kind_enum_exact"
jq -e '(.required_fields | length == 12) and (.required_fields | index("promotion_signal")) and (.required_fields | index("blocking_current_work"))' "$TMP/schema.json" >/dev/null \
  && pass "03_required_fields_listed" || fail "03_required_fields_listed"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 3 && "$fail_count" -eq 0 ]]
