# flywheel-ljrjw JSM Skill Audit

Bead: `flywheel-ljrjw`
Task: `flywheel-ljrjw-91a4e0`
Timestamp: 2026-05-08

## Scope

Waves 13-14 skill-enhance beads checked:

- `flywheel-ewqr`: `api-design-patterns`
- `flywheel-ftbe`: `brenner`
- `flywheel-irm9`: `cass`
- `flywheel-jf7c`: `database-modeling`
- `flywheel-npo8`: `agent-monitoring`
- `flywheel-96np`: `ecosystem-port-security`
- `flywheel-nf7x`: `beads-workflow`
- `flywheel-d7lv`: `webhook-automation`

Source of truth: serialized `jsm list --json` probe via
`.flywheel/scripts/skill-enhance-jsm-discipline.sh --audit`.

## Classification

Managed by JSM:

- `brenner` (`is_saved=true`, `is_jeffreys=true`, installed 2026-05-08)
- `cass` (`is_saved=true`, `is_jeffreys=true`, installed 2026-05-08)
- `beads-workflow` (`is_saved=true`, `is_jeffreys=true`, installed 2026-05-08)

Not found in `jsm list --json` at audit time, treated as unmanaged for this
gate:

- `api-design-patterns`
- `database-modeling`
- `agent-monitoring`
- `ecosystem-port-security`
- `webhook-automation`

## Direct-Edit Exposure

`git -C ~/.claude/skills status --short` showed live skill edits for wave
targets, including the three JSM-managed targets above. These are the direct
edits at risk of being overwritten by JSM sync/update.

Preserved managed-skill patch artifact:

- `.flywheel/receipts/flywheel-ljrjw/managed-skill-direct-edits.patch`

That patch contains the current live diffs for:

- `brenner/SKILL.md`
- `cass/SKILL.md`
- `beads-workflow/SKILL.md`

## Revert Or Promote Disposition

No `jsm push` was run. `jsm push --help` states it uploads one of your own
local skills and requires rights attestation; these three managed records are
Jeffrey/JSM-managed, so pushing them from this worker would be an ownership
violation.

No `jsm pull` was run. The installed JSM CLI reports `error: unrecognized
subcommand 'pull'`, so the dispatch packet's named recovery path is not
available on this machine.

The safe disposition for this bead is therefore:

1. Preserve current managed-skill live diffs as a `jsm-push-ready` patch
   artifact.
2. Prevent future skill-enhance packets from authorizing direct live mutation
   for JSM-managed skills.
3. Require unmanaged skill edits to emit `jsm-import-ready` patch artifacts.

## Enforcement Shipped

- `.flywheel/scripts/skill-enhance-jsm-discipline.sh`
- `tests/skill-enhance-jsm-discipline.sh`
- `.flywheel/scripts/build-dispatch-packet.sh` now injects the
  `SKILL-ENHANCE JSM DISCIPLINE BLOCK` when bead title/body references
  skill-enhance or `~/.claude/skills`.
- L146 added to `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, and
  `templates/flywheel-install/AGENTS.md`.
- README operating boundary updated.

## Four-Lens Self-Grade

- brand: 9
- sniff: 9
- jeff: 9
- public: 9

The public lens is 9 because the gate refuses future unsafe packets and
preserves the current risky diffs, but final cleanup of the live managed skill
working tree remains owner-routed rather than mutated by this worker.
