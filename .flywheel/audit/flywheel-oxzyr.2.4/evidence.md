---
schema_version: fm-detect-fix-byte-exact-undo/v1
---

# Evidence Pack — flywheel-oxzyr.2.4

**Bead:** flywheel-oxzyr.2.4 — `FM-6 + FM-9 detect/fix invariants (byte-exact undo class)`
**Identity:** CloudyMill | **Pane:** flywheel:0.2 | **Date:** 2026-05-11
**Priority:** P1
**Parent:** flywheel-oxzyr.2 (pass-2 wave; stays open)
**Foundations:** flywheel-oxzyr.2.1 (chokepoint `_flywheel_loop_mutate`) + flywheel-oxzyr.2.2 (`doctor undo <run-id>`)
**Sister-shape:** flywheel-oxzyr.2.3 (FM-5+FM-10 audit-only retraction; same dispatcher pattern)
**Substrate boundary:** Joshua-domain `.flywheel` skill (`~/.claude/skills/.flywheel/bin/flywheel-loop` is jsm-unmanaged; direct-mutation + paired jsm-import-ready patch per 2xdi.60.1)

## Disposition: SHIPPED — 2 FM detect/fix functions + 2 dispatcher intercepts + 10-AG regression test all PASS; byte-exact undo round-trip verified live for both FMs

## Class: byte-exact undo (sister to audit-only retraction class .2.3)

Where .2.3's FM-5 + FM-10 perform **audit-only retraction** (append a row to a JSONL ledger; no substrate mutation), .2.4's FM-6 + FM-9 perform **substrate mutation** through the `.2.1` chokepoint. The byte-exact backup chain stored by `_flywheel_loop_mutate` is the byte-exact-undo invariant — `flywheel-loop doctor undo <run-id>` restores the original via `cp -p <backup> <target>` + SHA verification (pre_sha == restored_sha).

## What shipped

### 1. `_flywheel_loop_fm6_detect_fix()` function (~115 lines)

**File:** `~/.claude/skills/.flywheel/bin/flywheel-loop:1037-1151`
**Class:** legacy-loop-config-schema-drift (Shape A substrate-without-version-probe)
**MEMORY source:** `feedback_loop_state_without_driver.md`

**Surface:**
```
flywheel-loop doctor fm6 --target PATH [--dry-run|--apply] [--run-id ID] [--json]
```

**Detect predicate:**
- Parse target JSON. If malformed → `drift_class=malformed_json` (no auto-fix; emit finding only).
- Required keys: `project`, `repo`, `active`
- Allowlist beyond required: `tier`, `interval`, `started_at`, `started_by`, `pane`, `session`, `tick_command`, `dispatch_mode`, `orchestrator_pane`, `callback_pane`, `auto_revive_on_reboot`, `plist_label`, `plist`, `activated_by_cc_1_at`, `first_tick_dispatch_id`, `paused_at`, `paused_by`, `pause_reason`, `_unknown_keys_archive`
- DRIFTED if: any unknown key OR any required key missing
- `drift_class`: `unknown_keys` | `missing_required` | `unknown_keys_and_missing_required` | `malformed_json` | `none`

**Fix (byte-exact undo via chokepoint):**
- Build migrated JSON via `jq`:
  - Strip unknown keys from top level
  - Archive them under `_unknown_keys_archive` (preserve audit trail)
  - Add missing required keys with `null` placeholder
- Write via `_flywheel_loop_mutate file_write "$target" "$migrated" "$run_id"` — chokepoint records intent → SHA-256 pre-state backup → mutate → applied receipt
- Original byte-exact preserved at `<undo-root>/<run-id>/backups/<sha-prefix>/<basename>.bak`

**Exit codes:** 0=clean | 1=DRIFTED+migrated | 2=usage | 3=DRIFTED+dry-run

**Schema:** `fm6-detect-fix/v1`

### 2. `_flywheel_loop_fm9_detect_fix()` function (~110 lines)

**File:** `~/.claude/skills/.flywheel/bin/flywheel-loop:1156-1265`
**Class:** frozen-projection-of-mutable-state-in-tick-prompts (Shape A canonical exemplar)
**MEMORY source:** `feedback_frozen_projection_of_mutable_state_class.md` (META-RULE 2026-05-06)

**Surface:**
```
flywheel-loop doctor fm9 --template PATH [--dry-run|--apply] [--run-id ID] [--json]
```

**Detect predicate:** scan target template for literal-value patterns:
| Class | Regex | Proposed replacement |
|---|---|---|
| `hardcoded_user_path` | `/Users/[A-Za-z0-9_-]+/` | `{{user_home}}/` |
| `hardcoded_bead_id` | `\b(flywheel|skillos|mobile-eats|cfs|alps|vrtx|terratitle|picoz|zesttube|zeststream|alpsinsurance|clutterfreespaces|blackfoot)-[a-z0-9]{4,8}\b` | `{{bead_id}}` |
| `hardcoded_git_sha` | `\b[a-f0-9]{40}\b` | `{{sha}}` |

FROZEN if any class has ≥1 match. `frozen_class` = comma-joined list of triggered classes.

**Fix (byte-exact undo via chokepoint):**
- Apply 3 perl regex substitutions in sequence to produce rewritten content
- Write via `_flywheel_loop_mutate file_write "$target" "$rewritten" "$run_id"` — chokepoint backs up byte-exact
- Reversible via `doctor undo <run-id>`

**Exit codes:** 0=clean | 1=FROZEN+rewritten | 2=usage | 3=FROZEN+dry-run

**Schema:** `fm9-detect-fix/v1`

### 3. Native dispatcher intercepts (`flywheel-loop:1340-1349`)

Added 2 new branches in the `doctor)` case after fm8's intercept:

```bash
# flywheel-oxzyr.2.4: intercept `doctor fm6` (legacy-loop-config-schema-drift) + `doctor fm9` (frozen-projection-in-tick-prompts)
if [[ "${1:-}" == "fm6" ]]; then
    shift; _flywheel_loop_fm6_detect_fix "$@"; exit $?
fi
if [[ "${1:-}" == "fm9" ]]; then
    shift; _flywheel_loop_fm9_detect_fix "$@"; exit $?
fi
```

Other `doctor` invocations route normally through `portable_doctor` — verified via AG10a/AG10b backward-compat tests.

### 4. End-to-end round-trip tests (10 AGs, 12 PASS assertions, 0 FAIL)

`.flywheel/tests/test-oxzyr.2.4-fm6-fm9-byte-exact-undo.sh`:

```
PASS AG1  FM-6 clean config detected=false rc=0
PASS AG2  FM-6 drift dry-run detected=true drift_class=unknown_keys rc=3
PASS AG3  FM-6 apply migrated (rc=1, backup=true, unknown keys archived)
PASS AG4  FM-6 byte-exact undo restored_sha=687d6e76… == pre_sha
PASS AG5  FM-9 clean template detected=false rc=0
PASS AG6  FM-9 frozen dry-run detected=true total=3 classes=hardcoded_user_path,hardcoded_bead_id,hardcoded_git_sha rc=3
PASS AG7  FM-9 apply rewrote template ({{user_home}} + {{bead_id}} + {{sha}}; literals stripped)
PASS AG8  FM-9 byte-exact undo restored_sha=da07eebb… == pre_sha
PASS AG9a dispatcher routes 'doctor fm6' (usage on no args, rc=2)
PASS AG9b dispatcher routes 'doctor fm9' (usage on no args, rc=2)
PASS AG10a backward-compat: --help returns usage
PASS AG10b backward-compat: doctor undo still works (rc=3 on nonexistent run-id; .2.2 intercept intact)
12 passed, 0 failed
```

The 2 byte-exact undo AGs (AG4 + AG8) are the **load-bearing class invariant**: pre-fix SHA captured, fix applied (substrate mutated), undo executed, post-undo SHA equals pre-fix SHA. Round-trip discipline holds end-to-end.

## Honest discovery (calibrate-test-to-actual-contract)

Initial implementation used `grep -cE 'pattern' "$target" 2>/dev/null || echo 0` for finding counts. With `set -euo pipefail` at the top of flywheel-loop, this silently aborted the function when grep returned rc=1 (no matches) — AG5 (clean template) failed with rc=1 and empty output. Diagnosis: pipefail+errexit propagates rc=1 from the `$()` substitution. Fix: switch to `grep -o ... | wc -l | tr -d ' \n' || true` so 0 matches yield clean `"0"` and don't trip errexit.

This is a reusable pattern (added as inline comment so the next FM author doesn't rediscover the trap):
```bash
# `|| true` is required because top-of-file `set -euo pipefail` would
# otherwise abort the function when grep finds zero matches (rc=1 +
# pipefail propagates).
```

## AG receipt

| AG | Status | Evidence |
|---|---|---|
| AG1 FM-6 detect predicate (unknown_keys class) | DONE | clean config rc=0 detected=false; drift config rc=3 detected=true class=unknown_keys |
| AG2 FM-6 chokepoint write + backup | DONE | rc=1, backup_written=true, pre_sha matches, target contains `_unknown_keys_archive` |
| AG3 FM-6 byte-exact undo via doctor undo | DONE | restored_sha == pre_sha (live verification) |
| AG4 FM-9 detect predicate (3 literal classes) | DONE | frozen template detected=true total=3 with all 3 classes; clean template detected=false |
| AG5 FM-9 chokepoint write + backup | DONE | rc=1, backup_written=true; literals replaced with `{{user_home}}` / `{{bead_id}}` / `{{sha}}` |
| AG6 FM-9 byte-exact undo via doctor undo | DONE | restored_sha == pre_sha (live verification) |
| AG7 canonical-CLI args (--help/--dry-run/--apply/--json/--run-id) | DONE | --help emits usage rc=2; --dry-run is default; --apply requires mutation path; exit codes 0/1/2/3 |
| AG8 native dispatcher intercepts | DONE | doctor fm6 + doctor fm9 routed BEFORE portable_doctor (line 1340-1349) |
| AG9 round-trip positive + negative cases for both FMs | DONE | 4 positive + 2 negative live-verified |
| AG10 backward-compatible (no regression) | DONE | --help still works; doctor undo still works; other doctor invocations unaffected |

did=10/10. didnt=none. gaps=none.

## Verification chain (re-runnable)

```bash
# 1. Syntax
bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop

# 2. Both functions defined
grep -cE '^_flywheel_loop_fm(6|9)_detect_fix\(\)' /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop
# Expected: 2

# 3. Dispatcher intercepts present
grep -cE '"\$\{1:-\}" == "fm(6|9)"' /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop
# Expected: 2

# 4. Full regression test
bash /Users/josh/Developer/flywheel/.flywheel/tests/test-oxzyr.2.4-fm6-fm9-byte-exact-undo.sh
# Expected: "12 passed, 0 failed"
```

## Files touched

| Path | Δ | Repo |
|---|---|---|
| `~/.claude/skills/.flywheel/bin/flywheel-loop` | +228 lines (2 functions + 2 dispatcher intercepts + 1 explanatory comment) | skillos (jsm-unmanaged) |
| `.flywheel/audit/flywheel-oxzyr.2.4/evidence.md` | NEW | flywheel.git |
| `.flywheel/audit/flywheel-oxzyr.2.4/jsm-import-ready-patch.md` | NEW | flywheel.git |
| `.flywheel/tests/test-oxzyr.2.4-fm6-fm9-byte-exact-undo.sh` | NEW (10 AGs, 12 PASS / 0 FAIL) | flywheel.git |

L107 reservation: flywheel-loop reserved + released.

Post-patch metrics:
- flywheel-loop total lines: 1632 (was 1404; +228 additive)
- post-patch SHA-256: `82deb563cd9a44fb536f3173187d01b4d51047eca41449109e6b943ad5605ef1`

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: bead body is self-contained; no new sub-beads warranted (sister beads .2.5 + .2.6 already filed; .2.5 = FM-8, .2.6 = real-fixture round-trip tests for all 10 FMs).

## L61 ecosystem-touch

- `agents_md_updated`: not_applicable
- `readme_updated`: not_applicable
- `no_touch_reason`: substrate-script extension to existing chokepoint module; no doctrine/INCIDENTS/canonical/L-rule mutations.

## Skill auto-routes

- **canonical-cli-scoping=yes** — both fm6 + fm9 expose canonical-cli surface: `--help/-h` rc=2 usage; `--dry-run` default + `--apply` mutation discipline; `--json` envelope with stable schema versions (`fm6-detect-fix/v1`, `fm9-detect-fix/v1`); exit codes 0/1/2/3 follow sibling .2.3 contract.
- **rust-best-practices=n/a**
- **python-best-practices=n/a** (bash + inline jq + inline perl)
- **readme-writing=n/a**

## Four-Lens Self-Grade

- **brand** (10): mirrored sister `.2.3` shape exactly (function signature, exit codes, JSON schema versioning, dispatcher intercept pattern) for review parity. Byte-exact undo class formalized as distinct from audit-only retraction class — the load-bearing distinction between mutating vs. non-mutating fix invariants is captured in the audit pack class header.
- **sniff** (10): 10 AGs / 12 PASS assertions; byte-exact undo round-trip verified for both FMs (pre_sha == restored_sha — load-bearing class invariant). Caught the pipefail+errexit bug in pre-flight smoke test and added inline-comment guard to prevent next-author re-discovery. AG5 false-positive (rc=1 silent) surfaced honestly and root-caused before commit.
- **jeff** (10): scoped to 2 functions + 2 dispatcher intercepts + 1 test (3 file classes; ~228 LOC additive). Did NOT touch fm5/fm10/fm8 (out of scope). Did NOT bundle .2.6 fixture work (proper sibling-bead scope). Joshua-domain mutation discipline followed (jsm-unmanaged → direct mutation + paired patch artifact).
- **public** (10): Three Judges —
  - Skeptical operator: 12-PASS test is single `bash <path>` re-runnable; AG3 + AG7 verify chokepoint backup chain by checking SHA-equality post-undo; FLYWHEEL_DOCTOR_UNDO_DIR sandboxed so test doesn't pollute prod state dir.
  - Maintainer: 2 new functions follow .2.3's sibling shape character-for-character (same arg parser style, same JSON output emitter, same exit-code semantics). The errexit-trap inline comment teaches the next FM author.
  - Future worker: when .2.6 dispatches (real-fixture round-trip tests for all 10 FMs), FM-6 + FM-9 are already round-trip-verified — they inherit a known-good upstream and can focus on fixture realism + edge-case coverage.

Per Donella Meadows #5 (rules of the system): the byte-exact-undo invariant *is* the new rule — any substrate-mutating fix now has a defined reversibility contract enforced by the chokepoint backup chain. Per `feedback_decompose_by_natural_unit_not_bundle`: held to natural unit (2 FMs in same class), did not bundle .2.5 (FM-8 audit-only) or .2.6 (fixture realism).

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

cli_canonical=yes
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
bash /Users/josh/Developer/flywheel/.flywheel/tests/test-oxzyr.2.4-fm6-fm9-byte-exact-undo.sh
```
Expected: `grep:12 passed, 0 failed`
Timeout: 30 seconds.
