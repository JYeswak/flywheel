# Publication Completion Audit

Date: 2026-05-12
Objective: Get `/Users/josh/Developer/flywheel` ready for publication.

This audit maps the explicit publication requirements from the resumed goal to
concrete artifacts and verification commands. Passing a single doctor or test is
not treated as completion by itself.

## Success Criteria

1. Public front door explains Flywheel to a business owner without requiring a
   deep substrate dive.
2. The repo honestly explains upstream substrate, ZestStream's role, and how
   project lessons compound.
3. First-run docs and commands support both reduced local mode and full
   substrate detection.
4. Support copy distinguishes NTM and non-NTM workflows across Claude, Codex,
   Gemini, OpenClaw, and reduced local mode.
5. Naming conventions, including Yuzu Method boundaries, are documented and
   verified.
6. Doctor and watcher surfaces run as designed, with hard blockers cleared and
   residual warnings classified.
7. Install, uninstall, journey smoke, closeout validation, and inspection have
   executable proof.
8. Long-running publication checks are profiled or narrowed when a
   behavior-preserving optimization is available.
9. SkillOS and Mobile Eats are treated as adjacent proof/control surfaces, not
   silently absorbed into Flywheel.

## Prompt-To-Artifact Checklist

| Requirement | Artifact or command | Evidence | Status |
|---|---|---|---|
| SMB/business-owner trust story | `README.md`, `CHARTER.md` | README opens with the disconnected-systems problem, ZestStream method, upstream adoption, doctors, receipts, and lessons compounding. Charter records the longer business-owner framing. | covered |
| "Peel back the curtain" without forcing deep dive | `README.md`, `docs/getting-started/first-run.md` | README links the public first run before operator internals. First-run guide gives the inspectable path from preflight to next action. | covered |
| Honest upstream attribution / Jeff substrate | `CHARTER.md`, `docs/brand/naming-conventions.md`, README runtime surfaces | Charter names Dicklesworthstone-derived substrate and explains adoption/verification. Naming doc prevents renaming upstream into ZestStream-owned terms. | covered |
| Every project improves reusable substrate | `CHARTER.md`, `README.md`, `.flywheel/PUBLISHABILITY-AUDIT.md` | Charter states lessons, receipts, guards, and patterns compound. README now repeats the operating method at the front door. | covered |
| Public first-run journey | `docs/getting-started/first-run.md`, `scripts/journey-smoke.sh`, `tests/journey-smoke.sh` | Reduced mode is runtime-proven through init, doctor, tick, dispatch-or-simulate, closeout validation, and inspect. | covered |
| NTM and non-NTM workflows | `docs/getting-started/first-run.md`, `scripts/preflight.sh`, `scripts/journey-smoke.sh`, `bin/flywheel` | Preflight detects full substrate including NTM/Agent Mail and selects reduced mode when absent. Journey smoke keeps harness lanes registry-valid until runtime proof. | covered |
| Claude/Codex/Gemini/OpenClaw support tiers | `scripts/journey-smoke.sh` | Claude/Codex are `supported-first`; Gemini/OpenClaw are `compatibility-target`; reduced mode is `required-fallback`. | covered |
| Yuzu naming plan | `docs/brand/naming-conventions.md`, `tests/naming-conventions.sh` | Canonical terms and rename gate are documented; test checks core terms and doctrine references. | covered |
| Doctor hard blockers cleared | `flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` | Final doctor status is `warn` with `errors=[]` and `repo_docs_state=ready` after lock repair; publishability, repo-local CLI floor, watcher, and Agent Mail FD pressure are passing. | covered |
| Frozen pane / watcher system runs as designed | `.flywheel/scripts/frozen-pane-detector.sh`, watcher tests | Detector self-test covers classes A-G, preview-only recovery, apply gates, and watcher local/fleet probes. | covered |
| Install and uninstall trust | `install.sh`, `uninstall.sh`, `tests/installer-smoke.sh` | Installer smoke validates dry-run, install, reduced first-run, idempotent reinstall, uninstall, and empty-prefix removal. | covered |
| Speed on long checks | `tests/publishability-bar.sh` | Replaced full-doctor proxy assertion with source-wiring plus direct packet proof; runtime dropped from 17.15s to about 1.2s. | covered |
| SkillOS coordination | Agent Mail contact request to SkillOS bridge, `tests/o4b4h-skillos-journey-alignment-receipt.sh` | Fresh Agent Mail message to `JadeFinch` is blocked by contact approval policy and has a pending request. Local SkillOS journey-alignment test was repaired after finding lifecycle drift; it now proves the Layer-1 journey-entry schema and journal substrate landed. | covered_with_live_ack_pending |
| Mobile Eats journey semantics | `CHARTER.md`, `scripts/journey-smoke.sh`, `tests/o4b4h-skillos-journey-alignment-receipt.sh` | Charter keeps Mobile Eats as journey proof input, not Flywheel product meaning. Journey smoke implements persona/first value/return loop/guardrail shape. SkillOS/Mobile Eats alignment receipt test passes after inversion for shipped journey-entry substrate. | covered |
| Publication audit trail | `.flywheel/PUBLISHABILITY-AUDIT.md`, this file | Publishability audit is updated with current doctor/speed evidence; this file maps explicit prompt requirements to artifacts. | covered |

## Known Residual Warnings

The full repo doctor can remain `warn` while publication hard blockers are clear.
Current residual warning classes are fleet/backlog hygiene:

- fleet L-rule lag across sibling repos;
- mixed watcher fleet status outside this repo;
- oversized legacy files;
- callback and validation backlog;
- closed-bead artifact and reopen-candidate backlog;
- plan-state quality warnings;
- Jeff corpus storage yellow.

These are tracked as operational hygiene, not blockers for publishing the
current public-preview Flywheel surface. Strict full-fleet green remains a later
hardening goal.

Repo-doc lock drift was found during this audit and repaired with
`flywheel-lock-repair --apply --idempotency-key publication-lock-repair-20260512`;
the follow-up doctor reports `repo_docs_state=ready`.

## Live Coordination Note

An Agent Mail contact request to the active SkillOS bridge (`JadeFinch`) is
pending. Contact policy prevents direct delivery from this new Codex identity
until the recipient approves. Local SkillOS-boundary and journey-alignment
evidence is present and passing; a live SkillOS acknowledgement should be
recorded as follow-up evidence when contact approval completes.

## Completion Decision

Publication-ready here means public-preview ready with honest limitations:
reduced local mode is executable and runtime-proven; full multi-agent harness
lanes are detected and named as targets until runtime receipts exist.

Do not claim "fully supported Gemini/OpenClaw runtime" or "fleet-wide strict
doctor green" from this audit.
