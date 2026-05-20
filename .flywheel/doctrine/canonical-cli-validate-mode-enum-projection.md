---
title: "Canonical-CLI: Native-Flags-to-Validate-Enum Mode Projection"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Canonical-CLI: Native-Flags-to-Validate-Enum Mode Projection

Version: `canonical-cli-validate-mode-enum-projection/v1`
Owner: scaffold-canonical-cli authors + canonical-cli-scoping skill users
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.136 (memory-without-cross-link wire-in)

## TL;DR

When scaffolding canonical-CLI on a script with **rich, mutually-exclusive
native flags** (e.g., `--apply` / `--dry-run`; `--reconcile` /
`--first-run-audit` / `--apply-fs-rag`), **project those flags into a single
`validate <name>-mode` enum subject** so orchestrators get a uniform
machine-readable API mirroring native flag semantics.

## Canonical memory source

This doctrine summarizes
`feedback_native_flags_to_validate_enum_projection.md` — the META-rule
memory (N=3 convergent evolution; promoted 2026-05-11). Read the memory
for the full convergence trail.

## The pattern (formal)

For a script with mutually-exclusive native mode-selection flags
`--<flag-A>` / `--<flag-B>` / `--<flag-C>`:

```bash
# Native CLI surface (what operators type):
script.sh --<flag-A>
script.sh --<flag-B>
script.sh --<flag-C>

# Canonical-CLI projection (what orchestrators introspect):
script.sh validate <name>-mode <value>
# where <name>-mode is the projected enum subject and <value> in {flag-A, flag-B, flag-C, <default>}
```

The validate-enum is the **canonical projection**:
- 1 enum value per mutually-exclusive native flag
- Plus the implicit default (if any) as its own enum value
- Cross-sourced in emitted JSON via `source: "native --<flag>/--<flag>/... flag contract"`

## Why

- Native flag namespaces are how scripts accept mode selection at the
  command line, but they're not introspectable via a uniform `validate`
  interface.
- Projecting flags into an enum subject gives orchestrators a single
  `validate <name>-mode` API that mirrors native flag semantics **without
  requiring per-script awareness**.
- Pattern is now load-bearing for canonical-CLI scaffolding fleet rollout.

## Convergence trail (N=3, promotion-ready)

| # | Source bead | Enum subject | Native flags cross-sourced |
|---|---|---|---|
| 1 | `flywheel-1hshd.25` (docs-validation-probe) | `validation-status` enum `{validated, pending, failed, self_validated}` | native `--schema .metadata_fields` |
| 2 | `flywheel-1hshd.29` (flywheel-adopt) | `adoption-mode` enum `{bootstrap, reconcile, first_run_audit, apply_fs_rag}` | `--reconcile` / `--first-run-audit` / `--apply-fs-rag` |
| 3 | `flywheel-1hshd.30` (codex-stuck-detector-install) | `install-mode` enum `{dry_run, apply}` | `--apply` / `--dry-run` |

N=3 → convergent-evolution promotion threshold met. Pattern is canonical
for any subsequent canonical-CLI scaffold touching a multi-flag mode surface.

## Apply (scaffold authors)

In `scaffold_cmd_validate` (or equivalent function in the canonical-CLI
scaffolder):

1. Identify the script's mutually-exclusive native mode flags (`grep` for `case`
   blocks routing on flag tokens; usage strings).
2. Define a `<name>-mode` subject whose enum **exactly mirrors** the native
   flag set (one enum value per flag, plus implicit-default).
3. Wire the validate handler to accept `validate <name>-mode <value>` and
   return JSON `{schema_version, subject, value, valid, ...}`.
4. Cross-source the projection in emitted JSON:
   ```json
   {
     "subject": "<name>-mode",
     "source": "native --<flag-A>/--<flag-B>/... flag contract",
     "enum": ["<flag-A>", "<flag-B>", "<default>"]
   }
   ```
5. Add a regression test asserting `validate <name>-mode <each-value>` works
   AND `validate <name>-mode <invalid>` rejects.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Per-script `validate` shapes that don't project native flags. | Orchestrators must teach themselves every script's validate shape — no uniform API. |
| Projecting non-mutually-exclusive flags as a single enum. | Misrepresents the CLI contract; `--verbose --apply` can't be one enum value. Use multiple subjects. |
| Skipping the cross-source field. | Future readers don't know the validate-enum mirrors a native flag set; the projection looks free-standing. |
| Adding new native flags without expanding the enum. | Validate-enum drifts from native CLI; orchestrators get false-valid results for new flags. |

## Sister doctrine + memory

- `feedback_native_flags_to_validate_enum_projection` (above-cited canonical memory)
- Sister memory `feedback_canonical_cli_at_dispatch` — canonical-CLI-scoping skill is required at every dispatch
- `canonical-cli-scoping` skill (SKILL.md) — the rubric this projection serves
- Sister convergence-evolution memory `feedback_convergent_evolution_is_canonical_signal` — N=3 promotion threshold

## Conformance

A scaffolded canonical-CLI surface proves conformance via:
- `validate --json` enumerates a `<name>-mode` subject when the script has mutually-exclusive native mode flags
- The enum values mirror the native flag set (1-to-1 + implicit-default)
- Cross-source field names the native flag set as the truth source
- Regression test asserts each enum value works and invalid values reject

## Lifecycle

This is a HARD RULE for any future canonical-CLI scaffold authored against
a script with mutually-exclusive native mode flags. The N=3 convergence
trail (1hshd.25, 1hshd.29, 1hshd.30) demonstrates the pattern is operational
fleet-wide; future scaffolds inherit the discipline by default.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
