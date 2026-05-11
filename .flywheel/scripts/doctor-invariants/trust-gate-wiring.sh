#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (authored per Phase C, mirror of skillos B4)
# trust-gate-wiring.sh — fleet-wide doctor invariant for B4 trust-gate.
#
# Canonical owner: skillos:1 (skillos commit 62823a4 authored
# `mcp/skillos-mcp-server/lib/doctor_checks/trust_gate_wiring.py`).
# This file is the flywheel-side mirror, fulfilling Phase C of the
# pack-feedback cadence loop coordination (handoff 20260511T0438Z).
#
# Checks that the 3 trust-gate named skills are present in the global
# skill registry: gate-truth-separation, agent-sandboxing, slb.
# Emits canonical .checks shape envelope for AG3 + canonical-cli-lint.
set -euo pipefail

VERSION="trust-gate-wiring.v1.1.0"
SCHEMA_VERSION="trust-gate-wiring/v1"
# FLYWHEEL_TARGET_REPO_ROOT mirrors skillos's SKILLOS_TARGET_REPO_ROOT
# (skillos commit d19c747, retraction 2026-05-11T04:58Z).
# When set, probe the consumer repo's skills directory rather than the
# orchestrator's own — trust-gate-wiring must verify the actual consumer's
# wiring, not the orchestrator's. Falls back to ~/.claude/skills when unset.
FLYWHEEL_TARGET_REPO_ROOT="${FLYWHEEL_TARGET_REPO_ROOT:-}"
if [[ -n "$FLYWHEEL_TARGET_REPO_ROOT" ]]; then
  SKILLS_ROOT="${SKILLS_ROOT:-$FLYWHEEL_TARGET_REPO_ROOT/.claude/skills}"
else
  SKILLS_ROOT="${SKILLS_ROOT:-$HOME/.claude/skills}"
fi
NAMED_SKILLS=("gate-truth-separation" "agent-sandboxing" "slb")

usage() {
  cat <<'EOF'
usage:
  trust-gate-wiring.sh [--json]
  trust-gate-wiring.sh --info --json
  trust-gate-wiring.sh --schema --json
  trust-gate-wiring.sh --examples [--json]
  trust-gate-wiring.sh doctor --json
  trust-gate-wiring.sh --help|-h|--version
EOF
}

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg version "$VERSION" --arg root "$SKILLS_ROOT" \
    '{
      schema_version:$sv,
      command:"info",
      name:"trust-gate-wiring.sh",
      version:$version,
      purpose:"Fleet-wide doctor invariant: verify B4 trust-gate named skills (gate-truth-separation, agent-sandboxing, slb) are present in the skills registry. Mirror of skillos canonical (commit 62823a4) per cross-orch-anti-divergence-v1.0.0.",
      skills_root:$root,
      named_skills:["gate-truth-separation","agent-sandboxing","slb"],
      subcommands:["doctor"],
      canonical_flags:["--info","--schema","--examples","--json"],
      capabilities:["trust-gate-skill-presence-check","fleet-wide-mirror-of-skillos-b4","canonical-receipt-emission"],
      apply_supported:false,
      dry_run_supported:false,
      mutates_state:false,
      env_vars:["SKILLS_ROOT"],
      mirror_of:"skillos:mcp/skillos-mcp-server/lib/doctor_checks/trust_gate_wiring.py",
      mirror_commit:"62823a4",
      exit_codes:{"0":"all-wired","1":"missing-skill","64":"bad-args"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        skills_root:{type:"string",description:"override skills registry path (default ~/.claude/skills)"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","status","wired_count","total_count","missing_skills"],
      properties:{
        schema_version:{type:"string"},
        status:{enum:["OK","WARN","FAIL"]},
        wired_count:{type:"integer",minimum:0},
        total_count:{type:"integer",minimum:1},
        missing_skills:{type:"array",items:{type:"string"}},
        checks:{type:"array"}
      }
    },
    exit_codes:{"0":"all-wired","1":"missing-skill","64":"bad-args"}
  }'
}

emit_examples() {
  if [[ "${1:-}" == "--json" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" '{
      schema_version:$sv,
      command:"examples",
      examples:[
        {name:"default-probe",invocation:"trust-gate-wiring.sh --json",purpose:"check all 3 named skills present in default skills root"},
        {name:"doctor-positional",invocation:"trust-gate-wiring.sh doctor --json",purpose:"canonical doctor envelope (same body as default)"},
        {name:"custom-skills-root",invocation:"SKILLS_ROOT=/tmp/fixture-skills trust-gate-wiring.sh --json",purpose:"override skills root (for tests)"}
      ]
    }'
  else
    cat <<'EOF'
examples:
  trust-gate-wiring.sh --json
  trust-gate-wiring.sh doctor --json
  SKILLS_ROOT=/tmp/fixture-skills trust-gate-wiring.sh --json
EOF
  fi
}

emit_doctor() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local missing=()
  local checks_jsonl=""
  local skill
  for skill in "${NAMED_SKILLS[@]}"; do
    local path="$SKILLS_ROOT/$skill"
    local skill_status="pass"
    if [[ ! -d "$path" ]]; then
      skill_status="fail"
      missing+=("$skill")
    fi
    local row
    row="$(jq -nc --arg name "$skill" --arg status "$skill_status" --arg path "$path" \
      '{name:$name,status:$status,path:$path,detail:"named skill required for B4 trust-gate wiring"}')"
    checks_jsonl="${checks_jsonl}${row}"$'\n'
  done
  local total=${#NAMED_SKILLS[@]}
  local wired=$((total - ${#missing[@]}))
  local overall="OK"
  if [[ "$wired" -eq 0 ]]; then
    overall="FAIL"
  elif [[ "$wired" -lt "$total" ]]; then
    overall="WARN"
  fi
  local missing_json='[]'
  if [[ ${#missing[@]} -gt 0 ]]; then
    missing_json="$(printf '%s\n' "${missing[@]}" | jq -R . | jq -sc .)"
  fi
  local checks_array
  checks_array="$(printf '%s' "$checks_jsonl" | jq -sc '.')"
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --argjson wired "$wired" --argjson total "$total" \
    --argjson missing "$missing_json" --argjson checks "$checks_array" \
    --arg root "$SKILLS_ROOT" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      wired_count:$wired,
      total_count:$total,
      missing_skills:$missing,
      skills_root:$root,
      checks:$checks
    }'
}

case "${1:-}" in
  --info) emit_info; exit 0 ;;
  --schema) emit_schema; exit 0 ;;
  --examples) shift; emit_examples "${1:-}"; exit 0 ;;
  --help|-h) usage; exit 0 ;;
  --version) printf '%s\n' "$VERSION"; exit 0 ;;
  doctor) shift; emit_doctor
    if jq -e '.status == "OK"' <<<"$(emit_doctor 2>/dev/null)" >/dev/null 2>&1; then exit 0; else exit 1; fi
    ;;
  --json|"")
    payload="$(emit_doctor)"
    printf '%s\n' "$payload"
    jq -e '.status == "OK"' <<<"$payload" >/dev/null && exit 0 || exit 1
    ;;
  *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
esac
