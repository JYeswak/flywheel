#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
WRITE=0
JSON_OUT=1
OUTPUT=""

usage() {
  cat <<'EOF'
Usage: act-workflow-classify.sh [--repo PATH] [--write] [--output PATH] [--json]

Classifies .github/workflows/*.yml as:
  act-compatible | act-with-secrets | GHA-only
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      ROOT="$(cd "$2" && pwd -P)"
      shift 2
      ;;
    --write)
      WRITE=1
      shift
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'act-workflow-classify: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

OUTPUT="${OUTPUT:-$ROOT/.flywheel/state/workflow-classification.json}"

classify_one() {
  local file="$1" rel name class reasons triggers act_command
  rel="${file#"$ROOT"/}"
  name="$(sed -nE 's/^[[:space:]]*name:[[:space:]]*"?([^"#]+)"?[[:space:]]*$/\1/p' "$file" | head -1)"
  [[ -n "$name" ]] || name="$(basename "$file")"

  reasons=()
  triggers=()
  grep -qE '^[[:space:]]*pull_request:' "$file" && triggers+=("pull_request")
  grep -qE '^[[:space:]]*push:' "$file" && triggers+=("push")
  grep -qE '^[[:space:]]*schedule:' "$file" && triggers+=("schedule")
  grep -qE '^[[:space:]]*workflow_dispatch:' "$file" && triggers+=("workflow_dispatch")

  if grep -qiE 'macos-|windows-' "$file"; then reasons+=("hosted_os_matrix"); fi
  if grep -qE 'secrets\.' "$file"; then reasons+=("secrets_context"); fi
  if grep -qE '^[[:space:]]*environment:' "$file"; then reasons+=("github_environment"); fi
  if grep -qE 'id-token:[[:space:]]*write|pages:[[:space:]]*write|deploy-pages|upload-pages-artifact|configure-pages' "$file"; then reasons+=("github_pages_or_oidc"); fi
  if grep -qE '\bgh[[:space:]]+(api|release|workflow|run)\b' "$file"; then reasons+=("github_api_required"); fi
  if grep -qE '^[[:space:]]*strategy:|^[[:space:]]*matrix:' "$file" && grep -qiE 'macos|windows|\$\{\{[[:space:]]*matrix\.' "$file"; then
    reasons+=("matrix_requires_hosted_parity")
  fi

  if [[ " ${reasons[*]} " == *" secrets_context "* ]]; then
    class="act-with-secrets"
  else
    class="act-compatible"
  fi
  if [[ " ${reasons[*]} " == *" hosted_os_matrix "* ]] \
    || [[ " ${reasons[*]} " == *" github_environment "* ]] \
    || [[ " ${reasons[*]} " == *" github_pages_or_oidc "* ]] \
    || [[ " ${reasons[*]} " == *" github_api_required "* ]] \
    || [[ " ${reasons[*]} " == *" matrix_requires_hosted_parity "* ]]; then
    class="GHA-only"
  fi

  if [[ "$class" == "act-compatible" ]]; then
    act_command="act pull_request --directory $ROOT --workflows $rel"
  else
    act_command=""
  fi

  jq -nc \
    --arg path "$rel" \
    --arg name "$name" \
    --arg classification "$class" \
    --arg act_command "$act_command" \
    --argjson triggers "$(printf '%s\n' "${triggers[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
    --argjson reasons "$(printf '%s\n' "${reasons[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
    '{path:$path,name:$name,classification:$classification,triggers:$triggers,reasons:$reasons,act_command:($act_command | if length > 0 then . else null end)}'
}

rows_tmp="$(mktemp -t act-workflow-classification.XXXXXX)"
trap 'rm -f "$rows_tmp"' EXIT

if [[ -d "$ROOT/.github/workflows" ]]; then
  while IFS= read -r workflow; do
    classify_one "$workflow" >>"$rows_tmp"
  done < <(find "$ROOT/.github/workflows" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
fi

result="$(jq -s \
  --arg schema_version "flywheel.workflow_classification.v1" \
  --arg repo "$ROOT" \
  --arg generated_from_bead "flywheel-ic6td" \
  --arg doctrine "/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/act-first-canonical-extension.md" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{schema_version:$schema_version,repo:$repo,generated_at:$ts,generated_from_bead:$generated_from_bead,doctrine_ref:$doctrine,workflows:.}' "$rows_tmp")"

if [[ "$WRITE" -eq 1 ]]; then
  mkdir -p "$(dirname "$OUTPUT")"
  printf '%s\n' "$result" >"$OUTPUT"
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$result"
fi
