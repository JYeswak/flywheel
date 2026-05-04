#!/usr/bin/env bash
set -euo pipefail

VERSION="agent-mail-pre-allocate-worker-identities/1.0.0"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
session=""
json=0
dry_run=0
apply=0

usage() {
  printf '%s\n' "Usage: agent-mail-pre-allocate-worker-identities.sh [--session <name>] [--dry-run|--apply] [--json]"
  printf '%s\n' "       agent-mail-pre-allocate-worker-identities.sh --help|--info|--examples|--version"
}

info() {
  printf '%s\n' "Pre-allocates durable Agent Mail session:pane identities from latest session-topology.jsonl."
  printf '%s\n' "Writes rows under ~/.local/state/flywheel/agent-mail/sessions without printing tokens."
}

examples() {
  printf '%s\n' "agent-mail-pre-allocate-worker-identities.sh --apply --json"
  printf '%s\n' "agent-mail-pre-allocate-worker-identities.sh --session flywheel --dry-run --json"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session)
      session="${2:?--session requires a value}"
      shift 2
      ;;
    --session=*)
      session="${1#*=}"
      shift
      ;;
    --json)
      json=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --apply)
      apply=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --info)
      info
      exit 0
      ;;
    --examples)
      examples
      exit 0
      ;;
    --version)
      printf '%s\n' "$VERSION"
      exit 0
      ;;
    *)
      printf 'ERR unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ "$dry_run" -eq 1 && "$apply" -eq 1 ]]; then
  printf '%s\n' "ERR choose only one of --dry-run or --apply" >&2
  exit 64
fi

args=(identity --preallocate-workers)
if [[ -n "$session" ]]; then
  args+=(--session "$session")
fi
if [[ "$dry_run" -eq 1 ]]; then
  args+=(--dry-run)
fi
if [[ "$json" -eq 1 ]]; then
  args+=(--json)
fi

"$LOOP" "${args[@]}"
