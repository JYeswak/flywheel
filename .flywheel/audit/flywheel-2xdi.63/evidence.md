# Evidence: flywheel-2xdi.63 — register flywheel-codex-orient-runs as self-instrumentation silo

**Bead**: flywheel-2xdi.63 (P3) | **Task ID**: flywheel-2xdi.63-14f934 | **Identity**: MistyCliff
**Class**: cross-source-silos
**Flagged**: `~/.local/state/flywheel/flywheel-codex-orient-runs.jsonl`

## Disposition: register as self-instrumentation (sister of 2xdi.55)

The ledger is the audit log for `~/.claude/skills/.flywheel/bin/flywheel-codex-orient` (a canonical-CLI scaffolded script, filled-in by flywheel-wzjo9.1.9). Schema: `{ts, action, status, sha256, id, ...}` — one row per invocation. Read by the script's own `audit` / `why` subcommands (operator inspection), not by tick/status/synth/doctrine.

Same shape as already-allowlisted self-instrumentation ledgers:
- autoloop-executor.jsonl
- polish.jsonl
- security-posture.jsonl
- blocker-discipline-tick-chain-install-runs.jsonl (2xdi.55)

Canonical pattern per flywheel-gui5f / 2xdi.32 / 2xdi.43 / 2xdi.55 precedent.

## Fix

One-row append to `.flywheel/gap-hunt-known-silos.jsonl` (95 → 96 entries):

```jsonl
{"name":"flywheel-codex-orient-runs.jsonl","class":"self-instrumentation","writer":"/Users/josh/.claude/skills/.flywheel/bin/flywheel-codex-orient","rationale":"audit log for flywheel-codex-orient canonical-CLI scaffolded surface (filled-in by flywheel-wzjo9.1.9); writes one row per invocation with ts/action/status/sha256/id; intentionally not referenced by tick/status/synth/doctrine surfaces — consumed by gap-hunt-probe wired-but-cold + cross-source-silos rules (flywheel-2xdi.63)"}
```

Re-probe confirms 0 matches for `flywheel-codex-orient` basename.

## Skill recurrence

`self-instrumentation allowlist registration` pattern now N=5+ (joined autoloop-executor, polish, security-posture, blocker-discipline-tick-chain-install-runs). Pattern: every canonical-CLI scaffolded script that writes a `*-runs.jsonl` audit log of its own invocations is a self-instrumentation silo by design and needs allowlist registration after auto-bead-filing surfaces it.

## L112 verify probe

`bash -c '.flywheel/scripts/gap-hunt-probe.sh --json --dry-run 2>/dev/null | jq -r ".gaps // [] | map(select(.where | test(\"flywheel-codex-orient\"))) | length"'`
Expected: `grep:^0$`
