#!/usr/bin/env bash
set -euo pipefail

RECIPES_FILE="${SLB_RECIPES_FILE:-$HOME/.flywheel/slb-recipes.json}"
RECIPE_ID=""
PATTERN=""
DESCRIPTION=""
PRE_SNAPSHOT=""
EXECUTE=""
POST_VERIFY=""
FALLBACKS=()
APPLY=0
JSON_OUTPUT=0

usage() {
  cat <<'EOF'
Usage: slb-recipe-add.sh --id ID --pattern REGEX --description TEXT \
  --pre-snapshot CMD --execute CMD --post-verify CMD --fallback-if REASON \
  [--fallback-if REASON ...] [--recipes-file PATH] [--apply] [--json]
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --id) RECIPE_ID="${2:-}"; shift 2 ;;
    --pattern) PATTERN="${2:-}"; shift 2 ;;
    --description) DESCRIPTION="${2:-}"; shift 2 ;;
    --pre-snapshot) PRE_SNAPSHOT="${2:-}"; shift 2 ;;
    --execute) EXECUTE="${2:-}"; shift 2 ;;
    --post-verify) POST_VERIFY="${2:-}"; shift 2 ;;
    --fallback-if) FALLBACKS+=("${2:-}"); shift 2 ;;
    --recipes-file) RECIPES_FILE="${2:-}"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --json) JSON_OUTPUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

if [ -z "$RECIPE_ID" ] || [ -z "$PATTERN" ] || [ -z "$DESCRIPTION" ] || \
   [ -z "$PRE_SNAPSHOT" ] || [ -z "$EXECUTE" ] || [ -z "$POST_VERIFY" ] || \
   [ "${#FALLBACKS[@]}" -eq 0 ]; then
  usage >&2
  exit 2
fi

fallback_json="$(printf '%s\n' "${FALLBACKS[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')"

RECIPE_ID="$RECIPE_ID" \
PATTERN="$PATTERN" \
DESCRIPTION="$DESCRIPTION" \
PRE_SNAPSHOT="$PRE_SNAPSHOT" \
EXECUTE="$EXECUTE" \
POST_VERIFY="$POST_VERIFY" \
FALLBACK_JSON="$fallback_json" \
RECIPES_FILE="$RECIPES_FILE" \
APPLY="$APPLY" \
JSON_OUTPUT="$JSON_OUTPUT" \
python3 <<'PY'
import json
import os
import re
import sys

SCHEMA = "flywheel.slb.recipes.v1"


def fail(message, code=2):
    print(message, file=sys.stderr)
    sys.exit(code)


def validate_recipe(recipe):
    for key in ("id", "command_pattern", "description", "safe_execution_protocol", "fallback_to_prompt_if"):
        if not recipe.get(key):
            fail(f"recipe missing {key}")
    try:
        re.compile(recipe["command_pattern"])
    except re.error as exc:
        fail(f"invalid regex: {exc}")
    protocol = recipe["safe_execution_protocol"]
    if not isinstance(protocol, dict):
        fail("safe_execution_protocol must be object")
    for key in ("pre_snapshot", "execute", "post_verify"):
        if not protocol.get(key):
            fail(f"safe_execution_protocol missing {key}")
    fallbacks = recipe["fallback_to_prompt_if"]
    if not isinstance(fallbacks, list) or not all(str(item).strip() for item in fallbacks):
        fail("fallback_to_prompt_if must be a non-empty array")


recipes_file = os.environ["RECIPES_FILE"]
recipe = {
    "id": os.environ["RECIPE_ID"],
    "description": os.environ["DESCRIPTION"],
    "command_pattern": os.environ["PATTERN"],
    "safe_execution_protocol": {
        "pre_snapshot": os.environ["PRE_SNAPSHOT"],
        "execute": os.environ["EXECUTE"],
        "post_verify": os.environ["POST_VERIFY"],
        "audit_log_required": True,
    },
    "fallback_to_prompt_if": json.loads(os.environ["FALLBACK_JSON"]),
}
validate_recipe(recipe)

if os.path.exists(recipes_file):
    try:
        with open(recipes_file, "r", encoding="utf-8") as handle:
            data = json.load(handle)
    except json.JSONDecodeError as exc:
        fail(f"invalid recipes JSON: {exc}")
else:
    data = {"schema_version": SCHEMA, "recipes": []}

if data.get("schema_version") != SCHEMA or not isinstance(data.get("recipes"), list):
    fail("unsupported recipes schema")
for existing in data["recipes"]:
    validate_recipe(existing)

updated = False
for index, existing in enumerate(data["recipes"]):
    if existing.get("id") == recipe["id"] or existing.get("command_pattern") == recipe["command_pattern"]:
        data["recipes"][index] = recipe
        updated = True
        break
if not updated:
    data["recipes"].append(recipe)

apply_change = os.environ["APPLY"] == "1"
if apply_change:
    os.makedirs(os.path.dirname(recipes_file), exist_ok=True)
    tmp_path = recipes_file + ".tmp"
    with open(tmp_path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")
    os.replace(tmp_path, recipes_file)

result = {
    "applied": apply_change,
    "recipe_id": recipe["id"],
    "recipe_count": len(data["recipes"]),
    "recipes_file": recipes_file,
}
if os.environ["JSON_OUTPUT"] == "1":
    print(json.dumps(result, separators=(",", ":"), sort_keys=True))
else:
    print(f"{'applied' if apply_change else 'planned'} {recipe['id']} recipes={len(data['recipes'])}")
PY
