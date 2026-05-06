#!/usr/bin/env bash
set -euo pipefail

VERSION="dispatch-author-skill-routing-contract/v1"
MAX_SKILLS=10
JSON_OUT=0
QUIET=0
MODE=probe
DISPATCH_PATH=""

usage() {
  cat <<'USAGE'
usage: dispatch-author-contract-probe.sh [--json] [--quiet] [--max-skills N] --dispatch PATH
       dispatch-author-contract-probe.sh [--json] [--quiet] [--max-skills N] PATH
       dispatch-author-contract-probe.sh --info|--help|--examples [--json]
USAGE
}

info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg version "$VERSION" '{
      name:"dispatch-author-contract-probe",
      schema_version:$version,
      canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],
      checks:["deterministic_class_merge","discovery_precedence","required_overlays","secret_value_bans","route_receipts_schema","prompt_budget_within_limit"],
      verdicts:["pass","partial","fail"]
    }'
  else
    printf '%s\n' \
      "name=dispatch-author-contract-probe" \
      "schema=$VERSION" \
      "verbs=--info,--help,--examples,--json,--quiet" \
      "verdicts=pass,partial,fail"
  fi
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:[
      "dispatch-author-contract-probe.sh --json /tmp/dispatch.md",
      "dispatch-author-contract-probe.sh --dispatch /tmp/dispatch.md --quiet",
      "dispatch-author-contract-probe.sh --max-skills 12 --json /tmp/dispatch.md"
    ]}'
  else
    printf '%s\n' \
      "dispatch-author-contract-probe.sh --json /tmp/dispatch.md" \
      "dispatch-author-contract-probe.sh --dispatch /tmp/dispatch.md --quiet" \
      "dispatch-author-contract-probe.sh --max-skills 12 --json /tmp/dispatch.md"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --max-skills) MAX_SKILLS="${2:?--max-skills requires N}"; shift 2 ;;
    --max-skills=*) MAX_SKILLS="${1#*=}"; shift ;;
    --dispatch|--file) DISPATCH_PATH="${2:?--dispatch requires PATH}"; shift 2 ;;
    --dispatch=*|--file=*) DISPATCH_PATH="${1#*=}"; shift ;;
    --info) MODE=info; shift ;;
    --examples) MODE=examples; shift ;;
    --help|-h) usage; exit 0 ;;
    --*) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) DISPATCH_PATH="$1"; shift ;;
  esac
done

case "$MODE" in
  info) info; exit 0 ;;
  examples) examples; exit 0 ;;
esac

[[ "$MAX_SKILLS" =~ ^[0-9]+$ ]] || { printf 'ERR --max-skills must be numeric\n' >&2; exit 2; }
[[ -n "$DISPATCH_PATH" && -r "$DISPATCH_PATH" ]] || { usage >&2; exit 2; }

BODY="$(cat "$DISPATCH_PATH")"
TMP_CHECKS="$(mktemp "${TMPDIR:-/tmp}/dispatch-author-contract-checks.XXXXXX")"
TMP_VIOLATIONS="$(mktemp "${TMPDIR:-/tmp}/dispatch-author-contract-violations.XXXXXX")"
trap 'rm -f "$TMP_CHECKS" "$TMP_VIOLATIONS"' EXIT
: >"$TMP_CHECKS"
: >"$TMP_VIOLATIONS"

has_fixed() { grep -Fqi -- "$1" <<<"$BODY"; }
has_regex() { grep -Eqi -- "$1" <<<"$BODY"; }
check() {
  jq -nc --arg name "$1" --arg status "$2" --arg detail "$3" \
    '{name:$name,status:$status,detail:$detail}' >>"$TMP_CHECKS"
}
violation() {
  jq -nc --arg code "$1" --arg severity "$2" --arg check "$3" \
    --arg detail "$4" --arg recommendation "$5" \
    '{code:$code,severity:$severity,check:$check,detail:$detail,recommendation:$recommendation}' >>"$TMP_VIOLATIONS"
}

if has_fixed "collision_policy=unresolved"; then
  check deterministic_class_merge fail "class collision is marked unresolved"
  violation "class_collision_unresolved" error deterministic_class_merge "collision_policy=unresolved" "run dispatch-skill-router-collision-resolver.sh and preserve its collision receipt"
elif has_fixed "dispatch_class_merge_order" && has_fixed "strictest_invariant_wins=true" && has_fixed "collision_policy=resolved"; then
  check deterministic_class_merge pass "merge order and resolved collision policy present"
else
  check deterministic_class_merge fail "missing merge order, resolved collision policy, or strictest-invariant marker"
  violation "deterministic_class_merge_missing" error deterministic_class_merge "required class-merge markers are missing" "add dispatch_class_merge_order, collision_policy=resolved, and strictest_invariant_wins=true"
fi

expected_precedence="exact:get_skill > local:SKILL.md-readable > semantic:socraticode > external:npx-skills-find-installable-only > fallback:rg-filesystem"
if has_fixed "$expected_precedence"; then
  check discovery_precedence pass "canonical precedence order present"
else
  check discovery_precedence fail "canonical precedence order missing or reversed"
  violation "discovery_precedence_invalid" error discovery_precedence "source precedence is not canonical" "use exact/local before semantic, external install-only, then rg fallback"
fi

missing_overlays=()
for token in canonical-cli-scoping readme-writing de-slopify simplify socraticode agent-mail agent-monitoring cost-attribution search-tool-routing-doctrine; do
  has_fixed "$token" || missing_overlays+=("$token")
done
if ((${#missing_overlays[@]} == 0)); then
  check required_overlays pass "universal and cross-cutting overlays represented"
else
  check required_overlays fail "missing required overlays"
  violation "required_overlay_missing" error required_overlays "one or more required overlay tokens are absent" "represent every universal and cross-cutting overlay with applied, alias, skip, or not-applicable receipt"
fi

secret_regex='(sk-ant-[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9_-]{20,}|xai-[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|AIza[A-Za-z0-9_-]{35}|Bearer[[:space:]]+[A-Za-z0-9._-]{20,}|registration_token[=:][A-Za-z0-9._-]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{20,})'
if ! has_fixed "secret_values_allowed=false"; then
  check secret_value_bans fail "secret_values_allowed=false marker missing"
  violation "secret_value_ban_missing" error secret_value_bans "packet does not declare secret values forbidden" "add secret_values_allowed=false"
elif has_regex "$secret_regex"; then
  check secret_value_bans fail "secret-shaped literal detected"
  violation "secret_value_literal_present" error secret_value_bans "packet contains a forbidden secret-shaped value" "replace literal values with secret class, key name, vault path, or redacted evidence"
else
  check secret_value_bans pass "secret-value ban present and no secret-shaped literal detected"
fi

missing_receipt=()
for token in route_receipt_schema_version skill_routing "skill_receipts[]" receipt_identity_key skill source action_taken policy_version evidence alias_of not_applicable_reason idempotency_key replay_detection_hash transaction_boundary receipt_completeness; do
  has_fixed "$token" || missing_receipt+=("$token")
done
if ((${#missing_receipt[@]} == 0)); then
  check route_receipts_schema pass "route receipt fields present"
else
  check route_receipts_schema fail "route receipt schema fields missing"
  violation "route_receipt_schema_malformed" error route_receipts_schema "one or more route receipt fields are absent" "include dispatch-author-route-receipt/v1 and Wave 1 dispatch-receipt identity fields"
fi

skill_count="$(awk -F: 'tolower($1)=="selected_skill_count"{gsub(/[[:space:]]/,"",$2); print $2}' "$DISPATCH_PATH" | tail -n 1)"
[[ "$skill_count" =~ ^[0-9]+$ ]] || skill_count=0
if ! has_fixed "prompt_budget_policy"; then
  check prompt_budget_within_limit fail "prompt budget policy missing"
  violation "prompt_budget_policy_missing" error prompt_budget_within_limit "packet lacks prompt budget policy" "add names-plus-one-line-why policy and excerpt cap"
elif (( skill_count > MAX_SKILLS )); then
  check prompt_budget_within_limit fail "selected skill count exceeds budget"
  violation "prompt_budget_exceeded" warn prompt_budget_within_limit "selected skill count exceeds max-skills" "prune secondary excerpts to paths and keep only risk-bearing excerpts"
else
  check prompt_budget_within_limit pass "prompt budget policy present and skill count within limit"
fi

checks_json="$(jq -s 'map({(.name): {status:.status, detail:.detail}}) | add' "$TMP_CHECKS")"
violations_json="$(jq -s '.' "$TMP_VIOLATIONS")"
if jq -e 'any(.[]; .severity == "error")' >/dev/null <<<"$violations_json"; then
  verdict=fail
elif jq -e 'any(.[]; .severity == "warn")' >/dev/null <<<"$violations_json"; then
  verdict=partial
else
  verdict=pass
fi

payload="$(jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg path "$DISPATCH_PATH" --arg schema "$VERSION" --arg verdict "$verdict" \
  --argjson checks "$checks_json" --argjson violations "$violations_json" \
  '{schema_version:$schema,ts:$ts,dispatch_path:$path,checks:$checks,verdict:$verdict,violations:$violations}')"

if [[ "$QUIET" -eq 0 ]]; then
  if [[ "$JSON_OUT" -eq 1 || "$MODE" == probe ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"verdict=\(.verdict) violations=\(.violations|length)"' <<<"$payload"
  fi
fi

[[ "$verdict" != fail ]]
