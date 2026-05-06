---
description: Snapshot and restore flywheel fleet state after reboot, pane loss, or session recovery.
allowed-tools: Bash, Read, Write, Edit, mcp__socraticode__codebase_list_projects
---

# /flywheel:recovery

Use the `flywheel-recovery` skill. This is the canonical fleet-wide recovery
surface; `/flywheel:handoff` remains per-repo, and `/flywheel:respawn` remains
pane-level.

## Args

```text
/flywheel:recovery snapshot [--session <name>] [--reason <slug>] [--dry-run]
/flywheel:recovery restore [--snapshot <id|path>] [--dry-run] [--apply]
/flywheel:recovery list [--json]
/flywheel:recovery diff <snapshot-id|path> [--json]
```

## snapshot

Goal: write `~/.flywheel/recovery/<ts>.json` and
`~/.flywheel/recovery/restore-fleet-<ts>.sh`.

Steps:

1. Read `~/.claude/skills/flywheel-recovery/SKILL.md`.
2. Create `~/.flywheel/recovery/`.
3. For each target session, collect:
   - `ntm health <session> --json`
   - `ntm activity <session>`
   - `ntm save <session>`
   - repo-local `br list --status=in_progress --json`
   - repo-local dispatch log rows without callbacks
4. Run `/flywheel:handoff` logic for repo-level state capture; do not interrupt
   workers.
5. Capture launchd loop labels, Socraticode indexed project count, watchtower
   freshness, and pinned versions for `codex`, `ntm`, `br`, `dcg`, `cass`, and
   `mcp_agent_mail`.
6. Write a manifest matching
   `~/.claude/skills/flywheel-recovery/references/MANIFEST-SCHEMA.md`.
7. Validate with:

   ```bash
   ~/.claude/skills/flywheel-recovery/scripts/validate-snapshot.sh \
     ~/.flywheel/recovery/<ts>.json
   ```

8. Generate restore script from the manifest. The script must be idempotent,
   fail-open, and must report `already_present[]`, `restored[]`, and `failed[]`.

## restore

1. Select the requested snapshot or latest valid snapshot.
2. Validate the snapshot before mutation.
3. Diff current fleet state against the manifest.
4. If `--dry-run`, print planned actions and stop.
5. If `--apply`, run the generated restore script.
6. Continue if one pane/session fails; append the failure to the receipt.
7. Verify:
   - pane counts match manifest or are listed in `failed[]`
   - agent types match manifest or are listed in `failed[]`
   - `ntm health <session> --json` is readable
   - repo-local `br ready --json` is readable
8. Write restore receipt under `~/.flywheel/recovery/receipts/`.

## list

List manifests under `~/.flywheel/recovery/` with created time, reason, session
count, and validator status. `--json` emits an array.

## diff

Compare current sessions, panes, agent types, launchd loop labels, and in-flight
dispatches against the selected manifest. This command is read-only.

## Clean Predicate

Recovery is clean only when:

- latest manifest validates
- restore receipt has no untriaged `failed[]` row
- all restored sessions have readable `ntm health`
- repo-local beads are readable
- callback route is verified or explicitly listed as failed

## Constraints

- Do not remove `/Users/josh/Desktop/restore-fleet.sh` until canonical recovery
  is verified in a real reboot or equivalent drill.
- Do not auto-load cron or launchd from this command.
- Do not rely on prose-only resume notes when a manifest is available.
