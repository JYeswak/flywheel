#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HARNESS="$ROOT/.flywheel/scripts/bcv-task-harness.sh"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/bcv-task-harness.XXXXXX")"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command for test: $1" >&2
    exit 77
  }
}

require_cmd br
require_cmd jq
require_cmd git

write_compliance_pack() {
  local bd="$1" id="$2"
  jq -n \
    --arg id "$id" \
    --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      bead_id: $id,
      executed_at: $now,
      executor: "subagents/compliance-verifier.md",
      checks: []
    }' > "$bd/compliance.json"
}

write_depth_pack() {
  local bd="$1" id="$2"
  jq -n \
    --arg id "$id" \
    --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      bead_id: $id,
      audited_at: $now,
      auditor: "subagents/test-depth-auditor.md",
      checks: []
    }' > "$bd/test_depth.json"
}

wait_for_prompt_files() {
  local phase="$1" expected="$2" deadline count
  deadline=$(( $(date +%s) + 20 ))
  while true; do
    count="$(find "$AUDIT_DIR/passes" -path "*/task-prompts/$phase/*.md" -type f 2>/dev/null | wc -l | tr -d ' ' || true)"
    if [ "$count" -ge "$expected" ]; then
      return 0
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
      echo "timed out waiting for $expected prompt files for $phase" >&2
      return 1
    fi
    sleep 1
  done
}

REPO="$TMP_DIR/repo"
AUDIT_DIR="$TMP_DIR/audit"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email test@example.invalid
git -C "$REPO" config user.name "BCV Harness Test"
(
  cd "$REPO"
  br init --prefix bcv >/dev/null

  ID1="$(br create "first closed bead" \
    --description "Acceptance: preserve alpha behavior" \
    --priority 2 \
    --json | jq -r '.id')"
  ID2="$(br create "second closed bead" \
    --description "Acceptance: preserve beta behavior" \
    --priority 2 \
    --json | jq -r '.id')"
  br close "$ID1" --reason "fixture closed for harness test" >/dev/null
  br close "$ID2" --reason "fixture closed for harness test" >/dev/null
  printf '%s\n%s\n' "$ID1" "$ID2" > "$TMP_DIR/ids.txt"
)
ID1="$(sed -n '1p' "$TMP_DIR/ids.txt")"
ID2="$(sed -n '2p' "$TMP_DIR/ids.txt")"

(
  wait_for_prompt_files phase4 2
  PASS_DIR="$(find "$AUDIT_DIR/passes" -mindepth 1 -maxdepth 1 -type d | head -1)"
  for bd in "$PASS_DIR"/beads/*; do
    [ -d "$bd" ] || continue
    id="$(basename "$bd")"
    write_compliance_pack "$bd" "$id"
  done

  wait_for_prompt_files phase6 2
  for bd in "$PASS_DIR"/beads/*; do
    [ -d "$bd" ] || continue
    id="$(basename "$bd")"
    write_depth_pack "$bd" "$id"
  done
) &
WRITER_PID=$!

OUT="$TMP_DIR/harness.json"
"$HARNESS" \
  --repo "$REPO" \
  --audit-dir "$AUDIT_DIR" \
  --beads "$ID1,$ID2" \
  --wait-timeout-seconds 25 \
  --poll-seconds 1 \
  --apply \
  --json > "$OUT"
wait "$WRITER_PID"

jq -e '
  .status == "complete"
  and .non_stub_compliance_count == 2
  and .non_stub_test_depth_count == 2
  and .validation_passed == true
  and .deterministic_banner_present == false
  and (.phase4_prompts | length) == 2
  and (.phase6_prompts | length) == 2
' "$OUT" >/dev/null

REPORT="$(jq -r '.report_path' "$OUT")"
if grep -Fq "DETERMINISTIC-ONLY PASS" "$REPORT"; then
  echo "unexpected deterministic-only banner in $REPORT" >&2
  exit 1
fi

for bd in "$(jq -r '.pass_dir' "$OUT")"/beads/*; do
  jq -e '.executor != "stub-wrapper"' "$bd/compliance.json" >/dev/null
  jq -e '.auditor != "stub-wrapper"' "$bd/test_depth.json" >/dev/null
done

echo "bcv-task-harness fixture passed"
