# flywheel-l95he Compliance Pack

## Dispatch

- task_id: `flywheel-l95he-528b0c`
- identity_name: `MistyCliff`
- worker_substrate: `codex-pane`
- agent_type: `codex`
- mission_fitness: `adjacent`
- mission_fitness_evidence: `Scratch cleanup helper removes recurring worker closeout friction around DCG-blocked raw tmp deletion.`

## Evidence

- Evidence receipt: `.flywheel/receipts/flywheel-l95he-528b0c-evidence.md`
- Validation receipt: `.flywheel/audit/flywheel-l95he/validation-receipt.json`
- L112 probe: `.flywheel/audit/flywheel-l95he/l112-probe.sh`

## Verification

- `bash tests/cleanup-scratch.sh`: pass; 12 checks.
- `bash -n .flywheel/scripts/cleanup-scratch.sh tests/cleanup-scratch.sh .flywheel/scripts/sync-canonical-doctrine.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-doctrine-sync`: pass.
- `shellcheck .flywheel/scripts/cleanup-scratch.sh tests/cleanup-scratch.sh`: pass.
- `bash /Users/josh/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh .flywheel/scripts/cleanup-scratch.sh`: pass; 13 checks.
- `dcg allowlist validate --robot`: pass.
- `dcg allowlist list --robot`: pass; repo-local and wrapper exact commands present.
- `/Users/josh/.local/bin/flywheel-cleanup-scratch --dry-run --json /tmp/flywheel-l95he-nonexistent | jq -e '.status == "ok" and .reason == "nonexistent_noop"'`: pass.
- `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-l95he-528b0c.md`: pass.
- `/Users/josh/.claude/skills/.flywheel/bin/flywheel-doctrine-sync --dry-run --json --repo /Users/josh/Developer/flywheel`: pass; `cleanup-scratch.sh` emitted as `copy_shared_script`.
- `plutil -lint /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-doctrine-sync.plist`: pass.

## Acceptance Gates

- AG1: `.flywheel/scripts/cleanup-scratch.sh` added with strict path validation, JSON output, dry-run default, and explicit `--apply` mutation gate.
- AG2: `.dcg/allowlist.toml` contains exact-command allowlist entries for `/Users/josh/.local/bin/flywheel-cleanup-scratch` and the repo-local helper.
- AG3: worker-tick and shared dispatch template surfaces now instruct `flywheel-cleanup-scratch --apply --json "$WORK_TMP"` instead of raw tmp deletion.
- AG4: `tests/cleanup-scratch.sh` covers valid, invalid, relative, and nonexistent paths.
- AG5: `.flywheel/doctrine/scratch-cleanup-canonical-pattern.md` documents the canonical pattern and history.
- AG6: doctrine sync surfaces include `cleanup-scratch.sh` in the shared script allowlist; the repo-local dry-run proves the helper is a managed row, and the 6h launchd plist lints.

## Compliance Score

`940/1000`

Rationale: packet read, bead context verified, Socraticode K>=10 applied, skill routes checked, helper/test/doctrine/allowlist/template/sync surfaces updated, validation passed, evidence written, scratch tmp cleaned with the new helper, commit created, and bead close planned before callback. Lost points only for Agent Mail reservation being unavailable in this MCP session because MistyCliff registration token was not present, and for the all-repo doctrine-sync run hanging while repo-local propagation evidence succeeded.

## Skill Routes

- canonical-cli-scoping: `yes`; helper passes canonical CLI scoping checker.
- dcg: `yes`; allowlist validated and no raw destructive cleanup command is required for worker tmp closeout.
- rust-best-practices: `n/a`; no Rust code changed.
- python-best-practices: `n/a`; helper only invokes Python stdlib for safe deletion behind shell validation.
- readme-writing: `n/a`; no README requested or needed.

## Artifact Checks

- `.flywheel/scripts/cleanup-scratch.sh`: exists
- `tests/cleanup-scratch.sh`: exists
- `.flywheel/doctrine/scratch-cleanup-canonical-pattern.md`: exists
- `.dcg/allowlist.toml`: exists
- `/Users/josh/.local/bin/flywheel-cleanup-scratch`: exists
- `/Users/josh/.claude/commands/flywheel/worker-tick.md`: exists
- `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md`: exists
- `/Users/josh/.claude/skills/.flywheel/bin/flywheel-doctrine-sync`: exists

## L112 Probe

Command:

```bash
.flywheel/audit/flywheel-l95he/l112-probe.sh
```

Expected: `literal:true`

Timeout: `30`

