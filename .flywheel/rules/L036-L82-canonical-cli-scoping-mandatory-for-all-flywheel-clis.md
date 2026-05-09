## L82 — CANONICAL-CLI-SCOPING-MANDATORY-FOR-ALL-FLYWHEEL-CLIS

---
id: L82
title: Canonical CLI scoping mandatory for all flywheel CLIs
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: partial-cli-surface
---

Every flywheel CLI surface MUST implement the canonical CLI scoping contract
from `~/.claude/skills/canonical-cli-scoping/SKILL.md` before it is treated as
real operator substrate. CLI work may not ship as a narrow command helper with
doctor/health/repair, validation, self-documentation, schema, and mutation
discipline deferred to a future bead.

**How to apply:**
- Every new or extended CLI dispatch cites `canonical-cli-scoping` and embeds
  its implementation checklist in the bead acceptance gates.
- Before claiming a console-script name, run `which <name>` / `command -v
  <name>` and prove no collision or intentional ownership.
- Every CLI provides `doctor`, `health`, `repair`, `validate`, `audit`, `why`,
  `--info`, `--examples` or `examples`, `quickstart`, `help <topic>`,
  `completion <shell>`, `schema <command>`, and `--json` everywhere.
- Mutating commands provide `--dry-run`, `--explain`, idempotency keys, and an
  audit log. Dry-run JSON uses planned-only keys; applied JSON uses
  actual-only keys.
- Every CLI publishes stable JSON schemas and canonical exit codes:
  0 success, 1 expected/domain failure, 2 usage, 3 transient/upstream, 4 gate
  blocked, 5+ documented domain-specific codes.
- Implementation callbacks run
  `~/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh <cli>`
  and report PASS/FAIL for every checklist cluster, not only the quick checker.

**Forbidden outputs:**
- "CLI shipped" when only the happy-path domain command exists.
- Deferring doctor/health/repair, schema output, JSON mode, or mutation
  dry-run/idempotency to an unnamed future pass.
- Adding a flywheel CLI command without a name-collision precheck.
- Treating internal helper commands as exempt when agents or operators depend
  on them for live decisions.

**Evidence:** bead `flywheel-ic6`; parent epic `flywheel-ntf`; `flywheel-qnc`
for `flywheel-readme`; incident
`INCIDENTS.md#canonical-cli-scoping-missed-on-new-cli-design`; plan
`.flywheel/plans/cross-pane-protocol-2026-05-01/04-XPANE-SYNTHESIS.md`.

**Companion rules:** L61 (wire doctrine into AGENTS/README), L65 (CLI identity
proof), L71 (validate-and-redispatch discipline), L80 (DID/DIDNT/GAPS
callbacks), `canonical-cli-scoping`, and the `flywheel-ntf` repair epic. The
source bead requested L70 for this doctrine, but L70 was already allocated to
ORCH-NO-PUNT before this bead landed; L82 preserves canonical ID uniqueness.

