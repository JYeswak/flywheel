#!/usr/bin/env bash
set -euo pipefail

umask 077

BLOCKED_EXIT=2

usage() {
  cat <<'USAGE'
Usage:
  safe-probe.sh env-names
  safe-probe.sh has-env NAME
  safe-probe.sh -- COMMAND [ARG...]
  safe-probe.sh COMMAND [ARG...]

Runs diagnostics with secret-substrate path guards and name-only env helpers.
Blocked probes exit 2 and do not print captured command output.
USAGE
}

die_blocked() {
  printf 'SAFE_PROBE_BLOCKED: %s\n' "$1" >&2
  exit "$BLOCKED_EXIT"
}

is_identifier() {
  case "$1" in
    ''|[0-9]*|*[!A-Za-z0-9_]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

is_secretish_env_name() {
  printf '%s\n' "$1" | grep -Eiq '(TOKEN|SECRET|PASSWORD|PASS|AUTH|CREDENTIAL|PRIVATE_KEY|API_KEY|INFISICAL|GITHUB|GH_|AWS|CLOUDFLARE|CF_|NPM|OPENAI|ANTHROPIC)'
}

env_is_set() {
  local name="$1"
  eval '[ "${'"$name"'+x}" = x ]'
}

env_is_nonempty() {
  local name="$1"
  eval '[ -n "${'"$name"'}" ]'
}

env_names() {
  local name status
  compgen -e | sort -u | while IFS= read -r name; do
    is_identifier "$name" || continue
    is_secretish_env_name "$name" || continue
    if env_is_nonempty "$name"; then
      status="SET"
    else
      status="EMPTY"
    fi
    printf '%s=%s\n' "$name" "$status"
  done
}

has_env() {
  local name="$1"
  local status
  is_identifier "$name" || die_blocked "invalid environment variable name"
  if ! env_is_set "$name"; then
    status="UNSET"
  elif env_is_nonempty "$name"; then
    status="SET"
  else
    status="EMPTY"
  fi
  printf '%s=%s\n' "$name" "$status"
}

normalize_path() {
  case "$1" in
    \~)
      printf '%s\n' "$HOME"
      ;;
    \~/*)
      printf '%s/%s\n' "$HOME" "${1#~/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

path_is_secret_substrate() {
  local raw="$1"
  local path
  path="$(normalize_path "$raw")"

  case "$path" in
    "$HOME/.opencode/secrets"|"$HOME/.opencode/secrets/"*|*/.opencode/secrets|*/.opencode/secrets/*)
      return 0
      ;;
    "$HOME/.config/infisical/"*.env|*/.config/infisical/*.env|"$HOME/.config/infisical/"*cache*|*/.config/infisical/*cache*)
      return 0
      ;;
    "$HOME/.config/gh/hosts.yml"|*/.config/gh/hosts.yml|"$HOME/.git-credentials"|*/.git-credentials|"$HOME/.netrc"|*/.netrc)
      return 0
      ;;
    "$HOME/.npmrc"|*/.npmrc|"$HOME/.cargo/credentials"|*/.cargo/credentials|"$HOME/.aws/credentials"|*/.aws/credentials)
      return 0
      ;;
    "$HOME/.ssh/id_rsa"|"$HOME/.ssh/id_ed25519"|*/.ssh/id_rsa|*/.ssh/id_ed25519|*.pem|*.p12|*.key)
      return 0
      ;;
    /tmp/infisical-export.*|/tmp/*credential-helper*|*/credential-helper-output*|*/git-credential*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

dir_contains_secret_substrate() {
  local dir="$1"
  [ -d "$dir" ] || return 1

  find "$dir" \
    \( \
      -path '*/.opencode/secrets' -o \
      -path '*/.opencode/secrets/*' -o \
      -path '*/.config/infisical/*.env' -o \
      -path '*/.config/infisical/*cache*' -o \
      -path '*/.config/gh/hosts.yml' -o \
      -name '.git-credentials' -o \
      -name '.netrc' -o \
      -name '.npmrc' -o \
      -path '*/.aws/credentials' -o \
      -path '*/.cargo/credentials' -o \
      -path '*/.ssh/id_rsa' -o \
      -path '*/.ssh/id_ed25519' -o \
      -name '*.pem' -o \
      -name '*.p12' -o \
      -name '*.key' -o \
      -name 'credential-helper-output*' -o \
      -name 'git-credential*' \
    \) -print -quit 2>/dev/null | grep -q .
}

check_path_args() {
  local arg path
  for arg in "$@"; do
    [ "$arg" = "--" ] && continue
    path="$(normalize_path "$arg")"
    if path_is_secret_substrate "$path"; then
      die_blocked "argument targets secret substrate: $arg"
    fi
    if [ -d "$path" ] && dir_contains_secret_substrate "$path"; then
      die_blocked "directory contains secret substrate: $arg"
    fi
  done
}

command_is_blocked() {
  local cmd="$1"
  shift || true
  local base
  base="$(basename "$cmd")"

  case "$base" in
    env|printenv|set|export)
      die_blocked "use safe-probe.sh env-names or has-env instead of printing environment values"
      ;;
    bash|sh|zsh|fish|python|python3|ruby|perl|node)
      die_blocked "shell/interpreter probes can bypass argument guards"
      ;;
    gh)
      if [ "${1:-}" = "auth" ] && [ "${2:-}" = "token" ]; then
        die_blocked "gh auth token prints a credential"
      fi
      ;;
    git)
      if [ "${1:-}" = "credential" ]; then
        die_blocked "git credential helpers can print credential bodies"
      fi
      ;;
    git-credential*)
      die_blocked "git credential helpers can print credential bodies"
      ;;
    infisical)
      case "${1:-}" in
        export|run)
          die_blocked "infisical $1 can expose secret values"
          ;;
        secrets)
          if [ "${2:-}" = "get" ]; then
            die_blocked "infisical secrets get can print secret values"
          fi
          ;;
      esac
      ;;
    op)
      case "${1:-}" in
        read)
          die_blocked "op read can print secret values"
          ;;
        item)
          if [ "${2:-}" != "list" ]; then
            die_blocked "op item subcommands other than list can print secret values"
          fi
          ;;
      esac
      ;;
    cf-secret)
      case "${1:-}" in
        --probe|list|--help|-h|'')
          ;;
        *)
          die_blocked "cf-secret value reads must use --probe or list"
          ;;
      esac
      ;;
    security)
      local arg
      for arg in "$@"; do
        [ "$arg" = "-w" ] && die_blocked "security -w prints keychain password values"
      done
      ;;
    aws)
      if [ "${1:-}" = "configure" ] && [ "${2:-}" = "get" ]; then
        die_blocked "aws configure get can print credential values"
      fi
      ;;
    npm)
      if [ "${1:-}" = "token" ]; then
        die_blocked "npm token commands can print or mutate credentials"
      fi
      if [ "${1:-}" = "config" ] && [ "${2:-}" = "get" ]; then
        local arg lower
        for arg in "$@"; do
          lower="$(printf '%s\n' "$arg" | tr '[:upper:]' '[:lower:]')"
          case "$lower" in
            *token*|*auth*|*password*|*credential*)
              die_blocked "npm config get for credential-shaped keys is unsafe"
              ;;
          esac
        done
      fi
      ;;
  esac
}

file_has_secret_output() {
  local file="$1"
  [ -s "$file" ] || return 1
  grep -Eq 'FAKE_(GITHUB_TOKEN|INFISICAL_CACHE_VALUE)_[0-9]+' "$file" && return 0
  grep -Eq 'gh[pousr]_[A-Za-z0-9_]{20,}' "$file" && return 0
  grep -Eq 'AKIA[0-9A-Z]{16}' "$file" && return 0
  grep -Eiq '(TOKEN|SECRET|PASSWORD|AUTH|CREDENTIAL|PRIVATE_KEY|API_KEY)[A-Z0-9_ -]*=[^[:space:]]{12,}' "$file" && return 0
  return 1
}

run_guarded() {
  local out err rc
  out="$(mktemp "${TMPDIR:-/tmp}/safe-probe-out.XXXXXX")"
  err="$(mktemp "${TMPDIR:-/tmp}/safe-probe-err.XXXXXX")"
  SAFE_PROBE_OUT="$out"
  SAFE_PROBE_ERR="$err"
  trap 'rm -f "${SAFE_PROBE_OUT:-}" "${SAFE_PROBE_ERR:-}"' EXIT HUP INT TERM

  set +e
  "$@" >"$out" 2>"$err"
  rc=$?
  set -e

  if file_has_secret_output "$out" || file_has_secret_output "$err"; then
    die_blocked "command output matched credential-shaped content; output suppressed"
  fi

  cat "$out"
  cat "$err" >&2
  rm -f "$out" "$err"
  trap - EXIT HUP INT TERM
  return "$rc"
}

main() {
  if [ "$#" -eq 0 ]; then
    usage >&2
    exit 64
  fi

  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    env-names)
      [ "$#" -eq 1 ] || die_blocked "env-names takes no arguments"
      env_names
      exit 0
      ;;
    has-env)
      [ "$#" -eq 2 ] || die_blocked "has-env requires exactly one variable name"
      has_env "$2"
      exit 0
      ;;
    --)
      shift
      [ "$#" -gt 0 ] || die_blocked "-- requires a command"
      ;;
  esac

  command_is_blocked "$@"
  check_path_args "$@"
  run_guarded "$@"
}

main "$@"
