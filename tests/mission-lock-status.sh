#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mission-lock-age-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-lock-status.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  jq -e "$filter" "$file" >/dev/null || {
    printf 'FAIL: %s\n' "$label" >&2
    jq . "$file" >&2 || true
    exit 1
  }
  printf 'PASS: %s\n' "$label"
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
body="$TMP/body.txt"
placeholder="0000000000000000000000000000000000000000000000000000000000000000"
cat >"$body" <<'EOF'
## Body

Mission body.
EOF
cat >"$repo/.flywheel/MISSION.md" <<EOF
# Fixture Mission

schema_version: 1
doc_type: mission
status: locked
locked_at: 2026-05-07T00:00:00Z
lock_hash: $placeholder

$(cat "$body")
EOF
hash="$("$SCRIPT" --repo "$repo" --status --json | jq -r '.computed_body_hash')"
MISSION_HASH="$hash" PLACEHOLDER="$placeholder" perl -0pi -e 's/$ENV{PLACEHOLDER}/$ENV{MISSION_HASH}/g' "$repo/.flywheel/MISSION.md"
jq -nc \
  --arg ts "2026-05-07T00:00:00Z" \
  --arg hash "$hash" \
  '{ts:$ts, action:"mission-lock", file:".flywheel/MISSION.md", lock_hash:$hash, locked_by:"flywheel:mission-lock"}' \
  >"$repo/.flywheel/lock-log.jsonl"

before="$(find "$repo/.flywheel" -type f -maxdepth 1 -print0 | sort -z | xargs -0 shasum -a 256)"
"$SCRIPT" --repo "$repo" --status --json >"$TMP/status.json"
after="$(find "$repo/.flywheel" -type f -maxdepth 1 -print0 | sort -z | xargs -0 shasum -a 256)"
[[ "$before" == "$after" ]] || fail "--status mutated fixture files"

assert_jq "$TMP/status.json" '
  .schema_version == "flywheel.mission_lock_age.v1"
  and .mode == "status"
  and .status == "ok"
  and .mission_schema_version == "1"
  and .locked_at == "2026-05-07T00:00:00Z"
  and .mission_lock_age_hours != null
  and .lock_hash_valid == true
  and .lock_hash_matches_body == true
  and .lock_hash_matches_lock_log == true
  and .last_lock_log_row.action == "mission-lock"
' "status mode emits read-only lock state"

bad="$TMP/bad"
mkdir -p "$bad/.flywheel"
cp "$repo/.flywheel/MISSION.md" "$bad/.flywheel/MISSION.md"
jq -nc '{ts:"2026-05-07T00:00:00Z", action:"mission-lock", file:".flywheel/MISSION.md", lock_hash:"bad"}' >"$bad/.flywheel/lock-log.jsonl"
"$SCRIPT" --repo "$bad" --status --json >"$TMP/degraded.json"
assert_jq "$TMP/degraded.json" '.status == "degraded" and .lock_hash_valid == false and (.warnings | index("lock_hash_not_found_in_lock_log"))' "status mode degrades on invalid lock hash evidence"

printf 'OK mission-lock status\n'
