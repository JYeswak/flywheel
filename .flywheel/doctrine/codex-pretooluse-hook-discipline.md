# Codex PreToolUse Hook Discipline

Every Codex invocation that mutates state must fire the PreToolUse hook stack before tool execution.

For flywheel autonomous workers, the accepted execution path is a live Codex pane receiving the dispatch packet through NTM and executing worker-tick parity. `codex exec` is not an accepted worker substrate unless `tests/codex-exec-pretooluse-fires.sh` has a current live PASS receipt proving the PreToolUse hook fires, or the gap is documented as `ACCEPTED_DIVERGENCE` with a mitigation plan.

The minimum hook contract is:

- DCG fires before Bash tool execution.
- Cross-repo write guards remain pre-action, not post-facto audit.
- Any bypass or missing hook is a safety-substrate gap and must write a row to `.flywheel/runtime/safety-substrate-gap-ledger.jsonl`.

Current 2026-05-19 disposition for `openai/codex#23411`: `NOT_IN_USE`. Flywheel dispatches use live Codex pane worker-tick parity; exec-mode dispatch remains refused by contract.
