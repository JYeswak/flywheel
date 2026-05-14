# SkillOS Capability Boundary Draft

Created: 2026-05-12T21:27Z
Agent: TopazMeadow
Primary downstream bead: B16 / `flywheel-erudn`
Status: implementation input, not the B16 handoff

## Purpose

B16 must keep Flywheel's public installability work aligned with SkillOS without
turning the public release into a cross-repo negotiation or narrowing SkillOS to
one commercial proof surface. This draft defines the boundary contract and the
eventual Agent Mail topic body for `flywheel-skill-boundary-v0.2`.

This is not the B16 handoff. B16 remains blocked by B0 until the charter review
gate lands or the DAG is explicitly re-sequenced.

## Source Basis

- SkillOS pane2 correction: SkillOS GOAL rev7 is the Skills Operating System and
  capability control plane for ZestStream's AI-native pods.
- `CHARTER.md` boundaries section.
- `05-INSTALLABILITY-COVERAGE-AUDIT.md` A4 boundary amendment.
- `04-BEADS-DAG.md` B16 acceptance and 14-day SLA fallback.
- `07-CHARTER-REVIEW-PACKET.md` charter mapping.
- `ARCHITECTURE.md` Flywheel control-plane scope.
- `agent-governance` skill: production agents need explicit ownership,
  policy-bound action, audit trail, and exception expiry.

## Boundary Statement

Flywheel owns the public operating loop around agentic coding:

- public engine extraction and depersonalization;
- installer, preflight, reduced-mode resolver, and uninstaller;
- repo-local initialization templates;
- doctrine, L-rules, closeout contracts, and public publishability gates;
- doctor, tick, dispatch-or-simulate, validated closeout, and inspection;
- Beads workflow shape and dependency discipline;
- Agent Mail coordination expectations and file-reservation doctrine;
- Socraticode-first investigation gate for non-trivial repo work;
- public docs and website surfaces that teach the first-run journey.

SkillOS owns the capability control plane:

- capability-loop substrate;
- skill-surface governance and publication discipline;
- Jeff-stack capability ingestion;
- research-triad signal and capability evaluation;
- skill promotion, ratification, and rollback policy;
- validated self-improving capability loops;
- agent/skill governance state that should not be copied into public Flywheel
  artifacts.

Flywheel integrates with SkillOS. It does not redefine the SkillOS mission.

## Proof-Surface Rule

Red Hat/SMB positioning and Mobile Eats journey semantics are proof surfaces,
not the whole mission.

| Proof surface | What Flywheel may use | What Flywheel must not claim |
|---|---|---|
| Red Hat/SMB | Commercial explanation of why a supported agentic stack matters. | SkillOS exists only for SMB or only as fleet rollout support. |
| Mobile Eats L170 | Journey vocabulary: persona, first value, return loop, guardrail, evidence state. | Flywheel owns Mobile Eats product semantics or data fixtures. |
| SkillOS Phase A/L169/L170 | Capability-loop and skill-surface evidence feeding public installability. | Flywheel owns SkillOS' control-plane implementation or local doctor gates. |

## B16 Acceptance Shape

B16 should close only when the handoff evidence has all of these:

| Requirement | Evidence |
|---|---|
| Agent Mail topic exists | topic `flywheel-skill-boundary-v0.2` |
| Recipient path is live | sent to SkillOS pane/orchestrator via Agent Mail or NTM callback with durable receipt |
| Boundary is explicit | body contains the ownership bullets above |
| Proof surfaces are scoped | body states Red Hat/SMB and Mobile Eats are proof surfaces, not mission ceilings |
| SLA is non-blocking | either `acknowledged_at` is non-null or `auto_locked_at` is at least 14 days after `created_at` |
| Public release fallback is clear | if no ack, v0.2 ships zero ambient SkillOS skills and documents SkillOS as future/full-mode capability substrate |
| Private-state guardrail is named | body says private SkillOS state is source evidence only and cannot be copied into public Flywheel |

The SLA fallback prevents B16 from dragging v0.2 while still preserving the
governance trail.

## Proposed Handoff Body

```markdown
Subject: flywheel-skill-boundary-v0.2

Flywheel public-share B16 boundary proposal.

Flywheel owns public installability and the loop engine: extraction,
depersonalization, installer/preflight/reduced mode, repo init, doctor, tick,
dispatch-or-simulate, validated closeout, Beads inspection, templates, doctrine,
and public docs/website first-run surfaces.

SkillOS owns the capability control plane: capability-loop substrate,
skill-surface governance, Jeff-stack capability ingestion, research-triad signal,
skill promotion/ratification/rollback, and validated self-improving capability
loops.

Red Hat/SMB positioning and Mobile Eats L170 journey semantics are proof
surfaces. They do not narrow SkillOS' mission and they do not make Flywheel the
owner of SkillOS or Mobile Eats semantics.

For v0.2, Flywheel may document SkillOS as the capability-control-plane
integration point. It must not copy private SkillOS state into public artifacts.
If this topic is not acknowledged within 14 days, Flywheel locks a zero-ambient-
skills public release stance: public Flywheel ships the interface and docs, while
specific SkillOS capability packs wait for later ratification.
```

## Public Documentation Constraint

Public Flywheel docs should say:

- "SkillOS is the capability control plane" when explaining deeper capability
  loops.
- "Reduced mode works without SkillOS" when teaching the first-run path.
- "Full mode may integrate with SkillOS-managed capability packs" only after
  SkillOS ratification exists.

Public docs should not say:

- SkillOS is required for every first-run Flywheel install.
- Red Hat/SMB is the whole SkillOS goal.
- Mobile Eats runtime failures imply Flywheel doctrine gaps.
- SkillOS private state, local doctor output, or pane context is part of the
  public package.

## Non-Completion Note

This draft does not satisfy B16. B16 remains open until the approved handoff is
sent through the durable coordination path, receives acknowledgement or reaches
the 14-day auto-lock condition, and the public docs carry the resulting boundary.
The active public-installability goal remains incomplete.
