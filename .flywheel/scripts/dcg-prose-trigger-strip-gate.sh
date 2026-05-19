#!/usr/bin/env bash
# .flywheel/scripts/dcg-prose-trigger-strip-gate.sh
#
# Structural gate for memory rule
# `feedback_dcg_prose_trigger_strip_dangerous_substrings.md` (META-RULE
# 2026-05-08 — DCG matches dangerous shell substrings even inline in
# br/ntm prose; rephrase before submit).
#
# Wired by flywheel-wire-dcg-prose-trigger-strip-dangerous-704d805a per
# the memory-rule-gate-parity-detector AG1 contract.
#
# Reads candidate prose from a file path (--file) or stdin (-) and
# scans for the canonical dangerous-substring set that DCG blocks
# inline. Emits a structured JSON receipt + non-zero exit when matches
# are found. Default mode is --check (read-only). Operators chain it
# into pre-flight before `br create -d`, `ntm send`, or
# `_shared/dispatch-template.md` body assembly.
#
# Canonical canonical-cli-scoping triad: --info / --schema / --examples
# + --check / --apply (apply is reserved for future "auto-rephrase"
# evolution; today --apply == --check, refuse with rc=2 if invoked).
set -euo pipefail

VERSION="dcg-prose-trigger-strip-gate.v1"
MEMORY_RULE="${DCG_PROSE_TRIGGER_MEMORY_RULE:-$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dcg_prose_trigger_strip_dangerous_substrings.md}"

INPUT_FILE=""
JSON_OUT=0
MODE="check"

# Canonical dangerous substrings observed in prose-trigger DCG blocks
# (per the memory rule + INCIDENTS observations 2026-05-08+).
# Each entry: <substring>|<dcg_rule_id>|<descriptive_replacement>
DANGEROUS_PATTERNS=(
  "git add -A|strict_git:add-all-flag|the all-paths flag (-A / --all)"
  "git add --all|strict_git:add-all-flag|the all-paths flag (-A / --all)"
  "rm -rf|core.filesystem:rm-rf-general|recursive deletion / force-recursive removal"
  "rm -fr|core.filesystem:rm-rf-general|recursive deletion / force-recursive removal"
  "git reset --hard|core.git:reset-hard|hard-reset / destructive reset"
  "git push --force|core.git:push-force-long|force-push (long form)"
  "git stash clear|core.git:stash-clear|stash clear (destructive)"
  "git worktree remove|strict_git:worktree-remove|worktree-remove (structured op)"
)

usage() {
  cat <<'USAGE'
usage:
  dcg-prose-trigger-strip-gate.sh --file PATH [--check] [--json]
  dcg-prose-trigger-strip-gate.sh - [--check] [--json]   # read stdin
  dcg-prose-trigger-strip-gate.sh doctor|--doctor [--json]
  dcg-prose-trigger-strip-gate.sh --info|--schema|--examples|--help

Scans candidate prose (file path or stdin) for canonical
DCG-prose-trigger substrings that block downstream Bash invocations.
Reports any matches with the canonical replacement guidance from
the memory rule.

Exit codes:
  0  prose is safe (no canonical dangerous substrings found)
  1  one or more dangerous substrings detected (call to action: rephrase
     before submitting through br create -d / ntm send)
  2  usage error
USAGE
}

info_json() {
  local pattern_count="${#DANGEROUS_PATTERNS[@]}"
  jq -nc \
    --arg name "dcg-prose-trigger-strip-gate.sh" \
    --arg version "$VERSION" \
    --arg memory_rule "$MEMORY_RULE" \
    --arg sourced_by "flywheel-wire-dcg-prose-trigger-strip-dangerous-704d805a" \
    --argjson exit_codes '{"0":"prose safe","1":"dangerous substring detected","2":"usage error"}' \
    --argjson pattern_count "$pattern_count" \
    '{
      schema_version: "tool-info/v1",
      name: $name,
      version: $version,
      memory_rule_path: $memory_rule,
      sourced_by_bead: $sourced_by,
      modes: ["check"],
      default_mode: "check",
      flags: ["--file","--check","--apply","--json","doctor","--doctor","--info","--schema","--examples","--help","-"],
      env_vars: ["DCG_PROSE_TRIGGER_MEMORY_RULE"],
      mutates: false,
      pattern_count: $pattern_count,
      exit_codes: $exit_codes,
      receipt_schema: "dcg-prose-trigger-strip-gate-receipt/v1",
      doctor_schema: "dcg-prose-trigger-strip-gate.doctor.v1"
    }'
}

schema_json() {
  jq -nc '{
    "$schema": "http://json-schema.org/draft-07/schema#",
    schema_version: "dcg-prose-trigger-strip-gate-receipt/v1",
    type: "object",
    required: ["ts","mode","input_source","status","matches"],
    properties: {
      ts: {type:"string"},
      mode: {type:"string", enum:["check"]},
      input_source: {type:"string"},
      status: {type:"string", enum:["safe","dangerous_substring_detected"]},
      input_bytes: {type:"integer"},
      matches: {
        type:"array",
        items: {
          type:"object",
          required: ["substring","dcg_rule","replacement","occurrences"],
          properties: {
            substring: {type:"string"},
            dcg_rule: {type:"string"},
            replacement: {type:"string"},
            occurrences: {type:"integer"}
          }
        }
      },
      memory_rule_path: {type:"string"}
    }
  }'
}

doctor_json() {
  local jq_status memory_status pattern_status overall
  overall="pass"
  if command -v jq >/dev/null; then
    jq_status="pass"
  else
    jq_status="fail"
    overall="fail"
  fi
  if [[ -f "$MEMORY_RULE" ]]; then
    memory_status="pass"
  else
    memory_status="warn"
    [[ "$overall" == "fail" ]] || overall="warn"
  fi
  if [[ "${#DANGEROUS_PATTERNS[@]}" -gt 0 ]]; then
    pattern_status="pass"
  else
    pattern_status="fail"
    overall="fail"
  fi
  jq -nc \
    --arg status "$overall" \
    --arg version "$VERSION" \
    --arg memory_rule "$MEMORY_RULE" \
    --arg jq_status "$jq_status" \
    --arg memory_status "$memory_status" \
    --arg pattern_status "$pattern_status" \
    --argjson pattern_count "${#DANGEROUS_PATTERNS[@]}" \
    '{
      schema_version: "dcg-prose-trigger-strip-gate.doctor.v1",
      command: "doctor",
      status: $status,
      mode: "read_only",
      mutates: false,
      version: $version,
      memory_rule_path: $memory_rule,
      pattern_count: $pattern_count,
      checks: [
        {name:"jq_available", status:$jq_status},
        {name:"memory_rule_present", status:$memory_status},
        {name:"pattern_catalog_nonempty", status:$pattern_status}
      ]
    }'
}

examples() {
  cat <<'EXAMPLES'
Examples:
  # Read-only prerequisite/catalog doctor:
  .flywheel/scripts/dcg-prose-trigger-strip-gate.sh doctor --json

  # Pre-flight prose before `br create -d` (intended canonical pattern):
  cat > /tmp/bead-body.md <<'EOF'
  ## Trauma class
  worker keeps trying `git add -A` and DCG blocks it.
  EOF
  .flywheel/scripts/dcg-prose-trigger-strip-gate.sh --file /tmp/bead-body.md --json
  # → status=dangerous_substring_detected, matches[0].substring="git add -A"

  # Stdin path (for pipelines):
  printf 'don\\047t use rm -rf' | .flywheel/scripts/dcg-prose-trigger-strip-gate.sh - --json

  # Safe prose (no dangerous substrings):
  echo "use the all-paths flag instead" | .flywheel/scripts/dcg-prose-trigger-strip-gate.sh - --json
  # → status=safe, matches=[]

  # Inspect the pattern catalog
  .flywheel/scripts/dcg-prose-trigger-strip-gate.sh --info | jq '.pattern_count'
EXAMPLES
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info)     info_json; exit 0 ;;
    --schema)   schema_json; exit 0 ;;
    --examples) examples; exit 0 ;;
    doctor|--doctor) doctor_json; exit 0 ;;
    -h|--help)  usage; exit 0 ;;
    --check)    MODE="check"; shift ;;
    --apply)
      printf 'apply mode is reserved for future auto-rephrase; use --check\n' >&2
      exit 2 ;;
    --json)     JSON_OUT=1; shift ;;
    --file)     INPUT_FILE="${2:-}"; shift 2 ;;
    -)          INPUT_FILE="-"; shift ;;
    --*)        printf 'unknown flag: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *)
      if [[ -z "$INPUT_FILE" ]]; then
        INPUT_FILE="$1"
      else
        printf 'unexpected positional: %s\n' "$1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [[ -z "$INPUT_FILE" ]]; then
  printf 'error: --file PATH or - (stdin) required\n' >&2
  usage >&2
  exit 2
fi

if [[ "$INPUT_FILE" == "-" ]]; then
  INPUT_BODY="$(cat)"
elif [[ -f "$INPUT_FILE" ]]; then
  INPUT_BODY="$(cat "$INPUT_FILE")"
else
  printf 'error: input file not found: %s\n' "$INPUT_FILE" >&2
  exit 2
fi

INPUT_BYTES="${#INPUT_BODY}"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

matches_json='[]'
for entry in "${DANGEROUS_PATTERNS[@]}"; do
  IFS='|' read -r substring rule_id replacement <<<"$entry"
  # Count occurrences. grep -c returns matching-line count (rc=1 if zero
  # matches; rc=0 with the count on stdout). Wrap with `|| true` to
  # neutralize set -e, then default to 0 when empty.
  occurrences="$(printf '%s' "$INPUT_BODY" | grep -F -c -- "$substring" 2>/dev/null || true)"
  occurrences="${occurrences:-0}"
  occurrences="${occurrences//[^0-9]/}"
  occurrences="${occurrences:-0}"
  if [[ "$occurrences" -gt 0 ]]; then
    matches_json="$(jq -nc \
      --argjson prev "$matches_json" \
      --arg substring "$substring" \
      --arg dcg_rule "$rule_id" \
      --arg replacement "$replacement" \
      --argjson occurrences "$occurrences" \
      '$prev + [{substring:$substring, dcg_rule:$dcg_rule, replacement:$replacement, occurrences:$occurrences}]')"
  fi
done

if jq -e '. | length > 0' >/dev/null 2>&1 <<<"$matches_json"; then
  STATUS="dangerous_substring_detected"
  EXIT_CODE=1
else
  STATUS="safe"
  EXIT_CODE=0
fi

RECEIPT="$(jq -nc \
  --arg schema_version "dcg-prose-trigger-strip-gate-receipt/v1" \
  --arg ts "$TS" \
  --arg mode "$MODE" \
  --arg input_source "$INPUT_FILE" \
  --arg status "$STATUS" \
  --argjson input_bytes "$INPUT_BYTES" \
  --argjson matches "$matches_json" \
  --arg memory_rule_path "$MEMORY_RULE" \
  '{
    schema_version: $schema_version,
    ts: $ts,
    mode: $mode,
    input_source: $input_source,
    status: $status,
    input_bytes: $input_bytes,
    matches: $matches,
    memory_rule_path: $memory_rule_path
  }')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$RECEIPT"
else
  if [[ "$STATUS" == "safe" ]]; then
    printf 'OK: prose has no canonical DCG-prose-trigger substrings\n'
  else
    printf 'WARN: dangerous substring(s) detected (rephrase before submitting)\n'
    jq -r '.matches[] | "  - \(.substring) [\(.dcg_rule)] (×\(.occurrences)) → \(.replacement)"' <<<"$RECEIPT"
    printf '\nMemory rule: %s\n' "$MEMORY_RULE"
  fi
fi

exit "$EXIT_CODE"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
