# Publication Completion Audit

Date: 2026-05-13T21:59Z
Objective: Publish Flywheel as a renamed, public-ready agentic workflow
ecosystem with honest support claims, executable first-run proof, SkillOS
boundaries, and release blockers tracked to real closure.

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
| Claude/Codex/Gemini/OpenClaw support tiers | `scripts/isolated-agent-lane-smoke.sh --live-adapters`, `scripts/agent-lane-probe.sh --receipt-dir state/isolated-agent-lanes --json`, `state/agent-lane-runtime-audit.receipt.json` | Reduced mode is runtime-proven. Claude Code, Codex CLI, Gemini CLI, and OpenClaw all have valid isolated runtime receipts with `support_copy_allowed=true`. Codex reads auth from explicit `FLYWHEEL_CODEX_HOME` while `HOME`, XDG paths, and the target repo stay isolated; OpenClaw creates a disposable isolated agent before the smoke turn. | covered locally |
| Yuzu naming plan | `docs/brand/naming-conventions.md`, `tests/naming-conventions.sh` | Canonical terms and rename gate are documented; test checks core terms and doctrine references. | covered |
| Doctor hard blockers cleared | `flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` | Final doctor status is `warn` with `errors=[]` and `repo_docs_state=ready` after lock repair; publishability, repo-local CLI floor, NTM spawn templates, memory health, Agent Mail FD pressure, and Jeff corpus local storage are passing. | covered |
| Frozen pane / watcher system runs as designed | `.flywheel/scripts/frozen-pane-detector.sh`, watcher tests | Detector self-test covers classes A-G, preview-only recovery, apply gates, and watcher local/fleet probes. | covered |
| Install and uninstall trust | `install.sh`, `uninstall.sh`, `tests/installer-smoke.sh` | Installer smoke validates dry-run, install, reduced first-run, idempotent reinstall, uninstall, and empty-prefix removal. | covered |
| Speed on long checks | `tests/publishability-bar.sh`, `tests/jeff-corpus-accretive.sh`, `tests/jeff-corpus-doctor-scoping.sh` | Publishability bar now runs in about 1.1s. Jeff corpus scoping dropped from about 42s to 0.26s and accretive coverage dropped from about 16s to 1.38s by testing the Jeff doctor helper directly instead of paying for unrelated full-doctor probes. | covered |
| SkillOS coordination | SkillOS handoff from `JadeFinch`, `tests/o4b4h-skillos-journey-alignment-receipt.sh` | SkillOS created `/Users/josh/Developer/skillos/.flywheel/handoffs/20260513T0038Z-from-skillos-to-flywheel-mobile-eats-side-effect-and-stale-spec-substrate.md` and `/Users/josh/Developer/skillos/state/skillos-mobile-eats-side-effect-and-stale-spec-substrate-20260513T0038Z.md`; local SkillOS journey-alignment test proves the Layer-1 journey-entry schema and journal substrate landed. | covered |
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
- plan-state quality warnings.

These are tracked as operational hygiene, not blockers for publishing the
current public-preview Flywheel surface. Strict full-fleet green remains a later
hardening goal.

The former Jeff corpus storage warning was a false conflation of represented
source corpus size (`jeff_corpus_v1_total_mb=3783.3`) with local storage use
(`jeff_corpus_local_storage_mb=70.8`). The doctor now gates on actual local
storage and reports `jeff_corpus_storage_health=GREEN`.

Repo-doc lock drift was found during this audit and repaired with
`flywheel-lock-repair --apply --idempotency-key publication-lock-repair-20260512`;
the follow-up doctor reports `repo_docs_state=ready`.

## Live Coordination Note

SkillOS supplied live handoff evidence while this audit was active. The
JadeFinch handoff records two Mobile Eats-derived substrate rules for Flywheel:
durable primary writes must not be downgraded by non-critical side effects, and
generated journey compilers must remove stale specs while enforcing one-to-one
YAML/spec registry matching. A separate BlackGlen -> JadeFinch Agent Mail
contact request remains pending because the recipient contact policy requires
target approval; that does not block this audit now that SkillOS produced the
handoff evidence independently.

## Current Blocking Evidence

`python3 scripts/publication_readiness.py --release --json` still returns
`status=blocked` with these live release blockers:

- `remote_repo_private`
- `remote_workflows_missing`
- `remote_green_runs_missing`
- `github_release_missing_or_draft`
- `github_release_assets_missing`
- `joshua_release_signoff_missing`

Latest public-export evidence is `codex-public-export-20260513T2302Z`:
14,700 files classified, 10,218 copied into the staged public tree, 4,040
denylisted paths excluded, 7,444 manual-review rows retained, and
`source_git_status_unchanged=true`. Staged replay passed publication readiness
58/0, public docs 144/0, website static 72/0, user journey pack 8/0, public
links 3/0, public top-level files 21/0, release assets 12/0, cutover receipts
23/0, agent-lane probe 10/0, journey smoke 7/0, true-publication blocker
coverage 7/0, and depersonalization scan with zero findings.

## Completion Decision

The goal is not complete. The repo is materially closer to public-preview
readiness: reduced local mode is executable and runtime-proven; Claude Code,
Codex CLI, Gemini CLI, and OpenClaw now have isolated runtime receipts instead
of vague compatibility copy. Final publication still
requires the real public remote, hosted workflow proof, GitHub release/assets,
and Joshua's exact release signoff.

Do not claim "public release complete" or "fleet-wide strict doctor green" from
this audit.
