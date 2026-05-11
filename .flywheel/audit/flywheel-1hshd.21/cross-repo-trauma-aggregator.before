#!/usr/bin/env bash
set -euo pipefail

OUTPUT="${HOME}/.flywheel/global-trauma-log.jsonl"
ROOTS=("${HOME}/Developer" "${HOME}/Desktop/Projects")
WRITE=0
ROOT_SEEN=0

usage() {
  printf 'Usage: %s [--root DIR ...] [--output FILE] [--write] [--json]\n' "$(basename "$0")"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ "${2:-}" ]] || { usage >&2; exit 2; }
      [[ "$ROOT_SEEN" -eq 1 ]] || { ROOTS=(); ROOT_SEEN=1; }
      ROOTS+=("$2")
      shift 2
      ;;
    --output)
      [[ "${2:-}" ]] || { usage >&2; exit 2; }
      OUTPUT="$2"
      shift 2
      ;;
    --write)
      WRITE=1
      shift
      ;;
    --json)
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

discover_logs() {
  local root log
  shopt -s nullglob
  for root in "${ROOTS[@]}"; do
    [[ -d "$root" ]] || continue
    for log in \
      "$root"/*/.flywheel/lock-log.jsonl \
      "$root"/*/*/.flywheel/lock-log.jsonl \
      "$root"/*/*/*/.flywheel/lock-log.jsonl; do
      printf '%s\n' "$log"
    done
  done
  shopt -u nullglob
}

while IFS= read -r log; do
  repo="${log%/.flywheel/lock-log.jsonl}"
  rel_repo="${repo#${HOME}/}"
  jq -Rcn --arg repo "$rel_repo" --arg path "$log" '
      foreach inputs as $line ({n:0}; .n += 1;
        ($line | fromjson? // empty) as $row
        | (($row.trauma_class // $row.class // "") | tostring) as $class
        | if ($row | type) == "object" and $class != "" then
            {
              schema_version:"global-trauma-log/v1",
              repo:$repo,
              source_path:$path,
              source_line:.n,
              ts:($row.ts // $row.timestamp // $row.created_ts // null),
              trauma_class:$class,
              severity:($row.severity // null),
              mission_lock_id:($row.mission_lock_id // $row.lock_id // null),
              action:($row.action // $row.kind // null),
              should_become:($row.should_become // null)
            }
          else empty end
      )
  ' "$log" >>"$tmp"
done < <(discover_logs | sort -u)

summary="$(jq -sc \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    schema_version:"cross-repo-trauma-aggregator/v1",
    generated_at:$generated_at,
    event_count:length,
    repo_count:([.[].repo] | unique | length),
    cross_repo_trauma_class_top:(
      [.[].trauma_class]
      | group_by(.)
      | map({trauma_class:.[0], count:length})
      | sort_by(-.count, .trauma_class)
      | .[:10]
    ),
    events:.
  }' "$tmp")"

if [[ "$WRITE" -eq 1 ]]; then
  mkdir -p "$(dirname "$OUTPUT")"
  out_tmp="$(mktemp "${OUTPUT}.XXXXXX")"
  jq -c '.events[]' <<<"$summary" >"$out_tmp"
  mv "$out_tmp" "$OUTPUT"
fi

printf '%s\n' "$summary"
