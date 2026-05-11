---
bead: flywheel-v38e1.3
title: Promote inbox-discipline-missed-during-deep-burndown-motion to flywheel doctrine canonical
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE
priority: P1
mission_fitness: adjacent
parent: flywheel-v38e1
---

# v38e1.3 evidence pack — inbox-discipline doctrine promotion

## What this bead does

Promotes the durable rule `inbox-discipline-missed-during-deep-burndown-motion` from skillos fuckup-log (`~/.local/state/flywheel/fuckup-log.jsonl`, ts=`2026-05-11T17:00:00Z`) to flywheel canonical doctrine.

## Source

Origin: `skillos:1` 2026-05-11T09:30-16:35Z accumulated 5 mobile-eats:1 handoffs during a 9-tick Shape B burndown chain without checking `.flywheel/handoffs/`. Joshua surfaced via `/login` channel at ~16:50Z. Skillos:1 acknowledged at 17:00Z and logged the durable rule.

The skillos handoff `20260512T000000Z-from-skillos-1-to-flywheel-1-WAVE-2-DOCTRINE-COHORT-PROMOTION-READY.md` formally requests fleet-wide canonical promotion of the 4 durable rules (this bead handles the 17:00Z entry).

## Acceptance gates (implicit; bead body empty)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | Author flywheel doctrine file for inbox-discipline rule | DID | `.flywheel/doctrine/inbox-discipline-missed-during-deep-burndown-motion.md` (5191 bytes) |
| 2 | Cite source fuckup-log entry with ts | DID | doctrine `promoted_from: skillos-fuckup-log-2026-05-11T17:00:00Z` frontmatter |
| 3 | Include canonical rule text verbatim or rephrased | DID | doctrine `## Rule (canonical)` section |
| 4 | Cross-reference sister rule (outbox-discipline) | DID | doctrine `## Sister rule (inverse direction)` section + cross-references list |
| 5 | Cross-reference cohort siblings (v38e1.1, v38e1.2, v38e1.4) | DID | doctrine `## Cross-references` section |
| 6 | Frontmatter parseable (YAML) | DID | frontmatter blocks `---` parse cleanly with `title/type/created/promoted_from/canonical_class/status` |
| 7 | Status marked canonical | DID | frontmatter `status: canonical` + body `Status: canonical, promoted 2026-05-11` |

`did=7/7`, `didnt=none`, `gaps=none`.

## L112 probe

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/doctrine/inbox-discipline-missed-during-deep-burndown-motion.md && head -1 /Users/josh/Developer/flywheel/.flywheel/doctrine/inbox-discipline-missed-during-deep-burndown-motion.md
```

Expected: literal `---` (YAML frontmatter opening).

## Files changed

- `.flywheel/doctrine/inbox-discipline-missed-during-deep-burndown-motion.md` — new canonical doctrine (5191 bytes)
- `.flywheel/audit/flywheel-v38e1.3/evidence.md` — this evidence pack

## Mission fitness

`mission_fitness=adjacent`. Codifying inbox-discipline doctrine supports the continuous-orchestrator-uptime-self-sustaining-fleet mission anchor by hardening the bilateral cross-orch communication protocol that prevents silent handoff accumulation during burndown chains. Affects every orchestrator pane in the fleet.

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. This is a canonical doctrine promotion (already-validated rule from skillos fuckup-log); no new pattern emerged.

## Four-Lens Self-Grade

- Brand: 9/10 — flywheel-canonical-doctrine class, frontmatter follows scaffold convention, cross-referenced sibling doctrines
- Sniff: 9/10 — 7/7 implicit gates DID, source-cited, evidence-pathed
- Jeff: 9/10 — cross-orch bilateral protocol formalized (sister rule referenced for outgoing direction)
- Public: 8/10 — three judges: skeptical operator can see "when to apply"; maintainer can extend with new sister rules; future worker can mechanize via the bash snippet
