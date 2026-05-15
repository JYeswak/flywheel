#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/josh-request-tick-promote.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/josh-req-consume.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

state="$TMP/josh-requests.jsonl"
evidence="$TMP/evidence"
mkdir -p "$evidence/memory" "$evidence/incidents"

cat >"$state" <<'JSONL'
{"id":"jr-consumed-hash","status":"open","priority":"P0","ts":"2026-05-15T00:00:00Z","prompt_hash":"hash-consumed-123","excerpt":"already handled by hash evidence"}
{"id":"jr-consumed-bead","state":"needs_triage","priority":"P1","captured_at":"2026-05-15T00:01:00Z","linked_bead_ids":["flywheel-abc123"],"sanitized_excerpt":"linked bead proof"}
{"id":"jr-consumed-excerpt","status":"open","priority":"P2","ts":"2026-05-15T00:02:00Z","excerpt":"private tmp accretes until disk dies"}
{"id":"jr-unconsumed","status":"open","priority":"P1","ts":"2026-05-15T00:03:00Z","prompt_hash":"hash-not-seen","excerpt":"still needs real handling"}
{"id":"jr-closed","status":"closed","priority":"P0","ts":"2026-05-15T00:04:00Z","prompt_hash":"closed-hash","excerpt":"closed row ignored"}
JSONL

cat >"$evidence/memory/MEMORY.md" <<'EOF'
hash-consumed-123 has already been absorbed into memory.
The failure class says private tmp accretes until disk dies.
EOF

cat >"$evidence/incidents/INCIDENTS.md" <<'EOF'
The closeout receipt for flywheel-abc123 proves the linked bead was handled.
EOF

if bash -n "$SCRIPT"; then pass "syntax"; else fail "syntax"; fi

JOSH_REQUEST_STATE_FILE="$state" \
  JOSH_REQUEST_EVIDENCE_ROOTS="$evidence/memory:$evidence/incidents" \
  "$SCRIPT" --json >"$TMP/out.json"

assert_jq "$TMP/out.json" '.action == "surfaced"' "action surfaced"
assert_jq "$TMP/out.json" '.queued_count == 4' "queued count includes consumed and unread"
assert_jq "$TMP/out.json" '.unread == 1' "unread excludes consumed evidence"
assert_jq "$TMP/out.json" '.consumed_with_evidence_count == 3' "consumed evidence counted"
assert_jq "$TMP/out.json" '.ids == ["jr-unconsumed"]' "ids surface only unconsumed work"
assert_jq "$TMP/out.json" '.highest_priority == "P1"' "highest priority from unconsumed work"
assert_jq "$TMP/out.json" '.consumed_requests | length == 3' "consumed requests summarized"
assert_jq "$TMP/out.json" '.consumed_requests[] | select(.id == "jr-consumed-hash" and .match_type == "prompt_hash")' "prompt hash evidence match"
assert_jq "$TMP/out.json" '.consumed_requests[] | select(.id == "jr-consumed-bead" and .match_type == "linked_bead_id")' "linked bead evidence match"
assert_jq "$TMP/out.json" '.consumed_requests[] | select(.id == "jr-consumed-excerpt" and .match_type == "excerpt_tokens")' "excerpt evidence match"

JOSH_REQUEST_STATE_FILE="$TMP/missing.jsonl" "$SCRIPT" --json >"$TMP/missing.json"
assert_jq "$TMP/missing.json" '.action == "missing_state_file" and .unread == 0' "missing file remains nonblocking"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
