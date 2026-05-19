# .flywheel/audits

Audits are replayable evidence. A report should name the command that produced it and the source paths it inspected.

## Conventions

- Prefer dated directories: `.flywheel/audits/<audit-name>-YYYY-MM-DD/`.
- Markdown reports should include generated timestamp, source inputs, metrics, findings, and rerun command.
- JSONL row files must be schema-stable enough for `jq` consumers; include `schema_version` when rows are durable evidence.
- Large generated JSONL files should be excluded from Claude context via `.claudeignore` when they are not the edited surface.
- Retain summaries and scorecards in git when they prove acceptance; avoid committing noisy intermediate logs.
