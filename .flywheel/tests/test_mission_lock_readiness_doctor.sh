#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mission-lock-readiness-doctor.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-lock-readiness-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

section_hash() {
  python3 - "$1" "$2" <<'PY'
import hashlib, re, sys
path, title = sys.argv[1], sys.argv[2]
lines = open(path, encoding="utf-8").read().splitlines()
body, current = [], None
for line in lines:
    m = re.match(r"^##\s+(.+?)\s*$", line)
    if m:
        current = m.group(1).strip()
        continue
    if current and current.lower() == title.lower():
        if not re.search(r"<!--\s*section[_-]hash:", line, re.I):
            body.append(line.rstrip())
while body and body[0] == "":
    body.pop(0)
while body and body[-1] == "":
    body.pop()
print(hashlib.sha256(("\n".join(body) + "\n").encode()).hexdigest())
PY
}

append_hash() {
  local file="$1" title="$2" hash
  hash="$(section_hash "$file" "$title")"
  printf '<!-- section_hash: %s sha256:%s -->\n' "$title" "$hash" >>"$file"
}

base_payload() {
  jq -nc '{
    schema_version:"mission-lock-output/v1",
    mission_anchor_rev:1,
    lock_hash:"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    locked_at:"2026-05-06T16:00:00Z",
    status:"locked",
    mission_anchor_text:"self-sustaining-company-architecture-health",
    mission_license:{
      vendors_approved:["OpenAI"], platforms_approved:["macOS"], tier_per_vendor:{OpenAI:"team"},
      budget_envelope_usd_monthly:500,
      tos_accepted_at:[{vendor:"OpenAI",ts:"2026-05-06T16:00:00Z"}],
      secrets_provisioned_at_lock_time:["infisical:/openai"],
      auto_rotate_allowed:["OpenAI"], secret_vendor_map:{OpenAI:"infisical:/openai"}
    },
    negative_invariants:[{id:"SEC-006",surface:"mission-lock",forbidden_action:"readiness_without_schema",enforcement:"fail_close"}],
    cross_cutting_concerns_addressed:[{concern:"readiness-doctor",status:"addressed",evidence:"golden fixture"}],
    surface_principal_metadata:[{surface:"doctor",secret_source_of_truth:"infisical",principal_type:"worker",allowed_operations:["audit"],forbidden_principals:["anonymous"],service_role_policy:"no service-role mutation"}],
    skill_surface_map:[{surface:"doctor",skill:"flywheel-doctor-author",decision:"ADOPT",source:"dispatch packet"}],
    failure_mode_matrix:[{failure_mode:"false readiness",risk:"doctor omits blocked surface",guard:"golden negative fixture",evidence:"test"}],
    receipt_identity_envelope:{
      idempotency_key:"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      replay_detection_hash:"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      transaction_boundary:{begin:true,commit:true,abort:false},
      receipt_completeness:{SEC:true,IDEM:true,CSR:true}
    },
    provenance:{created_by:"test",last_modified_by:"test",source:"golden fixture"}
  }'
}

write_mission() {
  local path="$1" mode="$2" dir payload
  dir="$(dirname "$path")"
  mkdir -p "$dir/substrate"
  printf '{"tokens":true}\n' >"$dir/substrate/tokens.json"
  {
    printf '# Fixture Mission\n\n'
    printf 'schema_version: 1\nstatus: locked\nlock_hash: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n\n'
    printf '## Mission Source\n\nFixture mission source.\n\n'
    printf '## North-Star Outcome\n\nDurable mission lock substrate.\n\n'
    printf '## Primary Beneficiary\n\nFlywheel workers.\n\n'
    printf '## Explicit Non-Goals\n\nNo runtime mutation.\n\n'
    printf '## Safety And Privacy Boundaries\n\nNo secret payloads.\n\n'
    printf '## Evidence That Would Change The Mission\n\nOwner review.\n\n'
    printf '## Owner-Review Cadence\n\nQuarterly.\n\n'
    printf '## Lock Receipt\n\nLocked for readiness validation.\n'
    [[ "$mode" == *blocked* ]] && printf 'blocked_readiness: blocked_phase0_missing\n'
    printf '\n## Negative invariants (security)\n\n'
    printf -- '- SEC-006: readiness requires output schema, scaffold, and lens merge evidence.\n\n'
    printf '## Substrate inventory\n\n'
    if [[ "$mode" == *bad_scaffold* ]]; then
      printf -- '- design tokens: `substrate/missing.json`\n'
    else
      printf -- '- design tokens: `substrate/tokens.json`\n'
    fi
    printf '\n'
  } >"$path"
  append_hash "$path" "Mission Source"
  append_hash "$path" "Negative invariants (security)"
  payload="$(base_payload)"
  [[ "$mode" == *bad_schema* ]] && payload="$(jq -c 'del(.mission_anchor_rev)' <<<"$payload")"
  printf '%s\n' "$payload" >"$path.json"
}

write_plan() {
  local dir="$1" mode="$2"
  mkdir -p "$dir"
  if [[ "$mode" == "bad_lens" ]]; then
    printf '{"lens_merge_rows":[{"lens":"security-negative-invariants"}]}\n' >"$dir/STATE.json"
  else
    printf '%s\n' '{"lens_merge_rows":[{"lens":"security-negative-invariants","ts":"2026-05-06T16:00:00Z","state_observed_sha":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","state_written_sha":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","audit_lens_identity_key":"sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"}]}' >"$dir/STATE.json"
  fi
}

run_doctor() {
  local out="$1" mission="$2" plan="$3" rc
  set +e
  "$SCRIPT" --mission "$mission" --plan "$plan" --json >"$out"
  rc=$?
  set -e
  printf '%s\n' "$rc"
}

normalize() {
  jq -c '{schema_validator_verdict,scaffold_validator_verdict,lens_merge_consistent,score:((.mission_lock_readiness_health_score * 100 | round) / 100),blocked_surfaces,suggestion_slugs:(.phase0_scaffold_bead_suggestions | map(.slug) | sort),repair_key_valid:(.repair_receipt_identity_fields.repair_idempotency_key | test("^sha256:[0-9a-f]{64}$"))}' "$1"
}

golden_case() {
  local name="$1" mission_mode="$2" lens_mode="$3" expect_rc="$4" expect_json="$5"
  local base mission plan out rc actual
  base="$TMP/${name// /_}"
  mission="$base/MISSION.md"
  plan="$base/plan"
  out="$base/out.json"
  mkdir -p "$base"
  write_mission "$mission" "$mission_mode"
  write_plan "$plan" "$lens_mode"
  rc="$(run_doctor "$out" "$mission" "$plan")"
  actual="$(normalize "$out")"
  if [[ "$rc" == "$expect_rc" && "$actual" == "$(jq -c . <<<"$expect_json")" ]]; then
    pass "$name golden"
  else
    fail "$name golden"
    printf 'rc=%s actual=%s expected=%s\n' "$rc" "$actual" "$(jq -c . <<<"$expect_json")" >&2
    cat "$out" >&2 || true
  fi
}

bash -n "$SCRIPT"
"$SCRIPT" --help | rg -q '^usage:'
"$SCRIPT" --info | jq -e '.mutates == false and (.canonical_cli_verbs | length == 5) and (.doctor_fields | index("mission_lock_readiness_health_score"))' >/dev/null
"$SCRIPT" --examples --json | jq -e '.examples | length >= 3' >/dev/null
"$SCRIPT" schema --json | jq -e '.consumer == "flywheel-loop doctor field set"' >/dev/null
pass "canonical CLI metadata"

golden_case "healthy mission" valid valid 0 '{"schema_validator_verdict":"pass","scaffold_validator_verdict":"ready","lens_merge_consistent":true,"score":1,"blocked_surfaces":[],"suggestion_slugs":[],"repair_key_valid":true}'
golden_case "schema failure suggests repair" bad_schema valid 1 '{"schema_validator_verdict":"fail","scaffold_validator_verdict":"ready","lens_merge_consistent":true,"score":0.45,"blocked_surfaces":["mission-lock-output-schema"],"suggestion_slugs":["mission-lock-output-schema"],"repair_key_valid":true}'
golden_case "scaffold failure suggests repair" bad_scaffold_blocked valid 1 '{"schema_validator_verdict":"pass","scaffold_validator_verdict":"blocked","lens_merge_consistent":true,"score":0.65,"blocked_surfaces":["blocked-readiness:blocked_phase0_missing","mission-lock-scaffold","mission-lock-scaffold:blocked_readiness:blocked_phase0_missing","mission-lock-scaffold:substrate_inventory_unresolved:substrate/missing.json"],"suggestion_slugs":["mission-lock-scaffold"],"repair_key_valid":true}'
golden_case "lens failure suggests repair" valid bad_lens 1 '{"schema_validator_verdict":"pass","scaffold_validator_verdict":"ready","lens_merge_consistent":false,"score":0.55,"blocked_surfaces":["plan-state-lens-merge"],"suggestion_slugs":["plan-state-lens-merge"],"repair_key_valid":true}'

multi_base="$TMP/multiple_blocks"
mkdir -p "$multi_base"
write_mission "$multi_base/MISSION.md" bad_schema_bad_scaffold_blocked
write_plan "$multi_base/plan" bad_lens
run_doctor "$multi_base/out.json" "$multi_base/MISSION.md" "$multi_base/plan" >/dev/null
if jq -e '
  .mission_lock_readiness_health_score == 0 and
  (.blocked_surfaces | index("mission-lock-output-schema")) and
  (.blocked_surfaces | index("plan-state-lens-merge")) and
  (.blocked_surfaces | index("blocked-readiness:blocked_phase0_missing")) and
  any(.blocked_surfaces[]; startswith("mission-lock-scaffold:substrate_inventory_unresolved:")) and
  (.phase0_scaffold_bead_suggestions | map(.slug) | sort == ["mission-lock-output-schema","mission-lock-scaffold","plan-state-lens-merge"])
' "$multi_base/out.json" >/dev/null; then
  pass "multiple blocks surface all blocked surfaces"
else
  fail "multiple blocks surface all blocked surfaces"
  cat "$multi_base/out.json" >&2 || true
fi

audit_base="$TMP/audit_only"
mkdir -p "$audit_base"
write_mission "$audit_base/MISSION.md" valid
write_plan "$audit_base/plan" valid
before_mtime="$(stat -f %m "$audit_base/MISSION.md")"
before_sha="$(shasum -a 256 "$audit_base/MISSION.md" | awk '{print $1}')"
run_doctor "$audit_base/out.json" "$audit_base/MISSION.md" "$audit_base/plan" >/dev/null
after_mtime="$(stat -f %m "$audit_base/MISSION.md")"
after_sha="$(shasum -a 256 "$audit_base/MISSION.md" | awk '{print $1}')"
if [[ "$before_mtime" == "$after_mtime" && "$before_sha" == "$after_sha" ]] && jq -e '.audit_only == true' "$audit_base/out.json" >/dev/null; then
  pass "audit-only mode never mutates mission fixture"
else
  fail "audit-only mode never mutates mission fixture"
fi

run_doctor "$audit_base/out2.json" "$audit_base/MISSION.md" "$audit_base/plan" >/dev/null
key1="$(jq -r '.repair_receipt_identity_fields.repair_idempotency_key' "$audit_base/out.json")"
key2="$(jq -r '.repair_receipt_identity_fields.repair_idempotency_key' "$audit_base/out2.json")"
if [[ "$key1" == "$key2" && "$key1" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  pass "repair receipt identity fields deterministic"
else
  fail "repair receipt identity fields deterministic"
fi

printf 'RESULT test_cases=%s failures=%s golden_cases=4\n' "$pass_count" "$fail_count"
[[ "$pass_count" -ge 8 && "$fail_count" == "0" ]]
