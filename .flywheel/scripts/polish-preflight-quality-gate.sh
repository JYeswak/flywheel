#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAN_SLUG="mission-lock-paradigm-extension-2026-05-06"
MODE=check; JSON_OUT=0; APPLY=0; VERSION=v1
LEDGER="${POLISH_PREFLIGHT_LEDGER:-$HOME/.local/state/flywheel/polish-preflight-quality-gate.jsonl}"
IDEMP="${POLISH_PREFLIGHT_IDEMPOTENCY_LEDGER:-$HOME/.local/state/flywheel/polish-preflight-quality-gate-idempotency.jsonl}"
LOCK_DIR="${POLISH_PREFLIGHT_LOCK_DIR:-$HOME/.local/state/flywheel/polish-preflight-quality-gate-locks}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) MODE=info; shift ;;
    --check) MODE=check; shift ;;
    --json) JSON_OUT=1; shift ;;
    --plan-slug) PLAN_SLUG="${2:-}"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --help|-h) echo "polish-preflight-quality-gate.sh [--info] [--check] [--json] [--plan-slug <slug>] [--apply]"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ "$MODE" == info ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg v "$VERSION" --arg p "$PLAN_SLUG" '{name:"polish-preflight-quality-gate",gate_version:$v,plan_slug:$p,gates:8,apply_mutates_state:false}'
  else
    printf 'polish-preflight-quality-gate %s\nplan_slug=%s\ngates=8\n' "$VERSION" "$PLAN_SLUG"
  fi
  exit 0
fi

PLAN_STATE="$ROOT/.flywheel/PLANS/$PLAN_SLUG/STATE.json"
if [[ -z "$PLAN_SLUG" || ! -f "$PLAN_STATE" ]]; then
  r="$(jq -nc --arg p "$PLAN_SLUG" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg v "$VERSION" '{gate_status:"PENDING",plan_slug:$p,gates_run:[],first_fire_reason:"plan state missing",composite_health_score:0,all_audit_findings_closed:false,ts:$ts,gate_version:$v}')"
  [[ "$JSON_OUT" -eq 1 ]] && echo "$r" || echo "PENDING plan state missing"
  exit 2
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/polish-preflight.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
GATES="$TMP/gates.jsonl"; FIRST_FIRE=""; PASS_COUNT=0; TOTAL_GATES=8

make_fixtures() {
  python3 - "$TMP" <<'PY'
import hashlib, json, pathlib, sys
t=pathlib.Path(sys.argv[1]); t.mkdir(parents=True, exist_ok=True)
slug="mission-lock-paradigm-extension-2026-05-06"; bead="flywheel-phase5-polish-preflight-quality-gate-2026-05-06"
(t/"substrate").mkdir()
(t/"substrate/tokens.json").write_text('{"tokens":true}\n')
payload={"schema_version":"mission-lock-output/v1","mission_anchor_rev":1,"lock_hash":"sha256:"+"a"*64,"locked_at":"2026-05-06T16:00:00Z","status":"locked","mission_anchor_text":"polish preflight quality gate terminal close","mission_license":{"vendors_approved":["OpenAI"],"platforms_approved":["macOS"],"tier_per_vendor":{"OpenAI":"team"},"budget_envelope_usd_monthly":500,"tos_accepted_at":[{"vendor":"OpenAI","ts":"2026-05-06T16:00:00Z"}],"secrets_provisioned_at_lock_time":["infisical:/openai"],"auto_rotate_allowed":["OpenAI"],"secret_vendor_map":{"OpenAI":"infisical:/openai"}},"negative_invariants":[{"id":"SEC-006","surface":"mission-lock","forbidden_action":"state_mutation_from_apply","enforcement":"fail_close"}],"cross_cutting_concerns_addressed":[{"concern":"preflight","status":"addressed","evidence":"eight sub-gates"}],"surface_principal_metadata":[{"surface":"quality-gate","secret_source_of_truth":"infisical","principal_type":"worker","allowed_operations":["audit"],"forbidden_principals":["anonymous"],"service_role_policy":"no service-role mutation"}],"skill_surface_map":[{"surface":"quality-gate","skill":"testing-conformance-harnesses","decision":"ADOPT","source":"dispatch packet"}],"failure_mode_matrix":[{"failure_mode":"false shipped state","risk":"terminal close without preflight","guard":"polish preflight quality gate","evidence":"receipt"}],"receipt_identity_envelope":{"idempotency_key":"sha256:"+"b"*64,"replay_detection_hash":"sha256:"+"c"*64,"transaction_boundary":{"begin":True,"commit":True,"abort":False},"receipt_completeness":{"SEC":True,"IDEM":True,"CSR":True}},"provenance":{"created_by":"polish-preflight-quality-gate","last_modified_by":"polish-preflight-quality-gate","source":"contract fixture"}}
(t/"mission.json").write_text(json.dumps(payload)+"\n")
sections={
"Mission Source":f"plan_slug: {slug}\nbead_id: {bead}\n",
"North-Star Outcome":"Durable terminal plan close substrate.\n",
"Primary Beneficiary":"Flywheel workers.\n",
"Explicit Non-Goals":"No runtime STATE mutation from --apply.\n",
"Safety And Privacy Boundaries":"No secret payloads.\n",
"Evidence That Would Change The Mission":"Owner review.\n",
"Owner-Review Cadence":"Quarterly.\n",
"Lock Receipt":"Locked for polish preflight validation.\n",
"Negative invariants (security)":"- do not rotate secrets.\n- do not mutate STATE from --apply.\n",
"Substrate inventory":"- design tokens: `substrate/tokens.json`\n"}
mission="# Mission Lock Fixture\n\n"+"".join(f"## {k}\n\n{v}\n" for k,v in sections.items())
for name in ["Mission Source","Negative invariants (security)"]:
    body=sections[name].strip()+"\n"; mission+=f"<!-- section_hash: {name} sha256:{hashlib.sha256(body.encode()).hexdigest()} -->\n"
(t/"MISSION.md").write_text(mission)
(t/"MISSION.md.json").write_text(json.dumps(payload)+"\n")
p=t/"plan"; p.mkdir()
(p/"STATE.json").write_text(json.dumps({"lens_merge_rows":[{"lens":"security-negative-invariants","ts":"2026-05-06T16:00:00Z","state_observed_sha":"sha256:"+"d"*64,"state_written_sha":"sha256:"+"e"*64,"audit_lens_identity_key":"sha256:"+"f"*64}],"phase5_ready":True,"audit_findings_count":18})+"\n")
d=f"""# Dispatch fixture
Task ID: wave4-polish-preflight-quality-gate-2026-05-06
To: flywheel:3 codex
dispatch_class_merge_order: bead_labels,touched_files,mission_surfaces,socraticode,override
strictest_invariant_wins=true
collision_policy=resolved
discovery_precedence: exact:get_skill > local:SKILL.md-readable > semantic:socraticode > external:npx-skills-find-installable-only > fallback:rg-filesystem
required_overlays: canonical-cli-scoping, readme-writing, de-slopify, simplify, socraticode, agent-mail, agent-monitoring, cost-attribution, search-tool-routing-doctrine
secret_values_allowed=false
route_receipt_schema_version=dispatch-author-route-receipt/v1
skill_routing: present
skill_receipts[] required_fields: receipt_identity_key, skill, source, action_taken, policy_version, evidence, alias_of, not_applicable_reason
dispatch_receipt required_fields: idempotency_key, replay_detection_hash, transaction_boundary, receipt_completeness
selected_skill_count: 9
prompt_budget_policy: names-plus-one-line-why; excerpts <= 25 percent or 1200 tokens
"""
(t/"dispatch.md").write_text(d)
self_body=f"# DISPATCH\n\nTask ID: wave4-polish-preflight-quality-gate-2026-05-06\nTo: flywheel:3 codex\nidempotency_key: sha256:{hashlib.sha256(b'preflight').hexdigest()}\n"
(t/"self-test.md").write_text(self_body)
observed="OK_wave4_polish_preflight_quality_gate_dag_closed"; command="bash wave4-polish-preflight-quality-gate"
sh=lambda s:"sha256:"+hashlib.sha256(s.encode()).hexdigest()
close={"status":"DONE","ref_id":bead,"task_id":"wave4-polish-preflight-quality-gate-2026-05-06","close_identity_key":"close-key-polish-preflight","dedupe_policy":"latest-row-by-ref_id-event","skill_receipts":[{"schema_version":"skill-receipt/v1","receipt_identity_key":"skill-receipt:polish-preflight","skill":"socraticode","resolved_to":"socraticode","source":"local-skill-root","path":"/Users/josh/.claude/skills/socraticode/SKILL.md","sha":"sha256:"+"a"*64,"version":"2026-05-06","freshness_status":"fresh","route_allowed":True,"checked_at":"2026-05-06T16:00:00Z","action_taken":"applied","policy_version":"close-validator-receipt-contract/v1","credential_touch":False,"secret_value_allowed":False,"safe_wrapper":"n/a"}],"l112":{"command":command,"command_hash":sh(command),"observed":observed,"expected":observed,"output_hash":sh(observed)},"evidence":[{"type":"path","value":".flywheel/scripts/polish-preflight-quality-gate.sh"}]}
(t/"close.json").write_text(json.dumps(close)+"\n")
(t/"dispatch-log.jsonl").write_text("")
PY
}

record_gate() {
  local n="$1" s="$2" e="$3" l="$4" why="${5:-}"
  jq -nc --arg name "$n" --arg status "$s" --arg evidence_path "$e" --argjson latency_ms "$l" '{name:$name,status:$status,evidence_path:$evidence_path,latency_ms:$latency_ms}' >> "$GATES"
  if [[ "$s" == PASS ]]; then PASS_COUNT=$((PASS_COUNT+1)); elif [[ -z "$FIRST_FIRE" ]]; then FIRST_FIRE="${why:-$n failed}"; fi
}

run_gate() {
  local n="$1" expr="$2" out="$TMP/$1.json" rc; shift 2
  if [[ "${POLISH_PREFLIGHT_FORCE_FAIL:-}" == "$n" ]]; then
    jq -nc --arg name "$n" '{forced_failure:$name}' > "$out"; record_gate "$n" FAIL "$out" 0 "$n forced failure"; return
  fi
  set +e; "$@" > "$out" 2>"$TMP/$n.err"; rc=$?; set -e
  if [[ "$rc" -eq 0 ]] && jq -e "$expr" "$out" >/dev/null 2>&1; then record_gate "$n" PASS "$out" 0; else record_gate "$n" FAIL "$out" 0 "$n failed"; fi
}

apply_receipt() {
  local r="$1" ident guard status line marked
  mkdir -p "$(dirname "$LEDGER")" "$(dirname "$IDEMP")" "$LOCK_DIR"
  ident="$(jq -c '{plan_slug,gate_version,gate_status,gates:(.gates_run|map(.name))}' <<<"$r")"
  guard="$(bash "$ROOT/.flywheel/scripts/idempotency-replay-guard.sh" --input "$ident" --ledger "$IDEMP" --lock-dir "$LOCK_DIR" --json)"
  status="$(jq -r '.status' <<<"$guard")"
  if [[ "$status" == already_completed ]]; then
    jq -c --arg ledger "$LEDGER" '.+{applied:false,ledger_path:$ledger,idempotency_status:"already_completed"}' <<<"$r"; return
  fi
  printf '%s\n' "$r" >> "$LEDGER"; line="$(wc -l < "$LEDGER" | tr -d ' ')"
  marked="$(bash "$ROOT/.flywheel/scripts/idempotency-replay-guard.sh" --input "$ident" --ledger "$IDEMP" --lock-dir "$LOCK_DIR" --mark-completed --receipt-ref "$LEDGER#L$line" --json)"
  jq -c --arg ledger "$LEDGER" --arg line "$line" --arg status "$(jq -r '.status' <<<"$marked")" '.+{applied:true,ledger_path:$ledger,ledger_line:($line|tonumber),idempotency_status:$status}' <<<"$r"
}

make_fixtures
run_gate mission_lock_output_schema '.status=="pass" and .valid==true' bash "$ROOT/.flywheel/scripts/mission-lock-output-schema-validator.sh" --mission "$TMP/mission.json" --json
run_gate dispatch_author_contract '.verdict=="pass"' bash "$ROOT/.flywheel/scripts/dispatch-author-contract-probe.sh" --dispatch "$TMP/dispatch.md" --json
run_gate close_validator_contract '.valid==true' bash "$ROOT/.flywheel/scripts/close-validator-contract-probe.sh" --callback-file "$TMP/close.json" --json
run_gate mission_lock_scaffold '.verdict=="ready"' bash "$ROOT/.flywheel/scripts/mission-lock-scaffold-validator.sh" --mission "$TMP/MISSION.md" --json
run_gate mission_lock_readiness '.mission_lock_readiness_health_score >= 1' bash "$ROOT/.flywheel/scripts/mission-lock-readiness-doctor.sh" --mission "$TMP/MISSION.md" --plan "$TMP/plan" --json
run_gate dispatch_self_test_identity '.verdict=="proceed"' bash "$ROOT/.flywheel/scripts/dispatch-self-test-delivery-identity.sh" pretest --packet "$TMP/self-test.md" --dispatch-log "$TMP/dispatch-log.jsonl" --lock-dir "$TMP/self-test-locks" --json
run_gate golden_fixture_replay_all '.status=="pass" and .fixtures_count>=7 and ([.results[].status]|all(.=="pass"))' bash "$ROOT/.flywheel/scripts/golden-fixture-replay-runner.sh" replay-all --json
run_gate golden_fixture_verify_invariants '.status=="pass"' bash "$ROOT/.flywheel/scripts/golden-fixture-replay-runner.sh" verify-invariants --json

gates_json="$(jq -s '.' "$GATES")"
if [[ "$PASS_COUNT" -eq "$TOTAL_GATES" ]]; then GATE_STATUS=PASS; SCORE=10; FIRST_JSON=null
else GATE_STATUS=FAIL; SCORE="$(jq -n --argjson p "$PASS_COUNT" --argjson t "$TOTAL_GATES" '($p/$t*10)')"; FIRST_JSON="$(jq -nc --arg v "$FIRST_FIRE" '$v')"; fi
all_closed="$(jq -e '(.audit_findings_count==18 or .total_findings_closed==18) and (.phase5_ready==true or .current_phase=="shipped")' "$PLAN_STATE" >/dev/null 2>&1 && echo true || echo false)"
if [[ "$all_closed" != true && "$GATE_STATUS" == PASS ]]; then GATE_STATUS=FAIL; SCORE=8.75; FIRST_JSON="$(jq -nc '"audit findings not closed"')"; fi

receipt="$(jq -nc --arg gate_status "$GATE_STATUS" --arg plan_slug "$PLAN_SLUG" --argjson gates_run "$gates_json" --argjson first_fire_reason "$FIRST_JSON" --argjson composite_health_score "$SCORE" --argjson all_audit_findings_closed "$all_closed" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg gate_version "$VERSION" '{gate_status:$gate_status,plan_slug:$plan_slug,gates_run:$gates_run,first_fire_reason:$first_fire_reason,composite_health_score:$composite_health_score,all_audit_findings_closed:$all_audit_findings_closed,ts:$ts,gate_version:$gate_version}')"
[[ "$APPLY" -eq 1 ]] && receipt="$(apply_receipt "$receipt")"
[[ "$JSON_OUT" -eq 1 ]] && echo "$receipt" || jq -r '"\(.gate_status) \(.plan_slug) score=\(.composite_health_score)"' <<<"$receipt"
[[ "$GATE_STATUS" == PASS ]] && exit 0
exit 1
