---
title: flywheel-m12ji evidence — fleet-wide mutation-gate-ordering audit
type: evidence
created: 2026-05-10
bead: flywheel-m12ji
sister: flywheel-hoqq8 (the bash-scaffolder fix that surfaced this invariant)
chain: scaffolder-py-followup / fleet-wide-audit
---

# flywheel-m12ji evidence

**Status:** DONE — fleet-wide audit complete. **0 hoqq8-class violations remain.** The bash scaffolder fix at flywheel-hoqq8 was the only surface in `.flywheel/scripts/` that violated the invariant; all other apply-mode surfaces use the helper-lib's `cli_refuse_apply_without_idem_key` which is structurally clean by construction.

## Invariant audited

> **Mutation gates must fire BEFORE mutation side-effects.**

Surfaced by flywheel-hoqq8 fix to scaffold-canonical-cli.sh (commit 533d45e). Before the fix, the bash scaffolder wrote `tests/<basename>-canonical-cli.sh` to TESTS_DIR before its `--apply` without `--idempotency-key` refusal exited rc=3 — polluting the repo with a test pointing at an unscaffolded target.

## Audit scope

All `.flywheel/scripts/*.sh` files containing both `--apply` AND `--idempotency-key` flags. This is the canonical signature of "surface that has a mutation gate."

| Scope | Count |
|---|---:|
| Total `.sh` files in `.flywheel/scripts/` (estimate) | ~250 |
| Has `--apply` flag | 177 |
| Has `--apply` AND `--idempotency-key` (audit candidates) | **95** |
| Has `--apply` but NOT `--idempotency-key` (separate class — not hoqq8 invariant) | 82 |

The 82 no-key candidates are out of scope for THIS bead — the hoqq8 invariant is specifically about ordering between the gate and side-effects. Surfaces with `--apply` but no `--idempotency-key` may still be a legitimate concern (no gate at all), but that's a different bug class deserving its own audit. **Filing as orch-action recommendation.**

## Audit method

A Python scanner (`scanner.py` in this audit dir) classifies each candidate by:

1. **Detect apply-key gate lines** via patterns matching:
   - `cli_refuse_apply_without_idem_key` (helper-lib call)
   - `$mode == "apply" && -z $idem_key` (inline gate)
   - Inline JSON refusal envelope shapes
2. **Detect mutation side-effect lines** via patterns matching:
   - File writes (`>`, `>>`) to non-tmp paths
   - `cp`, `mv`, `rm -rf`, `sed -i` to non-tmp targets
   - `mkdir -p`, `chmod`, `touch` outside tmp paths
   - Mutating git commands (`commit`, `push`, `reset --hard`)
3. **Detect apply-mode block openers** via patterns matching `if [[ "$mode" == "apply" ]]; then`
4. **Verdict:** if any side-effect line under an apply-mode block occurs BEFORE the first gate line, flag as VIOLATION

### Scanner caveat (acknowledged)

The scanner is a heuristic. Initial v1 had a regex bug that missed gates of the form `"$mode" == "apply"` (the dollar-sign-quoted-var form most surfaces use). v2 fixed the regex. The CLEAN_HELPER count went 1 → 66 between versions, and VIOLATIONS stayed at 0. Spot-checking confirms the v2 verdicts.

## Result

| Verdict | Count | Meaning |
|---|---:|---|
| **VIOLATION** | **0** | gate fires AFTER mutation side-effect |
| CLEAN_HELPER | 66 | Uses `cli_refuse_apply_without_idem_key` from helper-lib (structurally safe) |
| CLEAN | 1 | Uses inline gate ordered correctly (scaffold-canonical-cli-py.sh) |
| NEEDS_REVIEW | 0 | Apply-mode block but no gate found |
| NA_no_apply_logic | 28 | False positives in candidate list (no actual apply mutation) |

**Headline: 0 violations remain.** The bash scaffolder fix at hoqq8 was the entirety of the bug class in the with-key set.

## Why CLEAN_HELPER is structurally safe

The 66 CLEAN_HELPER surfaces are all canonical-cli-scaffolded via flywheel-ws02m / war3i. Their `scaffold_cmd_repair()` function follows a uniform shape:

```bash
scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="${2:-}"; shift 2 ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      ...
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    # rc=3 from the helper-lib
  fi
  # per-scope mutations only run AFTER the gate
  case "$scope" in ...
  esac
}
```

The gate is the first action after argument parsing. **No side-effects can occur before it because the function does no work between the case-statement and the gate.** This is structurally enforced by the scaffolder template — operator fillins go INSIDE the case-statement, AFTER the gate. The wave-1 / wave-2 fillins (vc3zs through 1fk5f.x) all preserve this contract.

Spot-check evidence (3 random CLEAN_HELPER surfaces):

| Surface | scaffold_cmd_repair line | helper-lib gate line |
|---|---:|---:|
| `storage-pressure-doctor.sh` | 247 | 263 |
| `idle-pane-auto-dispatch.sh` | 276 | 292 |
| `dispatch-self-test-delivery-identity.sh` | 277 | 293 |

In each case the helper-lib refusal call is in the function's preamble, before any per-scope mutation.

## Why CLEAN (inline) is safe

The single CLEAN entry — `scaffold-canonical-cli-py.sh` — uses an inline gate (no helper-lib dependency) at line 754, BEFORE the test-scaffold side-effect at line 767:

```bash
# Apply gate FIRST: --apply without --idempotency-key must refuse before any
# side-effect (test scaffolding, backup, mutation). Moved ahead of the
# test-scaffold block per flywheel-hoqq8 — ...
if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
  ...
  exit 3
fi

# Optional test scaffold (after the apply-gate so refused applies leave no trace).
local test_path test_scaffolded=false
test_path="$TESTS_DIR/${target_basename}-canonical-cli-py.sh"
if [[ "$no_test" -ne 1 ]]; then
  if [[ ! -e "$test_path" ]]; then
    mkdir -p "$TESTS_DIR" 2>/dev/null || true
    if [[ "$mode" == "apply" ]]; then
      emit_test_scaffold_py "$target_basename" "$target_rel" > "$test_path"
      ...
```

Same pattern as the bash scaffolder post-hoqq8.

## Per-violation fix-specs

**None required — 0 violations.** If a future violation surfaces, the canonical fix template is `flywheel-hoqq8/fix-diff.patch`:

1. Identify the apply-block side-effect (e.g. `if [[ "$mode" == "apply" ]]; then write_file; fi`)
2. Identify the apply-key gate (e.g. `if [[ "$mode" == "apply" && -z "$idem_key" ]]; then refuse + exit 3; fi`)
3. If the gate appears AFTER the side-effect: hoist the gate to fire BEFORE all side-effects in the function
4. Add a regression test using the `tests/scaffold-canonical-cli-apply-gate-regression.sh` template (3 paths × 3 assertions: refused / dry-run / valid apply)

## Orch-action recommendations surfaced

1. **82 surfaces have `--apply` without `--idempotency-key`** — these may not enforce a mutation gate at all. Different bug class from hoqq8 (no gate vs gate-after-mutation), but worth a separate audit. Sample of the 82 includes `agents-md-shard-extract.sh`, `apply-tmux-tuning.sh`, `apply-substrate-tuning.sh`, `auto-l112-gate.sh` — names suggest some are actually mutating. Filing as orch-action recommendation.

2. **The structural invariant could be enforced at lint time** — `canonical-cli-lint.sh` could add a new rule (L9 or similar) that detects "apply-mode side-effect line < first apply-key gate line" within the same function. This would catch the bug class at authoring time, not after a refused apply pollutes the repo. Filing as orch-action recommendation.

## Cross-references

- Sister bead (the bug fix that surfaced the invariant): `flywheel-hoqq8` (CLOSED, commit 533d45e, 990/1000)
- Reference fix-diff: `.flywheel/audit/flywheel-hoqq8/fix-diff.patch`
- Reference regression test: `tests/scaffold-canonical-cli-apply-gate-regression.sh` (9/9 PASS)
- Helper-lib structural safety: `.flywheel/lib/canonical-cli-helpers.sh::cli_refuse_apply_without_idem_key`
- Scanner: `.flywheel/audit/flywheel-m12ji/scanner.py`
- Per-bucket file listings: `clean-helper-list.txt` (66), `clean-inline-list.txt` (1), `na-list.txt` (28), `no-key-candidates.txt` (82)
- Audit results JSON: `.flywheel/audit/flywheel-m12ji/audit-results.json`

## Four-Lens Self-Grade

- **brand: 9** — fulfills the bead's promise (audit report + per-violation fix-spec, even when 0 violations); methodology generalizable to other invariants
- **sniff: 10** — scanner methodology + caveat acknowledged + spot-check evidence + 2 orch-action recommendations honestly surfaced (related-but-separate bug classes)
- **jeff: 9** — preserves repo state (audit only, no mutations); scanner artifact reusable for future audits; references the canonical hoqq8 fix-diff as the fix template
- **public: 9** — three judges check: skeptical operator (the 0-violation result is verifiable via the saved scanner + candidates list), maintainer (per-bucket lists + scanner + caveat), future worker (the helper-lib structural-safety argument is articulated)

`four_lens=brand:9,sniff:10,jeff:9,public:9`

## Compliance score

Audit complete + 0 violations confirmed + scanner methodology saved as reusable artifact + 2 orch-action recommendations surfaced + helper-lib structural-safety argument articulated + reference to hoqq8 fix-template = **970/1000**. -30 because the scanner is a heuristic (regex-based, not AST-based) — the v1 → v2 false-negative shows the limit of the approach. A more rigorous AST-based scanner could give 100% confidence; this scanner gives high confidence with spot-check verification.
