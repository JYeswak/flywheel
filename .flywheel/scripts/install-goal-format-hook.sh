#!/usr/bin/env bash
set -euo pipefail

SOURCE="${CODEX_GOAL_FORMAT_HOOK_SOURCE:-$HOME/.claude/skills/codex-goal-format-enforcement/scripts/hook.sh}"
TARGET="${CODEX_GOAL_FORMAT_HOOK_TARGET:-$HOME/.claude/hooks/PreToolUse-codex-goal-format-enforcement.sh}"
json=0
uninstall=0

usage() {
  cat <<'EOF'
usage: install-goal-format-hook.sh [--json] [--uninstall]

Idempotently installs the Codex /goal dispatch PreToolUse hook by symlinking
the skill implementation into ~/.claude/hooks.
EOF
}

emit() {
  local status="$1" action="$2"
  if [[ "$json" -eq 1 ]]; then
    jq -nc \
      --arg schema "codex-goal-format-hook-installer/v0.1" \
      --arg status "$status" \
      --arg action "$action" \
      --arg source "$SOURCE" \
      --arg target "$TARGET" \
      '{schema_version:$schema,status:$status,action:$action,source:$source,target:$target}'
  else
    printf 'goal-format-hook status=%s action=%s target=%s\n' "$status" "$action" "$TARGET"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --uninstall) uninstall=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$uninstall" -eq 1 ]]; then
  if [[ -L "$TARGET" ]]; then
    rm "$TARGET"
    emit "pass" "uninstalled"
  elif [[ -e "$TARGET" ]]; then
    emit "blocked" "target_exists_not_symlink"
    exit 1
  else
    emit "pass" "already_absent"
  fi
  exit 0
fi

if [[ ! -x "$SOURCE" ]]; then
  emit "blocked" "source_missing_or_not_executable"
  exit 1
fi

mkdir -p "$(dirname "$TARGET")"
if [[ -e "$TARGET" && ! -L "$TARGET" ]]; then
  emit "blocked" "target_exists_not_symlink"
  exit 1
fi

ln -sfn "$SOURCE" "$TARGET"
emit "pass" "installed"
