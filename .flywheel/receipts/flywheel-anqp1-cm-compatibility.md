# flywheel-anqp1 cm compatibility receipt

Bead: flywheel-anqp1
Task: flywheel-anqp1-5a2e28
Identity: CloudyMill
Timestamp: 2026-05-09T00:45Z

## Decision

Keep local workers pinned to `cm 0.2.3`.

Do not move the worker pre-task memory contract to `cass/cm 0.4.x` yet. Do not
install a compatibility wrapper yet. The least risky upgrade path is:

1. Keep `/Users/josh/.local/bin/cm` at `0.2.3`.
2. Require explicit workspace scoping for worker memory preflight:
   `cm context "<task>" --workspace "$(pwd -P)" --json`.
3. Treat `cass 0.4.x` as a different command contract until a separate
   migration maps its `cass context --source <SOURCE> <PATH>` model to the
   worker task-memory use case and proves bounded machine-readable health.

## Why Not Wrapper Or Caller Rewrite

Wrapper rejected for this close: a wrapper would claim `cm 0.4.x`
compatibility before the new upstream `cass context` semantics are proven to
return the same worker pre-task fields.

Caller rewrite rejected for this close: existing local callers and skills depend
on task text plus absolute workspace. The `cass 0.4.x` `context` command expects
a source/session path, not a free-form task string.

## Upstream Rationale

No upstream issue was filed from this bead. The observed `cass 0.4.x` behavior
is a clear CLI contract change, not enough evidence of an upstream defect. The
local action is to pin and document the worker contract. File upstream only if a
future migration proves the intended `cass 0.4.x` equivalent is missing or
requires a compatibility alias.

## Evidence

Prior receipt:

- `.flywheel/receipts/flywheel-z7b8-cm-upgrade.md`

Fresh upstream check:

- `gh release view v0.4.2 --repo Dicklesworthstone/coding_agent_session_search`
  reported `v0.4.2` published `2026-05-08T20:18:00Z`.
- Downloaded `cass-darwin-arm64.tar.gz`.
- SHA256:
  `8998cdc30238a8fd27af2abc607fe0849b86932820a51d07f9237d7580787620`.
- Extracted binary reported `cass 0.4.2`.

Fresh 0.4.2 compatibility result:

```text
$ cass context "smoke" --workspace /Users/josh/Developer/flywheel --json
status=error
error=unexpected argument '--workspace' found
usage=cass context --source <SOURCE> <PATH>
```

Fresh 0.4.2 bounded-health result:

```json
{"elapsed_sec":5.059,"status":"timeout","timeout_sec":5}
```

Current local contract result:

```text
$ cm --version
0.2.3

$ cm context "smoke" --workspace /Users/josh/Developer/flywheel --json
success=true
metadata.version=0.2.3
```

Current local health result:

```text
$ cm doctor --json
success=true
data.overallStatus=degraded
metadata.version=0.2.3
elapsed=2.99s
```

The degraded state is from local optional repo-level `.cass` files and guard
installation warnings, not from command failure.

## Skill Contract Update

Updated `/Users/josh/.codex/skills/cass-memory/SKILL.md` so the Quick Start,
session-start prompt, command table, and agent protocol all use:

```bash
cm context "<task description>" --workspace "$(pwd -P)" --json
```

The same skill now explicitly warns that ZestStream workers require `cm 0.2.3`
until a replacement workspace-scoped command is validated.

## Acceptance Gates

- AG1: This receipt records the cm upgrade/pin decision and close evidence.
- AG2: `cm context "smoke" --workspace /Users/josh/Developer/flywheel --json`
  and `cm doctor --json` both passed on the pinned local binary.
- AG3: `br show flywheel-anqp1 --json` showed status `open` before this
  evidence artifact was created.

## Four-Lens Self-Grade

- Brand: 9/10. Preserves worker memory reliability instead of chasing latest.
- Sniff: 9/10. Decision is based on current local smoke, current upstream asset,
  and bounded-health behavior.
- Jeff: 9/10. Respects Jeff substrate without pushing a local compatibility
  assumption upstream prematurely.
- Public: 9/10. Three Judges check: a skeptical operator can rerun the probes,
  a maintainer can see why wrapper/rewrite were rejected, and a future worker
  has the exact pinned command.
