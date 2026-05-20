#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LEDGER="${AUTO_PUSH_LEDGER:-$ROOT/.flywheel/runtime/auto-push-ledger.jsonl}"
SECRET_LEDGER="${AUTO_PUSH_SECRET_LEDGER:-$ROOT/.flywheel/runtime/secret-leak-detected.jsonl}"
SOAK_LEDGER="${AUTO_PUSH_SOAK_LEDGER:-$ROOT/.flywheel/runtime/auto-push-soak-ledger.jsonl}"
DAY="${AUTO_PUSH_SOAK_DAY:-$(date -u +%F)}"
FORCE=0
JSON_OUT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    *) shift ;;
  esac
done

mkdir -p "$(dirname "$SOAK_LEDGER")"
if [[ "$FORCE" -eq 0 && -f "$SOAK_LEDGER" ]] && jq -e --arg day "$DAY" 'select(.day == $day)' "$SOAK_LEDGER" >/dev/null 2>&1; then
  row="$(jq -c --arg day "$DAY" 'select(.day == $day)' "$SOAK_LEDGER" | tail -1)"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$row"
  else
    jq -r '.dashboard_line' <<<"$row"
  fi
  exit 0
fi

row="$(
  jq -nc \
    --arg day "$DAY" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg ledger "$LEDGER" \
    --arg secret_ledger "$SECRET_LEDGER" \
    --slurpfile rows <(if [[ -f "$LEDGER" ]]; then cat "$LEDGER"; fi) \
    --slurpfile secrets <(if [[ -f "$SECRET_LEDGER" ]]; then cat "$SECRET_LEDGER"; fi) \
    '{
      schema_version:"flywheel.auto_push_soak_probe.v1",
      ts:$ts,
      day:$day,
      ledger:$ledger,
      secret_ledger:$secret_ledger,
      post_commit_hook_fired_count:($rows | map(select((.source // "") == "post-commit" and (.ts // "" | startswith($day)))) | length),
      push_success_count:($rows | map(select((.push_success // false) == true and (.ts // "" | startswith($day)))) | length),
      push_blocked_count:($rows | map(select((.status // "") == "blocked" and (.ts // "" | startswith($day)))) | length),
      gitguardian_finding_count:($secrets | map(select((.ts // "" | startswith($day))) | (.finding_count // 0)) | add // 0)
    } | .dashboard_line = "Auto-push soak: post_commit=\(.post_commit_hook_fired_count) push_ok=\(.push_success_count) blocked=\(.push_blocked_count) gg_findings=\(.gitguardian_finding_count)"'
)"
printf '%s\n' "$row" >>"$SOAK_LEDGER"
if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$row"
else
  jq -r '.dashboard_line' <<<"$row"
fi
