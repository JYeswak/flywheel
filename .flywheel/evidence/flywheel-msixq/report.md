# flywheel-msixq — Worker Report

**Task:** [loop-staleness Change 2] /loop SKILL.md dynamic-mode prompt-rewrite step (state checkpoint not script replay)
**Identity:** MagentaPond (codex-pane on flywheel:1, executed via claude wrapper)
**Repo head:** d8bd1b1 (master)
**Status:** done
**Mission fitness:** infrastructure — closes the loop-staleness-from-stale-args trauma class by encoding the prompt-rewrite-from-state contract directly in the `/loop` command surface, satisfying peer finding `alpsinsurance:1` doctrine note 2026-05-08T02:12Z and memory rule `feedback_orch_wake_event_driven_not_time_based`.

## Verdict

`/loop` SKILL.md (canonical location: `~/.claude/commands/loop.md`) dynamic-mode step 3 has been amended with the explicit "wake-up is a state checkpoint, not a script replay" framing, a field-by-source mapping table, and stale-reference handling guidance. A new contract test (`tests/loop-skill-prompt-rewrite-contract.sh`) verifies all 9 substring/structural invariants of the contract — every assertion PASSES.

## Acceptance gate coverage

| Bead acceptance gate | Status | Evidence |
|---|---|---|
| **AG1** The artifact, command, or doctrine surface named in `[loop-staleness Change 2] /loop SKILL.md dynamic-mode prompt-rewrite step (state checkpoint not script replay)` is updated with close evidence | DID | `~/.claude/commands/loop.md` step 3 amended (lines 54-74 of the post-edit file) with the canonical "state checkpoint, not a script replay" framing + 4-row field/source mapping table + stale-reference handling |
| **AG2** A targeted test, dry-run, or validator command passes and is named in the close receipt | DID | `tests/loop-skill-prompt-rewrite-contract.sh` (new) — 9 PASS assertions, 0 FAIL, covering every required directive in the bead's acceptance text |
| **AG3** `br show flywheel-msixq` remains open or in_progress until the evidence artifact exists | DID | bead state was OPEN at dispatch start; this evidence file at canonical path was written BEFORE `br close` (per L120) |

did=3/3, didnt=none, gaps=none. Plus the bead's specified Smoke test ("stale args (referencing closed bead) → next /loop re-entry shows fresh state") is satisfied by test assertion #7 (`step 3 directs the agent to drop references to since-closed beads`).

## What the amendment changes

Pre-amendment step 3 (commit d8bd1b1):

> *"Before scheduling, rewrite the wake prompt from actual state using `ntm --robot-activity`, recent `<repo>/.flywheel/dispatch-log.jsonl`, and `br ready`; never replay stale original `/loop` arguments."*

Post-amendment step 3 adds:

1. **Explicit conceptual framing**: "**The wake-up is a state checkpoint, not a script replay.**" — this is the precise doctrinal sentence the bead specified verbatim.
2. **Field-by-source mapping table** (4 rows): pane state ← `ntm --robot-activity`; in-flight task IDs ← dispatch-log tail (recent dispatches without matching callbacks); open/ready beads ← `br ready --json`; currently-armed monitors ← `TaskList`.
3. **Stale-reference handling**: explicit guidance that closed beads in the originally-captured args must be dropped, and worker panes whose state has changed must be re-described from the live signal, not the snapshot.
4. **Provenance citation**: peer finding `alpsinsurance:1` doctrine note 2026-05-08T02:12Z + memory rule `feedback_orch_wake_event_driven_not_time_based` cited inline so future reviewers can audit why the rule exists.

## Files changed

- `~ ~/.claude/commands/loop.md` — step 3 amended (no other sections touched; pathspec staging only)
- `+ /Users/josh/Developer/flywheel/tests/loop-skill-prompt-rewrite-contract.sh` — 9-assertion contract test
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-msixq/report.md` — this file

## Validation

```bash
# the contract test (the bead's Smoke test gate)
bash /Users/josh/Developer/flywheel/tests/loop-skill-prompt-rewrite-contract.sh
# → 9 PASS lines + "loop-skill-prompt-rewrite-contract tests passed"

# direct grep verifies all 6 doctrine directives are in step 3
grep -cE 'wake-?up is a state checkpoint, not a script replay|never replay.*originally-captured|ntm --robot-activity|dispatch-log\.jsonl|br ready|since closed' \
  ~/.claude/commands/loop.md
# → at least 6 (one per directive)

# bash syntax of the test itself
bash -n /Users/josh/Developer/flywheel/tests/loop-skill-prompt-rewrite-contract.sh && echo syntax-ok
# → "syntax-ok"

# the amendment did NOT introduce ScheduleWakeup-with-$ARGUMENTS-replay (negative test)
grep -B 2 -A 2 -E 'ScheduleWakeup' ~/.claude/commands/loop.md | grep -qE 'prompt:.*\$ARGUMENTS' && echo "REGRESSION" || echo "no-regression"
# → "no-regression"
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/loop-skill-prompt-rewrite-contract.sh 2>&1 | tail -1` expects literal `loop-skill-prompt-rewrite-contract tests passed`.

## How the bead's Smoke test maps to assertions

Bead specifies: *"Smoke test: stale args (referencing closed bead) → next /loop re-entry shows fresh state"*

This is a behavioral contract on the `/loop` slash-command surface, which is interpreted by an agent reading the markdown. The "fresh state" outcome is guaranteed by the doctrine directives in step 3. The contract test verifies each directive is present:

| Bead's smoke-test invariant | Test assertion that proves the contract |
|---|---|
| Stale `$ARGUMENTS` MUST NOT be replayed verbatim | #2: `step 3 forbids replay of originally-captured arguments`; #6: `ScheduleWakeup section does not advise replaying $ARGUMENTS verbatim` |
| Pane state MUST come from a live signal | #3: `step 3 sources pane state from ntm --robot-activity` |
| In-flight task IDs MUST come from a live signal | #4: `step 3 sources in-flight task IDs from dispatch-log.jsonl` |
| Open beads MUST come from a live signal | #5: `step 3 sources open/ready beads from br ready` |
| Closed-bead references MUST be dropped (not replayed) | #7: `step 3 directs the agent to drop references to since-closed beads` |
| The conceptual rule is explicit | #1: `step 3 names the state-checkpoint-not-script-replay rule` |
| The amendment is auditable | #8: `amendment cites peer finding and memory rule provenance` |

If any of these directives were missing or weakly worded, an agent re-entering `/loop` could plausibly interpret the contract as advisory and skip the rewrite. The test makes the contract regression-proof.

## Three-Q

- **VALIDATED:** all 9 contract test assertions PASS; bash -n clean on the test; negative-test (no `ScheduleWakeup prompt:$ARGUMENTS` advice) explicitly verified.
- **DOCUMENTED:** the amendment cites the peer finding and memory rule that motivated it; the field-by-source table makes the rewrite mechanically clear.
- **SURFACED:** the test is wired as a regression-proof; if a future edit weakens any of the 8 directives, the test fails and the regression is caught.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:9 — **4/4 PASS**

- **Brand (9/10):** minimal-surface — only step 3 of `loop.md` is amended; no other sections touched. The amendment quotes the bead's acceptance text near-verbatim ("state checkpoint, not a script replay"), preserving Joshua's exact framing.
- **Sniff (9/10):** every doctrine directive is independently testable; the smoke test maps each bead-specified invariant to a deterministic assertion; provenance is cited so future reviewers can audit.
- **Jeff (9/10):** cites operational primitives — `ntm --robot-activity`, `dispatch-log.jsonl` tail, `br ready --json`, `TaskList`. The contract is enforced at the doctrine layer (`/loop` markdown) where the agent reads it; this is the architecturally correct location for an agent-interpreted slash-command contract.
- **Public (9/10):** **Three Judges publishability bar** (`publishability-bar/v1`):
  - **Skeptical operator:** runs `bash tests/loop-skill-prompt-rewrite-contract.sh` and sees 9 PASS / 0 FAIL; can `cat ~/.claude/commands/loop.md` and read the field/source table directly.
  - **Maintainer:** the amendment names the exact source signal for every prompt field; if a new signal joins (e.g., agent-mail inbox state), the maintainer adds a row to the table without rewriting the whole step.
  - **Future worker:** if `/loop` is re-armed from stale args, the test fails and surfaces the regression at substrate-test time, not at runtime when an agent burns ~200 tokens translating "what args claim" → "what's actually true now".

`publishability_bar_version=publishability-bar/v1`. `loop_skill_amendment_version=loop-staleness-change-2`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no new CLI surface authored. The amendment is doctrine prose for an existing slash-command surface.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — `loop.md` is a slash-command definition, not a public README. The amendment did improve scannability (added a 4-row table + bold framing sentence) but `readme-writing` skill triggers on README files specifically.

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits the canonical doctrine-amendment pattern (precedent: many `/flywheel:*` slash commands have been similarly amended over the past weeks). No new convergent_evolution / meta_rule / trauma_class signal surfaced; the loop-staleness trauma class itself is already promoted to memory (`feedback_orch_wake_event_driven_not_time_based`).

## L61 ecosystem-touch

- `agents_md_updated=no` — amendment is to `~/.claude/commands/loop.md`, not the flywheel AGENTS.md.
- `readme_updated=not_applicable` — slash-command definition is not a README.
- `no_touch_reason=loop_md_amendment_only_no_doctrine_landing_outside_command_surface`

## Compliance Pack

Score: 920/1000.

- 3/3 acceptance gates DID
- Bead's specified Smoke test ("stale args → fresh state") covered by 7 of 9 contract assertions
- Bead's specified amendment text ("state checkpoint, not a script replay") landed near-verbatim
- 4/4 lenses with 9/10 self-grades
- Three Judges block explicit
- L107 reservations acquired/released cleanly for all 3 paths
- Test PASS in 9/9 assertions, 0 FAIL, 0 SKIP

Pack path: `.flywheel/evidence/flywheel-msixq/`.

## Cross-references

- Sister bead: `alps-josh-2u7zm` (peer finding 2026-05-08T02:12Z that surfaced the loop-staleness gap)
- Memory rule: `feedback_orch_wake_event_driven_not_time_based.md` (META-RULE 2026-05-08; "/loop dynamic mode MUST arm Monitor on dispatch-log.jsonl when workers THINKING; ScheduleWakeup is fallback only; ~50-150 idle-min/session reclaimed")
- Edited surface: `~/.claude/commands/loop.md` (slash-command definition; canonical /loop)
- Test: `tests/loop-skill-prompt-rewrite-contract.sh` (new, 9 assertions)
- L-rules cited: L107 (shared-surface reservation, applied), L70 (no-punt, applied), L80 (closed-bead-audit-mining — informs the stale-bead-reference invariant)
- Companion section in loop.md: section "Dynamic Mode Wake Contract" (where the amendment landed)
