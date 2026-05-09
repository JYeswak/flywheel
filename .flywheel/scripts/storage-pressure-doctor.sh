#!/usr/bin/env bash
set -euo pipefail

VERSION="storage-pressure-doctor.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
STORAGE_PROBE="$ROOT/.flywheel/scripts/storage-probe.sh"
TMP_PRUNE_LEDGER="${FLYWHEEL_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/tmp-aggressive-prune-cron.jsonl}"
JSON_OUT=0
MODE="doctor"
STORAGE_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_STORAGE_FIXTURE:-}"
TOP_CONSUMERS_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_TOP_CONSUMERS_FIXTURE:-}"
SNAPSHOT_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_SNAPSHOT_FIXTURE:-}"
TMP_LEDGER_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_TMP_LEDGER_FIXTURE:-}"
PRIVATE_TMP_GIB_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_PRIVATE_TMP_GIB_FIXTURE:-}"
AVAIL_WARN_GB="${FLYWHEEL_STORAGE_PRESSURE_AVAIL_WARN_GB:-20}"

usage() {
  printf '%s\n' \
    "Usage:" \
    "  storage-pressure-doctor.sh --doctor --json" \
    "  storage-pressure-doctor.sh --schema|--info|--examples|--help" \
    "" \
    "Read-only doctor. Aggregates storage-probe, top consumers, APFS snapshot" \
    "signals, and tmp prune ledger state. Recommends action when free space <20Gi."
}

examples() {
  printf '%s\n' \
    ".flywheel/scripts/storage-pressure-doctor.sh --doctor --json" \
    "FLYWHEEL_STORAGE_PRESSURE_STORAGE_FIXTURE=tests/fixtures/storage-pressure/low-storage.json \\" \
    "  FLYWHEEL_STORAGE_PRESSURE_TOP_CONSUMERS_FIXTURE=tests/fixtures/storage-pressure/top-consumers.txt \\" \
    "  .flywheel/scripts/storage-pressure-doctor.sh --doctor --json"
}

schema_json() {
  jq -nc '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"storage-pressure-doctor/v1",
    type:"object",
    required:["schema_version","status","storage","top_consumers","snapshots","private_tmp","recommendations"],
    properties:{
      schema_version:{const:"storage-pressure-doctor/v1"},
      status:{enum:["ok","warn","fail"]},
      storage:{type:"object"},
      top_consumers:{type:"array"},
      snapshots:{type:"object"},
      private_tmp:{type:"object"},
      recommendations:{type:"array"}
    }
  }'
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

human_to_gib() {
  awk -v raw="$1" '
    BEGIN {
      n = raw
      unit = substr(n, length(n), 1)
      sub(/[KMGTP]$/, "", n)
      val = n + 0
      if (unit == "T") val *= 1024
      else if (unit == "G") val *= 1
      else if (unit == "M") val /= 1024
      else if (unit == "K") val /= 1024 / 1024
      else if (unit == "P") val *= 1024 * 1024
      printf "%.2f", val
    }'
}

storage_json() {
  if [ -n "$STORAGE_FIXTURE" ]; then
    jq -c '.' "$STORAGE_FIXTURE"
    return 0
  fi
  "$STORAGE_PROBE" --json 2>/dev/null || true
}

top_consumers_json() {
  local source line size path gib count=0 tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/storage-pressure-top.XXXXXX")"
  if [ -n "$TOP_CONSUMERS_FIXTURE" ]; then
    cp "$TOP_CONSUMERS_FIXTURE" "$tmp"
  else
    du -sh "$HOME"/Developer/* "$HOME"/.socraticode/* "$HOME"/.knowledge/* "$HOME"/Library/Caches/* /private/tmp/* /private/var/folders/* 2>/dev/null \
      | sort -rh \
      | head -30 >"$tmp" || true
  fi
  {
    printf '['
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      size="$(awk '{print $1}' <<<"$line")"
      path="$(awk '{print $2}' <<<"$line")"
      gib="$(human_to_gib "$size")"
      [ "$count" -eq 0 ] || printf ','
      jq -nc --arg size "$size" --arg path "$path" --argjson gib "$gib" '{size:$size,size_gib:$gib,path:$path}'
      count=$((count + 1))
    done <"$tmp"
    printf ']'
  } | jq -c '.'
  rm -f "$tmp"
}

snapshot_json() {
  if [ -n "$SNAPSHOT_FIXTURE" ]; then
    jq -c '.' "$SNAPSHOT_FIXTURE"
    return 0
  fi
  local tm_file disk_file tm_count disk_count sealed_count
  tm_file="$(mktemp "${TMPDIR:-/tmp}/storage-pressure-tm.XXXXXX")"
  disk_file="$(mktemp "${TMPDIR:-/tmp}/storage-pressure-diskutil.XXXXXX")"
  tmutil listlocalsnapshots / >"$tm_file" 2>/dev/null || true
  diskutil apfs list >"$disk_file" 2>/dev/null || true
  tm_count="$(grep -c '^com\\.apple\\.TimeMachine\\.' "$tm_file" 2>/dev/null || true)"
  disk_count="$(grep -c 'Snapshot:' "$disk_file" 2>/dev/null || true)"
  sealed_count="$(grep -c 'Snapshot Sealed:[[:space:]]*Yes' "$disk_file" 2>/dev/null || true)"
  jq -nc \
    --argjson tm_count "${tm_count:-0}" \
    --argjson disk_count "${disk_count:-0}" \
    --argjson sealed_count "${sealed_count:-0}" \
    --argjson tm_snapshots "$(grep '^com\\.apple\\.TimeMachine\\.' "$tm_file" 2>/dev/null | jq -R . | jq -s .)" \
    '{
      tm_local_snapshot_count:$tm_count,
      apfs_snapshot_count:$disk_count,
      sealed_system_snapshot_count:$sealed_count,
      tm_local_snapshots:$tm_snapshots,
      evidence:"tmutil listlocalsnapshots /; diskutil apfs list"
    }'
  rm -f "$tm_file" "$disk_file"
}

private_tmp_json() {
  local ledger="$TMP_PRUNE_LEDGER" last="null" ledger_exists=false entry_count=0 total_gib=0 kb=0
  if [ -n "$TMP_LEDGER_FIXTURE" ]; then
    ledger="$TMP_LEDGER_FIXTURE"
  fi
  if [ -s "$ledger" ]; then
    ledger_exists=true
    last="$(tail -n 1 "$ledger" | jq -c '.' 2>/dev/null || printf 'null')"
  fi
  entry_count="$(find /private/tmp -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
  if [ -n "$PRIVATE_TMP_GIB_FIXTURE" ]; then
    total_gib="$PRIVATE_TMP_GIB_FIXTURE"
  else
    kb="$(du -sk /private/tmp 2>/dev/null | awk '{print $1+0}' || printf 0)"
    total_gib="$(awk -v kb="${kb:-0}" 'BEGIN { printf "%.2f", kb / 1024 / 1024 }')"
  fi
  jq -nc \
    --arg ledger "$ledger" \
    --argjson exists "$ledger_exists" \
    --argjson last "$last" \
    --argjson total_gib "$total_gib" \
    --argjson entry_count "${entry_count:-0}" \
    '{ledger_path:$ledger,ledger_exists:$exists,last_run:$last,private_tmp_total_gib:$total_gib,private_tmp_entry_count:$entry_count}'
}

recommendations_json() {
  local storage="$1" consumers="$2" snapshots="$3" tmp_json="$4"
  jq -nc \
    --argjson storage "$storage" \
    --argjson consumers "$consumers" \
    --argjson snapshots "$snapshots" \
    --argjson tmp "$tmp_json" \
    --argjson warn_gb "$AVAIL_WARN_GB" \
    '
      ($storage.disk_free_gb // 999999) as $free_gb
      | ($storage.disk_free_pct // 100) as $free_pct
      | [
          (if $free_gb < $warn_gb or $free_pct < 5 then {
            code:"storage_pressure_active",
            severity:(if $free_pct < 5 then "fire" elif $free_gb < $warn_gb then "critical" else "warn" end),
            action:"Pause growth-heavy clone/index jobs; run storage-health L1 and re-probe before L2+."
          } else empty end),
          (if ($snapshots.tm_local_snapshot_count // 0) > 0 and ($free_gb < $warn_gb) then {
            code:"tm_snapshots_present_under_pressure",
            severity:"warn",
            action:"Use apfs-snapshot-ops to inspect/thin Time Machine local snapshots; do not delete sealed system snapshots."
          } else empty end),
          (if (($tmp.ledger_exists // false) | not) then {
            code:"tmp_prune_ledger_missing",
            severity:"warn",
            action:"Verify ai.zeststream.tmp-aggressive-prune launchd wiring; ledger is missing."
          } else empty end),
          (if (($tmp.private_tmp_total_gib // 0) > 50) then {
            code:"private_tmp_large",
            severity:(if $free_gb < $warn_gb or $free_pct < 5 then "critical" else "warn" end),
            action:"/private/tmp is large even after the cron wrapper; inspect protected/recent tmp roots before widening prune age or patterns."
          } else empty end),
          (if ($consumers | length) > 0 then {
            code:"top_consumer_review",
            severity:"info",
            action:("Largest visible consumer: " + ($consumers[0].path // "unknown") + " (" + (($consumers[0].size // "unknown")|tostring) + ").")
          } else empty end)
        ]'
}

doctor_json() {
  local storage consumers snapshots tmp_json recs status
  storage="$(storage_json)"
  consumers="$(top_consumers_json)"
  snapshots="$(snapshot_json)"
  tmp_json="$(private_tmp_json)"
  recs="$(recommendations_json "$storage" "$consumers" "$snapshots" "$tmp_json")"
  status="$(jq -nr --argjson storage "$storage" --argjson recs "$recs" '
    if ($storage.status // "ok") == "fail" then "fail"
    elif any($recs[]?; .severity == "critical" or .severity == "fire") then "fail"
    elif (($recs | length) > 0 or ($storage.status // "ok") == "warn") then "warn"
    else "ok" end')"
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg status "$status" \
    --argjson storage "$storage" \
    --argjson consumers "$consumers" \
    --argjson snapshots "$snapshots" \
    --argjson tmp_json "$tmp_json" \
    --argjson recs "$recs" \
    '{
      schema_version:"storage-pressure-doctor/v1",
      version:"storage-pressure-doctor.v1",
      ts:$ts,
      status:$status,
      storage:$storage,
      top_consumers:$consumers,
      snapshots:$snapshots,
      private_tmp:$tmp_json,
      recommendations:$recs
    }'
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --doctor|doctor) MODE="doctor"; shift ;;
      --json) JSON_OUT=1; shift ;;
      --schema) schema_json; exit 0 ;;
      --info) jq -nc --arg version "$VERSION" --arg probe "$STORAGE_PROBE" '{version:$version,storage_probe:$probe,mutates:[]}'; exit 0 ;;
      --examples) examples; exit 0 ;;
      --help|-h) usage; exit 0 ;;
      *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
}

main() {
  local out
  parse_args "$@"
  case "$MODE" in
    doctor) out="$(doctor_json)" ;;
    *) printf 'ERROR: unknown mode: %s\n' "$MODE" >&2; exit 2 ;;
  esac
  if [ "$JSON_OUT" -eq 1 ]; then
    printf '%s\n' "$out"
  else
    jq -r '"storage_pressure status=\(.status) free_gb=\(.storage.disk_free_gb // "unknown") recommendations=\(.recommendations | length)"' <<<"$out"
  fi
  [ "$(jq -r '.status' <<<"$out")" != "fail" ]
}

main "$@"
