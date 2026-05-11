---
name: scaffolder-bash-vs-python-design-difference
type: doctrine
created: 2026-05-11
updated: 2026-05-11
authors:
  - flywheel-eyqo7-40b98a (MagentaPond / flywheel:0.3) — initial doctrine fold-in
  - flywheel-vyzza (MagentaPond / flywheel:0.3) — rename arc closeout (2026-05-11)
parent_beads:
  - flywheel-0pkcf (PYTHON variant exemplar; first surface that hit the bash-scaffolder refusal)
  - flywheel-oozt3 (scaffold-canonical-cli-py.sh introduction; closes the refused_python_shebang gap)
  - flywheel-eyqo7.1 (mass-rename arc meta-bead — decomposed to per-file sub-beads per META-RULE 2026-05-10)
  - flywheel-eyqo7.1.1 / flywheel-023hs (caam-auto-rotate .sh → .py rename)
  - flywheel-eyqo7.1.2 / flywheel-oyxd8 (jeff-issue .sh → .py rename)
  - flywheel-eyqo7.1.3 / flywheel-49c6i (fleet-rotate-on-caam-swap .sh → .py rename)
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

## File-extension convention (rename arc shipped 2026-05-11)

The flywheel repo previously had 3 scripts with `#!/usr/bin/env python3` shebangs but `.sh` file extensions. The mismatch was a HISTORICAL artifact — these scripts were originally bash, then rewritten in Python during canonical-CLI scaffold work, but the `.sh` extension was preserved to avoid breaking the 108 total cross-references (audit trails, doctrine docs, dispatch logs, etc.).

**Current state (post-2026-05-11):** all three scripts renamed to `.py` extension, LIVE refs updated, HISTORICAL refs preserved:

- `.flywheel/scripts/caam-auto-rotate-on-usage-limit.py` (was `.sh`, renamed `flywheel-eyqo7.1.1` / `flywheel-023hs`, commit `3e6b0f6`)
- `.flywheel/scripts/jeff-issue.py` (was `.sh`, renamed `flywheel-eyqo7.1.2` / `flywheel-oyxd8`, commit `1a59236`)
- `.flywheel/scripts/fleet-rotate-on-caam-swap.py` (was `.sh`, renamed `flywheel-eyqo7.1.3` / `flywheel-49c6i`, commit `852600c`)

### Rename arc completion (2026-05-11)

Parent meta-bead `flywheel-eyqo7.1` decomposed to 4 sub-beads per META-RULE 2026-05-10 (decompose-by-natural-unit-not-bundle). Reference graph + LIVE/HISTORICAL/DOCTRINE partitioning at `.flywheel/audit/flywheel-eyqo7.1/evidence.md`.

Per-sub-bead evidence packs:
- `.flywheel/audit/flywheel-eyqo7.1.1/evidence.md` — caam-auto-rotate (16 LIVE-ref updates; canonical-CLI test 14/14 PASS; 1 gap bead filed `flywheel-vzrs6` for pre-existing test 02 stale-assertion class, META-RULE 2026-05-09)
- `.flywheel/audit/flywheel-eyqo7.1.2/evidence.md` — jeff-issue (19 LIVE-ref updates; tests 16/16 + 26/26 PASS; argv[0]-grep calibration applied proactively)
- `.flywheel/audit/flywheel-eyqo7.1.3/evidence.md` — fleet-rotate-on-caam-swap (16 LIVE-ref updates incl 5 sister-script sites with 2 LOAD-BEARING path vars verified resolving)

### Reference partitioning (immutable post-rename)

Per audit-machinery-hygiene-discipline doctrine:
- **LIVE references** (active scripts, configs, watchers, launchd jobs, hooks, tests, NTM-SURFACE-INVENTORY, doctrine): UPDATED atomically with each rename
- **HISTORICAL references** (JSONL audit logs, dispatch-log rows, journal entries, evidence packs from prior beads, prompts/, checkpoints/, summaries/, rollback-receipts.jsonl, scaffold-runs.jsonl, `.beads/issues.jsonl`): NOT rewritten — immutable evidence of past activity
- **DOCTRINE references** (PLANS/, this doctrine, sister doctrines): updated to reflect post-rename state where load-bearing; historical value preserved otherwise

### Design decisions baked into the rename arc

1. **Ledger filename strings** (e.g. `outputs[]` arrays in script `--info`) updated `.sh-runs.jsonl` → `.py-runs.jsonl` (string-only; no on-disk file existed)
2. **Test filenames embedding unit-under-test extension** DO rename (e.g. `tests/<basename>.sh-canonical-cli-py.sh` → `.py-canonical-cli-py.sh` — canonical-CLI test convention `<script-basename-with-extension>-canonical-cli-py.sh`)
3. **Schema/result version names** KEEP suffix (e.g. `caam-auto-rotate-on-usage-limit.result.v1` — content-version, not filename)
4. **`--help`-output substring greps** in tests update to `.py` (Python script's `--help` emits `argv[0]` basename, which becomes `.py` post-rename)
5. **Doctrine close-out is post-renames**, not pre-renames intent (this sub-bead `flywheel-vyzza` blocks-on the 3 rename sub-beads)
6. **Slash-command names** (e.g. `$HOME/.claude/commands/flywheel/jeff-issue.md`) KEEP — slash command name has no extension to update
7. **Pre-scaffold `.bak.scaffold-py-...` files** UNTOUCHED — historical evidence of bash-version-before-scaffolding per audit-machinery-hygiene-discipline

### Test files NOT renamed

Per Design Decision #2, test filenames that embed the unit-under-test extension DO rename. But test filenames whose `.sh` reflects the TEST INTERPRETER (not unit-under-test) do NOT rename:

- `tests/jeff-issue.sh` — KEPT (`.sh` is the test interpreter; test exercises `.py` script via bash)
- `tests/jeff-issue-canonical-cli.sh` — KEPT (same reasoning)
- `tests/caam-auto-rotate-on-usage-limit-canonical-cli.sh` — KEPT (wrapper test, no `.sh-` infix)
- `tests/fleet-rotate-on-caam-swap-canonical-cli.sh` — KEPT (same reasoning)

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
- **New python script:** use `.py` extension + `#!/usr/bin/env python3` shebang + `scaffold-canonical-cli-py.sh`. **Do NOT use `.sh` extension** for new Python scripts — the historical mismatch class is now CLOSED (all 3 legacy files renamed in the flywheel-eyqo7.1 arc, 2026-05-11); new scripts must match extension to interpreter from day 1.
- **Refactoring a `.sh` to Python:** if the script lives in flywheel repo's authored set, file a refactor bead that includes the rename + reference-graph update; do not preserve the `.sh` extension as a side effect of "minimum churn". Reference: flywheel-eyqo7.1 evidence pack documents the canonical partitioning approach (LIVE / HISTORICAL / DOCTRINE) for this class of refactor.

## Cross-references

- `flywheel-0pkcf` — first PYTHON variant exemplar (caam-auto-rotate-on-usage-limit.py canonical-CLI scaffold)
- `flywheel-oozt3` — scaffold-canonical-cli-py.sh introduction (closes the refused_python_shebang gap)
- `flywheel-eyqo7` — this doctrine fold-in + follow-on rename bead filing
- `flywheel-eyqo7.1` — rename arc meta-bead; decomposed to 4 sub-beads per META-RULE 2026-05-10 (evidence: `.flywheel/audit/flywheel-eyqo7.1/evidence.md`)
- `flywheel-eyqo7.1.1` / `flywheel-023hs` — caam-auto-rotate rename (commit `3e6b0f6`; gap bead `flywheel-vzrs6` filed for pre-existing test 02 stale assertion)
- `flywheel-eyqo7.1.2` / `flywheel-oyxd8` — jeff-issue rename (commit `1a59236`; both test suites green; argv[0]-grep calibration applied proactively)
- `flywheel-eyqo7.1.3` / `flywheel-49c6i` — fleet-rotate-on-caam-swap rename (commit `852600c`; sister script load-bearing path resolution verified)
- `flywheel-vyzza` — this doctrine close-out (deps `eyqo7.1.{1,2,3}` all closed)
- canonical-cli-scoping skill — the rubric both scaffolders satisfy
- audit-machinery-hygiene-discipline doctrine — the LIVE/HISTORICAL/DOCTRINE partitioning principle applied per rename
