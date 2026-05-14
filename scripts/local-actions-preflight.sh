#!/usr/bin/env bash
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
  SOURCE_DIR="$(cd "$(dirname "$SOURCE")" && pwd -P)"
  TARGET="$(readlink "$SOURCE")"
  [[ "$TARGET" == /* ]] && SOURCE="$TARGET" || SOURCE="$SOURCE_DIR/$TARGET"
done
SCRIPT_ROOT="$(cd "$(dirname "$SOURCE")/.." && pwd -P)"
ROOT="$(
  git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd -P
)"
EVENT_NAME="pull_request"
RUN_ACT=1
ACT_DRYRUN=0
STRICT=1
SKIP_TESTS=0
ACT_PLATFORM="ubuntu-22.04=catthehacker/ubuntu:act-22.04"
ACT_SERVER_ADDR="${ACT_SERVER_ADDR:-127.0.0.1}"
ACT_SERVER_PORT="${ACT_SERVER_PORT:-0}"

usage() {
  cat <<'EOF'
usage:
  scripts/local-actions-preflight.sh
  scripts/local-actions-preflight.sh --dry-run
  scripts/local-actions-preflight.sh --no-act
  scripts/local-actions-preflight.sh --no-strict

Runs the cheap local workflow gate before spending GitHub Actions minutes:
  1. repo workflow contract tests
  2. actionlint over .github/workflows
  3. act through local OrbStack/Docker for safe Ubuntu jobs

Release and Pages workflows are actionlint/dry-run validated here. GitHub
remains the final approval surface for hosted runner parity, macOS, Pages,
release uploads, OIDC, and environment protection.

The act artifact/cache servers bind to 127.0.0.1 by default. Override with
ACT_SERVER_ADDR only when a different local network boundary is intentional.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      ACT_DRYRUN=1
      ;;
    --no-act)
      RUN_ACT=0
      ;;
    --no-strict)
      STRICT=0
      ;;
    --skip-tests)
      SKIP_TESTS=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'ERROR: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
  shift
done

need() {
  local cmd="$1" hint="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'ERROR: missing %s. %s\n' "$cmd" "$hint" >&2
    exit 30
  fi
}

run() {
  printf '+ %s\n' "$*" >&2
  "$@"
}

need actionlint "Install with: brew install actionlint"
if [[ "$RUN_ACT" -eq 1 ]]; then
  need act "Install with: brew install act"
  need docker "Install/start OrbStack or another Docker-compatible engine."
  if ! docker info >/dev/null 2>&1; then
    printf 'ERROR: Docker API is unavailable. Start OrbStack, then rerun this gate.\n' >&2
    exit 31
  fi
fi

if [[ "$SKIP_TESTS" -eq 0 ]]; then
  if [[ -x "$ROOT/tests/github-workflows.sh" || -f "$ROOT/tests/github-workflows.sh" ]]; then
    run bash "$ROOT/tests/github-workflows.sh"
  else
    printf 'SKIP repo_contract reason=missing-tests-github-workflows-sh repo=%s\n' "$ROOT"
  fi
fi

workflow_files=()
if [[ -d "$ROOT/.github/workflows" ]]; then
  for workflow in "$ROOT"/.github/workflows/*.yml "$ROOT"/.github/workflows/*.yaml; do
    [[ -f "$workflow" ]] && workflow_files+=("$workflow")
  done
fi

if [[ "${#workflow_files[@]}" -eq 0 ]]; then
  printf 'SKIP local_actions_preflight reason=no-github-workflows repo=%s\n' "$ROOT"
  printf 'SUMMARY local_actions_preflight=skipped reason=no-github-workflows\n'
  exit 0
fi

run actionlint "${workflow_files[@]}"

if [[ "$RUN_ACT" -eq 0 ]]; then
  printf 'SUMMARY local_actions_preflight=pass act=skipped\n'
  exit 0
fi

repo_key="$(printf '%s' "$ROOT" | cksum | awk '{print $1}')"

act_args=(
  "$EVENT_NAME"
  --directory "$ROOT"
  --container-architecture linux/amd64
  --platform "$ACT_PLATFORM"
  --artifact-server-addr "$ACT_SERVER_ADDR"
  --artifact-server-port "$ACT_SERVER_PORT"
  --artifact-server-path "${TMPDIR:-/tmp}/flywheel-act-artifacts/$repo_key"
  --cache-server-addr "$ACT_SERVER_ADDR"
  --cache-server-port "$ACT_SERVER_PORT"
)

if [[ "$STRICT" -eq 1 ]]; then
  act_args+=(--strict)
fi

if [[ "$ACT_DRYRUN" -eq 1 ]]; then
  act_args+=(--dryrun)
fi

if [[ "$ROOT" == "$SCRIPT_ROOT" ]]; then
  run act "${act_args[@]}" --workflows "$ROOT/.github/workflows/ci.yml" --job public-surface
  run act "${act_args[@]}" --workflows "$ROOT/.github/workflows/installer-smoke.yml" --job install-doctor-uninstall --matrix os:ubuntu-22.04

  run act workflow_dispatch \
    --directory "$ROOT" \
    --container-architecture linux/amd64 \
    --platform "$ACT_PLATFORM" \
    --artifact-server-addr "$ACT_SERVER_ADDR" \
    --artifact-server-port "$ACT_SERVER_PORT" \
    --cache-server-addr "$ACT_SERVER_ADDR" \
    --cache-server-port "$ACT_SERVER_PORT" \
    --strict \
    --dryrun \
    --input tag=v0.2.0 \
    --workflows "$ROOT/.github/workflows/release.yml" \
    --job package

  run act workflow_dispatch \
    --directory "$ROOT" \
    --container-architecture linux/amd64 \
    --platform "$ACT_PLATFORM" \
    --artifact-server-addr "$ACT_SERVER_ADDR" \
    --artifact-server-port "$ACT_SERVER_PORT" \
    --cache-server-addr "$ACT_SERVER_ADDR" \
    --cache-server-port "$ACT_SERVER_PORT" \
    --strict \
    --dryrun \
    --input tag=v0.2.0 \
    --workflows "$ROOT/.github/workflows/site.yml" \
    --job deploy
else
  for workflow in "${workflow_files[@]}"; do
    if ! grep -Eq '^[[:space:]]*pull_request:' "$workflow"; then
      printf 'SKIP act_workflow reason=no-pull-request-trigger workflow=%s\n' "$workflow"
      continue
    fi
    run act "${act_args[@]}" --workflows "$workflow"
  done
fi

printf 'SUMMARY local_actions_preflight=pass act=%s docker_context=%s\n' \
  "$([[ "$ACT_DRYRUN" -eq 1 ]] && printf dryrun || printf run)" \
  "$(docker context show 2>/dev/null || printf unknown)"
