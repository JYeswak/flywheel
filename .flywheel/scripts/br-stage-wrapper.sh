#!/usr/bin/env bash
set -euo pipefail

REAL_BR="${BR_STAGE_WRAPPER_REAL_BR:-/Users/josh/.cargo/bin/br}"

usage() {
  cat <<'EOF'
usage: br-stage-wrapper.sh <br-args...>

Runs the real br CLI, then stages .beads/issues.jsonl when the successful
subcommand is create, close, update, or dep.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ ! -x "$REAL_BR" ]]; then
  printf 'ERR: real br binary not executable: %s\n' "$REAL_BR" >&2
  exit 127
fi

stage_subcommand() {
  local arg skip_next=0
  for arg in "$@"; do
    if [[ "$skip_next" -eq 1 ]]; then
      skip_next=0
      continue
    fi
    case "$arg" in
      --db|--actor|--lock-timeout)
        skip_next=1
        continue
        ;;
      --db=*|--actor=*|--lock-timeout=*|--json|--no-daemon|--no-auto-flush|--no-auto-import|--allow-stale|--no-db|-v|-vv|-vvv|-q|--quiet|--no-color)
        continue
        ;;
      -*)
        continue
        ;;
      create|close|update|dep)
        return 0
        ;;
      *)
        return 1
        ;;
    esac
  done
  return 1
}

should_stage=0
if stage_subcommand "$@"; then
  should_stage=1
fi

"$REAL_BR" "$@"
rc=$?

if [[ "$rc" -eq 0 && "$should_stage" -eq 1 ]]; then
  if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" && [[ -f "$repo_root/.beads/issues.jsonl" ]]; then
    git -C "$repo_root" add -- .beads/issues.jsonl
  fi
fi

exit "$rc"
