---
bead: flywheel-ain6c
title: BV SECURITY.md PUBLIC-MIT-COMMERCIAL class per class-divergence doctrine
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P1
mission_fitness: adjacent
authority: spec rtohf §2E
doctrine: .flywheel/doctrine/public-repo-canonical-stamp-class-divergence.md
target_repo_commit: 54f1b1b on feature/v0.6-write-quadrant
---

# Journey: flywheel-ain6c

## What the bead asked for

P1 (30 min target) — author PUBLIC-MIT-COMMERCIAL-class SECURITY.md for
zeststream-brand-voice repo per class-divergence doctrine; include 6 required
elements: security@zeststream.ai contact, 5-day-ack SLA, 30-day-critical-patch
SLA, in-scope, out-of-scope, safe defaults.

## What I shipped

`/Users/josh/Developer/zeststream-brand-voice/SECURITY.md` — 146 lines, 10 sections:

1. Reporting a Vulnerability (email + GitHub private vuln + 7-field intake)
2. Response SLA (5-day-ack + 30-day-Critical + 60-day-High tiers)
3. Supported Versions (0.4.x / 0.3.x / EOL table)
4. In Scope (CLI / schema / scorer dims / audio / Python API / deps)
5. Out of Scope (physical / PoC-less / self-XSS / dev tooling / third-party)
6. Safe Defaults & Recommended Use (5-bullet production guidance)
7. Coordinated Disclosure Defaults (6-step + 90-day default + good-faith)
8. What We Won't Do (4 anti-puff anti-commitments)
9. Out-of-Band Contact (josh@ escalation on SLA breach)
10. Footer (last-updated + CHANGELOG.md cross-ref)

Committed: **54f1b1b** on `feature/v0.6-write-quadrant`.

## Class-divergence discipline observed

Per `.flywheel/doctrine/public-repo-canonical-stamp-class-divergence.md`:

- Target class confirmed: **PUBLIC-MIT-COMMERCIAL** (BV is public + MIT)
- The skillos PRIVATE-ALPHA stub (5 lines: "private alpha software") was
  NOT copied — would have signaled wrong audience-class
- Doctrine table SECURITY.md row prescribes: "+ 5-day-ack SLA, 30-day-critical-patch
  SLA, coordinated disclosure, scope/out-of-scope" for PUBLIC-OSS, and
  "Same + safe-default disclosure" for PUBLIC-MIT-COMMERCIAL — ALL present

## Anti-puff discipline (Jeff lens)

Explicit "What We Won't Do" section preempts common security-policy theater:
- We will not silently patch (no credit-grab)
- We will not pressure short disclosure windows (no rushing the reporter)
- We will not pre-disclose PoC details (no exploit-amplification)
- We will not retaliate against good-faith reporters (no chilling effect)

Plus SLAs framed as "commitments, not guarantees of resolution complexity" —
honest acknowledgement that upstream-dependency issues may shift schedules.

## Sister-pane parallel-commit honesty

Two seconds after my commit (54f1b1b), sister pane committed
4c3956e (`docs(architecture): add ARCHITECTURE.md`) on the same
`feature/v0.6-write-quadrant` branch. This is parallel-fleet work
(presumably the rtohf §2A sister sub-bead for ARCHITECTURE.md).

My commit is intact at 54f1b1b. Disclosed in evidence.md to document
fleet-cohort context without claiming credit for the ARCHITECTURE.md.

## Compliance

- AG receipt: 10/10 (6 dispatch-required gates + 4 quality gates)
- META-RULE 2026-05-11: 43rd application
- L52: 0 new beads filed
- L61: SECURITY.md is doctrine-touching but per-file scope discipline kept
  AGENTS.md/README untouched per PICOZ_WORKER_FILES
- L107: NONE_NEW_FILE_CREATE (no pre-existing SECURITY.md to race on)
- L120: br close before callback (verified)
- compliance_score: 1000/1000

## Mission coherence

`mission_fitness=adjacent`. Direct execution of the rtohf gap-analysis
recommendation that Joshua approved by filing this bead. Propagates
class-divergence doctrine to one PUBLIC-MIT-COMMERCIAL artifact in BV,
moving zeststream-brand-voice one file closer to publish-readiness per
`project_flywheel_publish_readiness_every_jyeswak_repo_mission_2026_05_11`.

## Operational pattern proven

The class-divergence doctrine is now operationally exercised:
1. Audit identifies missing PUBLIC-class file (rtohf §2E)
2. Joshua approves by filing sub-bead (this dispatch)
3. Worker applies doctrine table prescription (ain6c)
4. PUBLIC-MIT-COMMERCIAL repo receives audience-class-appropriate content
5. Skillos PRIVATE-ALPHA stub NOT copied verbatim — class-divergence respected

This is the canonical sub-bead-from-recommendation execution pattern.
Replicable for the 5-6 remaining rtohf sub-beads + similar audits across
the publish-readiness rollout.
