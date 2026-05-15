#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
EXTRACT="$ROOT/.flywheel/scripts/agents-md-shard-extract.sh"
DOCTRINE="$ROOT/.flywheel/doctrine/skillos-secrets-class-sister-shards.md"

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

contains() {
  local file="$1" needle="$2" label="$3"
  if rg -Fq -- "$needle" "$file"; then pass "$label"; else fail "$label"; fi
}

exists() {
  local file="$1" label="$2"
  if [[ -f "$file" ]]; then pass "$label"; else fail "$label"; fi
}

rules=(
  "L158|CLI-VERSION-FLAG-MISMATCH-OUTPUT-FORMAT-SWITCH-LEAKS|.flywheel/rules/L114-L158-cli-version-flag-mismatch-output-format-switch-leaks.md|/Users/josh/Developer/skillos/.flywheel/doctrine/cli-version-flag-mismatch-output-format-switch.md"
  "L160|AGENTIC-LOOP-HALT-VIA-POSTTOOLUSE-HOOK-WHEN-LEAK-DETECTED|.flywheel/rules/L115-L160-agentic-loop-halt-via-posttooluse-hook-when-leak-detected.md|/Users/josh/Developer/skillos/.flywheel/doctrine/cli-version-flag-mismatch-output-format-switch.md"
  "L161|OPERATOR-DIRECTED-MISSION-CONTINUATION-AFTER-LEAK|.flywheel/rules/L116-L161-operator-directed-mission-continuation-after-leak.md|/Users/josh/Developer/skillos/.flywheel/doctrine/cli-version-flag-mismatch-output-format-switch.md"
  "L163|CROSS-INFISICAL-PROJECT-CREDENTIAL-COLLISION-WRONG-TENANT-CONNECT|.flywheel/rules/L117-L163-cross-infisical-project-credential-collision-wrong-tenant-connect.md|/Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md"
  "L164|TENANT-VERIFICATION-GATE-MANDATORY-BEFORE-DB-MUTATION|.flywheel/rules/L118-L164-tenant-verification-gate-mandatory-before-db-mutation.md|/Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md"
  "L165|CF-SECRET-ITERATION-RETURNS-WRONG-PROJECT-FIRST-HIT|.flywheel/rules/L119-L165-cf-secret-iteration-returns-wrong-project-first-hit.md|/Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md"
  "L166|INFISICAL-SET-IGNORES-PROJECT-ID-ENV-OVERRIDE-USE-CLI-FLAG|.flywheel/rules/L120-L166-infisical-set-ignores-project-id-env-override-use-cli-flag.md|/Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md"
  "L167|TRANSACTIONAL-MIGRATION-AND-IDEMPOTENT-SCHEMA-MANDATORY|.flywheel/rules/L121-L167-transactional-migration-and-idempotent-schema-mandatory.md|/Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md"
)

for row in "${rules[@]}"; do
  IFS='|' read -r id title relpath source_path <<<"$row"
  file="$ROOT/$relpath"
  exists "$file" "$id shard exists"
  contains "$file" "id: $id" "$id frontmatter id"
  contains "$file" "source_owner: skillos" "$id marks SkillOS source ownership"
  contains "$file" "$source_path" "$id cites SkillOS source locator"
  exists "$source_path" "$id SkillOS source locator resolves"
  contains "$DOCTRINE" "$source_path" "$id doctrine source cross-ref"
  for surface in "$ROOT/AGENTS.md" "$ROOT/.flywheel/AGENTS-CANONICAL.md" "$ROOT/templates/flywheel-install/AGENTS.md"; do
    contains "$surface" "$id — $title" "$id indexed in ${surface#"$ROOT"/}"
  done
  if jq -e --arg id "$id" --arg path "$relpath" '.rules[] | select(.id == $id and .path == $path)' \
    "$ROOT/.flywheel/rules/MANIFEST.json" >/dev/null; then
    pass "$id manifest entry"
  else
    fail "$id manifest entry"
  fi
done

contains "$DOCTRINE" "SkillOS owns the canonical capability-control-plane doctrine" "doctrine states boundary"

if "$EXTRACT" --dry-run --json 2>/dev/null \
  | jq -e '.status == "in_sync" and .drifted_count == 0 and .rule_count >= 121' >/dev/null; then
  pass "shard extractor dry-run in sync"
else
  fail "shard extractor dry-run in sync"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
