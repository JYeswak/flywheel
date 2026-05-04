#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d "${TMPDIR:-/tmp}/fuckup-join-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

log="$tmp/test-fuckup-log.jsonl"
processed="$tmp/test-fuckup-processed.jsonl"

: > "$log"
for i in 1 2 3 4 5 6 7 8 9 10; do
  class="class-$(((i - 1) % 5 + 1))"
  jq -nc --arg ts "2026-05-03T00:00:$(printf '%02d' "$i")Z" --arg id "row-$i" --arg class "$class" \
    '{ts:$ts,id:$id,trauma_class:$class,severity:"medium",what_happened:("mock " + $id)}' >> "$log"
done

jq -nc \
  --arg ts "2026-05-03T00:10:00Z" \
  --arg trauma_class "class-1" \
  --arg processed_into "INCIDENTS.md#class-1" \
  '{ts:$ts,trauma_class:$trauma_class,decision:"promoted",fuckup_log_lines:[1,6,10],processed_into:$processed_into}' > "$processed"

joined_count() {
  local log_file="$1"
  local processed_file="$2"
  test -f "$processed_file" || processed_file=/dev/null
  jq -s --slurpfile processed "$processed_file" '
    def processed_lines:
      [$processed[]?
        | .fuckup_log_lines[]?
        | tonumber?];
    def processed_ids:
      [$processed[]?
        | (.fuckup_log_ids[]?, .fuckup_log_id?, .id?)
        | select(. != null)
        | tostring];
    def processed_ts:
      [$processed[]?
        | (.fuckup_ts?, .fuckup_log_ts?)
        | select(. != null)
        | tostring];
    [
      to_entries[]
      | (.key + 1) as $line
      | .value as $row
      | (($row.id // $row.event_id // "") | tostring) as $id
      | (($row.ts // "") | tostring) as $ts
      | select(($row.processed // false) != true)
      | select(($row.processed_at // null) == null)
      | select(($row.processed_into // null) == null)
      | select((processed_lines | index($line)) | not)
      | select(($id == "" or ((processed_ids | index($id)) | not)))
      | select($ts == "" or ((processed_ts | index($ts)) | not))
    ] | length
  ' "$log_file"
}

old_count="$(jq -s '[.[] | select(.processed != true)] | length' "$log")"
new_count="$(joined_count "$log" "$processed")"

if [[ "$old_count" != "10" ]]; then
  echo "FAIL: old count expected 10 got $old_count"
  exit 1
fi

if [[ "$new_count" != "7" ]]; then
  echo "FAIL: joined count expected 7 got $new_count"
  exit 1
fi

if [[ "$new_count" == "6" ]]; then
  echo "FAIL: negative guard accepted wrong count"
  exit 1
fi

echo "PASS: fuckup processed JOIN excludes 3 aggregate-processed rows; old=10 new=7"
