#!/usr/bin/env bash
set -euo pipefail

REPO="$(pwd -P)"
JSON=0
DOCTOR=0

usage() {
  cat <<'USAGE'
Usage: file-length-probe.sh [--repo PATH] [--json] [--doctor]

Reports source and doctrine files that exceed canonical-cli-scoping file-length
thresholds. Oversized files with a canonical-cli-scoping-allow-large comment are
reported separately and do not increment oversized_files_count.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ -n "${2:-}" ]] || { echo "ERR: --repo requires PATH" >&2; exit 2; }
      REPO="$2"
      shift 2
      ;;
    --repo=*)
      REPO="${1#*=}"
      shift
      ;;
    --json|--no-color|--no-emoji)
      JSON=1
      shift
      ;;
    --doctor)
      DOCTOR=1
      JSON=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

REPO_ABS="$(cd "$REPO" && pwd -P)"

language_for_file() {
  local file="$1" base ext first
  base="$(basename "$file")"
  ext="${base##*.}"
  case "$ext" in
    sh|bash|zsh) printf 'bash\n'; return 0 ;;
    py) printf 'python\n'; return 0 ;;
    rs) printf 'rust\n'; return 0 ;;
    md|markdown) printf 'markdown\n'; return 0 ;;
  esac
  first="$(head -n 1 "$file" 2>/dev/null || true)"
  case "$first" in
    *bash*|*"/sh"*|*zsh*) printf 'bash\n'; return 0 ;;
  esac
  if [[ "$base" == flywheel-loop || "$base" == flywheel-loop-* ]]; then
    printf 'bash\n'
    return 0
  fi
  printf '\n'
}

threshold_for_language() {
  case "$1" in
    bash) printf '500\n' ;;
    python) printf '400\n' ;;
    rust) printf '500\n' ;;
    markdown) printf '1500\n' ;;
    *) printf '0\n' ;;
  esac
}

emit_file_candidates() {
  find "$REPO_ABS" \
    \( -path '*/.git' -o -path '*/.beads' -o -path '*/.cass' -o -path '*/node_modules' -o -path '*/.venv' -o -path '*/venv' -o -path '*/__pycache__' \) -prune \
    -o -type f \( -name '*.sh' -o -name '*.bash' -o -name '*.zsh' -o -name '*.py' -o -name '*.rs' -o -name '*.md' -o -name '*.markdown' \) -print

  if [[ "${FLYWHEEL_FILE_LENGTH_INCLUDE_LOOP_BIN:-auto}" != "0" ]]; then
    local loop_bin="$HOME/.claude/skills/.flywheel/bin/flywheel-loop"
    if [[ -f "$loop_bin" && ( "${FLYWHEEL_FILE_LENGTH_INCLUDE_LOOP_BIN:-auto}" == "1" || "$REPO_ABS" == "/Users/josh/Developer/flywheel" ) ]]; then
      printf '%s\n' "$loop_bin"
    fi
  fi
}

oversized_tmp="$(mktemp "${TMPDIR:-/tmp}/file-length-oversized.XXXXXX")"
allowed_tmp="$(mktemp "${TMPDIR:-/tmp}/file-length-allowed.XXXXXX")"
trap 'rm -f "$oversized_tmp" "$allowed_tmp"' EXIT

scanned=0
while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  lang="$(language_for_file "$file")"
  [[ -n "$lang" ]] || continue
  threshold="$(threshold_for_language "$lang")"
  [[ "$threshold" -gt 0 ]] || continue
  lines="$(wc -l <"$file" | tr -d ' ')"
  scanned=$((scanned + 1))
  [[ "$lines" -gt "$threshold" ]] || continue
  if grep -q 'canonical-cli-scoping-allow-large:' "$file"; then
    target="$allowed_tmp"
    allowed=true
  else
    target="$oversized_tmp"
    allowed=false
  fi
  rel="$file"
  if [[ "$file" == "$REPO_ABS/"* ]]; then
    rel="${file#$REPO_ABS/}"
  fi
  jq -nc \
    --arg path "$rel" \
    --arg abs_path "$file" \
    --arg language "$lang" \
    --argjson lines "$lines" \
    --argjson threshold "$threshold" \
    --argjson allowed "$allowed" \
    '{path:$path,abs_path:$abs_path,language:$language,lines:$lines,threshold:$threshold,excess:($lines - $threshold),allow_override:$allowed}' >>"$target"
done < <(emit_file_candidates | sort -u)

oversized_json="$(jq -s 'sort_by(-.excess, .path)' "$oversized_tmp")"
allowed_json="$(jq -s 'sort_by(-.excess, .path)' "$allowed_tmp")"
oversized_count="$(jq 'length' <<<"$oversized_json")"
allowed_count="$(jq 'length' <<<"$allowed_json")"
status="pass"
if [[ "$oversized_count" -gt 3 ]]; then
  status="warn"
fi

payload="$(jq -nc \
  --arg repo "$REPO_ABS" \
  --arg status "$status" \
  --argjson scanned "$scanned" \
  --argjson oversized_count "$oversized_count" \
  --argjson oversized "$oversized_json" \
  --argjson allowed_count "$allowed_count" \
  --argjson allowed "$allowed_json" \
  '{
    schema_version:"file-length-probe/v1",
    status:$status,
    repo:$repo,
    thresholds:{bash:500,python:400,rust:500,markdown:1500},
    scanned_files_count:$scanned,
    oversized_files_count:$oversized_count,
    oversized_files:$oversized,
    allowed_oversized_files_count:$allowed_count,
    allowed_oversized_files:$allowed,
    errors:[],
    warnings:(if $oversized_count > 3 then [{code:"oversized_files_count",message:"more than 3 files exceed canonical file-length thresholds"}] else [] end)
  }')"

if [[ "$JSON" -eq 1 || "$DOCTOR" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  jq -r '"oversized_files_count=\(.oversized_files_count)\nallowed_oversized_files_count=\(.allowed_oversized_files_count)"' <<<"$payload"
fi
