#!/usr/bin/env bash
set -euo pipefail

json=0
callback=""
callback_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --callback) callback="${2:-}"; shift 2 ;;
    --callback-file) callback_file="${2:-}"; shift 2 ;;
    --json) json=1; shift ;;
    *) printf 'ERR unknown_arg=%s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ -n "$callback_file" ]]; then
  callback="$(<"$callback_file")"
fi

emit() {
  local status="$1" reason="$2" count="$3" ids="$4"
  if [[ "$json" -eq 1 ]]; then
    jq -nc \
      --arg status "$status" \
      --arg reason_code "$reason" \
      --arg skill_discoveries "$count" \
      --arg sd_ids "$ids" \
      '{
        schema_version:"skill-discovery-callback-validator/v1",
        status:$status,
        reason_code:$reason_code,
        skill_discoveries:($skill_discoveries|tonumber?),
        sd_ids:$sd_ids
      }'
  else
    printf 'status=%s reason_code=%s skill_discoveries=%s sd_ids=%s\n' "$status" "$reason" "$count" "$ids"
  fi
}

field_value() {
  local key="$1"
  tr ' ' '\n' <<<"$callback" | awk -F= -v key="$key" '$1 == key {print substr($0, length(key) + 2); found=1; exit} END {if (!found) exit 1}'
}

count="$(field_value skill_discoveries 2>/dev/null || true)"
ids="$(field_value sd_ids 2>/dev/null || true)"

if [[ -z "$count" ]]; then
  emit fail missing_skill_discoveries 0 "${ids:-missing}"
  exit 1
fi
if [[ -z "$ids" ]]; then
  emit fail missing_sd_ids "$count" missing
  exit 1
fi
if [[ ! "$count" =~ ^[0-9]+$ ]]; then
  emit fail skill_discoveries_not_numeric 0 "$ids"
  exit 1
fi
if [[ "$count" -eq 0 ]]; then
  if [[ "$ids" == "none" ]]; then
    emit pass ok "$count" "$ids"
    exit 0
  fi
  emit fail sd_ids_present_with_zero "$count" "$ids"
  exit 1
fi
if [[ "$ids" == "none" ]]; then
  emit fail skill_discovery_ids_missing "$count" "$ids"
  exit 1
fi

IFS=',' read -r -a id_array <<<"$ids"
if [[ "${#id_array[@]}" -ne "$count" ]]; then
  emit fail sd_ids_count_mismatch "$count" "$ids"
  exit 1
fi
for id in "${id_array[@]}"; do
  if [[ ! "$id" =~ ^sd-[A-Za-z0-9._-]+$ ]]; then
    emit fail sd_id_invalid "$count" "$ids"
    exit 1
  fi
done

emit pass ok "$count" "$ids"
