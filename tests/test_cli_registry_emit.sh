#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REGISTRY="$ROOT/.flywheel/cli-registry.json"
EMIT="$ROOT/.flywheel/scripts/cli-registry-emit.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/cli-registry.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL %s\n' "$1" >&2
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

assert_text() {
  local file="$1" pattern="$2" label="$3"
  if rg -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,120p' "$file" >&2 || true
  fi
}

bash -n "$EMIT" && pass "emit_shell_syntax" || fail "emit_shell_syntax"
bash -n "$ROOT/.flywheel/scripts/tmp-prune.sh" && pass "tmp_prune_shell_syntax" || fail "tmp_prune_shell_syntax"
jq empty "$REGISTRY" && pass "registry_json_valid" || fail "registry_json_valid"

assert_jq "$REGISTRY" '
  .schema_version == "flywheel-cli-registry/v1"
  and (.surfaces | length) >= 8
  and all(.surfaces[];
    (.name | length > 0)
    and (.path | length > 0)
    and (.lane | length > 0)
    and (.usage | length > 0)
    and (.summary | length > 0)
    and (.schema_id | length > 0)
    and (.owner | length > 0)
    and ((.exit_codes | type) == "object")
    and ((.args | type) == "array")
    and ((.examples | type) == "array")
    and ((.notes | type) == "array")
    and ((.output_formats | type) == "array")
  )
' "registry_required_shape"

while IFS= read -r path; do
  [ -n "$path" ] || continue
  if [ -e "$ROOT/$path" ]; then
    pass "registry_path_exists/$path"
  else
    fail "registry_path_exists/$path"
  fi
done < <(jq -r '.surfaces[].path' "$REGISTRY")

while IFS= read -r path; do
  [ -n "$path" ] || continue
  basename="$(basename "$path")"
  if jq -e --arg path "$path" --arg basename "$basename" \
    '.surfaces[] | select(.path == $path or .name == $basename)' "$REGISTRY" >/dev/null; then
    pass "marked_cli_registered/$path"
  else
    fail "marked_cli_registered/$path"
  fi
done < <(rg -l '^# flywheel-cli-surface: true$' "$ROOT/.flywheel/scripts" | sed "s#^$ROOT/##" | sort)

"$EMIT" tmp-prune.sh --mode help >"$TMP/emit-help.txt"
"$ROOT/.flywheel/scripts/tmp-prune.sh" --help >"$TMP/tmp-prune-help.txt"
diff -u "$TMP/emit-help.txt" "$TMP/tmp-prune-help.txt" >"$TMP/help.diff" && pass "tmp_prune_help_roundtrip" || {
  fail "tmp_prune_help_roundtrip"
  cat "$TMP/help.diff" >&2
}

assert_text "$TMP/emit-help.txt" '^usage: tmp-prune\.sh ' "help_usage_line"
assert_text "$TMP/emit-help.txt" 'Arguments:' "help_arguments_section"
assert_text "$TMP/emit-help.txt" 'Examples:' "help_examples_section"
assert_text "$TMP/emit-help.txt" 'Notes:' "help_notes_section"

"$EMIT" tmp-prune.sh --mode info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '
  .name == "tmp-prune.sh"
  and .lane == "storage"
  and .schema_id == "tmp-prune/v1"
  and (.output_formats | index("json"))
' "info_json_contract"

"$EMIT" tmp-prune.sh --mode examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '.name == "tmp-prune.sh" and (.examples | length) >= 2' "examples_json_contract"

"$EMIT" tmp-prune.sh --mode schema >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '
  .schema_version == "flywheel-cli-registry.emit/v1"
  and (.required_registry_fields | index("args"))
  and (.required_registry_fields | index("examples"))
  and (.required_registry_fields | index("lane"))
  and (.required_registry_fields | index("exit_codes"))
' "schema_contract"

"$EMIT" tmp-prune.sh --mode version --json >"$TMP/version.json"
assert_jq "$TMP/version.json" '
  .schema_version == "flywheel-cli-registry.version/v1"
  and .name == "tmp-prune.sh"
  and .registry_schema_version == "flywheel-cli-registry/v1"
  and .registry_version == "1.0.0"
  and .surface_schema_id == "tmp-prune/v1"
' "version_json_contract"

if "$EMIT" not-registered.sh --mode help >"$TMP/missing.out" 2>"$TMP/missing.err"; then
  fail "missing_surface_blocks"
else
  rg -q 'not found in registry' "$TMP/missing.err" && pass "missing_surface_blocks" || fail "missing_surface_blocks"
fi

if [ "$fail_count" -ne 0 ]; then
  printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
