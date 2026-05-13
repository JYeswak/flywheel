#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
EVENT_NAME="pull_request"
RUN_ACT=1
ACT_DRYRUN=0
STRICT=1
SKIP_TESTS=0
ACT_PLATFORM="ubuntu-22.04=catthehacker/ubuntu:act-22.04"
ACT_SERVER_ADDR="${ACT_SERVER_ADDR:-127.0.0.1}"

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
  run bash "$ROOT/tests/github-workflows.sh"
fi

run actionlint "$ROOT"/.github/workflows/*.yml

if [[ "$RUN_ACT" -eq 0 ]]; then
  printf 'SUMMARY local_actions_preflight=pass act=skipped\n'
  exit 0
fi

act_args=(
  "$EVENT_NAME"
  --directory "$ROOT"
  --container-architecture linux/amd64
  --platform "$ACT_PLATFORM"
  --artifact-server-addr "$ACT_SERVER_ADDR"
  --artifact-server-path "${TMPDIR:-/tmp}/flywheel-act-artifacts"
  --cache-server-addr "$ACT_SERVER_ADDR"
)

if [[ "$STRICT" -eq 1 ]]; then
  act_args+=(--strict)
fi

if [[ "$ACT_DRYRUN" -eq 1 ]]; then
  act_args+=(--dryrun)
fi

run act "${act_args[@]}" --workflows "$ROOT/.github/workflows/ci.yml" --job public-surface
run act "${act_args[@]}" --workflows "$ROOT/.github/workflows/installer-smoke.yml" --job install-doctor-uninstall --matrix os:ubuntu-22.04

run act workflow_dispatch \
  --directory "$ROOT" \
  --container-architecture linux/amd64 \
  --platform "$ACT_PLATFORM" \
  --artifact-server-addr "$ACT_SERVER_ADDR" \
  --cache-server-addr "$ACT_SERVER_ADDR" \
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
  --cache-server-addr "$ACT_SERVER_ADDR" \
  --strict \
  --dryrun \
  --input tag=v0.2.0 \
  --workflows "$ROOT/.github/workflows/site.yml" \
  --job deploy

printf 'SUMMARY local_actions_preflight=pass act=%s docker_context=%s\n' \
  "$([[ "$ACT_DRYRUN" -eq 1 ]] && printf dryrun || printf run)" \
  "$(docker context show 2>/dev/null || printf unknown)"
