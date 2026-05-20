#!/usr/bin/env bash
set -euo pipefail

VERSION="bv-readiness-probe.v1"
REPO="$PWD"
JSON_OUT=0
BV_BIN="${BV_BIN:-/opt/homebrew/bin/bv}"
BR_BIN="${BR_BIN:-/Users/josh/.cargo/bin/br}"
INSIGHTS_FIXTURE=""
PLAN_FIXTURE=""
READY_FIXTURE=""
COMMAND="probe"

usage() {
  cat <<'EOF'
usage: bv-readiness-probe.sh [probe|validate|doctor|health|repair|audit|why|quickstart|help|completion] [--repo PATH] [--json]
       bv-readiness-probe.sh --schema|--info|--examples|--help

Reports ready Beads work without depending on one bv JSON field name.

Readiness source order:
  1. bv --robot-insights .ready_beads when present in future bv versions
  2. bv --robot-plan .plan.tracks[].items for bv 0.13.0
  3. br ready --json as the stable fallback

Fixture flags:
  --robot-insights-fixture FILE
  --robot-plan-fixture FILE
  --br-ready-fixture FILE

repair is read-only and supports repair --dry-run --json. It reports no planned
or actual actions because this probe has no mutation surface.
EOF
}

json_bool() {
  case "$1" in
    1|true|TRUE|yes|YES) printf 'true' ;;
    *) printf 'false' ;;
  esac
}

schema() {
  jq -nc '{
    schema_version:"bv-readiness-probe.schema/v1",
    required:["schema_version","status","ready_count","source"],
    properties:{
      schema_version:{const:"bv-readiness-probe/v1"},
      status:{enum:["pass","fail"]},
      ready_count:{type:"integer",minimum:0},
      source:{enum:["bv_robot_insights.ready_beads","bv_robot_plan.items","br_ready","none"]},
      selected_id:{type:["string","null"]},
      checked_sources:{type:"array"}
    },
    exit_codes:{"0":"probe succeeded","1":"probe failed","2":"usage error"}
  }'
}

info() {
  jq -nc \
    --arg version "$VERSION" \
    --arg bv "$BV_BIN" \
    --arg br "$BR_BIN" \
    --arg repo "$REPO" \
    '{schema_version:"bv-readiness-probe.info/v1",version:$version,repo:$repo,bv_bin:$bv,br_bin:$br}'
}

examples() {
  cat <<'EOF'
{
  "schema_version": "bv-readiness-probe.examples/v1",
  "examples": [
    "bv-readiness-probe.sh --json",
    "bv-readiness-probe.sh --repo /Users/josh/Developer/flywheel --json",
    "bv-readiness-probe.sh --robot-insights-fixture fixtures/insights.json --br-ready-fixture fixtures/ready.json --json",
    "bv-readiness-probe.sh doctor --json",
    "bv-readiness-probe.sh repair --dry-run --json"
  ]
}
EOF
}

quickstart() {
  cat <<'EOF'
1. Run: .flywheel/scripts/bv-readiness-probe.sh --json
2. Read ready_count and source.
3. Use source to debug bv/br drift without assuming .ready_beads exists.
4. In dispatch validators, consume ready_count instead of raw bv fields.
EOF
}

topic_help() {
  local topic="${1:-overview}"
  case "$topic" in
    exit-codes)
      cat <<'EOF'
exit codes:
  0  probe succeeded or read-only repair dry-run completed
  1  probe failed because no readiness source was usable
  2  usage error or unsupported completion shell
EOF
      ;;
    sources|overview)
      cat <<'EOF'
sources:
  bv_robot_insights.ready_beads  future direct readiness field
  bv_robot_plan.items            bv 0.13.0 compatible fallback
  br_ready                       stable Beads CLI fallback
EOF
      ;;
    *)
      printf 'unknown help topic: %s\n' "$topic" >&2
      return 2
      ;;
  esac
}

completion() {
  local shell="${1:-bash}"
  case "$shell" in
    bash|zsh)
      cat <<'EOF'
complete -W "probe validate doctor health repair audit why quickstart help completion exit-codes sources --json --repo --schema --info --examples --help" bv-readiness-probe.sh
EOF
      ;;
    *)
      printf 'completion unavailable for %s\n' "$shell" >&2
      return 2
      ;;
  esac
}

load_json() {
  local fixture="$1" command_name="$2"
  if [ -n "$fixture" ]; then
    cat "$fixture"
  else
    case "$command_name" in
      insights) (cd "$REPO" && "$BV_BIN" --robot-insights) ;;
      plan) (cd "$REPO" && "$BV_BIN" --robot-plan) ;;
      ready) (cd "$REPO" && "$BR_BIN" ready --json) ;;
    esac
  fi
}

probe() {
  local tmp insights_status=skip plan_status=skip ready_status=skip
  tmp="$(mktemp -d -t bv-ready.XXXXXX)"
  trap 'rm -rf "$tmp"' RETURN

  if [ -n "$INSIGHTS_FIXTURE" ] || command -v "$BV_BIN" >/dev/null 2>&1; then
    if load_json "$INSIGHTS_FIXTURE" insights >"$tmp/insights.json" 2>"$tmp/insights.err"; then
      insights_status=ok
      if jq -e 'has("ready_beads")' "$tmp/insights.json" >/dev/null 2>&1; then
        jq -nc \
          --argjson ready_count "$(jq 'if (.ready_beads | type) == "array" then (.ready_beads | length) elif (.ready_beads | type) == "number" then .ready_beads else 0 end' "$tmp/insights.json")" \
          --arg selected_id "$(jq -r 'if (.ready_beads | type) == "array" then (.ready_beads[0].id // .ready_beads[0].bead_id // "") else "" end' "$tmp/insights.json")" \
          --argjson checked_sources "$(jq -nc --arg s "$insights_status" '[{source:"bv_robot_insights",status:$s}]')" \
          '{schema_version:"bv-readiness-probe/v1",status:"pass",ready_count:$ready_count,source:"bv_robot_insights.ready_beads",selected_id:($selected_id | select(. != "") // null),checked_sources:$checked_sources}'
        return 0
      fi
    else
      insights_status=fail
    fi
  fi

  if [ -n "$PLAN_FIXTURE" ] || command -v "$BV_BIN" >/dev/null 2>&1; then
    if load_json "$PLAN_FIXTURE" plan >"$tmp/plan.json" 2>"$tmp/plan.err"; then
      plan_status=ok
      if jq -e '(.plan.tracks // []) | length > 0' "$tmp/plan.json" >/dev/null 2>&1; then
        jq -nc \
          --argjson ready_count "$(jq '[.plan.tracks[]?.items[]?] | length' "$tmp/plan.json")" \
          --arg selected_id "$(jq -r '.plan.tracks[]?.items[]?.id // empty' "$tmp/plan.json" | head -1)" \
          --arg insights_status "$insights_status" \
          --arg plan_status "$plan_status" \
          '{schema_version:"bv-readiness-probe/v1",status:"pass",ready_count:$ready_count,source:"bv_robot_plan.items",selected_id:($selected_id | select(. != "") // null),checked_sources:[{source:"bv_robot_insights",status:$insights_status},{source:"bv_robot_plan",status:$plan_status}]}'
        return 0
      fi
    else
      plan_status=fail
    fi
  fi

  if [ -n "$READY_FIXTURE" ] || command -v "$BR_BIN" >/dev/null 2>&1; then
    if load_json "$READY_FIXTURE" ready >"$tmp/ready.json" 2>"$tmp/ready.err"; then
      ready_status=ok
      jq -nc \
        --argjson ready_count "$(jq 'if type == "array" then length elif has("issues") then (.issues | length) elif has("ready") then (.ready | length) else 0 end' "$tmp/ready.json")" \
        --arg selected_id "$(jq -r 'if type == "array" then (.[0].id // "") elif has("issues") then (.issues[0].id // "") elif has("ready") then (.ready[0].id // "") else "" end' "$tmp/ready.json")" \
        --arg insights_status "$insights_status" \
        --arg plan_status "$plan_status" \
        --arg ready_status "$ready_status" \
        '{schema_version:"bv-readiness-probe/v1",status:"pass",ready_count:$ready_count,source:"br_ready",selected_id:($selected_id | select(. != "") // null),checked_sources:[{source:"bv_robot_insights",status:$insights_status},{source:"bv_robot_plan",status:$plan_status},{source:"br_ready",status:$ready_status}]}'
      return 0
    else
      ready_status=fail
    fi
  fi

  jq -nc \
    --arg insights_status "$insights_status" \
    --arg plan_status "$plan_status" \
    --arg ready_status "$ready_status" \
    '{schema_version:"bv-readiness-probe/v1",status:"fail",ready_count:0,source:"none",selected_id:null,checked_sources:[{source:"bv_robot_insights",status:$insights_status},{source:"bv_robot_plan",status:$plan_status},{source:"br_ready",status:$ready_status}]}'
  return 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    probe|validate|doctor|health|repair|audit|why|quickstart|help|completion)
      COMMAND="$1"
      shift
      ;;
    --repo)
      REPO="${2:?--repo requires PATH}"
      shift 2
      ;;
    --robot-insights-fixture)
      INSIGHTS_FIXTURE="${2:?--robot-insights-fixture requires FILE}"
      shift 2
      ;;
    --robot-plan-fixture)
      PLAN_FIXTURE="${2:?--robot-plan-fixture requires FILE}"
      shift 2
      ;;
    --br-ready-fixture)
      READY_FIXTURE="${2:?--br-ready-fixture requires FILE}"
      shift 2
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --dry-run|--explain)
      shift
      ;;
    --schema)
      schema
      exit 0
      ;;
    --info)
      info
      exit 0
      ;;
    --examples)
      examples
      exit 0
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --version)
      printf '%s\n' "$VERSION"
      exit 0
      ;;
    *)
      if [ "$COMMAND" = "help" ]; then
        topic_help "$1"
        exit $?
      fi
      if [ "$COMMAND" = "completion" ]; then
        completion "$1"
        exit $?
      fi
      printf 'ERR: unknown arg: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$COMMAND" in
  probe|validate)
    probe
    ;;
  doctor|health)
    out="$(probe || true)"
    status="$(jq -r '.status' <<<"$out")"
    jq -nc --argjson probe "$out" --arg status "$status" '{schema_version:"bv-readiness-probe.health/v1",status:(if $status == "pass" then "pass" else "fail" end),checks:[{name:"readiness_probe",status:$status}],probe:$probe}'
    [ "$status" = "pass" ]
    ;;
  repair)
    jq -nc '{schema_version:"bv-readiness-probe.repair/v1",status:"pass",dry_run:true,planned_actions:[],actual_actions:[],reason:"read-only probe; no repair actions available"}'
    ;;
  audit)
    jq -nc --arg version "$VERSION" '{schema_version:"bv-readiness-probe.audit/v1",status:"pass",version:$version,mutations:[]}'
    ;;
  why)
    jq -nc '{schema_version:"bv-readiness-probe.why/v1",status:"pass",reason:"bv 0.13.0 does not expose .ready_beads; this probe normalizes bv and br readiness shapes into ready_count/source."}'
    ;;
  quickstart)
    quickstart
    ;;
  help)
    topic_help overview
    ;;
  completion)
    completion bash
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
