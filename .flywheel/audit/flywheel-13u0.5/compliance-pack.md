# flywheel-13u0.5 compliance pack

Task: `flywheel-13u0.5-c4357a`
Bead: `flywheel-13u0.5`
Identity: `CloudyMill`
Date: 2026-05-09

## Scope

Disposition for `[incidents-followup] br source_repo dot after create local doctrine disposition`.

This worker did not edit `INCIDENTS.md`. The task asks for a local doctrine decision, and the accepted no path is closeout with `no_followup_needed` plus upstream-owner citation.

## Decision

Decision for the exact class `br-source-repo-dot-after-create`: `no_followup_needed`.

Do not add a separate local `INCIDENTS.md` entry for `br-source-repo-dot-after-create`.

Rationale:

- The durable upstream owner exists: `flywheel-5ktw` / beads_rust#273.
- Live GitHub page for `https://github.com/Dicklesworthstone/beads_rust/issues/273` shows issue #273 is `Closed`.
- `flywheel-5ktw` is closed and says Jeff fixed #273 in upstream commit `03167479`, added tests in `c3417779`, rebuilt local `br` from main `3c46bea`, and verified the post-fix probe no longer returned `source_repo='.'`.
- `flywheel-f505` is closed and records the same Jeff response triage and local install/verification path.
- `flywheel-ap9n`, the promotion-candidate for `br-source-repo-dot-after-create`, is closed because a fresh fuckup-log audit found zero occurrences since 2026-05-04.
- `flywheel-13u0.4` already merged the missing draft disposition into this bead and warned not to apply the missing draft directly.

Therefore the old dot-after-create incident is owned by the upstream issue and stale-candidate receipts. A new local INCIDENTS entry would duplicate closed upstream and local tracking state.

## Distinct Current Gap

`bash tests/phase2-audit.sh` still fails local source-repo expectations:

- T2.3 found existing repo-local databases with `source_repo='.'` rows.
- T2.4 found current `br create` writes a non-absolute basename value, not the absolute repo path.

That is not the same as the exact `br-source-repo-dot-after-create` promotion request. It is a current `source_repo` hygiene/write-path regression and should be tracked separately rather than promoted as the old dot-after-create incident.

Follow-up bead filing is pending `.beads/issues.jsonl` reservation release. If the bead lane opens before callback, this pack will be patched with the follow-up bead ID.

## Missing /tmp Drafts

The packet named three `/tmp` artifacts:

- `/tmp/br_create_canonicalize_plan.md`
- `/tmp/promote-draft-br-source-repo-dot-after-create.md`
- `/tmp/promote-draft-br-source-repo-dot-after-create-round2.md`

All three were absent at execution time. Durable evidence came from Beads, `flywheel-13u0.4` audit receipts, the live GitHub issue page, and the Phase 2 audit.

## Evidence

| Claim | Evidence |
|---|---|
| Source implementation bead exists | `br show flywheel-7rr --json` returns `status=closed`, with close reason pointing to `/tmp/br_create_canonicalize_plan.md`. |
| Upstream owner exists and is closed locally | `br show flywheel-5ktw --json` returns `status=closed`, `external_ref=https://github.com/Dicklesworthstone/beads_rust/issues/273`, and close reason says Jeff fixed #273. |
| Live upstream issue is closed | GitHub issue #273 page was opened during this task and showed `Closed`. |
| Jeff response triage is closed | `br show flywheel-f505 --json` returns `status=closed` and records the local rebuild/probe path. |
| Promotion candidate is stale-closed | `br show flywheel-ap9n --json` returns `status=closed` and says zero occurrences since 2026-05-04. |
| Prior disposition merged this class here | `.flywheel/audit/flywheel-13u0.4/disposition.md` names `flywheel-13u0.5` as the live owner for this local doctrine choice. |
| Current audit reveals a distinct gap | `bash tests/phase2-audit.sh` failed T2.3 and T2.4 on 2026-05-09. |

## Acceptance Gates

AG1: Pass. Local `INCIDENTS.md` should not carry a separate `br-source-repo-dot-after-create` incident; close exact class with `no_followup_needed`.

AG2: Pass. Cited `flywheel-7rr`, `flywheel-5ktw`, and upstream beads_rust#273.

AG3: Pass. Did not apply `INCIDENTS.md`.

## Verification Commands

```bash
br show flywheel-13u0.5 --json
br dep tree flywheel-13u0.5
br show flywheel-7rr --json
br show flywheel-5ktw --json
br show flywheel-f505 --json
br show flywheel-ap9n --json
bash tests/phase2-audit.sh
bash .flywheel/receipts/flywheel-13u0.5/l112-probe.sh
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-13u0.5-c4357a.md
```

## Skill Auto-Routes

`canonical-cli-scoping=n/a`: no CLI implementation changed; this is doctrine disposition only.

`rust-best-practices=n/a`: no Rust files changed.

`python-best-practices=n/a`: no Python files changed.

`readme-writing=n/a`: no README changed.

## L61 Surface

No doctrine, canonical L-rule, skill, AGENTS, README, or `INCIDENTS.md` source was modified. `agents_md_updated=not_applicable`, `readme_updated=not_applicable`, `no_touch_reason=disposition_evidence_only_no_incidents_mutation`.

## L52 / L53

L52 for the exact class: `no_followup_needed` because upstream and local tracking are closed.

L52 for the distinct current source-repo hygiene gap: follow-up bead filing pending `.beads/issues.jsonl` reservation release.

No fuckup row was logged.

## Four-Lens Self-Grade

`four_lens=brand:7,sniff:8,jeff:8,public:8`

Brand: distinguishes the old resolved dot incident from the current non-absolute source-repo hygiene gap.

Sniff: uses durable bead records and live upstream state rather than missing `/tmp` drafts.

Jeff: preserves upstream as owner for the exact fixed issue while routing remaining local behavior separately.

Public: a skeptical operator, maintainer, and future worker can verify why no local incident was applied and why the new gap is separate.

## Compliance Score

`770/1000`

The score clears the 700 DONE bar. It is capped because the Phase 2 audit still fails for a distinct current source-repo hygiene issue.
