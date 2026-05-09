# flywheel-2xdi.1 Compliance Pack

Task: `flywheel-2xdi.1-062a70`
Bead: `flywheel-2xdi.1`
Decision: DONE
Compliance score: 900/1000

## Finding

The wired-but-cold report was valid. `/Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh` and `/Users/josh/.claude/hooks/npm-install-guard-hook.sh` existed and were executable, but `/Users/josh/.claude/settings.json` did not include the npm install guard in the active `hooks.PreToolUse` Bash chain.

## Scope Expansion

Joshua approved editing:

- `/Users/josh/.claude/settings.json`
- `.flywheel/receipts/flywheel-2xdi.1`
- `.flywheel/audit/flywheel-2xdi.1`

Reason: same security PreToolUse family as existing `dcg` and secret guard hooks.

## Repair

Added `$HOME/.claude/hooks/npm-install-guard-hook.sh` to the active Bash `PreToolUse` hook list in `/Users/josh/.claude/settings.json`, alongside `dcg` and the secret guard.

## Evidence

- Dispatch audit: `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-2xdi.1-062a70.md` passed.
- Settings parse: `jq empty /Users/josh/.claude/settings.json` passed.
- Settings wiring: jq lookup for `$HOME/.claude/hooks/npm-install-guard-hook.sh` under Bash `PreToolUse` passed.
- Hook syntax: `bash -n` passed for the guard and wrapper hook.
- Non-global `npm install` through the hook returned `0`.
- Forced global install through the hook returned `0`.
- Unforced global install through the hook returned `2` while Codex processes were alive, with the guard reporting running Codex PIDs.
- L112 probe: `.flywheel/receipts/flywheel-2xdi.1/l112-probe.sh` prints `pass`.

## L52

No follow-up bead filed. The observed gap was directly repaired in the approved settings scope and covered by a repeatable probe.

## Four Lens

- Brand: 8
- Sniff: 9
- Jeff: 8
- Public: 8
