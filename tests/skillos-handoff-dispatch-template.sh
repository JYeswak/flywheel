#!/usr/bin/env bash
set -euo pipefail

DISPATCH_TEMPLATE="${DISPATCH_TEMPLATE:-$HOME/.claude/commands/flywheel/_shared/dispatch-template.md}"
SKILL_PACKET="${SKILL_PACKET:-$HOME/.claude/skills/.flywheel/dispatch-templates/skill-creation-with-handoff.md}"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

line_number() {
  local pattern="$1" file="$2"
  rg -n -F "$pattern" "$file" | head -1 | cut -d: -f1
}

contains() {
  local file="$1" pattern="$2" label="$3"
  if rg -q -F "$pattern" "$file"; then pass "$label"; else fail "$label"; fi
}

[[ -f "$DISPATCH_TEMPLATE" ]] || { fail "dispatch template exists"; exit 1; }
[[ -f "$SKILL_PACKET" ]] || { fail "skill creation packet exists"; exit 1; }
pass "required files exist"

contains "$DISPATCH_TEMPLATE" "## Skillos handoff (REQUIRED if dispatch creates ~/.claude/skills/*)" "dispatch template has required handoff section"
contains "$DISPATCH_TEMPLATE" "Release Agent Mail file reservations and any shared-surface reservations" "dispatch template releases reservations before handoff"
contains "$DISPATCH_TEMPLATE" "Run the handoff helper after release, never before" "dispatch template forbids pre-release handoff"
contains "$DISPATCH_TEMPLATE" "skillos_handoff_message_id=<int|null>" "dispatch callback requires message id field"
contains "$DISPATCH_TEMPLATE" "skillos_handoff_skipped_reason=<text|null>" "dispatch callback requires skipped reason field"
contains "$DISPATCH_TEMPLATE" "Callback validation rejects skill-creation dispatches when both fields are" "dispatch template rejects null/null callbacks"
contains "$DISPATCH_TEMPLATE" "skill-creation-with-handoff.md" "dispatch template links example packet"

release_line="$(line_number "Release Agent Mail file reservations and any shared-surface reservations" "$DISPATCH_TEMPLATE")"
helper_line="$(line_number "Run the handoff helper after release, never before" "$DISPATCH_TEMPLATE")"
if [[ -n "$release_line" && -n "$helper_line" && "$release_line" -lt "$helper_line" ]]; then
  pass "release-before-handoff order"
else
  fail "release-before-handoff order"
fi

contains "$SKILL_PACKET" "## Work sequence" "example packet has work sequence"
contains "$SKILL_PACKET" "Release Agent Mail file reservations for the skill files" "example packet releases skill reservations"
contains "$SKILL_PACKET" "Run the skillos handoff helper after releases" "example packet runs helper after releases"
contains "$SKILL_PACKET" "DONE flywheel_skill_create_example" "example packet includes full callback"
contains "$SKILL_PACKET" "Reject if skill_path matches /Users/josh/.claude/skills/<skill-name>" "example packet has null/null rejection rule"

packet_release_line="$(line_number "Release Agent Mail file reservations for the skill files" "$SKILL_PACKET")"
packet_helper_line="$(line_number "Run the skillos handoff helper after releases" "$SKILL_PACKET")"
if [[ -n "$packet_release_line" && -n "$packet_helper_line" && "$packet_release_line" -lt "$packet_helper_line" ]]; then
  pass "example packet release-before-handoff order"
else
  fail "example packet release-before-handoff order"
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
