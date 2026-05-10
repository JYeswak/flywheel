# Draft: Jeffrey Emanuel skill-builder fleet-propagation issue

Repo: `Dicklesworthstone/skill-builder` (or wherever JSM/skill-builder source lives)
Status: HELD-FOR-JOSHUA-REVISION (per session pattern)
Anonymized per `jeff-issue-chain` v1.1 (no internal paths, bead IDs, or session names)

## Title

skill-builder: stamp canonical scripts/{validate,audit}.sh on `jsm push` when missing

## Body

The canonical-cli-scoping discipline calls for every CLI/skill to ship the validate/audit/why triad as first-class scripts (`scripts/validate.sh`, `scripts/audit.sh`). A live audit of locally-cached JSM-managed skills shows wide gaps:

```
total JSM-managed skills: 111
  scripts/ directory present:        41 (missing in 70)
  scripts/validate.sh present:        3 (missing in 108)
  scripts/audit.sh present:           0 (missing in 111)
```

Closing this gap by per-skill manual edits doesn't scale (108 patches just for validate.sh). The right shape is **first-class skill-builder propagation**: `jsm push` should auto-stamp canonical templates if missing, with an opt-out for skills that genuinely need a custom shape.

### Proposed addition

Add a stamp step to `jsm push` (or `skill-builder validate-skill --stamp`):

```bash
jsm push <skill> --stamp-canonical-scripts   # opt-in, off by default initially
```

Behavior:
1. If `scripts/validate.sh` is missing, generate a stub from a canonical template (substrate-binary check + --json mode + stable exit codes).
2. If `scripts/audit.sh` is missing, generate a stub (read-only substrate probe + JSON output).
3. Stubs include a `<SKILL_NAME>`/`<REQUIRED_BIN>`/`<DOCTOR_CMD>` placeholder block so skill authors customize per substrate.
4. Stamped scripts are committed to the JSM source repo as part of the push, becoming part of the skill's pinned version.

The opt-out path: a skill author who has good reason for a non-canonical shape can pass `--no-stamp-canonical-scripts` (or set a frontmatter flag `canonical_scripts: opt_out`).

### Why this matters

Skill-builder's own `validate-skill.sh` already requires `scripts/` + checks for missing dirs as a hard fail. Yet 70/111 JSM-managed skills fail that check today. The gap is an integration regression between `validate-skill.sh`'s requirements and `jsm push`'s stamping behavior — `jsm push` accepts the skill without stamping, and the skill author has to know to manually create the directory and stubs. Stamping at push time turns the validator's requirement into a guaranteed invariant.

A flywheel-side fleet rollup observed:
- `scripts/audit.sh`: 0/111 — never written by anyone; the canonical-cli-scoping audit triad is universally absent.
- `scripts/validate.sh`: 3/111 — only 3 skills have it; the remaining 108 either omit validation or hide it under non-canonical filenames (e.g. `validate-changelog-md.py`).
- `scripts/`: 41/111 — 70 skills don't even have the directory.

This is too many skills to fix one at a time. A single skill-builder change converts a 219-edit problem (108 + 111) into a one-tool-change problem.

### Workaround in use today

Downstream consumers (flywheel orch tick, fleet-rollup dashboards) currently fall back to substrate-specific probes when `scripts/audit.sh` is absent. That works for skills the consumer already knows about (e.g. cass via `cass status --json`); it doesn't work for the long tail of skills the consumer hasn't been taught.

### Canonical templates (proposed defaults)

Two stubs ~80 lines each; both honor canonical-cli-scoping:
- Stable schema_version (`skill-validate/v1`, `skill-audit/v1`)
- `--json` mode + plain-text mode
- Stable exit codes (`0` ok, `2` substrate-missing, `3` substrate-degraded for validate; `0` audit-ran, `2` audit-could-not-run for audit)
- Placeholder block for per-skill customization

Happy to share the templates separately if that would help; this issue is primarily about whether the propagation pattern (auto-stamp on push) is the right shape.

### Environment

- skill-builder version: latest installed locally
- JSM workspace size: 111 skills locally cached
- Platform: macOS Apple Silicon

Thank you for skill-builder + JSM — the substrate is doing real work; this is about closing a propagation regression rather than a quality complaint.
