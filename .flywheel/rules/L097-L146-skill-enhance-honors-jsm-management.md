## L146 — SKILL-ENHANCE-HONORS-JSM-MANAGEMENT

---
id: L146
title: Skill-enhance honors JSM management
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: jsm-managed-skill-direct-edit-overwrite
---

Skill-enhance dispatches MUST classify the target skill through JSM before any
live skill-file mutation. A skill present in `jsm list --json` with saved,
Jeffrey, or installed metadata is JSM-managed. JSM-managed skills are not edited
directly under `~/.claude/skills`; workers produce a `jsm-push-ready` patch
artifact and leave live mutation to the owning JSM/skillos flow. Unmanaged
skills may be edited directly only when the worker also writes a
`jsm-import-ready` patch artifact for later import.

**How to apply:**
- Skill-enhance dispatch packets must include a pre-flight command equivalent
  to `jsm status <skill-name> --json` plus the
  `.flywheel/scripts/skill-enhance-jsm-discipline.sh --validate-packet` gate.
- Managed target: direct mutation is forbidden; evidence names the
  `jsm-push-ready` patch artifact and the no-direct-mutation reason.
- Unmanaged target: direct mutation requires a paired `jsm-import-ready` patch
  artifact in the callback evidence.
- Audit rows for waves that already touched skills must classify each target as
  managed/unmanaged and preserve any managed-skill live diff as a patch artifact
  before cleanup or owner routing.

**Forbidden outputs:**
- Dispatching "edit `~/.claude/skills/<skill>/SKILL.md`" for a JSM-managed
  skill without a patch-only path.
- Running `jsm push` for a Jeffrey/JSM-managed skill without ownership and
  explicit attestation authority.
- Treating `jsm pull` as a recovery path; this installed JSM has no `pull`
  subcommand.
- Closing skill-enhance work with no `jsm-push-ready` or `jsm-import-ready`
  artifact.

**Evidence:** bead `flywheel-ljrjw`; audit
`.flywheel/receipts/flywheel-ljrjw/jsm-skill-audit.md`; patch artifact
`.flywheel/receipts/flywheel-ljrjw/managed-skill-direct-edits.patch`; gate
`.flywheel/scripts/skill-enhance-jsm-discipline.sh`; regression
`tests/skill-enhance-jsm-discipline.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L50, L51, L61, L94, L121, L143, and JSM discipline in
`~/.claude/references/claude-md-jsm.md`.

