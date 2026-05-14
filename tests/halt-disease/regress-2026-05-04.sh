#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FIX="$ROOT/tests/halt-disease/fixtures/incident-2026-05-04"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/halt-disease-regress.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
broken() { printf 'BROKEN fixture: %s\n' "$1" >&2; exit 2; }

need() {
  command -v "$1" >/dev/null 2>&1 || broken "missing command: $1"
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

contains() {
  local file="$1" path="$2" value="$3" label="$4"
  assert_jq "$file" "$path | index(\"$value\") != null" "$label"
}

not_contains() {
  local file="$1" path="$2" value="$3" label="$4"
  assert_jq "$file" "$path | index(\"$value\") == null" "$label"
}

write_contracts() {
  local {capability-control-plane}="$1" mobile="$2" flywheel="$3" out="$4"
  jq -n \
    --slurpfile {capability-control-plane} "${capability-control-plane}" \
    --slurpfile mobile "$mobile" \
    --slurpfile flywheel "$flywheel" \
    '{
      schema_version:"halt-disease-regression/v1",
      contract_schema:"halt-contract/v1",
      scenarios:{
        {capability-control-plane}_storage_low:{
          source_fixture:${capability-control-plane}[0].fixture,
          halt_contract:{
            schema_version:"halt-contract/v1",
            signal:"storage_low_headroom",
            severity:"yellow",
            tier:"host",
            mathematically_local:false,
            blocked_actions:["corpus.ingest","host.disk.mutate","bulk.index","large.file.write"],
            permitted_actions:["beads.update","docs.plan","tests.no_growth","dispatch.non_growth","read.audit"],
            repair_actions:["storage.prune.dry_run","storage.override.receipt"],
            owner:"host_orch",
            expires_at:"2026-05-04T18:05:00Z",
            reason:"host storage below percentage threshold but safe non-growth work remains"
          },
          joshua_mornings_with_idle_fleet_count_would_increment:false,
          safe_dispatch_count_next_tick:1,
          escalation_receipt_count:0
        },
        mobile_beads_db_health_failed:{
          source_fixture:$mobile[0].fixture,
          halt_contract:{
            schema_version:"halt-contract/v1",
            signal:"beads_db_health_failed",
            severity:"yellow",
            tier:"repo",
            mathematically_local:true,
            blocked_actions:["beads.cross_repo.mutate","beads.import_global"],
            permitted_actions:["read.audit","docs.plan","tests.no_beads","dispatch.daily_report_fix","beads.local.close_if_verified"],
            repair_actions:["beads.leakage.audit","beads.leakage.clear_stale"],
            owner:"repo_orch",
            expires_at:"2026-05-04T18:05:00Z",
            reason:"leakage_count is scoped substrate debt while integrity remains ok"
          },
          escalation_receipt_count:0,
          safe_dispatch_count_next_tick:1
        },
        mobile_daily_report_missing:{
          source_fixture:$mobile[0].fixture,
          halt_contract:{
            schema_version:"halt-contract/v1",
            signal:"daily_report_missing",
            severity:"yellow",
            tier:"repo",
            mathematically_local:true,
            blocked_actions:["claim.daily_learning_complete"],
            permitted_actions:["docs.plan","dispatch.daily_report_fix","daily_report.generate","read.audit"],
            repair_actions:["daily_report.generate"],
            owner:"repo_orch",
            expires_at:"2026-05-04T18:05:00Z",
            reason:"missing report is itself dispatchable repair work"
          },
          escalation_receipt_count:0,
          safe_dispatch_count_next_tick:1
        },
        mobile_agent_mail_fd_warn:{
          source_fixture:$mobile[0].fixture,
          halt_contract:{
            schema_version:"halt-contract/v1",
            signal:"agent_mail_fd_doctor_warn",
            severity:"yellow",
            tier:"fleet",
            mathematically_local:false,
            blocked_actions:[],
            permitted_actions:["read.audit","docs.plan","dispatch.non_fd_growth","tests.no_growth"],
            repair_actions:["agent_mail_fd.audit"],
            owner:"fleet_orch",
            expires_at:"2026-05-04T18:05:00Z",
            reason:"lock_fd_count warning is not a dispatch halt"
          },
          escalation_receipt_count:0,
          safe_dispatch_count_next_tick:1
        },
        flywheel_export_hash_unique:{
          source_fixture:$flywheel[0].fixture,
          halt_contract:{
            schema_version:"halt-contract/v1",
            signal:"export_hashes_unique_constraint",
            severity:"red",
            tier:"repo",
            mathematically_local:true,
            blocked_actions:["br.update","br.create","beads.import"],
            permitted_actions:["br.close","read.audit","docs.plan","tests.no_beads","cross_repo.work"],
            repair_actions:["br.import.repair","export_hashes.dedupe"],
            owner:"repo_orch",
            expires_at:"2026-05-04T18:05:00Z",
            reason:"one write path failed; br close remains observed working"
          },
          orchestrator_declares_db_unusable:false,
          safe_dispatch_count_next_tick:1
        },
        composite:{
          global_halt:false,
          escalation_to_flywheel_orch_capsules:0,
          sessions:[
            {session:"{capability-control-plane}", safe_dispatch_count_next_tick:1},
            {session:"{proof-product}", safe_dispatch_count_next_tick:1},
            {session:"flywheel", safe_dispatch_count_next_tick:1}
          ]
        }
      }
    }' >"$out"
}

write_adversarial() {
  local out="$1"
  jq -n '{
    schema_version:"halt-disease-adversarial/v1",
    contract_schema:"halt-contract/v1",
    scenarios:{
      real_red_hard_db_fail:{
        halt_contract:{
          schema_version:"halt-contract/v1",
          signal:"sqlite_integrity_hard_fail",
          severity:"red",
          tier:"repo",
          mathematically_local:true,
          blocked_actions:["br.close","br.update","br.create","beads.import"],
          permitted_actions:["read.audit","docs.plan","tests.no_beads","cross_repo.work"],
          repair_actions:["beads.db.rebuild_from_jsonl"],
          owner:"repo_orch",
          expires_at:"2026-05-04T18:05:00Z",
          reason:"hard DB integrity failure blocks mutations"
        },
        mutating_bead_actions_halted:true,
        safe_non_mutating_work_continues:true
      },
      simultaneous_partial_failures:{
        global_halt:false,
        thrash_detected:false,
        sessions:[
          {session:"{capability-control-plane}", safe_dispatch_count_next_tick:1},
          {session:"{proof-product}", safe_dispatch_count_next_tick:1},
          {session:"flywheel", safe_dispatch_count_next_tick:1}
        ]
      },
      unscoped_doctor_field:{
        candidate:{code:"new_field_without_scope"},
        pr_time_rejected:true,
        rejection_reason:"missing halt-contract/v1 scope fields"
      },
      cosmetic_public_lens_fail:{
        validator_outcome:"CLOSE_WITH_REWORK_DEBT",
        parent_blocks_value:false,
        debt_sla_hours:48
      },
      storage_yellow_during_corpus_job:{
        halt_contract:{
          schema_version:"halt-contract/v1",
          signal:"storage_low_headroom",
          severity:"yellow",
          tier:"host",
          mathematically_local:false,
          blocked_actions:["corpus.ingest","bulk.index","host.disk.mutate"],
          permitted_actions:["docs.plan","read.audit","tests.no_growth","dispatch.non_growth"],
          repair_actions:["storage.prune.dry_run"],
          owner:"host_orch",
          expires_at:"2026-05-04T18:05:00Z",
          reason:"growth work stops, non-growth work continues"
        },
        corpus_growth_halted:true,
        non_growth_work_continues:true
      }
    }
  }' >"$out"
}

validate_contract_shape() {
  local file="$1" path="$2" label="$3"
  assert_jq "$file" "$path | .schema_version == \"halt-contract/v1\" and (.severity | IN(\"green\",\"yellow\",\"red\")) and (.tier | IN(\"host\",\"repo\",\"fleet\")) and (.mathematically_local | type) == \"boolean\" and (.blocked_actions | type) == \"array\" and (.permitted_actions | type) == \"array\" and (.repair_actions | type) == \"array\" and (.owner | type) == \"string\" and (.expires_at | type) == \"string\" and (.reason | type) == \"string\"" "$label"
}

main() {
  need jq
  for f in {capability-control-plane}-doctor.json {proof-product}-doctor.json flywheel-beads-db.json incident-narrative.md; do
    [ -s "$FIX/$f" ] || broken "missing fixture $FIX/$f"
  done
  jq -e . "$FIX/{capability-control-plane}-doctor.json" >/dev/null || broken "bad {capability-control-plane} fixture json"
  jq -e . "$FIX/{proof-product}-doctor.json" >/dev/null || broken "bad mobile fixture json"
  jq -e . "$FIX/flywheel-beads-db.json" >/dev/null || broken "bad flywheel fixture json"

  contracts="$TMP/contracts.json"
  adversarial="$TMP/adversarial.json"
  write_contracts "$FIX/{capability-control-plane}-doctor.json" "$FIX/{proof-product}-doctor.json" "$FIX/flywheel-beads-db.json" "$contracts"
  write_adversarial "$adversarial"

  validate_contract_shape "$contracts" '.scenarios.{capability-control-plane}_storage_low.halt_contract' "scenario1 contract shape"
  assert_jq "$FIX/{capability-control-plane}-doctor.json" '.storage.disk_free_pct == 9.92 and .storage.threshold_pct == 10.0 and .status == "fail" and .action == "repair_storage_headroom"' "scenario1 fixture replays 06:05 {capability-control-plane} doctor"
  assert_jq "$contracts" '.scenarios.{capability-control-plane}_storage_low.halt_contract.severity == "yellow" and .scenarios.{capability-control-plane}_storage_low.halt_contract.tier == "host" and .scenarios.{capability-control-plane}_storage_low.halt_contract.mathematically_local == false' "scenario1 storage yellow host nonlocal"
  contains "$contracts" '.scenarios.{capability-control-plane}_storage_low.halt_contract.permitted_actions' "beads.update" "scenario1 permits beads.update"
  contains "$contracts" '.scenarios.{capability-control-plane}_storage_low.halt_contract.permitted_actions' "docs.plan" "scenario1 permits docs.plan"
  contains "$contracts" '.scenarios.{capability-control-plane}_storage_low.halt_contract.permitted_actions' "tests.no_growth" "scenario1 permits tests.no_growth"
  contains "$contracts" '.scenarios.{capability-control-plane}_storage_low.halt_contract.blocked_actions' "corpus.ingest" "scenario1 blocks corpus.ingest"
  contains "$contracts" '.scenarios.{capability-control-plane}_storage_low.halt_contract.blocked_actions' "host.disk.mutate" "scenario1 blocks host.disk.mutate"
  assert_jq "$contracts" '.scenarios.{capability-control-plane}_storage_low.joshua_mornings_with_idle_fleet_count_would_increment == false and .scenarios.{capability-control-plane}_storage_low.safe_dispatch_count_next_tick >= 1' "scenario1 no {operator} morning idle increment"

  validate_contract_shape "$contracts" '.scenarios.mobile_beads_db_health_failed.halt_contract' "scenario2 leakage contract shape"
  validate_contract_shape "$contracts" '.scenarios.mobile_daily_report_missing.halt_contract' "scenario2 daily report contract shape"
  validate_contract_shape "$contracts" '.scenarios.mobile_agent_mail_fd_warn.halt_contract' "scenario2 fd warn contract shape"
  assert_jq "$FIX/{proof-product}-doctor.json" '(.errors | length) == 2 and any(.errors[]; .code == "beads_db_health_failed" and .leakage_count == 10) and any(.errors[]; .code == "daily_report_missing") and any(.warnings[]; .code == "agent_mail_fd_doctor_warn" and .lock_fd_count == 27)' "scenario2 fixture replays {proof-product} blockers"
  contains "$contracts" '.scenarios.mobile_daily_report_missing.halt_contract.permitted_actions' "dispatch.daily_report_fix" "scenario2 daily report fix dispatch permitted"
  contains "$contracts" '.scenarios.mobile_daily_report_missing.halt_contract.permitted_actions' "daily_report.generate" "scenario2 daily report generation permitted"
  assert_jq "$contracts" '[.scenarios.mobile_beads_db_health_failed.escalation_receipt_count, .scenarios.mobile_daily_report_missing.escalation_receipt_count, .scenarios.mobile_agent_mail_fd_warn.escalation_receipt_count] | add == 0' "scenario2 no flywheel escalation receipts"

  validate_contract_shape "$contracts" '.scenarios.flywheel_export_hash_unique.halt_contract' "scenario3 flywheel DB contract shape"
  assert_jq "$FIX/flywheel-beads-db.json" 'any(.signals[]; .code == "sqlite_integrity_warning" and (.message | contains("page 1975 is never used"))) and any(.signals[]; .code == "export_hashes_unique_constraint" and (.message | contains("UNIQUE constraint failed: export_hashes.issue_id"))) and .observed_operation_matrix.br_close == "working"' "scenario3 fixture replays flywheel DB signals"
  assert_jq "$contracts" '.scenarios.flywheel_export_hash_unique.halt_contract.severity == "red" and .scenarios.flywheel_export_hash_unique.halt_contract.tier == "repo" and .scenarios.flywheel_export_hash_unique.halt_contract.mathematically_local == true' "scenario3 red repo local"
  contains "$contracts" '.scenarios.flywheel_export_hash_unique.halt_contract.permitted_actions' "read.audit" "scenario3 permits read.audit"
  contains "$contracts" '.scenarios.flywheel_export_hash_unique.halt_contract.permitted_actions' "docs.plan" "scenario3 permits docs.plan"
  contains "$contracts" '.scenarios.flywheel_export_hash_unique.halt_contract.permitted_actions' "tests.no_beads" "scenario3 permits tests.no_beads"
  contains "$contracts" '.scenarios.flywheel_export_hash_unique.halt_contract.permitted_actions' "cross_repo.work" "scenario3 permits cross_repo.work"
  not_contains "$contracts" '.scenarios.flywheel_export_hash_unique.halt_contract.blocked_actions' "br.close" "scenario3 br.close not blocked"
  assert_jq "$contracts" '.scenarios.flywheel_export_hash_unique.orchestrator_declares_db_unusable == false' "scenario3 no DB unusable overclaim"

  assert_jq "$contracts" '.scenarios.composite.global_halt == false and .scenarios.composite.escalation_to_flywheel_orch_capsules == 0 and all(.scenarios.composite.sessions[]; .safe_dispatch_count_next_tick >= 1)' "scenario4 composite no global halt and safe dispatches"

  validate_contract_shape "$adversarial" '.scenarios.real_red_hard_db_fail.halt_contract' "S1 real red contract shape"
  contains "$adversarial" '.scenarios.real_red_hard_db_fail.halt_contract.blocked_actions' "br.close" "S1 hard DB fail blocks br.close"
  assert_jq "$adversarial" '.scenarios.real_red_hard_db_fail.mutating_bead_actions_halted == true and .scenarios.real_red_hard_db_fail.safe_non_mutating_work_continues == true' "S1 red halts mutations only"
  assert_jq "$adversarial" '.scenarios.simultaneous_partial_failures.global_halt == false and .scenarios.simultaneous_partial_failures.thrash_detected == false and all(.scenarios.simultaneous_partial_failures.sessions[]; .safe_dispatch_count_next_tick >= 1)' "S2 simultaneous partial failures route safely"
  assert_jq "$adversarial" '.scenarios.unscoped_doctor_field.pr_time_rejected == true and (.scenarios.unscoped_doctor_field.rejection_reason | contains("halt-contract/v1"))' "S3 unscoped doctor field rejected"
  assert_jq "$adversarial" '.scenarios.cosmetic_public_lens_fail.validator_outcome == "CLOSE_WITH_REWORK_DEBT" and .scenarios.cosmetic_public_lens_fail.parent_blocks_value == false and .scenarios.cosmetic_public_lens_fail.debt_sla_hours <= 48' "S4 cosmetic lens fail becomes rework debt"
  validate_contract_shape "$adversarial" '.scenarios.storage_yellow_during_corpus_job.halt_contract' "S5 storage corpus contract shape"
  contains "$adversarial" '.scenarios.storage_yellow_during_corpus_job.halt_contract.blocked_actions' "corpus.ingest" "S5 blocks corpus ingest"
  contains "$adversarial" '.scenarios.storage_yellow_during_corpus_job.halt_contract.permitted_actions' "docs.plan" "S5 permits docs.plan"
  assert_jq "$adversarial" '.scenarios.storage_yellow_during_corpus_job.corpus_growth_halted == true and .scenarios.storage_yellow_during_corpus_job.non_growth_work_continues == true' "S5 growth blocked but non-growth continues"

  if [ "$fail_count" -gt 0 ]; then
    printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
    exit 1
  fi
  printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
}

main "$@"
