# flywheel-anqp1 compliance pack

Task: flywheel-anqp1-5a2e28
Bead: flywheel-anqp1

## Checks

- Socraticode survey: 10 queries, 100 indexed chunks observed.
- Shared-surface reservations: checked and reserved before mutation.
- Skill route: canonical CLI scoping addressed through explicit `--json`,
  bounded health, and no wrapper mutation.
- Rust route: n/a, no Rust edited.
- Python route: n/a, no Python edited.
- README route: n/a, no README edited.
- Decision: keep `cm 0.2.3` pinned for worker pre-task memory.
- Skill update: `/Users/josh/.codex/skills/cass-memory/SKILL.md`.
- Verification: pinned `cm context` success and pinned `cm doctor --json`
  machine-readable success.

## L112 Probe

Command:

```bash
cm context "smoke" --workspace /Users/josh/Developer/flywheel --json | jq -e '.success == true and .metadata.version == "0.2.3"'
```

Expected:

```text
jq:true
```
