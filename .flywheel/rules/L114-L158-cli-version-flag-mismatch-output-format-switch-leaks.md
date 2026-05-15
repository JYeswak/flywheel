# L158 — CLI-VERSION-FLAG-MISMATCH-OUTPUT-FORMAT-SWITCH-LEAKS

---
id: L158
title: CLI version flag mismatch must not be fixed by switching to a value-leaking output format
status: long_term
shipped: 2026-05-15
review_due: 2026-11-15
trauma_class: cli-version-flag-mismatch-secret-leak
source_owner: skillos
source_locator: /Users/josh/Developer/skillos/.flywheel/doctrine/cli-version-flag-mismatch-output-format-switch.md
ratification: .flywheel/handoffs/20260512T040500Z-from-flywheel-1-to-skillos-1-L158-L159-RATIFICATION.md
---

When a CLI changes a flag name, the safe repair is to map the flag name to the
installed CLI version. The repair is not allowed to switch to an output format
that carries secret values, then depend on downstream filtering to clean it up.

For secret-bearing tools, format choice is part of the safety boundary. A
line-oriented value-stripped listing can be safe. JSON, YAML, CSV, and similar
structured dumps can expose values before any `jq`, `yq`, `awk`, or model-side
filter sees them.

## Flywheel application

Flywheel scripts that inspect secret stores must encode the version-specific
flag shape they expect and must prefer explicit, value-stripped enumeration. A
script that falls back from one secret-store output mode to another must prove
the fallback does not expose values to stdout, logs, process memory intended for
agents, or audit ledgers.

## SkillOS source

SkillOS owns the canonical incident doctrine. This shard is the Flywheel-side
sister rule so fleet operators see the safety boundary while leaving source
truth in the SkillOS control-plane repo.

- SkillOS canonical:
  `/Users/josh/Developer/skillos/.flywheel/doctrine/cli-version-flag-mismatch-output-format-switch.md`
- Flywheel ratification:
  `.flywheel/handoffs/20260512T040500Z-from-flywheel-1-to-skillos-1-L158-L159-RATIFICATION.md`

