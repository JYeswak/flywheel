## L64 — JEFF-IS-MENTOR-NOT-JUST-DEPENDENCY

---
id: L64
title: Jeff is mentor not just dependency
status: long_term
shipped: 2026-05-03
review_due: 2026-11-09
trauma_class: jeff-mentor-bypass
---


L63 treats Jeff's repos as substrate to consume. L64 promotes Jeff to MENTOR
to study. The flywheel must run a daily 'what is Jeff up to / what can we
learn' snapshot AND a periodic deep-mine across all Jeff repos to extract
pattern catalog, then internalize patterns we don't already use into our own
doctrine. We are not just users of Jeff's tools; we are students of his method.

**Reason:** Joshua directive 2026-05-03 ~10:10Z: 'I want to embody his
philosophies and methods of working into our ecosystem.' Per memory entry
`feedback_meadows_jeff_mentors`, Jeff is one of TWO explicit mentors for the
flywheel (alongside Donella Meadows). Memory documents that Jeff originated
the fuckup-log concept and L-rule numbering shape that we inherited. There
are likely 10+ more patterns we use unconsciously (or fail to use) that
deeper study would surface.

**How to apply:**
- Layer 1 (deep mine, monthly): cross-repo pattern extraction via
  socraticode across all Jeff repos. Topics: state machine design, error
  handling, callback contracts, schema evolution, doctrine surfaces, README
  shape, test pyramid, telemetry, dispatch patterns, idempotency. Output
  `~/.local/state/jeff-philosophy/patterns.jsonl`.
- Layer 2 (daily snapshot, cron 06:00): pulls last-24h Jeff commits + X +
  website + GH activity + releases via L63 substrate; per-artifact 'what can
  we learn' analysis with verdict {YES_ADOPT | YES_ADAPT | NO_NOT_OUR_DOMAIN
  | NEED_RESEARCH}. Surfaces in `/flywheel:status` morning section.
- Layer 3 (internalization): when deep-mine finds a pattern Jeff uses
  everywhere that we use inconsistently, file P3 bead `adopt-jeff-pattern-<name>`
  with file:line citations. Once adopted, cite in AGENTS.md L-rule as
  'Source: Jeff <repo>:<file>:<line> + ZestStream adaptation'.
- Import contract: run `.flywheel/scripts/jeff-pattern-citation-probe.sh --json`
  before landing doctrine, skills, or plan artifacts that import mentor-corpus
  patterns. The probe exposes `jeff_pattern_uncited_count`; nonzero means the
  artifact is not ready until each import claim has the required Source line.

**Forbidden outputs:**
- Calling jeff-intel-network 'complete' without Layer 2 daily-snapshot active
- Inventing a flywheel pattern from scratch when Jeff already has a battle-tested
  version in his repos (deep-mine first)
- Writing a new L-rule without first searching the daily-snapshot stream and
  pattern catalog for Jeff's existing convention
- Citing Jeff's pattern as 'inspired by' without specific file:line evidence
- Ignoring `jeff_pattern_uncited_count > 0` after a doctrine, skill, or plan
  artifact imports mentor-corpus patterns

**Evidence:** Joshua directive 2026-05-03 ~10:10Z;
bead `flywheel-jeff-philosophy-study` (filed this turn);
`feedback_meadows_jeff_mentors` memory entry; Jeff-originated patterns we
inherited (fuckup-log, L-rule numbering, doctor surface, 7-axis rubric);
sibling rules L11, L60, L61, L62, L63; bead `flywheel-jhcd`; probe
`.flywheel/scripts/jeff-pattern-citation-probe.sh`.

**Companion rules:** L63 (substrate dependency — provides clones for mining);
L62 (latent-signal mining paradigm applied to Jeff's work); L61 (ecosystem
wire-in — this rule itself wires); `donella-meadows-systems-thinking` skill
(Donella is the OTHER mentor; Jeff joins her at the same level).

