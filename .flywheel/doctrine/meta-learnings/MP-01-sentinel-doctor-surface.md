# MP-01 — Sentinel-classified doctor surface

**Discovered:** 2026-05-18 (original investigation)
**Skills exemplifying:** 5+

## Essence

Before trusting `<bin> <verb> --help; exit 0` as proof verb exists, probe `<bin> __sentinel_xyz__ --help` first. If sentinel exits 0, parser has a fallback — switch to awk-parsing `Commands:` section.

## Where it applies

CLI binaries, doctor scripts, agent-consumed surfaces, any subcommand dispatcher.

## Adoption signal

Sentinel-probe meta-test exists at `scripts/tests/test_doctor_sentinel_probe*.py` OR equivalent.

## Exemplar skills (≥5)

- `~/.claude/skills/world-class-doctor-mode-for-cli-tools/CHANGELOG.md:361` — round-54 cass-bug
- `~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md:451` — canonical doctor surface
- `~/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh:1` — mechanical verifier
- `~/.claude/skills/agent-ergonomics-cli/SKILL.md:1` — agent-ergonomics rubric (sister)
- `~/.claude/skills/cass/SKILL.md:1` — cass-bug origin

## Adoption recipes

**Recipe 1 — Sentinel meta-test:** `<repo>/scripts/tests/test_doctor_sentinel_probe.py` probes every CLI subcommand dispatcher.

**Recipe 2 — Capabilities surface:** `<bin> capabilities --json` pins contract including exit codes + subcommands.

**Recipe 3 — Robot-docs:** `<bin> robot-docs` emits paste-ready agent handbook.

## Compliance test

```bash
"$CLI" __sentinel_xyz123__ --help >/dev/null 2>&1
[ $? -ne 0 ] || fail
```
