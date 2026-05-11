# Evidence: flywheel-2xdi.47 — gap-hunt-probe wired-but-cold for-loop blind spot

**Bead**: flywheel-2xdi.47 (P3) | **Task ID**: flywheel-2xdi.47-fede17 | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/gap-hunt-probe.sh` (probe; root cause)
**Originally flagged surface**: `~/.claude/skills/.flywheel/lib/reconcile.sh` (false-positive recipient)

## Bug shape correction

Bead premise: `lib/reconcile.sh` is dead code (wired but not referenced by recent ledgers). Investigation: **NOT dead code.** The script is sourced on every `flywheel-loop` invocation via:

```bash
for module in \
    misc parse repo canonical mission render reconcile bead wire fuckup memory \
    tentacle loop storage jeff daily agent fleet callback polish recovery doctor \
    session print portable skill-discovery step4i-coherence
do
    source "$LIB/$module.sh"
done
```

(at `bin/flywheel-loop:527-535`). The script is called every time `init --reconcile` fires.

**Real bug**: `gap-hunt-probe`'s `runtime_source_corpus()` only captures lines starting with `source ` or `. `. The `source "$LIB/$module.sh"` line uses a `$module` variable; the literal string "reconcile" never appears in any `source` line. The `for module in <list>` header *does* contain "reconcile" as a literal token, but it doesn't start with `source ` and isn't captured. So `lib/reconcile.sh` looks cold to the probe despite being load-bearing.

This is the same META-rule shape as `feedback_bead_hypothesis_starting_point_not_conclusion` (from o40x0): bead body's hypothesis = Bayesian prior; investigation produced the posterior (probe blind spot, not dead code).

## Fix

`.flywheel/scripts/gap-hunt-probe.sh` `runtime_source_corpus`: extend the corpus collector to also capture `for <var> in <list>` headers AND their backslash-continuation lines.

```python
for_in_re = re.compile(r"^\s*for\s+\w+\s+in\b")
# ...
if for_in_re.match(line):
    pieces.append(stripped)
    in_for_continuation = stripped.endswith("\\")
    continue
if in_for_continuation:
    pieces.append(stripped)
    in_for_continuation = stripped.endswith("\\")
```

Catches all 27 modules in `flywheel-loop`'s for-loop in one fix — same Meadows #5 leverage as o40x0 (fix the property, not the proxy).

## Verification

Live probe run (`gap-hunt-probe.sh --json --dry-run`) post-fix:

```
total wired-but-cold gaps: 0  (was ≥1: lib/reconcile.sh)
wired-but-cold gaps matching `reconcile`: 0
```

The specific gap that triggered this bead (`.claude/skills/.flywheel/lib/reconcile.sh`) is no longer flagged — AND no other false positive from the same blind spot remains.

## Regression test

New: `tests/gap-hunt-probe-for-loop-source-corpus.sh` (4 assertions):

1. Probe defines `for_in_re` regex
2. Probe tracks `in_for_continuation` for backslash-continuation lines
3. Live probe → 0 wired-but-cold gaps (vs ≥1 pre-fix)
4. Synthetic fixture proves the regex captures all module names from a 3-line backslash-continuation for-loop

**4/4 PASS.** Existing tests also pass: canonical-cli 30/30, on-demand-validator-allowlist 6/6, 0h0b-suppression-smoke 7/7.

## Acceptance

The bead asks to address the wired-but-cold gap for `lib/reconcile.sh`. Two paths considered:
- **Path A** (light): add reconcile.sh to substrate-registry under a new kind + extend `_ON_DEMAND_VALIDATOR_KINDS`. Catches reconcile.sh only.
- **Path B** (chosen): fix the probe's source-corpus blind spot. Catches ALL 27 lib modules in one fix + any future similar pattern across the fleet.

Path B is the Meadows-leverage path. Same shape as o40x0 (canonicalization-vs-raw hash split): symptom (false-positive cold flag) was the visible artifact; root cause (probe's source-corpus collector misses indirect-source patterns) is the fix surface.

## Files changed

- `.flywheel/scripts/gap-hunt-probe.sh` (+~20 lines: regex + continuation tracking + comment block)
- `tests/gap-hunt-probe-for-loop-source-corpus.sh` (NEW: 4-assertion regression test)

## L112 verify probe

`bash tests/gap-hunt-probe-for-loop-source-corpus.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=4 fail=0`
