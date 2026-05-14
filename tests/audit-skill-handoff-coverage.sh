#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/audit-skill-handoff-coverage.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/audit-skill-handoff-coverage.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

mkdir -p "$TMP/skills/info-source-watchtower" "$TMP/skills/covered-skill" "$TMP/skills/skipped-skill" "$TMP/skills/sent-no-receipt" "$TMP/skillos-state"

for skill in info-source-watchtower covered-skill skipped-skill sent-no-receipt; do
  cat >"$TMP/skills/$skill/SKILL.md" <<EOF
---
name: $skill
version: 1.2.3
---
EOF
done

cat >"$TMP/dispatch-log.jsonl" <<'EOF'
{"ts":"2026-05-14T00:00:00Z","event":"skillos_handoff_sent","skill":"covered-skill","version":"1.2.3","message_id":1,"skillos_handoff_skipped_reason":null}
{"ts":"2026-05-14T00:01:00Z","event":"skillos_handoff_skipped","skill":"skipped-skill","version":"1.2.3","skillos_handoff_skipped_reason":"ownership_forbidden"}
{"ts":"2026-05-14T00:02:00Z","event":"skillos_handoff_sent","skill":"sent-no-receipt","version":"1.2.3","message_id":2,"skillos_handoff_skipped_reason":null}
EOF
touch "$TMP/skillos-state/covered-skill-v1.2-20260514.json"

if bash -n "$SCRIPT"; then pass "script syntax"; else fail "script syntax"; fi

env \
  AUDIT_SKILL_HANDOFF_SKILL_ROOTS="$TMP/skills" \
  AUDIT_SKILL_HANDOFF_DISPATCH_LOG="$TMP/dispatch-log.jsonl" \
  AUDIT_SKILL_HANDOFF_SKILLOS_STATE_DIR="$TMP/skillos-state" \
  "$SCRIPT" --json >"$TMP/out.json"

assert_jq "$TMP/out.json" '.period_days == 30 and .skills_checked == 4' "json envelope counts recent skills"
assert_jq "$TMP/out.json" '.gaps[] | select(.skill == "info-source-watchtower" and .reason == "no_dispatch_log_entry")' "finds info-source-watchtower no-dispatch gap"
assert_jq "$TMP/out.json" '.gaps[] | select(.skill == "sent-no-receipt" and .reason == "no_skillos_receipt")' "finds sent skill missing skillos receipt"
assert_jq "$TMP/out.json" '([.gaps[].skill] | index("covered-skill") | not)' "receipt-covered skill is not a gap"
assert_jq "$TMP/out.json" '.intentional_skips[] | select(.skill == "skipped-skill" and .reason == "ownership_forbidden")' "known skip is intentional"

set +e
env \
  AUDIT_SKILL_HANDOFF_SKILL_ROOTS="$TMP/skills" \
  AUDIT_SKILL_HANDOFF_DISPATCH_LOG="$TMP/dispatch-log.jsonl" \
  AUDIT_SKILL_HANDOFF_SKILLOS_STATE_DIR="$TMP/skillos-state" \
  "$SCRIPT" --json >"$TMP/out2.json"
rc=$?
set -e
if [[ "$rc" == "0" ]]; then pass "gaps exit zero"; else fail "gaps exit zero rc=$rc"; fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
