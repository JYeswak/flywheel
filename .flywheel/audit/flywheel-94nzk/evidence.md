# flywheel-94nzk — jq arglist-too-long in run_doctor + run_audit + run_why + run_validate

Bead: flywheel-94nzk (P2)
Surface: `.flywheel/scripts/agents-md-fleet-propagator.sh`
Sister: flywheel-1hshd.2 (CLOSED, the canonical-cli scaffold+fillin that surfaced this pre-existing bug)
Lane: bug
mutates_state: yes (script edited; one new wrapper helper; 5 callsites refactored; one new regression test)

## Bug reproduction (pre-fix)

`agents-md-fleet-propagator.sh` builds JSON payloads by passing the full ledger array via `--argjson rows "$rows"` to jq. The serialized JSON value is embedded in argv. macOS ARG_MAX is ~1MB; once the ledger reaches ~5000 rows (~1.9MB serialized), argv overflow triggers:

```
.flywheel/scripts/agents-md-fleet-propagator.sh: line 276: /opt/homebrew/bin/jq: Argument list too long
.flywheel/scripts/agents-md-fleet-propagator.sh: line 393: /opt/homebrew/bin/jq: Argument list too long
.flywheel/scripts/agents-md-fleet-propagator.sh: line 504: /opt/homebrew/bin/jq: Argument list too long
```

Affected surfaces (all 4 named in the bead title):
- `run_doctor` → calls `doctor_json` (line 393 `--argjson rows`)
- `run_audit` (line 492 `--argjson rows --argjson doctor`)
- `run_why` (line 504 `--argjson rows --argjson scan`)
- `run_validate` → calls `validate_ledger_json` (line 474 `--argjson rows`)

Also affected (transitively, via `doctor_json`):
- `last_apply_json` (line 276 `--argjson rows`)

The pre-fix bug was KNOWN: the existing test `tests/agents-md-fleet-propagator-canonical-cli.sh` had four assertions explicitly accepting EITHER the envelope OR the jq-arglist error:

```bash
if printf '%s' "$out" | grep -qE '"schema_version"|jq:.*Argument list too long'; then
  pass "validate ledger dispatched (envelope OR known jq-arglist-too-long bug)"
```

## Fix

### Helper: `fw_jq_with_rows`

A single wrapper takes ledger rows from stdin, writes them to a tmpfile, invokes jq with `--slurpfile rows <path>`, and cleans up the tmpfile. The jq filter unwraps the slurpfile's outer-array wrap via `($rows[0]) as $rows`.

```bash
fw_jq_with_rows() {
  local rows_file
  rows_file="$(mktemp -t fleet-prop-rows.XXXXXX)"
  cat >"$rows_file"
  jq -nc --slurpfile rows "$rows_file" "$@"
  local rc=$?
  rm -f "$rows_file"
  return $rc
}
```

**Why a wrapper-per-call instead of a global EXIT trap**: each of the 5 callsites is itself invoked via `$(...)` command substitution from higher-level callers (e.g., `last="$(last_apply_json)"` inside `doctor_json`). Bash subshells RESET the EXIT trap. Tracking tmpfiles in a parent-shell array (the original attempt during investigation) didn't work because the subshell's mutations never reached the parent. The wrapper-per-call approach keeps the tmpfile lifecycle local to the same subshell that created it; cleanup is reliable because jq's rc is captured BEFORE rm fires.

### 5 callsites refactored

Each pattern `--argjson rows "$rows"` → `ledger_rows_json | fw_jq_with_rows ...` with `($rows[0]) as $rows` unwrap in the filter.

| Callsite | Pre-fix | Post-fix |
|---|---|---|
| `last_apply_json` (L273) | `rows="$(ledger_rows_json)"; jq --argjson rows "$rows" '...'` | `ledger_rows_json \| fw_jq_with_rows '($rows[0]) as $rows \| ...'` |
| `doctor_json` (L388) | passes `--argjson scan --argjson last --argjson rows` | `ledger_rows_json \| fw_jq_with_rows --argjson scan ... --argjson last ... '($rows[0]) as $rows \| ...'` |
| `validate_ledger_json` (L471) | `--argjson rows "$rows"` | `ledger_rows_json \| fw_jq_with_rows '($rows[0]) as $rows \| ...'` |
| `run_audit` (L487) | `--argjson rows --argjson doctor --argjson contract_present` | `ledger_rows_json \| fw_jq_with_rows --argjson doctor ... --argjson contract_present ... '($rows[0]) as $rows \| ...'` |
| `run_why` (L499) | `--argjson rows --argjson scan` | `ledger_rows_json \| fw_jq_with_rows --argjson scan ... '($rows[0]) as $rows \| ...'` |

Bounded values (`scan`, `last`, `doctor`, `contract_present`) STAY on `--argjson` — they're tiny envelopes (single rows or fixed-repo-list output, ≤ a few KB) and not the source of the ARG_MAX overflow.

### Test assertions tightened

The 4 test sites in `tests/agents-md-fleet-propagator-canonical-cli.sh` previously accepted EITHER envelope OR the bug error. Post-fix they require the envelope strictly AND assert no jq-arglist error:

```bash
out="$("$SCRIPT" validate ledger --json 2>&1 || true)"
if printf '%s' "$out" | grep -qE '"schema_version"' \
   && ! printf '%s' "$out" | grep -qE 'jq:.*Argument list too long'; then
  pass "validate ledger dispatched (envelope strict, no jq-arglist bug)"
```

Added `--json` to validate/why calls (audit already had it) so text-mode output doesn't mask the envelope match.

### Regression test added

`tests/agents-md-fleet-propagator-large-ledger.sh` — 7 assertions:
1. Synthetic ledger size > 1.5MB (proves overflow scale)
2. doctor --json envelope under large ledger; no jq-arglist error
3. audit --json envelope under large ledger; no jq-arglist error
4. validate ledger --json envelope under large ledger; no jq-arglist error
5. why <id> --json envelope under large ledger; no jq-arglist error
6. audit ledger_rows_total == 5000 (proves slurpfile reads the complete ledger)
7. No leftover `fleet-prop-rows.*` tmpfiles after script exits (proves cleanup is reliable)

## Acceptance gates

Bead has no explicit AC list (Title-only). Inferred AGs from title:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Reproduce the bug | **DONE** | 5000-row synthetic ledger (~1.9MB) triggers `jq: Argument list too long` on lines 276, 393, 504, and 474 (pre-fix). Captured in investigation. |
| AG2 | Fix all 4 named surfaces (`run_doctor`, `run_audit`, `run_why`, `run_validate`) | **DONE** | All 4 surfaces + the transitive `last_apply_json` use `fw_jq_with_rows` (slurpfile + tmpfile cleanup). No `--argjson rows` remaining in the script. |
| AG3 | Zero regression on existing tests | **DONE** | `tests/agents-md-fleet-propagator-canonical-cli.sh` 20/20 PASS; `tests/agents-md-fleet-propagator.sh` 5/5 PASS — identical to pre-fix baseline counts (which had bug-or-envelope assertions). |
| AG4 | Tighten test assertions that accepted the bug | **DONE** | 4 assertions in `agents-md-fleet-propagator-canonical-cli.sh` (L65, L101, L106, L111) require envelope strictly AND `! grep -qE 'jq:.*Argument list too long'`. `--json` flag added where missing. |
| AG5 | Regression test that exercises the large-ledger path | **DONE** | `tests/agents-md-fleet-propagator-large-ledger.sh` — 7 assertions, 7/7 PASS. Builds 5000-row synthetic ledger (~1.9MB) and exercises all 4 surfaces + cleanup verification. |
| AG6 | Tmpfile cleanup is reliable | **DONE** | T7 in regression test asserts `find ... fleet-prop-rows.* -mmin -1` returns 0 after script exits. Cleanup is inline-per-call inside `fw_jq_with_rows` (no global trap; trap-in-subshell would not fire). |

## Test execution receipts

### Pre-fix baseline (pre-this-bead state, ARG_MAX overflow path)

Synthetic 5000-row ledger / 1.9MB serialized:
```
running doctor...    jq: Argument list too long (RC=0, malformed envelope)
running audit...     jq: Argument list too long (RC=0, malformed envelope)
running why ...      jq: Argument list too long (RC=0, malformed envelope)
```

### Post-fix (current)

```
tests/agents-md-fleet-propagator-canonical-cli.sh: 20/20 PASS  (existing baseline tightened)
tests/agents-md-fleet-propagator.sh:               5/5 PASS    (existing baseline unchanged)
tests/agents-md-fleet-propagator-large-ledger.sh:  7/7 PASS    (NEW regression test)
                                                   ----
TOTAL:                                             32/32 PASS
```

Functional smoke (5000-row synthetic ledger):
- `doctor --json` → envelope emitted; `status=pass`; no jq error
- `audit --json` → envelope emitted; `ledger_rows_total: 5000`; no jq error
- `validate ledger --json` → envelope emitted; `rows_checked: 5000`; no jq error
- `why <id> --json` → envelope emitted; ledger_match found; no jq error
- `find $TMPDIR -name 'fleet-prop-rows.*' -mmin -1 | wc -l` → 0

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/agents-md-fleet-propagator.sh` | +27 lines (helper + comment block); 5 callsites refactored (~10 LOC each); total +50 / -25 net |
| `tests/agents-md-fleet-propagator-canonical-cli.sh` | 4 assertions tightened (env strict; no bug accept); `--json` added to validate/why |
| `tests/agents-md-fleet-propagator-large-ledger.sh` | NEW (95 lines, 7 assertions) |
| `.flywheel/audit/flywheel-94nzk/evidence.md` | NEW |

No doctrine/INCIDENTS/AGENTS.md/L-rule edits (this is a localized bash bug fix). No memory edit.

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: bug fully resolved; new regression test catches future regressions; no new gaps surfaced.

## Skill auto-routes addressed

- **canonical-cli-scoping** = YES — fix preserves all canonical-cli surfaces (doctor/health/repair/validate/audit/why/quickstart). `--json` shape unchanged for downstream consumers. File-length: 628 → 656 lines (under 900 threshold). New helper `fw_jq_with_rows` is internal — does not add a surface.
- **rust-best-practices** = n/a — bash script, no Rust.
- **python-best-practices** = n/a — regression test uses python3 only for synthetic ledger generation (fixture data); not a python module.
- **readme-writing** = n/a — no README touched.

## Four-Lens Self-Grade

- **brand** (10): fix cites bead in source comment block; documents the subshell-trap-doesn't-fire reasoning so future maintainers don't repeat the failed-attempt approach. Helper named with `fw_` prefix matching fleet convention. Tests tightened (not just hoarded) — bug-accept clauses removed.
- **sniff** (10): every claim is empirical. Pre-fix bug reproduced and captured with exact error message. Post-fix verified across all 4 surfaces with 5000-row ledger. Cleanup verification asserted explicitly (test 7).
- **jeff** (10): didn't refactor beyond what fixed the bug. Bounded values (scan/last/doctor) stay on `--argjson` (no over-engineered uniform slurpfile-everywhere). The investigation path (initial attempt with EXIT trap + named-variable helper) was documented in evidence comment so future workers understand why the simpler wrapper-per-call shape won.
- **public** (10): Three Judges check —
  - Skeptical operator: regression test deterministically reproduces the pre-fix bug class (5000-row synthetic ledger) and proves the fix; tmpfile cleanup verified.
  - Maintainer: helper has a clear `Usage:` comment; the subshell-scope reasoning is documented so the wrapper-shape decision is reviewable.
  - Future worker: when ledger grows beyond ARG_MAX, the wrapper handles it transparently. If someone adds a new jq-with-rows callsite, they pipe to `fw_jq_with_rows` and follow the `($rows[0]) as $rows` unwrap pattern.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG6: all DONE. ✓
- Bug reproduced empirically. ✓
- All 4 named surfaces fixed (plus transitive `last_apply_json`). ✓
- 20+5+7 = 32/32 tests PASS (zero regression + tightened assertions + new regression test). ✓
- Tmpfile cleanup reliable + verified. ✓
- Test assertions no longer accept the bug as a pass-condition (no theater). ✓
- Inline comment + this evidence pack document both the fix AND the failed-attempt reasoning. ✓

## L112 probe

Command: `bash /Users/josh/Developer/flywheel/tests/agents-md-fleet-propagator-large-ledger.sh 2>&1 | grep -c '^PASS'`
Expected: `literal:7`
Timeout: 30 seconds
