---
title: "Phase 5 POLISH r2 - Orchestrator Uptime Beads"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 5 POLISH r2 - Orchestrator Uptime Beads

task_id: `orch-uptime-polish-r2-2026-05-06`
plan_slug: `orch-uptime-2026-05-06`
scope: Phase 5 polish round 2, plan-space only
created_at: `2026-05-06T21:16:07Z`
socraticode_queries: 10
indexed_chunks_observed: 100

## Inputs Read

- Dispatch: `/tmp/dispatch_orch-uptime-polish-r2-2026-05-06.md`
- Primary plan inputs: `04-BEADS-DAG.md`, `05-POLISH-r1.md`, `STATE.json`
- Deep research folded: `02-DEEP-W0-baseline-reconcile.md`, `02-DEEP-C2-invariant-scanner.md`, `02-DEEP-C3-woe-bootstrap.md`
- Bead corpus observed: `.beads/issues.jsonl` plus `/tmp/orch-uptime-phase4-bead-rows-2026-05-06.jsonl`
- Worker parity inputs: `/flywheel:plan`, `/flywheel:worker-tick`, `beads-workflow`

## Worker Preflight

- Worker identity: `MagentaPond` by flywheel-loop identity; Agent Mail reservation identity `WindyForge`.
- File reservations: ids `6862` and `6863` for `06-POLISH-r2.md` and `STATE.json`.
- `flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json`: returned `status=fail` for repo drift / validation-receipt repair context. This polish round stayed inside the dispatch's bounded plan-space write scope.
- `flywheel-loop tick --repo /Users/josh/Developer/flywheel --dry-run --json`: returned `status=ok`, `planned_writes=[]`, WOE close gate allowed with missing-ledger warning.

## Round Verdict

- Beads reviewed: 15/15.
- Amendment coverage: 14/14, unchanged from r1 and mechanically enumerated below.
- r1 diff: 21%.
- r2 material delta: 386 bytes.
- Acceptance/testing corpus: 7,922 bytes.
- `polish_diff_pct_r2`: 4.87%.
- Full bead JSONL corpus: 26,792 bytes; r2 delta is 1.44% against the full corpus.
- Convergence verdict: `polish_convergence_steady_state=true`.
- Phase 5 verdict: ready for ship; no r3 required under the dispatch convergence gate.

Note: the dispatch mentions 15 r1 `polish-applied` JSONL rows, but live `.beads/issues.jsonl` has no such rows for `orch-uptime`. The mechanical comparison therefore uses the persisted 15-row JSONL bead corpus and the r1 report as the prior surface. No `.beads` mutation was performed in r2.

## R2 Marginal Changes Folded

| Bead | R2 acceptance/testing precision folded |
|---|---|
| W0 baseline reconcile | Require receipt schema `orch-uptime-w0-baseline-reconcile/v1`; A2 may proceed only on `closed_verified` or `closed_verified_jsonl_fallback`; all other W0 decisions block A2. Receipt path: `~/.local/state/flywheel/orch-uptime/w0-a2-baseline-reconcile-receipt.json`. |
| C2 frozen projection scanner | Require the regex bank from `02-DEEP-C2-invariant-scanner.md` and schema `frozen-projection-invariant/v1`; F4 ladder is warn for pre-cutoff debt, fail for post-cutoff, and fail always for secret, unreadable, malformed, or allow-without-reason hits. |
| C3 WOE bootstrap | Require 11 bootstrap rows with `identity_key=orch-uptime-c3:<bead_id>` and idempotency key `orch-uptime-c3-woe-bootstrap:2026-05-06:<bead_id>`; blocking scope ladder is `woe_claim`, `tick`, `local`, `none`; closeout receipt pattern is `/Users/josh/.local/state/flywheel/wire-or-explain/closeout-receipts/`. |

The exact r2 delta text measured was:

```text
W0: Require receipt schema `orch-uptime-w0-baseline-reconcile/v1`; A2 proceeds only on `closed_verified|closed_verified_jsonl_fallback`.
C2: Require regex bank from 02-DEEP-C2 and F4 cutoff ladder: warn pre-cutoff, fail post-cutoff, fail secrets/unreadable always.
C3: Require 11 bootstrap rows with `identity_key=orch-uptime-c3:<bead_id>` and scope ladder `woe_claim|tick|local|none`.
```

## Mechanical Probe Pass

Every r1 "verify" surface now has a command-shaped acceptance probe:

- W0: `rg -n 'OK_codex_queued_not_submitted_wired|flywheel-wire-codex-queued-not-submitted' INCIDENTS.md .beads/issues.jsonl` plus receipt JSON validation.
- A1: CAAM fake-provider tests, authorized/forbidden operation fixtures, redaction check, and TTL/idempotency JSON probe.
- C1: `rg -n 'templates-name-sources-not-values|Templates name sources, not values' AGENTS.md templates/flywheel-install/AGENTS.md`.
- A2: `bash tests/codex-template-stuck-detector.sh`, `bash tests/e2e/e2e_oom_classifier.sh`, and codex usage-limit classifier fixtures.
- A3: credential-rotation auth gate probe requiring `recovery_class=credential_rotation`, `authorized=false` for unsafe ops, and `credential_secret_values_observed=0`.
- B1/B2: topology tick refresh ledger row probe with source path, profile, topology hash, target pane, invocation id, lock path, and timeout.
- B3: mobile-eats arity fixture proves one-arg helper survival and `fleet_escalation_capsule_skipped`.
- B4/B5: watcher registration/load/fire split fixture plus scoped doctor output for `flywheel-watchers`.
- C2: invariant scanner dry-run proves forbidden literal payload hits are counted and path-named source references are allowed.
- C3: WOE writer bootstrap proves production ledger row count, temp proof path, idempotency, owner routing, and close-gate effect.
- A4: additive recovery-ledger schema probe for `credential_rotation`; existing `model_at_capacity` fields remain compatible.
- C4: fleet sweep dry-run proves frozen-projection targets, WOE targets, L87 sunset, label drift, and dependency-order surfaces.
- W4: integration closeout must aggregate command list, amendment coverage map, `founder_pages_avoided`, and L112.

## Amendment Coverage

| # | Amendment | Coverage |
|---|---|---|
| 1 | Credential rotation authorized and forbidden operations | A1, A3, W4 |
| 2 | Idempotency profile and TTL | A1, A4, W4 |
| 3 | `--allow-unhealthy` refused unless ack | A1, W4 |
| 4 | W0 before A2 | W0, A2 |
| 5 | Coordinate DAG edges | B1, A2, A3, B2, B4, B5 |
| 6 | Shared primitive fields | A1, B1, C2, C3, W4 |
| 7 | Topology ledger row on every fire | B1, B2, W4 |
| 8 | Watcher registration/load/fire split | B4, B5, W4 |
| 9 | Durable cross-orchestrator coordination row | C1, C4 |
| 10 | Frozen projection warn existing, fail new | C2, C4 |
| 11 | WOE scoped blocker only | C3, W4 |
| 12 | `founder_pages_avoided` metric | W4 |
| 13 | Label drift L75/L115/L117 | C1, C4, W4 |
| 14 | Mobile-eats empirical idle plus `--accept-stall` | A1, A2, B3 |

## Diff Measurement

- Persisted corpus: `/tmp/orch-uptime-phase4-bead-rows-2026-05-06.jsonl`
- `description_bytes`: 3,738
- `acceptance_bytes`: 5,571
- `testing_bytes`: 2,351
- `acceptance_testing_bytes`: 7,922
- `full_corpus_bytes`: 26,792
- `r2_material_delta_bytes`: 386
- `386 / 7922 = 0.0487`, so `polish_diff_pct_r2=4.87`
- `386 / 26792 = 0.0144`, so full-corpus confirmation is 1.44%

## Conclusion

Phase 5 r2 reaches steady-state by the dispatch convergence gate. W0, C2, and C3 deep research are now represented as small mechanical acceptance additions, not new design movement. The plan is ready for integration closeout execution.

L112: `OK_orch_uptime_polish_r2_complete`
Mission-anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
