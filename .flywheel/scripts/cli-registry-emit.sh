#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
REGISTRY="${FLYWHEEL_CLI_REGISTRY:-$ROOT/.flywheel/cli-registry.json}"
MODE="help"
JSON_OUT=0
SCRIPT_NAME=""

usage() {
  cat <<'USAGE'
usage: cli-registry-emit.sh SCRIPT [--mode help|info|examples|schema] [--registry PATH] [--json]

Emits canonical CLI surface text from .flywheel/cli-registry.json.
USAGE
}

fail_usage() {
  printf 'ERROR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      [ -n "${2:-}" ] || fail_usage "--mode requires value"
      MODE="$2"
      shift 2
      ;;
    --registry)
      [ -n "${2:-}" ] || fail_usage "--registry requires PATH"
      REGISTRY="$2"
      shift 2
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      fail_usage "unknown option: $1"
      ;;
    *)
      if [ -z "$SCRIPT_NAME" ]; then
        SCRIPT_NAME="$1"
      else
        fail_usage "unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

[ -n "$SCRIPT_NAME" ] || fail_usage "missing SCRIPT"
[ -r "$REGISTRY" ] || { printf 'ERROR: registry not readable: %s\n' "$REGISTRY" >&2; exit 3; }
command -v jq >/dev/null 2>&1 || { printf 'ERROR: jq is required\n' >&2; exit 69; }

entry_filter='
  .surfaces[]
  | select(.name == $key or .path == $key or (.path | split("/")[-1]) == $key)
'

if ! jq -e --arg key "$SCRIPT_NAME" "$entry_filter" "$REGISTRY" >/dev/null; then
  printf 'ERROR: CLI surface not found in registry: %s\n' "$SCRIPT_NAME" >&2
  exit 1
fi

case "$MODE" in
  help)
    jq -r --arg key "$SCRIPT_NAME" "$entry_filter"'
      | def arg_line:
          "  " + .flag
          + (if (.value_hint // "") != "" then " " + .value_hint else "" end)
          + (if .required then " (required)" else "" end)
          + "\n      " + .desc;
        "usage: " + .usage
        + "\n\n" + .summary
        + "\n\nArguments:\n" + ((.args // []) | map(arg_line) | join("\n"))
        + "\n\nExamples:\n" + ((.examples // []) | map("  " + .command) | join("\n"))
        + "\n\nNotes:\n" + ((.notes // []) | map("  " + .) | join("\n"))
    ' "$REGISTRY"
    ;;
  info)
    if [ "$JSON_OUT" -eq 1 ]; then
      jq -c --arg key "$SCRIPT_NAME" "$entry_filter" "$REGISTRY"
    else
      jq -r --arg key "$SCRIPT_NAME" "$entry_filter"'
        | "name=\(.name)\npath=\(.path)\nlane=\(.lane)\nowner=\(.owner)\nschema_id=\(.schema_id)\noutput_formats=\(.output_formats | join(","))"
      ' "$REGISTRY"
    fi
    ;;
  examples)
    if [ "$JSON_OUT" -eq 1 ]; then
      jq -c --arg key "$SCRIPT_NAME" "$entry_filter | {name, examples}" "$REGISTRY"
    else
      jq -r --arg key "$SCRIPT_NAME" "$entry_filter | (.examples // [])[] | .command" "$REGISTRY"
    fi
    ;;
  schema)
    jq -nc --arg schema_version "flywheel-cli-registry.emit/v1" --arg command "$SCRIPT_NAME" --arg registry "$REGISTRY" '{
      schema_version:$schema_version,
      command:$command,
      registry:$registry,
      required_registry_fields:["name","summary","args","examples","notes","schema_id","owner","output_formats"]
    }'
    ;;
  *)
    fail_usage "unknown mode: $MODE"
    ;;
esac
