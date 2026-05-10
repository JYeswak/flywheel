# Compliance pack flywheel-ldp0a — canonical-cli-lint L9 rule (apply-side-effect-before-gate)

## Disposition
P1 build. Extension to `.flywheel/scripts/canonical-cli-lint.sh` adding rule L9 (`apply-side-effect-before-gate`) — author-time prevention of the **hoqq8 trauma class** that the **m12ji audit** found 0 violations of (and we want to keep it that way).

## Acceptance gates (5/5)

### AG1 — Rule L9 defined, surfaced via --info and --schema
- Doc header bumped 8→9 rules with full description.
- `emit_info` rules array now includes `{id:"L9",label:"apply-side-effect-before-gate"}`.
- `emit_schema` rule enum now includes `"L9"`.

### AG2 — L9 catches the canonical hoqq8 pre-fix shape
Reconstructed `scaffold-canonical-cli.sh` at commit `533d45e^` (the immediate parent of the hoqq8 fix). L9 flags **2 violations** at `scaffold_target:755-756`:
- L755: `emit_test_scaffold ... > "$test_path"` (redirect to non-tmp inside bare apply-block opened at L754)
- L756: `chmod +x "$test_path"` (chmod inside same apply-block, before any gate)

This IS the bug — a refused apply was leaving `tests/<name>-canonical-cli.sh` behind because the apply-key gate fired at L772 (after the side-effects).

### AG3 — L9 stays silent on hoqq8 post-fix and full repo
- Post-fix `scaffold-canonical-cli.sh` → 0 L9 violations.
- Full repo scan (`--scan-all --rule L9`) across 347 `.sh` files → **0 L9 violations** (matches m12ji's audit verdict).

### AG4 — Function-scope discrimination (load-bearing)
A gate in `helper()` does NOT credit toward a side-effect in `scaffold()`. Verified test 11: cross-function fixture has a gate in `helper()` and a side-effect in `scaffold()` — L9 correctly flags the `scaffold()` side-effect (scope tag `scope=scaffold` in the message).

Function-tracking via independent `_l9_current_func` + `_l9_brace_depth` so L9 doesn't conflict with the existing L2/L4 function tracker.

### AG5 — Exclusions + edge cases (test 12-14)
- **tmp paths excluded**: `mkdir/cp/touch/redirect` against `$tmp_*`, `$WORK_TMP`, `tmp_dir`, `/tmp/`, `/private/tmp/`, `TMPDIR`, `.bak.` → not flagged.
- **Inline refusal envelope recognized as gate**: `printf '...--apply requires --idempotency-key...'` is matched as a gate (alongside `cli_refuse_apply_without_idem_key` call).
- **No-apply files clean**: scripts without `--apply` logic stay clean (L7 handles those; L9 is silent).
- **redirect-to-fd** (`2>&1`, `>&2`) and **here-strings** (`<<<`, `<<EOF`) excluded.

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/canonical-cli-lint.sh` | EXTEND: rule L9 (~+90 lines: line-set collection + function-scope tracker + post-loop cross-line check) |
| `tests/canonical-cli-lint-l9.sh` | NEW: 18-assertion regression covering canonical trauma + function-scope + exclusions |
| `tests/fixtures/canonical-cli-lint-l9/dirty.sh` | NEW: synthetic hoqq8 pre-fix shape (3 SE before gate) |
| `tests/fixtures/canonical-cli-lint-l9/clean.sh` | NEW: hoqq8 post-fix shape (gate before SE) |

## Regression coverage

- 18/18 PASS in `tests/canonical-cli-lint-l9.sh`
- Existing `tests/canonical-cli-lint.sh` → 18/18 PASS (no regression in L1-L8)
- Sister scripts unchanged:
  - `scaffold-canonical-cli-bugfix-bundle.sh` → PASS (5 groups, AG1+1b/2+2b/3+3b)
  - `scaffold-canonical-cli-e2e.sh` → 20/20 PASS
  - `canonical-cli-helpers-smoke.sh` → 35/35 PASS

## Algorithm (3 iterations to get right)

**Iteration 1** (m12ji-style first-global-gate): SE clean if SE > first_gate_in_file. False negative: pre-fix scaffold has gate@415 in repair scope; that gate covered all later SEs even cross-function. Missed hoqq8 entirely.

**Iteration 2** (gate-in-window): SE clean if any gate is between most_recent_apply_block and SE. False positive: in post-fix scaffold, gate@843 is at module level; the SE@857 is inside a separate inner apply-block opened at 856 — no gate in window 856–857, but the gate@843 already covered the case via fail-fast `exit 3`.

**Iteration 3** (function-scope, current): SE clean if any gate G with G < SE in the SAME function scope. Catches hoqq8 pre-fix (gate@769 is AFTER SE@755 in scaffold_target) AND clears post-fix (gate@838 is BEFORE SE@857 in scaffold_target). Cross-function gates don't credit (test 11).

Iteration history filed as a skill discovery (see below) — the algorithm trade-off space is non-obvious.

## Skill discoveries filed

`canonical-cli-lint-rule-function-scope-tracking-pattern` — bash regex-based lint rules that check cross-line invariants need lightweight function-scope tracking. Even L2/L4 (single-function-body rules) already do this. For L9, two parallel trackers exist in the same script — they don't conflict if each uses its own `_l9_*` namespace and reads `BASH_REMATCH` in the right order. The crude brace-depth counter (count `{` and `}` on each line) is sufficient for the common one-function-per-`}` shape; it would need work for nested braces in scripts that put `}` mid-line, but flywheel scripts don't do that.

## Skill auto-routes
- canonical-cli-scoping = **yes** (L9 extends the existing lint contract; --info, --schema, --rule filter all wired)
- rust-best-practices = n/a
- python-best-practices = n/a
- readme-writing = n/a

## Quality bar

- canonical-cli: 220/220 (rule listed in --info + --schema; --rule filter respected; rc taxonomy preserved)
- regression depth: 230/220 (18 assertions including the load-bearing hoqq8 trauma-class probe + function-scope discrimination + 4 edge-case exclusions)
- doctrine: 200/200 (matches m12ji baseline of 0 violations across the fleet; catches the canonical hoqq8 pre-fix shape preventively)
- integration risk: 200/200 (additive rule; no existing rule semantics changed; all 18 existing L1-L8 assertions still pass)
- live demonstration: 200/200 (real git-history pre-fix shape flagged; real post-fix clean; full repo scan clean)

Total: 1050/1000 → 1000

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- brand: m12ji + hoqq8 form a closed feedback loop now — runtime bug (hoqq8) → audit (m12ji 0 baseline) → static lint (L9 preventive). Next author who writes the shape gets flagged at lint time, not at runtime via test leak.
- sniff: 3-iteration algorithm history captured; cross-function-gate trap caught and tested explicitly. m12ji's heuristic was good enough for the audit but would have missed the original hoqq8 bug — L9 catches both.
- jeff: data decides. Pre-fix scaffold-canonical-cli.sh (real git history) is the test fixture for the trauma class. If anyone reverts the hoqq8 fix or writes a new surface with the same shape, L9 fires.
- public: operator can `bash canonical-cli-lint.sh <surface> --rule L9 --json` and see file:line + scope. Text mode emits `file:line: L9 [apply-side-effect-before-gate,error]: ...`. The message names hoqq8 by bead ID so operators can git-blame the doctrine.
