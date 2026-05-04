#!/usr/bin/env bash
set -euo pipefail

REAL="${INFISICAL_REAL:-/opt/homebrew/bin/infisical}"

block() {
  printf 'INFISICAL_SAFE_BLOCKED: %s\n' "$1" >&2
  printf 'Use: infisical-safe secrets list --silent --output=json | jq -r .[].secretKey\n' >&2
  exit 2
}

has_arg() {
  local needle="$1" arg; shift || true
  for arg; do [[ "$arg" == "$needle" ]] && return 0; done
  return 1
}

json_out() {
  local arg prev=""
  shift || true
  for arg; do
    case "$arg" in
      --output=json|--format=json) return 0 ;;
      json) [[ "$prev" == "--output" || "$prev" == "--format" ]] && return 0 ;;
    esac
    prev="$arg"
  done
  return 1
}

allow() {
  if [[ "${INFISICAL_SAFE_DRY_RUN:-0}" == "1" ]]; then
    printf 'INFISICAL_SAFE_ALLOW:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  exec "$REAL" "$@"
}

[[ "$#" -gt 0 ]] || allow "$@"

case "${1:-}" in
  login|logout|init|version|--version|-v|help|--help|-h)
    allow "$@"
    ;;
  run|export)
    block "infisical $1 can materialize secret values in pane-visible output"
    ;;
  secrets)
    sub="${2:-}"
    case "$sub" in
      list)
        has_arg "--plain" "$@" && block "plain output is pane-visible secret material"
        has_arg "--silent" "$@" || block "secrets list must be silent"
        json_out _ "$@" || block "secrets list must emit JSON for key-only filtering"
        allow "$@"
        ;;
      get)
        has_arg "--plain" "$@" && block "plain secret reads are pane-visible"
        has_arg "--silent" "$@" || block "secrets get must be silent and redirected by caller"
        allow "$@"
        ;;
      *)
        block "infisical secrets $sub is not allowlisted by infisical-safe"
        ;;
    esac
    ;;
  *)
    block "use the real infisical binary only after reviewing output shape"
    ;;
esac
