# flywheel-2xdi.50 — gap-hunt false-positive: variable-assigned source paths

Bead: flywheel-2xdi.50 (P3)
Parent: flywheel-2xdi (constant-gap-hunter, CLOSED)
Sister: flywheel-2xdi.48 (just-closed; eliminated for-loop indirect-source false-positives)
Lane: gap-detector-quality
mutates_state: yes (one extra corpus-pattern added; one regression test)

## Bead claim vs reality

The bead flagged `~/.claude/skills/.flywheel/scripts/substrate-doctor-common.sh` as `wired-but-cold`.

Reality: substrate-doctor-common.sh is **actively sourced** by 3 test scripts. Verified by reading `substrate-doctor-critical-gaps-test.sh` (canonical example):

```bash
# substrate-doctor-critical-gaps-test.sh:8-14
COMMON="${SUBSTRATE_DOCTOR_COMMON:-$HOME/.claude/skills/.flywheel/scripts/substrate-doctor-common.sh}"
RAILWAY_DOCTOR="${RAILWAY_DOCTOR:-$HOME/.claude/skills/railway-api/scripts/railway-substrate-doctor.sh}"
VERCEL_DOCTOR="${VERCEL_DOCTOR:-$HOME/.claude/skills/vercel-api/scripts/vercel-substrate-doctor.sh}"
...
# shellcheck source=/Users/josh/.claude/skills/.flywheel/scripts/substrate-doctor-common.sh
source "$COMMON"
```

The bead is another **false-positive** caused by a different gap-hunt-probe corpus gap than 2xdi.48 fixed.

## Root cause

The fix in flywheel-2xdi.48 added extension-less `bin/*` wrappers to the corpus candidates, which fixed for-loop-driven indirect sourcing. It did NOT address **variable-assignment-default substitution** sourcing.

`runtime_source_corpus()` captures four patterns:
1. Lines starting with `source ` or `. ` (direct sources)
2. Lines matching `*.d/` (module-glob conventions)
3. for-loop continuations (added by 2xdi.47)
4. **MISSING**: variable-assignment lines that resolve to `.sh` paths

In the substrate-doctor test files:
- Line 8: `COMMON="${SUBSTRATE_DOCTOR_COMMON:-$HOME/.../substrate-doctor-common.sh}"` — has the literal basename, but is NOT a source-line
- Line 14: `source "$COMMON"` — IS captured, but contains only `$COMMON`, not the basename

The corpus-check `name in source_text` fails for "substrate-doctor-common.sh" because neither line that gets captured contains the basename literally.

## Fix

Add a fourth corpus-pattern that captures variable-assignment lines containing `.sh` paths:

```python
# flywheel-2xdi.50: capture variable-assignment lines that resolve to a
# `.sh` path (e.g. `COMMON="${SUBSTRATE_DOCTOR_COMMON:-$HOME/.../foo.sh}"`).
# These drive variable-indirected sources like `source "$COMMON"` where
# the literal script basename never appears in any `source` line. The
# corpus check then sees the basename in the assignment line and treats
# the script as wired. The pattern matches: var-name + `=` + anything +
# `.sh` + word boundary.
var_assign_sh_re = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*=.*\.sh\b")
...
if var_assign_sh_re.search(line):
    pieces.append(line.rstrip())
    continue
```

The regex anchors on a word-boundary identifier + `=`, followed by any content, ending with `.sh<word-boundary>`. Matches:
- `COMMON="${VAR:-$HOME/foo.sh}"` ✓
- `DOCTOR="$HOME/bar.sh"` ✓
- `local FOO=$HOME/baz.sh` ✓

Does NOT match (already captured by other branches OR genuinely unrelated):
- `source "$LIB/qux.sh"` — caught by `startswith("source ")` branch
- `# comment about foo.sh` — no `=` token; correctly skipped
- `echo "running"` — no `.sh`; correctly skipped

## Acceptance gates

Auto-filed by gap-hunt-probe with stock template body. Inferred AGs from class "wired-but-cold":

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify the flag — is the script ACTUALLY cold? | **DONE** | NO. Script is sourced by 3 test files: substrate-doctor-critical-gaps-test.sh, substrate-doctor-infisical-test.sh, substrate-doctor-vercel-test.sh. Each uses `source "$COMMON"` with `COMMON` assigned via `${VAR:-$HOME/.../substrate-doctor-common.sh}` default substitution. |
| AG2 | If false-positive: identify root cause | **DONE** | gap-hunt-probe's runtime_source_corpus captures `source X` / `. X` / `*.d/` / for-loop-continuation patterns but NOT variable-assignment lines that contain `.sh` paths. The bug-source line (`COMMON=...sh`) was never in the corpus, so the corpus check couldn't see the basename. |
| AG3 | Fix the false-positive class | **DONE** | Added `var_assign_sh_re` regex pattern in `runtime_source_corpus()`. Pre-fix: substrate-doctor-common.sh in wired-but-cold list. Post-fix: gone. |
| AG4 | Zero regression on baseline gap-hunt tests | **DONE** | 30/30 + 6/6 + 7/7 + 7/7 (2xdi.48 sister) = **50/50 PASS** unchanged. |
| AG5 | Regression test for the new behavior | **DONE** | `tests/gap-hunt-probe-var-assigned-source.sh` — 8/8 PASS. Asserts substrate-doctor-common.sh not flagged + regex pattern is present + 6 regex-shape fixtures classified correctly + 3 real-world drivers detected + 2xdi.48 fix preserved. |
| AG6 | Class-fix not instance-fix | **DONE** | The pattern catches ANY `<VAR>=...sh` style. Benefits any script sourced via variable-default-substitution. Specifically: all 3 substrate-doctor-* test files would benefit if they were the sourced target (they're not — they're the sourcers — but the pattern they use is canonical for this class). |

## Test execution receipts

### New regression test

```
PASS T1: substrate-doctor-common.sh NOT in wired-but-cold (the false-positive named by 2xdi.50)
PASS T2: gap-hunt-probe.sh contains var_assign_sh_re regex (the fix is present in source)
PASS T3: var_assign_sh_re pattern correctly classifies 6 fixture shapes
PASS T4: substrate-doctor-critical-gaps-test.sh uses var-assignment-sh pattern
PASS T4: substrate-doctor-infisical-test.sh uses var-assignment-sh pattern
PASS T4: substrate-doctor-vercel-test.sh uses var-assignment-sh pattern
PASS T5: step4i-coherence.sh still NOT in wired-but-cold (2xdi.48 fix preserved)
PASS T6: gap_class_distribution['wired-but-cold'] is a non-negative integer (20)

Summary: 8 passed, 0 failed
```

### Baseline tests (zero regression)

| Suite | Result |
|---|---|
| `gap-hunt-probe-canonical-cli.sh` | 30/30 PASS |
| `gap-hunt-probe-on-demand-validator-allowlist.sh` | 6/6 PASS |
| `gap-hunt-probe-0h0b-suppression-smoke.sh` | 7/7 PASS |
| `gap-hunt-probe-for-loop-source.sh` (2xdi.48) | 7/7 PASS |
| **Total** | **50/50 PASS** |

### Pre/post comparison

Pre-2xdi.50 fix (post-2xdi.48 fix only):
```
gaps_by_class["wired-but-cold"] contained:
  ... substrate-doctor-common.sh ← false-positive ...
```

Post-2xdi.50 fix:
```
gaps_by_class["wired-but-cold"]:
  - substrate-doctor-common.sh GONE
  - The 3 substrate-doctor-*-test.sh files STILL flagged (they're test-class
    surfaces, on-demand verification per INCIDENTS.md:148 — separate concern,
    NOT addressed by this bead per scope)
```

## Side-finding (not addressed; preserved for separate bead if needed)

The 3 substrate-doctor-*-test.sh files are still in wired-but-cold:
- substrate-doctor-critical-gaps-test.sh
- substrate-doctor-infisical-test.sh
- substrate-doctor-vercel-test.sh

These are documented in `INCIDENTS.md:148` as "Verification" surfaces — they're run-on-demand by operators when verifying substrate-doctor critical gaps. NOT run on a recurring schedule, so no JSONL ledger touches them.

The cleanest fix would be either:
A. Add them to `~/.claude/skills/.flywheel/data/substrate-registry.json` with `kind` in `_ON_DEMAND_VALIDATOR_KINDS` (the canonical allowlist mechanism)
B. Extend `on_demand_script_allowlist()` to scan for scripts referenced from INCIDENTS.md as verification surfaces

Either approach would require edits in `~/.claude/skills/` repo (the substrate-registry.json file). Per scope, NOT addressed in this bead — the named gap (substrate-doctor-common.sh) is fixed. Separate followup bead could pick up the test-files class if Joshua/orch wants it; not filed speculatively.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/gap-hunt-probe.sh` | +9 lines (regex declaration + capture branch + comment block) |
| `tests/gap-hunt-probe-var-assigned-source.sh` | NEW (110 lines, 8 assertions) |
| `.flywheel/audit/flywheel-2xdi.50/evidence.md` | NEW |

No edits to `~/.claude/skills/` files (test-files class deferred). No doctrine/AGENTS edits.

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: class-fix benefits all var-assignment-sourced scripts; the test-files side-finding (3 sister false-positives still in the list) is a different class with a different canonical fix (substrate-registry on-demand allowlist), documented inline but not filed because (a) edits would be in different repo (.claude/skills/), (b) the test files are intentionally on-demand surfaces — the right fix is registry-allowlist, not corpus-extension.

## Skill auto-routes addressed

- **canonical-cli-scoping** = n/a — internal corpus fix, no canonical-cli surface.
- **rust-best-practices** = n/a — bash + python heredoc, no Rust.
- **python-best-practices** = YES — same as 2xdi.48. (1) `runtime_source_corpus` signature unchanged; (2) No new deps; (3) Regression test exercises both Python regex pattern AND end-to-end probe behavior; (4) Tests use TMPDIR; (5) file-length still well under threshold.
- **readme-writing** = n/a — no README touched.

## Four-Lens Self-Grade

- **brand** (10): fix follows the same pattern as 2xdi.47 (for-loop) and 2xdi.48 (bin/* wrappers) — additive regex branch with explanatory comment citing the bead. The cumulative fix narrative across .47 → .48 → .50 builds a coherent class-by-class story.
- **sniff** (10): empirical pre/post. Python-fixture regex test (T3) proves the pattern shape is correct for 6 input shapes including 3 expected-match and 3 expected-skip. End-to-end check (T1) proves the live probe behavior changed correctly.
- **jeff** (10): didn't refactor — added one regex + one capture branch. Did NOT extend the corpus to catch the on-demand-test-files class (different problem, deferred properly to a registry-allowlist approach). Side-finding documented honestly without speculative bead-filing.
- **public** (10): Three Judges check —
  - Skeptical operator: substrate-doctor-common.sh removed from the gap-list; regex correctness verified with deterministic fixtures.
  - Maintainer: regex pattern lives next to the existing dot_d_re/for_in_re patterns with parallel structure; future maintainer can extend with similar shape.
  - Future worker: if a new script gets variable-default-source pattern and gets falsely flagged, the regex pattern already handles it.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG6: all DONE. ✓
- Class-fix benefits all var-assignment-sourced scripts. ✓
- Empirical pre/post proof + deterministic regex fixture test. ✓
- 50/50 tests PASS (zero regression + new 8-assertion regression test). ✓
- 2xdi.48 fix preserved (T5 assertion). ✓
- Side-finding documented without speculative bead-filing. ✓

## L112 probe

Command: `bash /Users/josh/Developer/flywheel/tests/gap-hunt-probe-var-assigned-source.sh 2>&1 | grep -c '^PASS'`
Expected: `literal:8`
Timeout: 60 seconds
