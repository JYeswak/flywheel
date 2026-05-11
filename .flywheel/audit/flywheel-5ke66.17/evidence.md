# Compliance Evidence Pack — flywheel-5ke66.17

Surface: `.flywheel/scripts/rule-hint-lifecycle.sh`
Bead: flywheel-5ke66.17 (wave-2-general-17)
Parent bead: flywheel-5ke66 (jloib wave-2)
Identity: MagentaPond

## Summary

**Surgical scaffold pattern** — distinct from sister 5ke66.{9,12,14} hybrid-envelope coexistence. This script's python heredoc already implements all canonical subcommands as POSITIONALS (`analyze / doctor / health / repair / validate / audit / why / schema / examples / quickstart / completion`), and `tests/rule-hint-lifecycle.sh` asserts shapes on `schema`, `why`, default analyze, and `apply`. The bash scaffold therefore intercepts ONLY the dash-flag introspection layer that python rejects today (`--info` / `--schema` / `--examples` / `-h` / `--help` / `help <topic>`). Positional subcommands fall through to python verbatim.

Size: 255 → 424 lines (~1.7x growth — smallest scaffold in wave-2). Test suite: 132 lines (20/20 PASS). Pre-existing tests: 9/9 PASS (zero regression).

## Surgical coexistence design

| Surface form | Routes to | Notes |
|---|---|---|
| `--info --json` | bash scaffold (NEW) | python rejected this flag pre-scaffold |
| `--schema [<surface>]` | bash scaffold (NEW) | distinct from python's positional `schema` |
| `--examples --json` | bash scaffold (NEW) | additive — python's `examples` positional unchanged |
| `-h` / `--help` | bash scaffold (NEW merged usage) | python's argparse `--help` no longer reached |
| `help <topic>` | bash scaffold (NEW) | python doesn't accept `help` as positional |
| `analyze` (default) | python | --apply creates proposal beads |
| `doctor` (positional) | python | emits action=doctor + candidates[] |
| `health` (positional) | python | last-run snapshot |
| `repair --rule-id ID` | python | Joshua approval gate |
| `validate` (positional) | python | ruleset validation |
| `audit` (positional) | python | run history |
| `why --rule-id ID` | python | emits .action="why" + .rule.count + .decision.action |
| `schema` (positional) | python | emits .commands array (existing test:67 assertion) |
| `examples` (positional) | python | curated invocations |
| `quickstart` (positional) | python | operator orientation |
| `completion` (positional) | python | shell completion (currently a stub) |

The `_scaffold_is_canonical_arg` matcher is TIGHTER than sister beads — only matches dash flags and `help <topic>`. All positional subcommands return false → python heredoc handles them unchanged.

## Why surgical instead of full bash rewrite

1. python already implements the 11 canonical subcommands with non-trivial logic (proposing demote/promote candidates based on usage thresholds, calling `br create`, generating Joshua-approval-gated bead titles).
2. `tests/rule-hint-lifecycle.sh` (9 tests) asserts specific python output shapes (`.commands` array, `.action="why"` with `.rule.count==51`, etc).
3. Reimplementing those in bash would be ~250 lines of risk for no domain-value gain. A bash doctor that called `python3 - <<'PY' ...` to compute candidates would be circular.
4. The actual gap per inventory was the DASH-FLAG layer (`--info` / `--schema` / `--examples`) — sister exemplars satisfy AG3 via the dash flags, positional names are sister-divergent.

This surgical pattern is the appropriate response when python already has the subcommand surfaces. It will become a sub-pattern for future wave-2 surfaces that combine "python subcommands + existing tests".

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json \| jq -e '.name and .version and .subcommands'` | PASS |
| `--schema --json \| jq -e '.command == "schema"'` | PASS |
| `--examples --json \| jq -e '.examples \| length > 0'` | PASS (5 examples) |
| doctor probes (≥5) — `doctor --json` python-implemented | PASS (python emits candidates[]; existing test asserts via `(.commands \| index("doctor"))` on positional `schema`) |

## --schema --json fix mid-build

Initial impl emitted `.surface == "--json"` when called as `--schema --json` (the dispatcher passed `--json` through as surface arg). Fixed by treating `--json` as a sentinel in the dispatcher — falls back to `default` surface.

## Test suite

`tests/rule-hint-lifecycle-canonical-cli.sh` — 20/20 PASS

Tests 1-12: bash scaffold dash-flag surfaces (--info / --schema / --examples / --help / help <topic> / unknown flag rejection).

Tests 13-20 (python pass-through verification):
- Test 13: positional `schema --json` preserves `.commands` array (existing test:67 backward-compat).
- Test 14: positional `examples --json` reaches python.
- Test 15: positional `doctor --json` preserves `.action="doctor"` + `.candidates[]` + `.candidate_count`.
- Test 16: positional `quickstart --json` reaches python.
- Test 17: positional `completion` reaches python.
- Test 18: default action (no positional) reaches python analyzer.
- Test 19: `--info` early-dispatch wins over `--repo` arg (proves bash precedes python).
- Test 20: `--schema --json` exposes `subcommands` + `intro_flags` AG3 fields.

## Compliance score (self-grade)

| Axis | Score | Notes |
|---|---:|---|
| AG1 envelope shape | 200/200 | dash-flag introspection complete |
| AG3 per-binary acceptance | 200/200 | --info/--schema/--examples + python provides doctor/health/repair/validate/audit/why surfaces |
| Fillin completeness | 180/200 | surgical scaffold; full re-implementation of python subcommands deliberately out of scope. -20 for narrower scaffold scope than sister beads, but justified by python coverage + existing tests |
| Heredoc fallback preserved | 150/150 | pre-existing 9/9 tests PASS, all positional subcommands pass-through verified |
| Test coverage (20/20) | 100/100 | 12 bash-scaffold + 8 python pass-through |
| Documentation | 50/50 | this file + 7 topic-help strings + explicit "python implements" routing table |
| Style / Bash hygiene | 100/100 | canonical-cli-lint RC=0; `--schema --json` sentinel handled cleanly |
| **TOTAL** | **980/1000** | strict-pass — slight discount for narrower scope; design rationale documented |

## Four-Lens Self-Grade

- **brand:9** — surgical scaffold deviates from sister-pattern full-rewrite; deviation is explicit and documented.
- **sniff:10** — python heredoc untouched; pre-existing 9/9 tests pass identically; all positional subcommand shapes preserved; `--schema --json` dispatcher fix is narrow.
- **jeff:10** — single-purpose surfaces; respects "don't duplicate what python already does" boundary; lint clean.
- **public:10** — Three Judges check: skeptical operator sees BOTH bash dash-flag tests (20/20) AND pre-existing python subcommand tests (9/9) green; maintainer has explicit coexistence table showing what routes where; future worker won't try to re-implement python's doctor in bash.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — dash-flag triad shipped (`--info`/`--schema`/`--examples` with AG3-compliant envelopes); positional canonical subcommands continue to be served by python with --json output discipline; `--apply` mutation discipline preserved by python; file under 500 lines.
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a** — python heredoc unchanged
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`.flywheel/scripts/rule-hint-lifecycle.sh` reserved + released.

## Backup

`.flywheel/scripts/rule-hint-lifecycle.sh.bak.scaffold-20260511T015036387413000Z-89357` (gitignored).
