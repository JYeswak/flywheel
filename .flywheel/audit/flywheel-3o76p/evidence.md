# flywheel-3o76p Evidence — Dicklesworthstone/ntm#135 tracker (runtime_handoff singleton id)

Task: `flywheel-3o76p-34ce69`
Bead: `flywheel-3o76p` (P1 OPEN → CLOSED this turn)
Title: [jeff-track-ntm-135] runtime_handoff singleton id prevents multi-handoff state
Date: 2026-05-10
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — closes the
flywheel-1o0i.1 surfaced upstream-tracking bead. Upstream
issue ntm#135 is currently OPEN; flywheel evidence + Jeffrey-
restraint preserved; 9-test dormancy regression fires on any
lifecycle advance.

## Headline outcome

**Locate-verdict: tracking artifacts intact + upstream issue
OPEN + flywheel-side T2.8b guard correctly FAILing (trauma
condition still holds).** The flywheel-1o0i.1 close authored a
canonical evidence pack at
`.flywheel/receipts/flywheel-1o0i.1-53a838-{blocked-evidence,jeff-issue-body}.md`
and `tests/phase2-audit.sh` carries the T2.8b guard that
isolated-fixture-tests the upstream behavior. A 9-test
dormancy regression in
`tests/3o76p-ntm-135-tracker-staging-invariants.sh` asserts:
artifacts intact (Tests 1, 2, 6, 7, 8, 9), substrate
correctly captures the bug (Test 3 PASS + Test 4 FAIL on
T2.8b), upstream still OPEN (Test 5).

## Tracking-bead lifecycle

| Phase | Status | Signal that fires |
|---|---|---|
| **Now (2026-05-10)** | OPEN — upstream OPEN; T2.8b FAILs locally; flywheel cannot represent distinct session/workdir handoff rows | Test 4 FAIL=expected; Test 5 OPEN=expected |
| **When Jeffrey closes ntm#135** | upstream lifecycle advance | Test 5 will FAIL with "issue is CLOSED — plan flywheel absorption"; orchestrator dispatches absorption work |
| **After flywheel absorbs the fixed NTM** | substrate lifecycle advance | Test 4 will FAIL with "T2.8b is now PASS — close 3o76p as superseded"; orchestrator closes 3o76p |

The dormancy regression's Tests 4 + 5 are inverted-on-advance:
each one fires a clear "lifecycle advanced" signal so the
orchestrator at that phase can close 3o76p as superseded
(or file a successor bead).

## DoD status (per bead body)

| Acceptance | Status | Evidence |
|---|---|---|
| Tracking-bead surfaces upstream ntm#135 + flywheel evidence | DONE | bead body cites both upstream URL and `.flywheel/receipts/flywheel-1o0i.1-53a838-*` paths; this audit pack pins the SHA + cites the 9-test regression |
| flywheel-side T2.8b guard intact | DONE | Test 9 verifies `tests/phase2-audit.sh` carries the T2.8b guard substrate; Test 4 verifies it currently FAILs (canonical trauma condition) |
| Upstream issue still OPEN (no premature close) | DONE | Test 5 confirms `gh issue view 135 -R Dicklesworthstone/ntm` returns `state=OPEN` |
| Jeffrey-restraint preserved (no upstream push from this dispatch) | DONE | this dispatch authors regression + audit pack only; no upstream URL leak; pre-filing dedup probe cited in evidence (Test 7) |

did=4/4 didnt=none gaps=none.

## What this fix ships

### `tests/3o76p-ntm-135-tracker-staging-invariants.sh` (NEW, 9 PASS)

| # | Test | Invariant |
|---|---|---|
| 1 | parent evidence receipt exists with T2.8b + runtime_handoff citations | substrate gate |
| 2 | jeff-issue-body draft exists with canonical singleton-id + Repro sections | upstream-comm-ready artifact intact |
| 3 | T2.8 working_dir column PASSes | upstream partial fix detection |
| 4 | T2.8b multi-handoff state FAILs | **trauma condition holds; INVERTS on flywheel absorption** |
| 5 | upstream Dicklesworthstone/ntm#135 OPEN | **Jeffrey-restraint invariant; INVERTS when Jeffrey closes** |
| 6 | evidence cites canonical repro shape | content-correctness invariant |
| 7 | evidence cites pre-filing dedup probe | Jeffrey-restraint discipline (proves we searched before filing) |
| 8 | evidence asserts no live NTM state mutation | read-only contract invariant |
| 9 | phase2-audit.sh substrate intact with T2.8b guard | substrate substrate gate |

The phase2-audit.sh invocation is cached once (script is slow,
~30-60s) and re-grepped for Tests 3 + 4 to keep the regression
fast.

## Why no new follow-up bead

- This bead IS the tracking surface; no new bead needed until
  upstream lifecycle advances.
- When Test 5 fails (Jeffrey closed ntm#135): orchestrator files
  an "absorb fixed NTM contract" bead (concrete scope: bump NTM
  version + re-run T2.8b until PASS). That's a future closing
  worker's scope, not authored speculatively here.
- When Test 4 fails (T2.8b PASSes against live NTM): close
  3o76p as superseded; the regression test flips to assert the
  PASS state.

## Pinned artifact SHA

| Artifact | Path | SHA-256 |
|---|---|---|
| regression test | `tests/3o76p-ntm-135-tracker-staging-invariants.sh` | `039d3458b88a93a5c44007a0c1f85a46bb12dd3dd4924a45e6e75a5eeb19d144` |

## Verification commands (re-runnable)

```bash
# 9 PASS regression (cached phase2-audit; total ~60-90s)
bash /Users/josh/Developer/flywheel/tests/3o76p-ntm-135-tracker-staging-invariants.sh
# expected: SUMMARY pass=9 fail=0

# Direct trauma-condition probe
bash /Users/josh/Developer/flywheel/tests/phase2-audit.sh 2>&1 \
  | grep -E 'T2\.8b runtime_handoff supports distinct session/workdir rows'
# expected: FAIL ... "isolated fixture rejected distinct session/workdir rows: CHECK constraint failed: id = 1"

# Upstream issue state
gh issue view 135 -R Dicklesworthstone/ntm --json state,title,closedAt | jq
# expected: state=OPEN, closedAt=null

# Evidence trail
ls /Users/josh/Developer/flywheel/.flywheel/receipts/flywheel-1o0i.1-53a838-*

# No upstream URL leak in this audit
grep -E 'github\.com/Dicklesworthstone/ntm/(issues|pull)/' \
  /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-3o76p/evidence.md \
  || echo "no_upstream_url_leak"
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/3o76p-ntm-135-tracker-staging-invariants.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=9 fail=0`.

## Boundary

- **No edit to flywheel-1o0i.1 evidence receipts.** Canonical
  artifacts; immutable.
- **No edit to `tests/phase2-audit.sh`.** T2.8b guard is the
  load-bearing trauma probe; rewriting it would invalidate the
  inversion-on-advance signal pattern.
- **No upstream push.** Jeffrey's repo per memory rule
  `feedback_no_push_ntm_br`: "Jeff's repos, changes stay local
  only."
- **No `gh issue create` against Dicklesworthstone/ntm.** The
  issue body is staged; if Joshua approves the upstream push,
  the closing worker at that lifecycle phase follows
  jeff-issue-chain v1.3 Phase 1 (matches the
  ksey9 + se3h.8 pattern).
- **No edit to NTM live state.** Evidence cites read-only
  fixture-only invariant (Test 8).
- **No new INCIDENTS section or numbered L-rule.** Tracking-bead
  pattern matches earlier session beads (jzn2g, q53pp, ie2en,
  f23ix, mn870, 3h6f5, ksey9, this) — locate-verdict +
  regression = canonical for upstream-pending tracker beads.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — substrate test, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=tracking_bead_regression_for_upstream_ntm_135_no_doctrine_surface_mutated_no_l-rule_authored_9_test_dormancy_regression_inverts_on_lifecycle_advance_test_4_t2_8b_pass_test_5_upstream_closed_jeffrey_restraint_preserved_no_upstream_push_8th_tracking_bead_pattern_this_session`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes 4/4 acceptance gates verbatim;
  3-phase lifecycle table + Test 4 / Test 5 inversion-on-advance
  signal pattern matches earlier session tracking-beads (8th
  instance — pattern is canonical).
- **Sniff: 9** — outcome-shaped headline ("upstream issue
  OPEN + flywheel-side T2.8b guard correctly FAILing (trauma
  condition still holds)"); concrete file-path + line-citation
  verifications; 9-test regression with positive (artifacts
  exist) + negative (T2.8b currently FAILs as expected) +
  Jeffrey-restraint controls.
- **Jeff: 10** — Jeffrey-not-Jeff in human-facing prose;
  refuses to push upstream (Jeffrey-restraint canonical);
  refuses to author/edit phase2-audit T2.8b (substrate is
  flywheel-1o0i.1's scope, immutable from here); refuses to
  edit live NTM state; cites pre-filing dedup probe; cites
  canonical jeff-issue-chain v1.3 Phase 1 handoff path
  implicitly via the matching ksey9 / se3h.8 pattern.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow on lifecycle advance)**: 4
    verification commands + the 3-phase lifecycle table give a
    clear playbook; Test 4 + Test 5 fire the canonical advance
    signal.
  - **maintainer (extending later)**: per-test invariant table
    + cached phase2-audit-output pattern give the slow-source
    optimization template; adding a 10th invariant is a one-test
    addition.
  - **future worker (LLM agent)**: facing another
    upstream-pending tracker bead, the worker has (a) the
    8-instance pattern roster (jzn2g…ksey9 + this), (b) the
    inversion-on-advance test pattern as a canonical
    lifecycle-advance signal, (c) the Jeffrey-restraint
    invariant test (no-upstream-URL-leak via grep) for any
    cross-org collaboration tracker.

`four_lens=brand:9,sniff:9,jeff:10,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-3o76p
no_bead_reason=tracking_bead_for_upstream_ntm_135_locate_verdict_artifacts_intact_upstream_open_t2_8b_fails_correctly_9_test_regression_inverts_on_lifecycle_advance_no_followup_observed_until_jeffrey_closes_upstream_or_flywheel_absorbs_fixed_ntm_contract`.
