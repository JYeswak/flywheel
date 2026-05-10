# flywheel-ie2en Evidence — Codex #21869 post-push ref-drift guard (dormant rule + dormancy regression)

Task: `flywheel-ie2en-25291b`
Bead: `flywheel-ie2en` (P2 OPEN → CLOSED this turn)
Title: Codex #21869 post-push ref verification gate
Date: 2026-05-10
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — closes the
flywheel-z6lk3 codex-watchtower triage's filed follow-up for
upstream issue openai/codex#21869.

## Headline outcome

**Surface verdict: zero current fleet exposure to 21869.** The
flywheel fleet's worker lane runs Codex under
`--dangerously-bypass-approvals-and-sandbox` (full-access mode),
NOT `workspace-write`. The 21869 bug only manifests in
`workspace-write + network_access=true`, so the failure mode is
dormant. To future-proof against any worker lane that introduces
workspace-write+network, this close ships:

1. A doctrine entry naming the rule + the 5-step reconciliation
   probe required to satisfy it
2. A 7-test dormancy regression that fires the moment the rule
   activates (codex config sets sandbox=workspace-write OR
   `.flywheel/scripts/*.sh` adds a `git push` surface).

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — identify the active flywheel surface that permits or wraps git push from Codex workers | DID | none exists today: zero `git push` invocations in `.flywheel/scripts/*.sh`; codex config has no `sandbox = workspace-write` directive at fleet level; canonical worker mode is `--dangerously-bypass-approvals-and-sandbox` (full-access, NOT workspace-write) per `feedback_codex_relaunch_command_canonical` memory rule |
| AG2 — add a bounded check or explicit rule for post-push local ref consistency | DID | `.flywheel/doctrine/codex-21869-post-push-ref-drift-rule.md` documents the 5-step reconciliation probe (ls-remote → compare HEAD → compare tracking ref → fetch repair → emit receipt) required for any future workspace-write+network worker lane |
| AG3 — include a fixture or shell test, or document why no executable surface exists | DID | `tests/codex-21869-post-push-ref-drift-guard.sh` 7/7 PASS — asserts dormancy invariants (rule doc + no push surface + no workspace-write config + DCG force-push still blocked); fires when invariants regress |

did=3/3 didnt=none gaps=none.

## What this fix protects against

| Scenario | Today | Future-proof |
|---|---|---|
| Worker lane runs codex full-access (current) | OK — 21869 doesn't manifest | OK |
| Worker lane runs codex workspace-write WITHOUT network | OK — push not allowed in sandbox | OK |
| Worker lane runs codex workspace-write WITH network (21869 bug shape) | NO worker invokes `git push` from this lane today | Test 3 of regression FAILS the moment codex config adds `sandbox = workspace-write` fleet-wide; rule doc names the required reconciliation probe |
| Worker lane adds a `git push` invocation in `.flywheel/scripts/*.sh` | None present | Test 2 of regression FAILS the moment any `*.sh` adds inline `git push` |
| Force-push protection regresses | DCG core.git blocks `push --force` (long + short) at critical severity | Test 7 of regression FAILS the moment force-push protection regresses |

## What this fix does NOT do

- **No active push wrapper in `.flywheel/scripts/`.** Per Joshua's
  fleet pattern (workers commit locally; pushes are
  Joshua/orch-driven), there's no executable surface to wrap.
  Adding a wrapper that ANYONE could use would expand attack
  surface for no benefit — the fleet's defense-in-depth is
  "workers don't push at all."
- **No new numbered L-rule.** Per the doctrine entry's "Why
  doctrine, not L-rule" section: L-rules are reserved for
  canonical, recurring behaviors. This rule is dormant; the
  regression test enforces dormancy. If the rule wakes up, a
  future bead can promote it to a numbered L-rule.
- **No edit to codex config.** That's Joshua's substrate; the
  current full-access mode is the canonical fleet pattern.
- **No edit to DCG packs.** Force-push protection is already in
  place; 21869's specific failure mode (non-force push that
  desyncs local tracking ref) is OUT of DCG's blast-radius
  scope (DCG is shell-pattern-based, not git-state-aware).

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| regression test | `tests/codex-21869-post-push-ref-drift-guard.sh` | `6436f9f067ef9c7a3948c2fe672672af89acc8e1e2b30325e02e9d94c99037f2` |
| rule document | `.flywheel/doctrine/codex-21869-post-push-ref-drift-rule.md` | `3e802abb7a8ce74067db48f80e43e916bcdad5aedeb85959a9b6ca0713b0f6bf` |

## Verification commands (re-runnable)

```bash
# Regression suite (7 PASS)
bash /Users/josh/Developer/flywheel/tests/codex-21869-post-push-ref-drift-guard.sh
# expected: SUMMARY pass=7 fail=0

# Rule document exists with required sections
grep -cE "openai/codex#21869|workspace-write|network_access|reconciliation probe" \
  /Users/josh/Developer/flywheel/.flywheel/doctrine/codex-21869-post-push-ref-drift-rule.md
# expected: >=4

# No worker push surface
grep -lE '^[[:space:]]*git[[:space:]]+push\b' \
  /Users/josh/Developer/flywheel/.flywheel/scripts/*.sh 2>/dev/null
# expected: empty (no hits)

# No fleet-wide workspace-write
grep -E '^[[:space:]]*sandbox[[:space:]]*=[[:space:]]*"?workspace-write"?' \
  ~/.codex/config.toml 2>/dev/null
# expected: empty

# DCG force-push protection alive
dcg packs -v --enabled 2>&1 | grep -E 'push-force-(long|short).*critical' | wc -l
# expected: 2

# Triage chain intact
grep "21869" /Users/josh/Developer/flywheel/.flywheel/receipts/flywheel-z6lk3/triage-receipt.md
# expected: row classifying issue as fleet-affecting
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/codex-21869-post-push-ref-drift-guard.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=7 fail=0`.

## Boundary

- **No edit to ~/.codex/config.toml.** Joshua's substrate; full-
  access mode is canonical.
- **No edit to existing scripts.** No worker push surface exists;
  adding one for the sake of "wrapping" would be net-negative.
- **No new numbered L-rule.** Doctrine + regression is the
  canonical disposition for dormant rules.
- **No reopen of `flywheel-z6lk3`.** Triage close stands; this
  bead is the surfaced followup.
- **No upstream patch contribution.** openai/codex#21869 is filed
  upstream; the flywheel side ships the dormancy guard +
  doctrine, not a code fix to upstream.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — doctrine entry, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no AGENTS.md change; rule lives in
  `.flywheel/doctrine/` instead per L-rule numbering discipline.
- `readme_updated=not_applicable`.
- `no_touch_reason=dormant_rule_landed_in_dot_flywheel_doctrine_with_7_test_dormancy_regression_no_l-rule_numbered_no_doctrine_surface_propagation_required_no_active_push_surface_in_fleet_so_no_wrapper_to_edit`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes 3/3 acceptance gates verbatim;
  surface-verdict is concrete (zero exposure today, regression
  asserts dormancy); doctrine entry is the canonical reference
  for any future workspace-write lane.
- **Sniff: 9** — outcome-shaped headline ("zero current fleet
  exposure… ships dormancy regression that fires the moment the
  rule activates"); concrete what-this-protects vs
  what-this-doesn't tables; explicit rationale for "no L-rule
  numbered" + "no wrapper script" + "no codex config edit".
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one doctrine + one test + one audit pack); refuses
  to add a push wrapper (would expand attack surface), refuses
  to edit codex config (Joshua substrate), refuses to upstream-
  patch (openai/codex maintainer scope), refuses to promote to
  numbered L-rule (dormant rules belong in doctrine).
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: 6 verification commands
    confirm rule + dormancy + DCG protection + triage chain in
    <10s.
  - **maintainer (extending later)**: the rule doc names the
    5-step reconciliation probe with structured receipt schema
    (`codex-post-push-reconcile/v1`) — implementable when the
    rule wakes up. The dormancy regression's tests 2 + 3 are
    the canonical wake-up signals.
  - **future worker (LLM agent)**: facing another dormant
    upstream-bug class, the worker has (a) the
    doctrine-entry-without-L-rule-numbering pattern, (b) the
    dormancy-regression-test-template, (c) the explicit
    "what-this-fix-does-NOT-do" boundary list as a scope
    discipline reference.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-ie2en
no_bead_reason=3of3_acceptance_gates_closed_dormant_rule_in_doctrine_dot_flywheel_with_7_test_dormancy_regression_no_active_push_surface_in_fleet_no_workspace-write_codex_config_so_21869_failure_mode_is_dormant_no_followup_observed_test_fires_on_invariant_regression`.
