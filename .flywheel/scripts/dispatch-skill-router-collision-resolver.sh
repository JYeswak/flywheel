#!/usr/bin/env bash
set -euo pipefail

usage(){ printf '%s\n' \
"dispatch-skill-router-collision-resolver.sh [--json] [--quiet] <bead-class tags...>" \
"dispatch-skill-router-collision-resolver.sh --info [--json]" \
"dispatch-skill-router-collision-resolver.sh --examples [--json]" \
"dispatch-skill-router-collision-resolver.sh --help"; }
info(){ printf '%s\n' \
"name=dispatch-skill-router-collision-resolver" \
"schema=dispatch-skill-router-collision-resolver/v1" \
"verbs=--info,--help,--examples,--json,--quiet" \
"policy=exact/local first; semantic second; external install-only; rg fallback" \
"collision_rule=ordered input, dedupe, strictest invariant wins, prompt-budget prune"; }
examples(){ printf '%s\n' \
"backend-endpoint database-migration" \
"substrate-fix security cli" \
"docs operator-contract implementation" \
"missing-skill schema-complete-drift-guard" \
"agent-mail observability cost secret-rotation search"; }

json=false; quiet=false; mode=resolve; tags=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --info) mode=info; shift ;;
    --examples) mode=examples; shift ;;
    --json) json=true; shift ;;
    --quiet) quiet=true; shift ;;
    --) shift; break ;;
    -*) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
    *) IFS=',' read -r -a parts <<<"$1"
       for part in "${parts[@]}"; do
         part="$(printf '%s' "$part" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '-')"
         part="${part#-}"; part="${part%-}"
         [[ -n "$part" ]] && tags+=("$part")
       done
       shift ;;
  esac
done

if [[ "$mode" == info ]]; then
  $json && jq -n --arg schema "dispatch-skill-router-collision-resolver/v1" \
    --argjson verbs '["--info","--help","--examples","--json","--quiet"]' \
    --arg policy "exact/local first; semantic second; external install-only; rg fallback" \
    '{schema_version:$schema,verbs:$verbs,source_precedence:$policy}' || info
  exit 0
fi
if [[ "$mode" == examples ]]; then
  $json && jq -n --argjson examples '[
    "backend-endpoint database-migration",
    "substrate-fix security cli",
    "docs operator-contract implementation",
    "missing-skill schema-complete-drift-guard",
    "agent-mail observability cost secret-rotation search"]' '{examples:$examples}' || examples
  exit 0
fi
if ((${#tags[@]} == 0)); then usage >&2; exit 2; fi

skills=(socraticode); overlays=(); collisions=(); notes=()
source_precedence=("exact:get_skill" "local:SKILL.md-readable" "semantic:socraticode" "external:npx-skills-find-installable-only" "fallback:rg-filesystem")
route_status=pass; self_test_gate=pass; missing_skill_followup=false
degraded_mode_reason=; no_raw_secret_evidence=false; secret_rotation_overlay=false

add(){ local x="$1"; shift; local -n a="$1"; local y; for y in "${a[@]}"; do [[ "$y" == "$x" ]] && return; done; a+=("$x"); }
has(){ local t n; for t in "${tags[@]}"; do for n in "$@"; do [[ "$t" == *"$n"* ]] && return 0; done; done; return 1; }
skill(){ add "$1" skills; }
overlay(){ add "$1" overlays; skill "$1"; }
collision(){ add "$1" collisions; }
note(){ add "$1" notes; }

has backend endpoint api service && { skill api-design-patterns; skill authentication-authorization; }
has database db migration schema sql storage && { skill database-modeling; skill database-operations; skill data-quality-validation; }
has substrate driver hook launchd plist doctor loop && { skill canonical-cli-scoping; skill config-file-management; overlay agent-monitoring; }
has cli command script shell flags && { skill canonical-cli-scoping; skill testing-golden-artifacts; }
has security auth credential secret rotation token bearer infisical && {
  skill authentication-authorization; skill mcp-secret-scanner; skill infisical-secrets
  no_raw_secret_evidence=true; secret_rotation_overlay=true
}
has docs doc readme operator contract runbook && { skill readme-writing; skill de-slopify; }
has implementation code patch source && { skill codebase-archaeology; skill testing-golden-artifacts; }
has agent-mail mail reservation callback receipt jsonl concurrent shared parallel coordination && overlay agent-mail
has observability monitoring telemetry metric health runtime watchtower && overlay agent-monitoring
has cost budget spend token model gpu attribution && overlay cost-attribution
has search skill discovery exact semantic router route source && overlay search-tool-routing-doctrine
has missing-skill schema-complete-drift-guard simplify no-source blocked-no-source && {
  route_status=degraded; missing_skill_followup=true
  degraded_mode_reason="exact skill missing or blocked; use local/semantic fallback and file skillos follow-up"
  collision missing_exact_skill_fallback; overlay search-tool-routing-doctrine
}
has blocked irrelevant bogus self-test-fail && {
  route_status=fail; self_test_gate=fail
  degraded_mode_reason="negative fixture rejected by route-health gate"
}
if has backend endpoint api service && has database db migration schema sql storage; then
  collision backend_plus_database; note strictest_data_auth_invariant_wins; skill data-quality-validation
fi
if has substrate driver hook launchd plist doctor loop && has security credential secret rotation token && has cli command script shell flags; then
  collision substrate_security_cli; note forbid_raw_secret_evidence; no_raw_secret_evidence=true
fi
if has docs doc readme operator contract runbook && has implementation code patch source script; then
  collision docs_contract_plus_implementation; note explicit_skip_receipts_required
fi
$secret_rotation_overlay && overlay mcp-secret-scanner

arr(){ (($# == 0)) && printf '[]' || printf '%s\n' "$@" | jq -R . | jq -s .; }
tags_json="$(arr "${tags[@]}")"; skills_json="$(arr "${skills[@]}")"
overlays_json="$(arr "${overlays[@]}")"; collisions_json="$(arr "${collisions[@]}")"
notes_json="$(arr "${notes[@]}")"; precedence_json="$(arr "${source_precedence[@]}")"

if $json; then
  jq -n --arg schema "dispatch-skill-router-collision-resolver/v1" \
    --arg route_status "$route_status" --arg self_test_gate "$self_test_gate" \
    --arg degraded "$degraded_mode_reason" --argjson input_tags "$tags_json" \
    --argjson skills "$skills_json" --argjson overlays "$overlays_json" \
    --argjson collisions "$collisions_json" --argjson notes "$notes_json" \
    --argjson source_precedence "$precedence_json" \
    --argjson missing_skill_followup "$missing_skill_followup" \
    --argjson no_raw_secret_evidence "$no_raw_secret_evidence" \
    '{schema_version:$schema,input_tags:$input_tags,skills:$skills,overlays:$overlays,
      collisions:$collisions,notes:$notes,source_precedence:$source_precedence,
      route_status:$route_status,self_test_gate:$self_test_gate,
      missing_skill_followup:$missing_skill_followup,
      degraded_mode_reason:$degraded,no_raw_secret_evidence:$no_raw_secret_evidence,
      prompt_budget_policy:"dedupe ordered inputs; strictest invariant wins; prune to risk-bearing excerpts"}'
elif $quiet; then
  printf '%s\n' "${skills[@]}"
else
  printf 'route_status=%s\nskills=%s\noverlays=%s\ncollisions=%s\nself_test_gate=%s\n' \
    "$route_status" "$(IFS=,; printf '%s' "${skills[*]}")" \
    "$(IFS=,; printf '%s' "${overlays[*]}")" \
    "$(IFS=,; printf '%s' "${collisions[*]}")" "$self_test_gate"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
