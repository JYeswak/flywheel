# flywheel-13u0.3 evidence receipt

Bead: `flywheel-13u0.3`
Task: `flywheel-13u0.3-047a1b`
Evidence redacted: `yes`

## Result

Triage recommends a new `stale-command-protocol-drift` INCIDENTS class. The incident should not be closed under `bypass-canonical-substrate-cluster`, `three-surface-drift-detected`, or `tick-driver-primitive-failed` because those cover adjacent substrate/drift/runtime failures rather than a stale visible command/runbook protocol.

`INCIDENTS.md` was not edited because the dispatch requires Joshua/orchestrator approval before applying that surface.

## Commands Run

```bash
br show flywheel-13u0.3 --json
br dep tree flywheel-13u0.3
br show flywheel-38o --json
rg -n "flywheel-38o|stale-command-protocol|command-protocol|protocol-version|/flywheel:tick|receipt schema v2|receipt schema" INCIDENTS.md .flywheel README.md /Users/josh/.claude/commands/flywheel /Users/josh/.claude/skills/flywheel
rg -n "skill_version: 2|tick-skill-version-check|awareness_check|inbox_messages_handled|fuckups_to_beads|pagerank_top_5_blockers|dual_channel_pct" /Users/josh/.claude/commands/flywheel/tick.md
bash .flywheel/receipts/flywheel-13u0.3/l112-probe.sh
```

## Redacted Facts

- `flywheel-38o` is closed and records Joshua's stale `/flywheel:tick` report.
- `/Users/josh/.claude/commands/flywheel/tick.md` now has `skill_version: 2`, a validator note, current Codex tick commands, added awareness/inbox/fuckup/PageRank/L61 steps, and receipt fields.
- Existing INCIDENTS entries are adjacent but do not directly cover stale visible command/runbook protocol drift.
- Proposed Forever-Rule: command/runbook surfaces must either be generated from canonical doctrine or carry a freshness/protocol-version check.

## Acceptance

- AG1: pass
- AG2: pass
- AG3: pass
- AG4: pass

## Notes

No token values, token fragments, registration tokens, or token hashes are copied into this receipt.
