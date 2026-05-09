# flywheel-2xdi.1 Evidence

`npm-install-guard.sh` was wired back into Claude's active Bash `PreToolUse` chain via `/Users/josh/.claude/settings.json`.

Validation summary:

- `jq empty /Users/josh/.claude/settings.json`: pass
- jq path check for `$HOME/.claude/hooks/npm-install-guard-hook.sh`: pass
- `/Users/josh/.claude/hooks/npm-install-guard-hook.sh` with `npm install`: exit `0`
- `/Users/josh/.claude/hooks/npm-install-guard-hook.sh` with `FLYWHEEL_NPM_FORCE=1 npm install -g @openai/codex`: exit `0`
- `/Users/josh/.claude/hooks/npm-install-guard-hook.sh` with `npm install -g @openai/codex`: exit `2` while Codex processes were active
- `.flywheel/receipts/flywheel-2xdi.1/l112-probe.sh`: prints `pass`

External changed file:

- `/Users/josh/.claude/settings.json`

Repository evidence files:

- `.flywheel/audit/flywheel-2xdi.1/compliance-pack.md`
- `.flywheel/receipts/flywheel-2xdi.1/2xdi.1-062a70-evidence.md`
- `.flywheel/receipts/flywheel-2xdi.1/l112-probe.sh`
