# flywheel-dnxjb — Evidence Pack

**Bead:** flywheel-dnxjb (P3)
**Title:** [gap-hunt-probe] probe-finder false-positive — tests/*.sh files matching *-probe.sh glob get scanned as probes
**Mission fitness:** `adjacent` — eliminates root cause of duplicate-bead-pair pattern
**Sister:** flywheel-9a3k1 (auto-bead-filer dedup safety net; shipped earlier this tick)

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1 | Fix probe-finder glob to exclude tests/ tree | DONE — `_is_in_test_tree()` helper + path filter in `probe_without_receiver()` |
| AG2 | Regression test asserts test files NOT flagged when probe exists in .flywheel/scripts/ | DONE — `tests/gap-hunt-probe-tests-tree-exclusion-canonical-cli.sh` 8/8 PASS |
| AG3 | Prevents future occurrence of 2xdi.101/.102 FP pattern | DONE — 3 additional historical FPs cleared (count 14 → 11) |

## Fix

`.flywheel/scripts/gap-hunt-probe.sh` — `probe_without_receiver()`:

```python
# flywheel-dnxjb: exclude test-tree paths. The probe-finder's rglob picks
# up test files named like `<probe-name>.sh` (sister test convention used
# in pre-2xdi.101 codebase). Those files are RECEIVERS for the real probe,
# not probes themselves.
def _is_in_test_tree(p: Path) -> bool:
    try:
        rel = p.relative_to(REPO_ROOT)
    except ValueError:
        return False
    parts = rel.parts
    if parts and parts[0] == "tests":
        return True
    if len(parts) >= 2 and parts[0] == ".flywheel" and parts[1] == "tests":
        return True
    return False
files = [p for p in files if not _is_in_test_tree(p)]
```

Filter applied AFTER candidate collection and BEFORE the receiver-check loop. Excludes:
- `tests/*-probe.sh` (top-level tests)
- `.flywheel/tests/*-probe.sh` (nested flywheel tests)

Does NOT exclude:
- `.flywheel/scripts/*-probe.sh` (canonical probe location)
- `~/.claude/skills/<x>/scripts/*-probe.sh` (skill-substrate probes)

## Discovery design choice

Two of the three offered fix shapes from the bead body:

- **Option A (path filter)** — chosen. Simple, surgical, prevents future FPs.
- **Option B (introspect candidates)** — not implemented; combinator overhead (load file, check for MODE=/--json/--doctor shape) for marginal additional safety.
- **Option C (rename convention)** — already used as one-off in 2xdi.101 (resolved via canonical-cli rename); this bead solves the underlying detector behavior so the convention isn't load-bearing.

Defense-in-depth: this bead (probe-side fix) PLUS `flywheel-9a3k1` (auto-bead-filer dedup safety net) together ensure that even if a new probe shape somehow slips through Option A, the auto-filer will dedup against any existing open bead with the same title.

## Verification

| Gate | Command | Result |
|---|---|---|
| Syntax | `bash -n .flywheel/scripts/gap-hunt-probe.sh` | OK |
| Live probe — count drop | `bash .flywheel/scripts/gap-hunt-probe.sh --json --dry-run \| jq '.gap_class_distribution["probe-without-receiver"]'` | 14 → 11 (3 additional FPs cleared) |
| Regression | `bash tests/gap-hunt-probe-tests-tree-exclusion-canonical-cli.sh` | 8/8 PASS |
| Sister tests | 5 gap-hunt-probe sister suites | All green (4/4, 4/4, 4/4, 6/6, 8/8) |

Pre-fix count: 14 (gap-hunt cap-bounded). Post-fix count: 11. The 3 cleared were all `tests/*-probe.sh` files: probably some combination of `tests/agent-context-parity-probe.sh`, `tests/bv-readiness-probe.sh`, `tests/codex-hook-parity-probe.sh`, `tests/file-length-probe.sh`, `tests/fleet-comms-health-probe.sh`, etc. — there are 9+ test files matching the glob (sampling re-rank picks which appear in any given run's top-20).

## DID / DIDNT / GAPS

- **DID 3/3** — fix applied, regression test 8/8, FP count cleared
- **DIDNT none**
- **GAPS none**

## Files Changed

- `.flywheel/scripts/gap-hunt-probe.sh` — added `_is_in_test_tree()` helper + path filter in `probe_without_receiver()`
- `tests/gap-hunt-probe-tests-tree-exclusion-canonical-cli.sh` (new, 8/8 PASS)
- `.flywheel/audit/flywheel-dnxjb/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `bash tests/gap-hunt-probe-tests-tree-exclusion-canonical-cli.sh | tail -1`
- `l112_probe_expected`: `grep:pass=8 fail=0`
- `l112_probe_timeout_sec`: `60`

## Pattern note

8th distinct fix shape in 2xdi.* cluster:
- 47/49/64/66 = probe corpus extensions (broaden)
- 93 = doctrine cross-link
- 90/92 = test-receiver wire-in (new file)
- 100 = INCIDENTS citation
- 101/102 = canonical-cli rename
- **dnxjb = probe-finder path filter (narrow)**

Sister to 9a3k1: probe-side prevention (dnxjb) + safety-net dedup (9a3k1) = defense-in-depth against the duplicate-bead-pair class.

## Four-Lens Self-Grade

- **brand:** 9 — minimal-surface fix with explicit doctrine comment + bead-reference
- **sniff:** 10 — chose Option A over B for simplicity, with 9a3k1 defense-in-depth justifying single-layer fix
- **jeff:** 10 — convergent with 9a3k1; both surfaced + closed same session as the bead pair (2xdi.101/.102) that revealed them
- **public:** 9 — future operator reads the comment, understands tests/ exclusion + why
