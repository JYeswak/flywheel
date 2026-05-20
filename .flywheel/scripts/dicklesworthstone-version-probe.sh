#!/usr/bin/env bash
set -u -o pipefail

TOOLS=(ntm br jsm caam cf-secret)
LEDGER="${DICKLESWORTHSTONE_DRIFT_LEDGER:-$HOME/.local/state/flywheel/dicklesworthstone-version-drift.jsonl}"

now_iso() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

version_key() {
  sed -E 's/^v//' <<<"$1" | grep -Eo '[0-9]+(\.[0-9]+){1,3}([-+][A-Za-z0-9._-]+)?' | head -1
}

installed_version_for() {
  local tool="$1" output path
  if ! path="$(command -v "$tool" 2>/dev/null)"; then
    printf 'missing'
    return 1
  fi

  output="$("$tool" --version 2>&1 | head -1 || true)"
  if [[ -n "$output" && "$output" != *"unknown flag"* && "$output" != *"unrecognized"* && "$output" != *"live fetch failed"* ]]; then
    printf '%s' "$output"
    return 0
  fi

  output="$("$tool" version 2>&1 | head -1 || true)"
  if [[ -n "$output" && "$output" != *"unknown flag"* && "$output" != *"unrecognized"* && "$output" != *"live fetch failed"* ]]; then
    printf '%s' "$output"
    return 0
  fi

  printf 'mtime:%s' "$(stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%SZ' "$path" 2>/dev/null || echo unknown)"
}

release_json_for() {
  local tool="$1" payload
  if payload="$(gh api "repos/Dicklesworthstone/${tool}/releases/latest" 2>/dev/null)" \
    && jq -e '.tag_name? // empty' >/dev/null <<<"$payload"; then
    printf '%s' "$payload"
    return 0
  fi
  case "$tool" in
    br)
      payload="$(gh api "repos/Dicklesworthstone/beads_rust/releases/latest" 2>/dev/null)" \
        && jq -e '.tag_name? // empty' >/dev/null <<<"$payload" \
        && printf '%s' "$payload"
      ;;
    caam)
      payload="$(gh api "repos/Dicklesworthstone/coding_agent_account_manager/releases/latest" 2>/dev/null)" \
        && jq -e '.tag_name? // empty' >/dev/null <<<"$payload" \
        && printf '%s' "$payload"
      ;;
    *) return 1 ;;
  esac
}

releases_json_for() {
  local tool="$1" payload
  if payload="$(gh api "repos/Dicklesworthstone/${tool}/releases?per_page=100" 2>/dev/null)" \
    && jq -e 'type == "array"' >/dev/null <<<"$payload"; then
    printf '%s' "$payload"
    return 0
  fi
  case "$tool" in
    br)
      payload="$(gh api "repos/Dicklesworthstone/beads_rust/releases?per_page=100" 2>/dev/null)" \
        && jq -e 'type == "array"' >/dev/null <<<"$payload" \
        && printf '%s' "$payload"
      ;;
    caam)
      payload="$(gh api "repos/Dicklesworthstone/coding_agent_account_manager/releases?per_page=100" 2>/dev/null)" \
        && jq -e 'type == "array"' >/dev/null <<<"$payload" \
        && printf '%s' "$payload"
      ;;
    *) return 1 ;;
  esac
}

days_since() {
  local published="$1" published_epoch now_epoch
  published_epoch="$(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$published" '+%s' 2>/dev/null || echo '')"
  [[ -z "$published_epoch" ]] && { printf 'null'; return; }
  now_epoch="$(date -u '+%s')"
  printf '%s' $(( (now_epoch - published_epoch) / 86400 ))
}

missed_releases() {
  local releases="$1" installed="$2" latest="$3" installed_key latest_key
  installed_key="$(version_key "$installed")"
  latest_key="$(version_key "$latest")"

  if [[ -z "$installed_key" || "$installed" == *"unknown"* || "$installed" == mtime:* ]]; then
    printf 'null'
    return
  fi

  if [[ -n "$installed_key" && -n "$latest_key" && "$installed_key" == "$latest_key" ]]; then
    printf '0'
    return
  fi

  jq -r '.[].tag_name // empty' <<<"$releases" | awk -v installed="$installed_key" '
    BEGIN { count = 0 }
    {
      tag = $0
      sub(/^v/, "", tag)
      if (installed != "" && index(tag, installed) == 1) {
        print count
        found = 1
        exit
      }
      count++
    }
    END {
      if (!found) print count
    }
  '
}

status_for() {
  local missed="$1"
  if [[ "$missed" == "null" || -z "$missed" ]]; then
    printf 'unknown'
  elif (( missed == 0 )); then
    printf 'current'
  elif (( missed <= 2 )); then
    printf 'stale_minor'
  else
    printf 'stale_major'
  fi
}

probe_tool() {
  local tool="$1" ts installed release_json releases_json latest published days missed status error=""
  ts="$(now_iso)"
  installed="$(installed_version_for "$tool" || true)"

  if ! release_json="$(release_json_for "$tool")"; then
    latest="null"
    published="null"
    days="null"
    missed="null"
    status="unknown"
    error="latest_release_unavailable"
  else
    latest="$(jq -r '.tag_name // "null"' <<<"$release_json")"
    published="$(jq -r '.published_at // "null"' <<<"$release_json")"
    days="$(days_since "$published")"
    if releases_json="$(releases_json_for "$tool")"; then
      missed="$(missed_releases "$releases_json" "$installed" "$latest")"
    else
      missed="null"
      error="release_list_unavailable"
    fi
    if [[ "$missed" == "0" ]]; then
      days="0"
    elif [[ "$missed" == "null" ]]; then
      days="null"
    fi
    status="$(status_for "$missed")"
  fi

  jq -c -n \
    --arg ts "$ts" \
    --arg tool "$tool" \
    --arg installed_version "$installed" \
    --arg latest_version "$latest" \
    --arg status "$status" \
    --arg error "$error" \
    --argjson days_stale "$days" \
    --argjson releases_missed "$missed" \
    '{
      ts:$ts,
      tool:$tool,
      installed_version:$installed_version,
      latest_version:($latest_version | if . == "null" then null else . end),
      days_stale:$days_stale,
      releases_missed:$releases_missed,
      status:$status
    } + (if $error == "" then {} else {error:$error} end)'
}

main() {
  mkdir -p "$(dirname "$LEDGER")"
  local rows=0
  for tool in "${TOOLS[@]}"; do
    probe_tool "$tool" | tee -a "$LEDGER"
    rows=$((rows + 1))
  done
  jq -c -n --arg ts "$(now_iso)" --arg ledger "$LEDGER" --argjson rows "$rows" \
    '{ts:$ts,status:"ok",rows:$rows,ledger:$ledger}'
}

main "$@"
