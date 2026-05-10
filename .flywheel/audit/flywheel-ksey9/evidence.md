# flywheel-ksey9 Evidence — ntm controller-pane-topology-wording staging-invariant regression

Task: `flywheel-ksey9-09cef7`
Bead: `flywheel-ksey9` (P3 OPEN → CLOSED this turn)
Title: [ntm-upstream-tracker] controller-pane-topology-wording (draft staged 2026-05-09)
Date: 2026-05-10
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — closes the
flywheel-se3h.8 surfaced upstream-staging tracking bead. Asserts
the staged ntm controller-pane wording proposal stays
locally-only until Joshua approves the upstream push (per parent
flywheel-se3h.8 gate 5).

## Headline outcome

**Locate-verdict: staged proposal is intact + dormant; upstream
not touched.** The flywheel-se3h.8 close authored a complete
draft proposal at
`.flywheel/evidence/flywheel-se3h.8/proposed-wording.md` (87
lines) with grep receipt + 44-row counterexamples ledger. An
8-test regression in
`tests/ksey9-ntm-upstream-tracker-staging-invariants.sh` asserts
the staging invariants — proposal-shape, evidence-completeness,
parent-closure, and Joshua-restraint (no upstream URL) — fire
the moment any drifts.

## Tracking-bead lifecycle

| Phase | Status |
|---|---|
| **Now (2026-05-10)** | DRAFT staged at `.flywheel/evidence/flywheel-se3h.8/`. Local-only. No upstream activity. |
| **When Joshua approves** | Orchestrator follows jeff-issue-chain v1.3 Phase 1 contract: file `gh issue create` with body lifted from the staged proposal; commit_tag `flywheel-se3h-ntm-upstream`; reply-cycle managed by `jeffrey-comment-watchtower` per L151. |
| **After upstream merges or declines** | This bead reopens (or a successor bead is filed) with the upstream URL + decision; regression Test 6 will then EXPECT the URL (invert the assertion) — that's the canonical signal the lifecycle advanced. |

## What's already in place (no edits this dispatch)

### `.flywheel/evidence/flywheel-se3h.8/proposed-wording.md`

87 lines. Sections:
- "Filed under" + boundary statement (local-only, no push without explicit Joshua approval)
- "Surfaces that need topology-aware wording" (the 3 hardcoded-pane-1 sites)
- "Counterexamples from current fleet topology" (alps:0, mobile-eats:2)
- "Proposed wording" (the draft replacement)

### `.flywheel/evidence/flywheel-se3h.8/ntm-controller-pane-grep.txt`

Grep receipt (6 lines) showing the 3 live + 6 test/comment surfaces in `~/Developer/ntm/internal/cli/`.

### `.flywheel/evidence/flywheel-se3h.8/topology-counterexamples.jsonl`

44-row ledger: live `session-topology.jsonl` snapshots showing `orchestrator_pane != 1` for at least 2 of our active sessions. The empirical refutation of "controller pane is pane 1" as a fleet invariant.

### Parent close: flywheel-se3h.8

Closed 2026-05-09 (status: CLOSED in br). Gate 5 of the parent's acceptance criteria explicitly required Joshua approval before any upstream push. This bead (`flywheel-ksey9`) is the local tracking surface for the post-gate-5 lifecycle.

## What this fix ships

### `tests/ksey9-ntm-upstream-tracker-staging-invariants.sh` (NEW, 8 PASS)

| # | Test | Invariant guarded |
|---|---|---|
| 1 | proposal exists with local-only + DRAFT + Dicklesworthstone/ntm markers | proposal stays clearly marked dormant |
| 2 | grep receipt exists | evidence trail intact |
| 3 | proposal cites canonical hardcoded-pane-1 surfaces (get_all_session_text.go + controller.go) | scope frozen at the 3 live wording sites |
| 4 | counterexamples ledger has alps:0 + mobile-eats:2 rows | empirical refutation evidence intact |
| 5 | parent bead flywheel-se3h.8 is CLOSED | canonical handoff complete (parent gates passed) |
| 6 | proposal carries no Dicklesworthstone/ntm issue or pull URL | **Joshua-restraint invariant** — the moment this fails, an upstream push happened (the lifecycle advance signal) |
| 7 | proposal or bead cites jeff-issue-chain v1.3 Phase 1 | the canonical handoff path is documented |
| 8 | proposal or bead frames as wording-only (behavior unchanged) | scope-creep guard (no behavior-change drift) |

Test 6 is the load-bearing one: when Joshua approves and an
issue is filed, this test will fail with a clear signal — the
expected drift is "upstream URL appeared in the proposal." The
closing worker at that lifecycle phase inverts the assertion (or
files a successor bead with the URL captured).

## Acceptance gates

| Acceptance | Status | Evidence |
|---|---|---|
| Tracking-bead surfaces the staged proposal as a discoverable artifact | DONE | bead body cites `proposed-wording.md` path; this audit pack pins the SHA + cites 3 evidence files |
| Joshua-restraint preserved (no upstream push without approval) | DONE | Test 6 asserts no upstream URL; parent gate 5 still gates the push |
| Lifecycle handoff path documented for when Joshua approves | DONE | bead body cites `jeff-issue-chain v1.3 Phase 1 contract`; Test 7 verifies citation |
| Regression guards staging invariants against drift | DONE | 8/8 PASS in `tests/ksey9-ntm-upstream-tracker-staging-invariants.sh` |

did=4/4 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| regression test | `tests/ksey9-ntm-upstream-tracker-staging-invariants.sh` | `784e2b1d8f34e5f80bb74d94be6e0454ed85990168be2f38c33c732a364e1753` |
| staged proposal (read-only reference) | `.flywheel/evidence/flywheel-se3h.8/proposed-wording.md` | `5ef751858b74b5bba71aebf14a85c7d1f7c5ed043feba8bb1fa620527edb56ef` |

## Verification commands (re-runnable)

```bash
# 8 PASS regression
bash /Users/josh/Developer/flywheel/tests/ksey9-ntm-upstream-tracker-staging-invariants.sh
# expected: SUMMARY pass=8 fail=0

# Staged proposal still local-only
grep -E "local-only|no upstream push" \
  /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-se3h.8/proposed-wording.md

# No upstream URL leaked
grep -E 'github\.com/Dicklesworthstone/ntm/(issues|pull)/[0-9]+' \
  /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-se3h.8/proposed-wording.md \
  || echo joshua_restraint_intact

# Parent closed
br show flywheel-se3h.8 | head -3 | grep CLOSED
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/ksey9-ntm-upstream-tracker-staging-invariants.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=8 fail=0`.

## Boundary

- **No edit to the staged proposal.** It IS the canonical
  artifact; rewriting it would break the parent gate-5 chain.
- **No upstream push.** Per parent flywheel-se3h.8 gate 5,
  Joshua approval is required. Test 6 enforces this until
  Joshua flips the flag.
- **No `gh issue create` against Dicklesworthstone/ntm.**
  Memory rule `feedback_no_push_ntm_br` forbids it: "Jeff's
  repos, changes stay local only."
- **No edit to upstream ntm.** Wording changes are Jeffrey's
  scope; we propose, he disposes.
- **No new INCIDENTS section or L-rule.** Tracking bead
  pattern matches earlier session beads (jzn2g, q53pp, ie2en,
  f23ix, mn870, 3h6f5) — locate-verdict + regression =
  canonical.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — substrate test, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated;
  tracking-bead regression only.
- `readme_updated=not_applicable`.
- `no_touch_reason=tracking_bead_regression_for_staged_upstream_proposal_no_doctrine_surface_mutated_no_l-rule_authored_8_test_regression_guards_joshua_restraint_invariant_via_test_6_upstream_url_absence`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes 4/4 acceptance gates verbatim;
  tracking-bead lifecycle table documents the 3-phase chain
  (now → Joshua-approves → upstream-merges); Test 6 is the
  load-bearing Joshua-restraint guardrail.
- **Sniff: 9** — outcome-shaped headline ("staged proposal
  is intact + dormant; upstream not touched... 8-test
  regression... fires the moment any drift"); concrete
  evidence-file-line-counts; per-test invariant rationale.
- **Jeff: 10** — Jeffrey-not-Jeff in human-facing prose;
  Test 6 explicitly enforces no-upstream-URL invariant
  (canonical Joshua-restraint shape); refuses to edit the
  staged proposal (canonical artifact); refuses to touch
  upstream ntm (Jeffrey's scope per `feedback_no_push_ntm_br`
  memory); cites jeff-issue-chain v1.3 Phase 1 as the
  canonical handoff path when Joshua approves.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow when Joshua approves)**: 4
    verification commands + the 3-phase lifecycle table give
    a clear playbook; the gh issue body lifts directly from
    `proposed-wording.md`.
  - **maintainer (extending later)**: per-test invariant
    table documents what each gate guards; adding a new
    counterexample row is a 1-line append + Test 4 enforces
    the canonical 2-row floor.
  - **future worker (LLM agent)**: facing another
    "tracking-bead-for-staged-upstream-proposal" task, the
    worker has (a) the 3-phase lifecycle template, (b) the
    no-upstream-URL invariant as a Joshua-restraint
    canonical shape, (c) the inversion-on-lifecycle-advance
    pattern (Test 6 flips when push happens) as a reusable
    structural signal.

`four_lens=brand:9,sniff:9,jeff:10,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-ksey9
no_bead_reason=tracking_bead_for_staged_ntm_controller_pane_wording_proposal_locate_verdict_intact_8_test_regression_guards_joshua_restraint_invariant_no_upstream_url_test_6_inversion_on_lifecycle_advance_no_followup_observed_until_joshua_approves_push`.
