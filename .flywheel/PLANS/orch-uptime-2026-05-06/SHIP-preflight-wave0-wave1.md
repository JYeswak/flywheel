# Orch Uptime Wave 0/Wave 1 Ship Preflight - 2026-05-06

Scope: read-only ship-prep for W0/A1/B1/C1 so ship dispatches can fire without re-research.

Socraticode: K=10, 10 searches against `/Users/josh/Developer/flywheel`; status green, indexed chunks observed 979.

Inputs read:
- `/Users/josh/Developer/flywheel/.flywheel/plans/orch-uptime-2026-05-06/04-BEADS-DAG.md`
- `/Users/josh/Developer/flywheel/.flywheel/plans/orch-uptime-2026-05-06/02-DEEP-W0-baseline-reconcile.md`
- `/Users/josh/Developer/flywheel/.flywheel/plans/orch-uptime-2026-05-06/02-DEEP-C2-invariant-scanner.md`
- Supporting precision from `00-PLAN.md`, `01-RESEARCH-{A,B,C}.md`, `05-POLISH-r1.md`, `06-POLISH-r2.md`, and current `.beads/issues.jsonl` rows.

## W0 - `flywheel-orch-uptime-detector-baseline-reconcile-2026-05-06`

Files to create:
- `/Users/josh/.local/state/flywheel/orch-uptime/w0-a2-baseline-reconcile-receipt.json`
- `/Users/josh/.local/state/flywheel/orch-uptime/w0-a2-detector-baseline.lock` (transient; remove/release at close)

Files to modify:
- none. W0 is read-only against source and bead state.

Source paths read/proven:
- `/Users/josh/Developer/flywheel/.beads/issues.jsonl`
- `/Users/josh/Developer/flywheel/INCIDENTS.md`
- `/Users/josh/Developer/flywheel/.flywheel/scripts/codex-template-stuck-detector.sh`
- `/Users/josh/Developer/flywheel/tests/codex-template-stuck-detector.sh`
- `/Users/josh/Developer/flywheel/tests/e2e/e2e_oom_classifier.sh`

Collision risk:
- Receipt parent dir `/Users/josh/.local/state/flywheel/orch-uptime` is missing; create it in W0.
- Receipt and lock paths are missing; no path collision.
- Read-only proof sources exist; `.beads/issues.jsonl`, `INCIDENTS.md`, and `tests/codex-template-stuck-detector.sh` are currently dirty, so W0 must record current line numbers rather than assuming the deep-research 1315/1317/1318/1319 lines still match.

L112 marker:
- `OK_orch_uptime_w0_detector_baseline_reconciled`

Acceptance probe one-liner:
- `set -euo pipefail; cd /Users/josh/Developer/flywheel; r=/Users/josh/.local/state/flywheel/orch-uptime/w0-a2-baseline-reconcile-receipt.json; jq -e '.schema_version=="orch-uptime-w0-baseline-reconcile/v1" and .baseline_reconciled==true and (.outcome=="closed_verified" or .outcome=="closed_verified_jsonl_fallback") and .latest_jsonl_row.l112=="OK_codex_queued_not_submitted_wired" and .latest_jsonl_row.detector_regression_pass==true and .latest_jsonl_row.targeted_tests=="11/11" and .latest_jsonl_row.files_released==true' "$r" && rg -n 'OK_codex_queued_not_submitted_wired|flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06' INCIDENTS.md .beads/issues.jsonl && rg -n 'codex_queued_not_submitted|bare_enter|model_at_capacity_halt|oom_killed_pane|unknown_stable' .flywheel/scripts/codex-template-stuck-detector.sh tests/codex-template-stuck-detector.sh tests/e2e/e2e_oom_classifier.sh`

## A1 - `flywheel-orch-uptime-caam-auto-rotate-primitive-2026-05-06`

Files to create:
- `/Users/josh/Developer/flywheel/.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh`
- `/Users/josh/Developer/flywheel/.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh`
- `/Users/josh/Developer/flywheel/.flywheel/tests/fixtures/caam-auto-rotate/fake-caam`
- `/Users/josh/Developer/flywheel/.flywheel/tests/fixtures/caam-auto-rotate/profiles-current-alt.json`
- `/Users/josh/Developer/flywheel/.flywheel/tests/fixtures/caam-auto-rotate/profiles-no-alternate.json`
- `/Users/josh/Developer/flywheel/.flywheel/tests/fixtures/caam-auto-rotate/status-current.json`
- `/Users/josh/Developer/flywheel/.flywheel/tests/fixtures/caam-auto-rotate/status-selected.json`
- `/Users/josh/Developer/flywheel/.flywheel/tests/fixtures/caam-auto-rotate/activate-success.json`
- `/Users/josh/Developer/flywheel/.flywheel/tests/fixtures/caam-auto-rotate/activate-failure.json`
- `/Users/josh/Developer/flywheel/.flywheel/tests/fixtures/caam-auto-rotate/secret-negative-output.json`

Files to modify:
- none for A1. Do not fold A2/A3/A4 files into this bead; detector, auth gate, and recovery schema are downstream beads.

Collision risk:
- Required A1 script/test/fixture directory are all missing; no direct file collision.
- If a worker expands A1 into `.flywheel/scripts/capacity-halt-pane-authorization.sh`, `.flywheel/validation-schema/v1/recovery-ledger.schema.json`, or detector tests, it is crossing into A3/A4/A2 ownership.
- Explicit check: `/Users/josh/Developer/flywheel/.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh` does not already exist.

L112 marker:
- `OK_orch_uptime_a1_caam_auto_rotate_primitive`

Acceptance probe one-liner:
- `set -euo pipefail; cd /Users/josh/Developer/flywheel; bash .flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh && out="$(.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh --tool codex --session flywheel --pane 2 --digest "$(printf orch-uptime-a1 | shasum -a 256 | awk '{print $1}')" --dry-run --json)"; jq -e '.schema_version=="caam-auto-rotate-on-usage-limit.result.v1" and .dry_run==true and .apply==false and .primitive_invoked=="caam-auto-rotate-on-usage-limit" and has("idempotency_key") and has("lock_path") and has("ledger_path") and has("post_check") and (.authorized_operations|index("caam_activate_existing_profile")) and (.forbidden_operations|index("pane_mutation")) and (.forbidden_operations|index("oauth_refresh")) and (.forbidden_operations|index("token_rotation")) and ((tostring|test("auth\\\\.json|bearer|api[_-]?key";"i")|not))' <<<"$out"`

## B1 - `flywheel-orch-uptime-topology-tick-refresh-script-2026-05-06`

Files to create:
- `/Users/josh/Developer/flywheel/.flywheel/scripts/topology-tick-refresh.sh`
- `/Users/josh/Developer/flywheel/tests/topology-tick-refresh.sh`
- `/Users/josh/Developer/flywheel/tests/fixtures/topology-tick-refresh/fake-ntm`
- `/Users/josh/Developer/flywheel/tests/fixtures/topology-tick-refresh/unchanged-shape.jsonl`
- `/Users/josh/Developer/flywheel/tests/fixtures/topology-tick-refresh/shape-changed.jsonl`
- `/Users/josh/Developer/flywheel/tests/fixtures/topology-tick-refresh/lock-held.json`
- `/Users/josh/Developer/flywheel/tests/fixtures/topology-tick-refresh/malformed.jsonl`
- `/Users/josh/Developer/flywheel/tests/fixtures/topology-tick-refresh/missing-live-session.jsonl`
- `/Users/josh/Developer/flywheel/tests/fixtures/topology-tick-refresh/worker-kind-changed.jsonl`
- `/Users/josh/Developer/flywheel/tests/fixtures/topology-tick-refresh/extra-agent-pane.jsonl`

Files to modify:
- none for B1. B2 owns `/Users/josh/Developer/flywheel/.flywheel/flywheel-loop-tick` and `/Users/josh/Developer/flywheel/.flywheel/scripts/tick-driver-manifest.json`.

Collision risk:
- B1 script/test/fixture directory are missing; no direct B1 collision.
- `.flywheel/flywheel-loop-tick` and `.flywheel/scripts/tick-driver-manifest.json` already have unrelated uncommitted changes; B1 dispatch must avoid them and leave manifest/tick wiring to B2.

L112 marker:
- `OK_orch_uptime_b1_topology_tick_refresh`

Acceptance probe one-liner:
- `set -euo pipefail; cd /Users/josh/Developer/flywheel; bash tests/topology-tick-refresh.sh && tmp="$(mktemp -d)"; cp tests/fixtures/topology-tick-refresh/unchanged-shape.jsonl "$tmp/topology.jsonl"; out="$(.flywheel/scripts/topology-tick-refresh.sh --topology "$tmp/topology.jsonl" --ntm-bin tests/fixtures/topology-tick-refresh/fake-ntm --ledger "$tmp/invocations.jsonl" --apply --json)"; jq -e '.schema_version=="topology-tick-refresh.result.v1" and .primitive_invoked=="topology-tick-refresh" and (.status=="refreshed" or .status=="already_fresh") and has("idempotency_key") and has("lock_path") and has("ledger_path") and has("post_check") and has("max_age_sec_before") and has("max_age_sec_after")' <<<"$out" && test "$(wc -l < "$tmp/invocations.jsonl")" -eq 1 && jq -e 'select(.run_id and (.status=="refreshed" or .status=="already_fresh" or .status=="refused" or .status=="skipped" or .status=="malformed" or .status=="lock_held") and .topology_shape_hash and has("max_age_sec_before") and has("max_age_sec_after"))' "$tmp/invocations.jsonl"`

## C1 - `flywheel-orch-uptime-frozen-projection-l-rule-2026-05-06`

Files to create:
- none.

Files to modify:
- `/Users/josh/Developer/flywheel/AGENTS.md`
- `/Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md`
- `/Users/josh/Developer/flywheel/templates/flywheel-install/AGENTS.md`

Coordination state to verify, not append unless deliberately adding an ack row:
- `/Users/josh/.local/state/flywheel/cross-orch-coordination.jsonl` line 203 already has `schema_version=cross_orch_handoff.v1`, `blocker_type=flywheel_class`, `blocker_class=frozen-projection-of-mutable-state`, `requested_owner=flywheel:1`, and `proposed_action=Option C Hybrid + canonical L-rule templates-name-sources-not-values`.

Collision risk:
- High. All three doctrine surfaces already have uncommitted changes.
- C1 must re-read tail/max L-rule before editing. Current max visible L-rule is L118, so the next rule should be L119 unless another worker lands a rule first.
- L96 requires the three-surface doctrine diff in one coherent ship unit; do not report canonical if only one or two surfaces change.

L112 marker:
- `OK_orch_uptime_c1_frozen_projection_l_rule`

Acceptance probe one-liner:
- `set -euo pipefail; cd /Users/josh/Developer/flywheel; for f in AGENTS.md .flywheel/AGENTS-CANONICAL.md templates/flywheel-install/AGENTS.md; do test "$(rg -c '^## L119 .*TEMPLATES-NAME-SOURCES-NOT-VALUES' "$f")" -eq 1; rg -n 'id: L119|templates-name-sources-not-values|Templates name sources, not values|frozen-projection-of-mutable-state' "$f"; done; .flywheel/scripts/doctrine-3-surface-divergence-probe.sh --repo /Users/josh/Developer/flywheel --json | jq -e '.status=="pass" and .doctrine_3_surface_divergent_count==0'; sed -n '203p' /Users/josh/.local/state/flywheel/cross-orch-coordination.jsonl | jq -e '.schema_version=="cross_orch_handoff.v1" and .blocker_type=="flywheel_class" and .blocker_class=="frozen-projection-of-mutable-state" and .requested_owner=="flywheel:1" and (.proposed_action|contains("Option C Hybrid"))'`

## Recommended Dispatch Order / Panes

Order:
1. W0 first, immediately, because it gates A2 and is read-only receipt work.
2. A1 and B1 can run in parallel after W0 is dispatched; neither depends on W0, but W0 keeps A2 unblocked.
3. C1 can run in parallel with A1/B1 only if the worker gets an L51/L107 reservation on the three doctrine surfaces and re-reads dirty tails first. If no reservation is available, hold C1 until current doctrine-surface work settles.

Pane recommendation per L101 continuous productivity:
- `flywheel:2` -> W0 now; small read-only receipt, fastest unblock for A2.
- `flywheel:3` -> A1 after W0 packet lands; isolated new script/test surface.
- `flywheel:4` -> B1 after W0 packet lands; isolated new script/test surface.
- `flywheel:1` or next free worker -> C1, because doctrine surfaces are dirty and shared; reserve `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, and `templates/flywheel-install/AGENTS.md` before edits.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
