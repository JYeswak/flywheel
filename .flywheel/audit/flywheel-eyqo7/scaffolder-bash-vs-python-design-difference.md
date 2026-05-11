---
name: scaffolder-bash-vs-python-design-difference
type: doctrine
created: 2026-05-11
authors:
  - flywheel-eyqo7-40b98a (MagentaPond / flywheel:0.3) — initial doctrine fold-in
parent_beads:
  - flywheel-0pkcf (PYTHON variant exemplar; first surface that hit the bash-scaffolder refusal)
  - flywheel-oozt3 (scaffold-canonical-cli-py.sh introduction; closes the refused_python_shebang gap)
sister_doctrines:
  - canonical-cli-scoping
  - audit-machinery-hygiene-discipline
status: ratified
---

# Bash vs Python Scaffolder Design Difference

The flywheel substrate ships TWO canonical-CLI scaffolders, intentionally split by interpreter. This doctrine explains the design difference, why both exist, and which one to pick.

## TL;DR

- `.flywheel/scripts/scaffold-canonical-cli.sh` — for **bash** targets. Refuses non-bash shebangs with `rc=66 status=refused reason=non_bash_shebang`.
- `.flywheel/scripts/scaffold-canonical-cli-py.sh` — for **python3** targets. Sister tool; injects a Python shim instead of bash boilerplate.

If your script's shebang is `#!/usr/bin/env python3` (regardless of file extension), use the **py** scaffolder. The bash scaffolder will refuse cleanly with a suggestion.

## Why two scaffolders, not one polymorphic tool

Appending bash-syntax canonical-CLI boilerplate to a Python script produces a corrupt mixed-language file. The bash scaffolder's refusal is a **safety gate** — it catches the mismatch before generating broken output.

The py scaffolder is a sibling tool that injects a Python shim AFTER shebang + module docstring + future-imports + BEFORE the target's own imports. The injected block uses Python idioms (argparse subparsers, dispatch dict, `sys.exit(0)` etc.) instead of bash case-esac dispatch.

## Design differences (what each scaffolder generates)

| Surface | bash scaffolder | py scaffolder |
|---|---|---|
| `--info` / `--schema` / `--examples` | ✓ injected | ✓ injected |
| `quickstart` | ✓ injected | ✓ injected |
| `audit` / `why` | ✓ injected (no-dash subcommand stubs) | ✓ injected (canonical fallback subcommand stubs) |
| `doctor` / `health` | ✓ injected stubs | ⚠ NOT injected by default — see Regression 1 below |
| `repair` / `validate` | ✓ injected stubs | ✗ NOT injected (py scaffolder design says these belong in target's own argparse since they're domain-specific) |
| TODO marker count per surface | 18 | 15 |
| Boilerplate lines added | ~200 | ~150 |

**TODO count rationale:** the bash scaffolder injects `repair` + `validate` stubs (3 extra TODOs); the py scaffolder defers those to the target's own argparse because well-architected Python CLIs typically already have domain-specific repair/validate logic that wraps the canonical envelope.

## Regression 1: doctor/health unreachable via py-scaffolder fallback

(Source: `flywheel-0pkcf` evidence pack, 2026-05-10.)

The py scaffolder's `_SCAFFOLD_CANONICAL_SUBCOMMANDS_FALLBACK` originally only included `{"audit", "why", "quickstart", "scaffold-help"}`. So an invocation like `caam-auto-rotate.sh doctor --json` fell through to the target's argparse, which doesn't know about `doctor` and emitted the native usage message — making the doctor + health fillins dead code.

**Fix landed in flywheel-0pkcf:** extended `_SCAFFOLD_CANONICAL_SUBCOMMANDS_FALLBACK` to include `doctor` and `health` (with documentation). Added explicit dispatch in `_scaffold_main`. Now both reachable; doctor returns named `.checks`, health binds audit log.

**Operational guidance for new py targets:** verify `--info` / `--schema` / `--examples` / `doctor --json` / `health --json` all reach the canonical envelope after scaffolding. Don't assume the scaffolder's fallback dispatch covers a verb just because the doctrine lists it as canonical.

## File-extension convention (current state vs target state)

Current state (2026-05-11): the flywheel repo has 3 scripts with `#!/usr/bin/env python3` shebangs but `.sh` file extensions:

- `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh` (49 cross-references)
- `.flywheel/scripts/jeff-issue.sh` (24 cross-references)
- `.flywheel/scripts/fleet-rotate-on-caam-swap.sh` (35 cross-references)

The mismatched extensions are a HISTORICAL artifact — these scripts were originally bash, then rewritten in Python during canonical-CLI scaffold work, but the `.sh` extension was preserved to avoid breaking the 108 total cross-references (audit trails, doctrine docs, dispatch logs, etc.).

**Target state:** rename all three to `.py` extension AND update the live cross-references (NOT the historical audit trail entries — those are immutable evidence).

**Why this isn't done yet:** mass-rename requires carefully partitioning the 108 references into:
- LIVE references (active scripts, configs, watchers, launchd jobs, hooks): MUST be updated atomically with the rename
- HISTORICAL references (JSONL audit logs, dispatch-log rows, journal entries, evidence packs): MUST NOT be rewritten (they're immutable evidence of past activity)
- DOCTRINE references (PLANS/, runbooks): can be updated but their value is partly as historical record

A safe mass-rename is itself a multi-tick orchestration arc. The current `flywheel-eyqo7` worker tick documents the design difference (this file) and files a follow-on bead with the migration plan + reference graph for the actual rename.

## Decision rule — which scaffolder to use

```text
if test -x <target> && head -1 <target> | grep -q 'python'; then
    use scaffold-canonical-cli-py.sh
else
    use scaffold-canonical-cli.sh
fi
```

The bash scaffolder's refusal envelope (`status:refused reason:non_bash_shebang interpreter:python3 suggested_extension:py`) gives the operator a clean signal to switch to the py sibling.

## Operational guidance for new scripts

- **New bash script:** use `.sh` extension + bash shebang + `scaffold-canonical-cli.sh` to add canonical-CLI surfaces.
- **New python script:** use `.py` extension + `#!/usr/bin/env python3` shebang + `scaffold-canonical-cli-py.sh`. **Do NOT use `.sh` extension** for new Python scripts — the historical mismatch class is bounded to the 3 legacy files above; new scripts should match extension to interpreter from day 1.
- **Refactoring a `.sh` to Python:** if the script lives in flywheel repo's authored set, file a refactor bead that includes the rename + reference-graph update; do not preserve the `.sh` extension as a side effect of "minimum churn".

## Cross-references

- `flywheel-0pkcf` — first PYTHON variant exemplar (caam-auto-rotate-on-usage-limit.sh canonical-CLI scaffold)
- `flywheel-oozt3` — scaffold-canonical-cli-py.sh introduction (closes the refused_python_shebang gap)
- `flywheel-eyqo7` — this doctrine fold-in + follow-on rename bead filing
- canonical-cli-scoping skill — the rubric both scaffolders satisfy
