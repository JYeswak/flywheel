# Codex App-Server Metadata Discipline

Every dispatch callback field used for workspace inference must be internally consistent before downstream substrate trusts it.

For Codex workers, app-server metadata is not an accepted source for flywheel callback identity unless the callback row also passes the cwd/originator integrity check:

- `cwd` must resolve to the git top-level of the named `repo_path`.
- `originator` must match the callback agent identity when both fields are present.
- `source` or `originator` values that imply app-server, desktop, or IDE mediation must be treated as polluted until explicitly verified.

The accepted 2026-05-19 worker path remains live Codex TUI panes receiving dispatch packets through NTM. Current disposition for `openai/codex#23437`: `NOT_IN_USE`.

The mechanical guard is `.flywheel/scripts/dispatch-log-fitness-invariant.sh`. Any detected cwd/originator mismatch is a safety-substrate gap and must write a row to `.flywheel/runtime/safety-substrate-gap-ledger.jsonl`.
