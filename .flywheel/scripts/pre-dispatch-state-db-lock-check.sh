#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: pre-dispatch-state-db-lock-check.sh --db PATH --operation CLASS [--owner NAME] [--timeout SECONDS] [--keep-lock] [--json]
       pre-dispatch-state-db-lock-check.sh --schema

Acquires an atomic repo/fleet SQLite writer lock long enough to prove that a
mutating dispatch can own the single-writer lane. Without --keep-lock, the lock
is released before exit and this is a preflight receipt, not a write wrapper.
EOF
}

json=0
schema=0
keep_lock=0
db_path=""
operation_class="unspecified"
owner="${USER:-unknown}:$PPID"
timeout_seconds=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db) db_path="${2:-}"; shift 2 ;;
    --operation) operation_class="${2:-}"; shift 2 ;;
    --owner) owner="${2:-}"; shift 2 ;;
    --timeout) timeout_seconds="${2:-0}"; shift 2 ;;
    --keep-lock) keep_lock=1; shift ;;
    --json) json=1; shift ;;
    --schema) schema=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ "$schema" -eq 1 ]]; then
  jq -n '{
    schema_version:"sqlite-write-lock-check/v1",
    required_fields:["db_path","db_fingerprint","operation_class","writer_owner","lock_path","lock_acquired_at","lock_timeout_seconds","competing_writer_count","pre_integrity_state","post_integrity_state","release_status"],
    doctor_fields:["sqlite_concurrent_writer_risk_count","sqlite_write_lock_conflict_count","sqlite_write_locks.top_conflicts"]
  }'
  exit 0
fi

if [[ -z "$db_path" ]]; then
  printf 'missing required --db PATH\n' >&2
  exit 64
fi

canonical_db() {
  local path="$1" dir base
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  if [[ -d "$dir" ]]; then
    (cd "$dir" && printf '%s/%s\n' "$(pwd -P)" "$base")
  else
    printf '%s\n' "$path"
  fi
}

integrity_state() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    printf 'missing'
    return
  fi
  if ! command -v sqlite3 >/dev/null 2>&1; then
    printf 'sqlite3_unavailable'
    return
  fi
  local out
  out="$(sqlite3 "$path" 'PRAGMA quick_check;' 2>&1 || true)"
  if [[ "$out" == "ok" ]]; then
    printf 'ok'
  else
    printf '%s' "$out" | tr '\n' ' ' | cut -c 1-240
  fi
}

competing_writers() {
  local path="$1"
  if [[ ! -f "$path" ]] || ! command -v lsof >/dev/null 2>&1; then
    printf '0'
    return
  fi
  { lsof -t -- "$path" 2>/dev/null || true; } | sort -u | wc -l | tr -d ' '
}

db_path="$(canonical_db "$db_path")"
db_fingerprint="$(printf '%s' "$db_path" | shasum -a 256 | awk '{print $1}')"
lock_root="${FLYWHEEL_SQLITE_LOCK_DIR:-$HOME/.local/state/flywheel/sqlite-locks}"
lock_path="$lock_root/$db_fingerprint.lock"
mkdir -p "$lock_root"

pre_integrity_state="$(integrity_state "$db_path")"
competing_writer_count="$(competing_writers "$db_path")"
lock_acquired=false
lock_acquired_at=null
release_status="not_acquired"
conflict_owner=""
conflict_age_seconds=null
start_epoch="$(date +%s)"

while true; do
  if mkdir "$lock_path" 2>/dev/null; then
    lock_acquired=true
    lock_acquired_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    jq -n \
      --arg owner "$owner" \
      --arg db_path "$db_path" \
      --arg operation_class "$operation_class" \
      --arg acquired_at "$lock_acquired_at" \
      '{owner:$owner, db_path:$db_path, operation_class:$operation_class, acquired_at:$acquired_at, pid:env.PPID}' \
      >"$lock_path/owner.json"
    break
  fi

  if [[ "$timeout_seconds" -le 0 || $(( $(date +%s) - start_epoch )) -ge "$timeout_seconds" ]]; then
    if [[ -f "$lock_path/owner.json" ]]; then
      conflict_owner="$(jq -r '.owner // empty' "$lock_path/owner.json" 2>/dev/null || true)"
      local_acquired="$(jq -r '.acquired_at // empty' "$lock_path/owner.json" 2>/dev/null || true)"
      if [[ -n "$local_acquired" ]]; then
        conflict_epoch="$(date -j -f '%Y-%m-%dT%H:%M:%SZ' "$local_acquired" +%s 2>/dev/null || echo '')"
        if [[ -n "$conflict_epoch" ]]; then
          conflict_age_seconds=$(( $(date +%s) - conflict_epoch ))
        fi
      fi
    fi
    break
  fi
  sleep 1
done

post_integrity_state="$pre_integrity_state"
if [[ "$lock_acquired" == true ]]; then
  post_integrity_state="$(integrity_state "$db_path")"
  if [[ "$keep_lock" -eq 1 ]]; then
    release_status="kept"
  else
    rm -rf "$lock_path"
    release_status="released"
  fi
fi

sqlite_concurrent_writer_risk_count=0
sqlite_write_lock_conflict_count=0
if [[ "$competing_writer_count" -gt 0 ]]; then
  sqlite_concurrent_writer_risk_count=1
fi
if [[ "$lock_acquired" != true ]]; then
  sqlite_write_lock_conflict_count=1
fi

jq -n \
  --arg db_path "$db_path" \
  --arg db_fingerprint "$db_fingerprint" \
  --arg operation_class "$operation_class" \
  --arg writer_owner "$owner" \
  --arg lock_path "$lock_path" \
  --arg lock_acquired_at "$lock_acquired_at" \
  --arg pre_integrity_state "$pre_integrity_state" \
  --arg post_integrity_state "$post_integrity_state" \
  --arg release_status "$release_status" \
  --arg conflict_owner "$conflict_owner" \
  --argjson lock_acquired "$lock_acquired" \
  --argjson lock_timeout_seconds "$timeout_seconds" \
  --argjson competing_writer_count "$competing_writer_count" \
  --argjson sqlite_concurrent_writer_risk_count "$sqlite_concurrent_writer_risk_count" \
  --argjson sqlite_write_lock_conflict_count "$sqlite_write_lock_conflict_count" \
  --argjson conflict_age_seconds "$conflict_age_seconds" \
  '{
    schema_version:"sqlite-write-lock-check/v1",
    status:(if $lock_acquired then "ok" else "conflict" end),
    db_path:$db_path,
    db_fingerprint:$db_fingerprint,
    operation_class:$operation_class,
    writer_owner:$writer_owner,
    lock_path:$lock_path,
    lock_acquired:$lock_acquired,
    lock_acquired_at:(if $lock_acquired_at == "null" then null else $lock_acquired_at end),
    lock_timeout_seconds:$lock_timeout_seconds,
    competing_writer_count:$competing_writer_count,
    pre_integrity_state:$pre_integrity_state,
    post_integrity_state:$post_integrity_state,
    release_status:$release_status,
    sqlite_concurrent_writer_risk_count:$sqlite_concurrent_writer_risk_count,
    sqlite_write_lock_conflict_count:$sqlite_write_lock_conflict_count,
    sqlite_write_locks:{
      top_conflicts:(
        if $lock_acquired then []
        else [{lock_path:$lock_path, owner:($conflict_owner // ""), age_seconds:$conflict_age_seconds}]
        end
      )
    }
  }'

if [[ "$lock_acquired" != true ]]; then
  exit 2
fi
