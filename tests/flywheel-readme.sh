#!/usr/bin/env bash
set -euo pipefail

BIN="/Users/josh/.claude/skills/.flywheel/bin/flywheel-readme"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

export FLYWHEEL_STATE_DIR="$TMPDIR/state"

"$BIN" --help | grep -q 'flywheel-readme doctor'
"$BIN" doctor --help | grep -q 'flywheel-readme doctor'
"$BIN" health --help | grep -q 'flywheel-readme health'
"$BIN" completion --help | grep -q 'completion'
"$BIN" --info --json | jq -e '.name == "flywheel-readme" and .version and .paths.queue' >/dev/null
"$BIN" --examples --json | jq -e '.examples | length >= 5' >/dev/null
"$BIN" quickstart --json | jq -e '.status == "ok" and .title == "flywheel-readme quickstart"' >/dev/null
"$BIN" help lifecycle --json | jq -e '.topic == "lifecycle"' >/dev/null
"$BIN" schema doctor --json | jq -e '.title == "flywheel-readme doctor output"' >/dev/null
"$BIN" doctor --json | jq -e '.subsystems.queue.status == "OK"' >/dev/null
"$BIN" health --json | jq -e '.queue_depth == 0' >/dev/null
"$BIN" repair --scope locks --dry-run --json | jq -e '.mode == "dry_run"' >/dev/null
"$BIN" audit --json | jq -e '.audit_rows == 0' >/dev/null
"$BIN" metrics --json | jq -e '.audit_rows == 0' >/dev/null
"$BIN" logs --json | jq -e '.log_rows == 0' >/dev/null
"$BIN" palette --json | jq -e '.commands | index("doctor")' >/dev/null
"$BIN" activity --json | jq -e '.queue_depth == 0' >/dev/null
"$BIN" triage --json | jq -e '.next_actions | length > 0' >/dev/null

artifact="$TMPDIR/artifact.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$artifact"
chmod +x "$artifact"
readme="$TMPDIR/artifact.README.md"
fake_ntm="$TMPDIR/fake-ntm"
printf '%s\n' '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'printf "%s\n" "$*" >> "${FLYWHEEL_README_FAKE_NTM_LOG:?}"' \
  'exit "${FLYWHEEL_README_FAKE_NTM_RC:-0}"' > "$fake_ntm"
chmod +x "$fake_ntm"
transport_env=(
  FLYWHEEL_README_ALLOW_TRANSPORT=1
  FLYWHEEL_README_NTM="$fake_ntm"
  FLYWHEEL_README_FAKE_NTM_LOG="$TMPDIR/ntm.log"
  FLYWHEEL_DISPATCH_LOG="$TMPDIR/dispatch-log.jsonl"
  FLYWHEEL_README_AGENT_MAIL_OUTBOX="$TMPDIR/agent-mail-outbox.jsonl"
)

"$BIN" draft "$artifact" --out "$readme" --from-bead flywheel-qnc --drafted-by test-worker --dry-run --json | jq -e '.mode == "dry_run"' >/dev/null
"$BIN" draft "$artifact" --out "$readme" --from-bead flywheel-qnc --drafted-by test-worker --idempotency-key draft-test --json | jq -e '.status == "drafted"' >/dev/null
test -f "$readme"
"$BIN" validate "$readme" --json | jq -e '.valid == true' >/dev/null
"$BIN" submit "$readme" --bead flywheel-qnc --dry-run --json | jq -e '.mode == "dry_run"' >/dev/null
"$BIN" review --queue --json | jq -e '.queue_size == 0' >/dev/null
env "${transport_env[@]}" "$BIN" submit "$readme" --bead flywheel-qnc --pane flywheel:1 --idempotency-key live-submit --json \
  | jq -e '.status == "submitted" and .transport.status == "sent" and .transport.legs.ntm.status == "sent" and .transport.legs.agent_mail.status == "queued" and .transport.legs.dispatch_log.status == "appended"' >/dev/null
test -s "$TMPDIR/ntm.log"
test -s "$TMPDIR/agent-mail-outbox.jsonl"
test -s "$TMPDIR/dispatch-log.jsonl"
jq -e 'select(.action == "submit" and .status == "pending_mcp_send")' "$TMPDIR/agent-mail-outbox.jsonl" >/dev/null
jq -e 'select(.event == "flywheel_readme_transport" and .action == "submit" and .status == "sent")' "$TMPDIR/dispatch-log.jsonl" >/dev/null

for leg in ntm agent_mail dispatch_log; do
  fail_readme="$TMPDIR/fail-$leg.README.md"
  cp "$readme" "$fail_readme"
  set +e
  fail_out="$(env "${transport_env[@]}" FLYWHEEL_README_TRANSPORT_TEST_FAIL="$leg" "$BIN" submit "$fail_readme" --bead flywheel-qnc --idempotency-key "fail-$leg" --json)"
  fail_rc=$?
  set -e
  test "$fail_rc" -eq 3
  printf '%s\n' "$fail_out" | jq -e --arg leg "$leg" '.status == "transport_failed" and .transport.failed_leg == $leg' >/dev/null
  grep -q '^state: 1_drafted$' "$fail_readme"
done

"$BIN" review "$readme" --reviewed-by test-orch --non-interactive --dry-run --json | jq -e '.state_to == "2_orchestrator_reviewing"' >/dev/null
"$BIN" reject "$readme" --reasons validation_failed --reviewed-by test-orch --dry-run --json | jq -e '.reasons[0] == "validation_failed"' >/dev/null
env "${transport_env[@]}" "$BIN" reject "$readme" --reasons validation_failed --reviewed-by test-orch --idempotency-key live-reject --json \
  | jq -e '.status == "rejected" and .reasons[0] == "validation_failed" and .transport.status == "sent"' >/dev/null

review_readme="$TMPDIR/review-artifact.README.md"
"$BIN" draft "$artifact" --out "$review_readme" --from-bead flywheel-qnc --drafted-by test-worker-2 --idempotency-key draft-review --json \
  | jq -e '.status == "drafted"' >/dev/null
"$BIN" review "$review_readme" --reviewed-by test-orch --non-interactive --dry-run --json \
  | jq -e '.state_to == "2_orchestrator_reviewing" and .gate2.status == "pass" and (.gate2.checklist | has("cold_read_replicable") and has("mermaid_parse_valid") and has("see_also_paths_resolve") and has("examples_no_surprise_side_effects") and has("strict_state_transition") and has("self_validation_prevented"))' >/dev/null
"$BIN" review "$review_readme" --reviewed-by test-orch --non-interactive --idempotency-key live-review --json \
  | jq -e '.status == "reviewing" and .gate2.status == "pass"' >/dev/null
"$BIN" pass "$review_readme" --reviewed-by test-orch --dry-run --json | jq -e '.state_to == "3_orchestrator_passed" and .gate2.status == "pass"' >/dev/null
"$BIN" pass "$review_readme" --reviewed-by test-orch --idempotency-key live-pass --json | jq -e '.status == "passed" and .gate2.status == "pass"' >/dev/null
"$BIN" signoff --queue --json | jq -e '.queue_size >= 1' >/dev/null
"$BIN" signoff "$review_readme" --signed-by joshua --dry-run --json | jq -e '.state_to == "4_joshua_signed" and .gate2.status == "pass"' >/dev/null

gate2_fail() {
  local path="$1" actor="$2" klass="$3" cmd="${4:-review}"
  set +e
  if [[ "$cmd" == "review" ]]; then
    out="$("$BIN" "$cmd" "$path" --reviewed-by "$actor" --non-interactive --dry-run --json 2>/dev/null)"
  else
    out="$("$BIN" "$cmd" "$path" --reviewed-by "$actor" --dry-run --json 2>/dev/null)"
  fi
  rc=$?
  set -e
  test "$rc" -ne 0
  printf '%s\n' "$out" | jq -e --arg klass "$klass" '.status == "gate2_failed" and (.blocked_by | index($klass))' >/dev/null
}

failure_base_readme="$TMPDIR/failure-base.README.md"
"$BIN" draft "$artifact" --out "$failure_base_readme" --from-bead flywheel-qnc --drafted-by failure-worker --idempotency-key draft-failure-base --json >/dev/null

cold_readme="$TMPDIR/cold.README.md"
cp "$failure_base_readme" "$cold_readme"
perl -0pi -e 's#validation_command: .*\n#validation_command: test -e ./artifact.sh\n#' "$cold_readme"
gate2_fail "$cold_readme" test-orch cold_read_replicable

mermaid_readme="$TMPDIR/mermaid.README.md"
cp "$failure_base_readme" "$mermaid_readme"
perl -0pi -e 's/flowchart LR/notADiagram/' "$mermaid_readme"
gate2_fail "$mermaid_readme" test-orch mermaid_parse_valid

seealso_readme="$TMPDIR/seealso.README.md"
cp "$failure_base_readme" "$seealso_readme"
printf '\n- `missing-related-file.md`\n' >> "$seealso_readme"
gate2_fail "$seealso_readme" test-orch see_also_paths_resolve

examples_readme="$TMPDIR/examples.README.md"
cp "$failure_base_readme" "$examples_readme"
printf '\n## Examples\n\n```bash\nflywheel-readme submit /tmp/example.README.md\n```\n' >> "$examples_readme"
gate2_fail "$examples_readme" test-orch examples_no_surprise_side_effects

state_readme="$TMPDIR/state.README.md"
cp "$failure_base_readme" "$state_readme"
gate2_fail "$state_readme" test-orch strict_state_transition pass

self_readme="$TMPDIR/self.README.md"
"$BIN" draft "$artifact" --out "$self_readme" --from-bead flywheel-qnc --drafted-by self-worker --idempotency-key draft-self --json >/dev/null
gate2_fail "$self_readme" self-worker self_validation_prevented

signer_readme="$TMPDIR/signer.README.md"
"$BIN" draft "$artifact" --out "$signer_readme" --from-bead flywheel-qnc --drafted-by sign-worker --idempotency-key draft-signer --json >/dev/null
"$BIN" review "$signer_readme" --reviewed-by reviewer-one --non-interactive --idempotency-key review-signer --json >/dev/null
"$BIN" pass "$signer_readme" --reviewed-by reviewer-one --idempotency-key pass-signer --json >/dev/null
set +e
signer_out="$("$BIN" signoff "$signer_readme" --signed-by reviewer-one --dry-run --json)"
signer_rc=$?
set -e
test "$signer_rc" -eq 4
printf '%s\n' "$signer_out" | jq -e '.status == "gate2_failed" and (.blocked_by | index("self_validation_prevented"))' >/dev/null

set +e
blocked_reject="$(FLYWHEEL_README_NTM="$fake_ntm" "$BIN" signoff "$review_readme" --signed-by joshua --reject-with-reason docs_not_clear --json)"
blocked_rc=$?
set -e
test "$blocked_rc" -eq 4
printf '%s\n' "$blocked_reject" | jq -e '.status == "blocked" and (.blocked_by[0] | contains("FLYWHEEL_README_ALLOW_TRANSPORT"))' >/dev/null
env "${transport_env[@]}" "$BIN" signoff "$review_readme" --signed-by joshua --reject-with-reason docs_not_clear --idempotency-key live-joshua-reject --json \
  | jq -e '.status == "rejected" and .reject_reason == "docs_not_clear" and .transport.status == "sent"' >/dev/null
"$BIN" why "$review_readme" --json | jq -e '.event_count >= 0' >/dev/null
"$BIN" trace "$review_readme" --json | jq -e '.status == "ok"' >/dev/null

bash /Users/josh/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh "$BIN" >/dev/null
