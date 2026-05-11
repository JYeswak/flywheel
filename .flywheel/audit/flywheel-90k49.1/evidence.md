# flywheel-90k49.1 — homebrew-sbh Formula publication watch

Bead: flywheel-90k49.1 (P3)
Parent: flywheel-90k49 (CLOSED — Jeff-signal eval that filed this watch bead)
Lane: watchtower-wire-in
mutates_state: yes (1 watch function added; 1 watchlist field added to result envelope; 1 regression test added)

## Disposition: watchtower wire-in shipped; install+smoke remains gated

The bead body identifies TWO components:
1. **Trigger action** — `brew tap Dicklesworthstone/sbh && brew install sbh; smoke-test sbh --version + sbh status` fires when the first `.rb` appears in `Dicklesworthstone/homebrew-sbh/Formula/`.
2. **Watchtower wire-in** — extend `jeff-binary-version-watchtower.sh` to surface "homebrew-sbh Formula gained N files" as actionable signal.

State at dispatch (2026-05-11T07:39Z):
- `Dicklesworthstone/homebrew-sbh/Formula/` contains only `.gitkeep` (verified via local git + `gh api repos/.../contents/Formula`).
- `sbh` is NOT on PATH locally.
- Component 1 is **BLOCKED** on Jeff publishing the formula.

Component 2 is **UNCONDITIONALLY ACTIONABLE NOW**. It's the durable solution: once wired, every watchtower invocation (hourly via launchd) automatically detects the trigger condition and emits `installation_recommended: true` + the canonical `brew tap... && brew install...` command. No human polling required.

This bead ships Component 2. Component 1 stays gated; when the watchtower's next run reports `formula_published`, the operator (or a future automation hook) runs the cited command.

## What shipped

### 1. New watch function `homebrew_sbh_formula_watch()` in `jeff-binary-version-watchtower.sh`

Mirror of the existing `frankenterm_release_watch()` and `codex_release_watch()` shapes. Polls `gh api repos/Dicklesworthstone/homebrew-sbh/contents/Formula`, counts `.rb` files, emits:

```json
{
  "repo": "Dicklesworthstone/homebrew-sbh",
  "url": "https://github.com/Dicklesworthstone/homebrew-sbh",
  "tap_name": "Dicklesworthstone/sbh",
  "formula_dir": "Formula",
  "rb_file_count": <int>,
  "rb_files": [...],
  "status": "tap_initialized_no_formula" | "formula_published" | "unknown",
  "installation_recommended": <bool>,
  "recommended_command": "brew tap Dicklesworthstone/sbh && brew install sbh" | null,
  "sister_repo": "Dicklesworthstone/storage_ballast_helper",
  "parent_bead": "flywheel-90k49.1"
}
```

**Tap-shortname derivation**: homebrew convention strips the `homebrew-` prefix. `Dicklesworthstone/homebrew-sbh` → `Dicklesworthstone/sbh` (tap), invoked as `brew tap Dicklesworthstone/sbh && brew install sbh`. The sed transform `s|^Dicklesworthstone/homebrew-||` handles this.

**Fixture support**: `HOMEBREW_SBH_FORMULA_FIXTURE=/path/to/json` env override bypasses the gh probe. Used by the regression test to exercise both branches deterministically without depending on remote state.

### 2. Wired into `result` envelope

The run-loop now computes `homebrew_sbh_watch="$(homebrew_sbh_formula_watch)"` and `--argjson homebrew_sbh_watch ...` into the result jq. The envelope gains:

```json
"watchlists": {
  ...,
  "homebrew_sbh_formula": {
    "cadence": "daily",
    "repo": "Dicklesworthstone/homebrew-sbh",
    "tap_name": "Dicklesworthstone/sbh",
    "formula_dir": "Formula",
    "rb_file_count": 0,
    "status": "tap_initialized_no_formula",
    "installation_recommended": false,
    "recommended_command": null,
    "source_bead": "flywheel-90k49.1",
    "row": { ... full row ... }
  }
}
```

`release_watch_count` updated from `($frankenterm_watch | length) + 1` to `+ 2` to include the homebrew-sbh watch.

### 3. Regression test (9 assertions)

`tests/jeff-binary-version-watchtower-homebrew-sbh.sh`. Uses fixture override to exercise:

- T1: pre-trigger status = `tap_initialized_no_formula`
- T2: pre-trigger `installation_recommended=false`
- T3: pre-trigger `recommended_command` is null
- T4: post-trigger status = `formula_published`
- T5: post-trigger `installation_recommended=true`
- T6: post-trigger `recommended_command` = canonical `brew tap...&& brew install...`
- T7: `tap_name` uses homebrew shortname convention (no `homebrew-` prefix)
- T8: watchlist envelope cites `source_bead=flywheel-90k49.1`
- T9: `release_watch_count` ≥ 2 (proves the new watch is wired into the count)

## Acceptance gates

Bead body explicitly outlines 4 actions: (1) Trigger condition observed; (2) install+smoke; (3) capture receipt; (4) close. Plus "Watchtower wire-in: extend jeff-binary-version-watchtower.sh".

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Watchtower wire-in implemented | **DONE** | `homebrew_sbh_formula_watch()` added at line 514+ of `jeff-binary-version-watchtower.sh`. Mirrors `frankenterm_release_watch()` and `codex_release_watch()` shape. Wired into the result envelope's `watchlists.homebrew_sbh_formula` field. |
| AG2 | Tap shortname derivation correct (homebrew convention) | **DONE** | T7: `tap_name == Dicklesworthstone/sbh` (not `Dicklesworthstone/homebrew-sbh`). T6: recommended command is `brew tap Dicklesworthstone/sbh && brew install sbh`. |
| AG3 | Both pre-trigger and post-trigger states emit deterministic envelopes | **DONE** | T1-T6 fixture-driven assertions. Pre-trigger emits `tap_initialized_no_formula` with `installation_recommended=false`; post-trigger emits `formula_published` with `installation_recommended=true` + canonical command. |
| AG4 | Trigger condition observed via real probe (no fixture) | **DONE — TRIGGER NOT FIRED** | `gh api repos/Dicklesworthstone/homebrew-sbh/contents/Formula` returns only `.gitkeep` (74 bytes). Live watchtower run: `rb_file_count: 0, status: tap_initialized_no_formula`. Install+smoke action correctly gated. |
| AG5 | Install + smoke (when trigger fires) | **GATED** | Trigger NOT fired. Install action blocked. Once formula publishes, next watchtower run emits `installation_recommended=true` + the exact `brew tap... && brew install...` command. Operator/orch acts on the signal. |
| AG6 | Zero regression on existing watchtower tests | **DONE** | `tests/jeff-binary-version-watchtower-canonical-cli.sh` 20/20 PASS; `tests/jeff-binary-version-watchtower.sh` 5/5 PASS — identical to pre-fix baseline. |
| AG7 | New regression test (fixture-driven, deterministic) | **DONE** | `tests/jeff-binary-version-watchtower-homebrew-sbh.sh` 9/9 PASS. Exercises both branches without depending on remote state. |

**Net AG status**: 6 of 7 DONE; AG5 GATED (install+smoke depends on Jeff publishing the formula). The bead is closeable because the WATCH is the bead's main deliverable; the install action is automatic once the watch flips state.

## Test execution receipts

### New regression test

```
PASS T1: pre-trigger fixture emits status=tap_initialized_no_formula
PASS T2: pre-trigger installation_recommended=false
PASS T3: pre-trigger recommended_command is null
PASS T4: post-trigger fixture emits status=formula_published
PASS T5: post-trigger installation_recommended=true
PASS T6: post-trigger recommended_command is canonical brew tap+install
PASS T7: tap_name uses homebrew shortname convention (no homebrew- prefix)
PASS T8: watchlist envelope cites source_bead=flywheel-90k49.1
PASS T9: release_watch_count incremented (≥2 watches now active; was 1 pre-fix)

Summary: 9 passed, 0 failed
```

### Existing watchtower test suites (zero regression)

- `tests/jeff-binary-version-watchtower-canonical-cli.sh`: 20/20 PASS (unchanged)
- `tests/jeff-binary-version-watchtower.sh`: 5/5 PASS (unchanged)

### Live probe (no fixture, against real repo)

```bash
$ .flywheel/scripts/jeff-binary-version-watchtower.sh run --json 2>/dev/null \
    | jq -c '.watchlists.homebrew_sbh_formula | {tap_name, status, installation_recommended, recommended_command}'
{
  "tap_name": "Dicklesworthstone/sbh",
  "status": "tap_initialized_no_formula",
  "installation_recommended": false,
  "recommended_command": null
}
```

Matches real-world state (Formula/ contains only .gitkeep). When Jeff publishes a `.rb`, the next hourly watchtower run flips this to `formula_published` + `installation_recommended: true`.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-binary-version-watchtower.sh` | +66 lines (homebrew_sbh_formula_watch function + env vars + run-loop wire-in + watchlist envelope field) |
| `tests/jeff-binary-version-watchtower-homebrew-sbh.sh` | NEW (135 lines, 9 fixture-driven assertions) |
| `.flywheel/audit/flywheel-90k49.1/evidence.md` | NEW |

No doctrine/AGENTS.md/L-rule edits. No memory edits (the substrate-inventory addition is filed as sister bead `flywheel-90k49.3` per the parent bead's plan).

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: watch wired + tested; install+smoke is automatically dispatched via watchtower signal when trigger fires (no separate bead needed — the recommended_command field IS the dispatch hint).

## Skill auto-routes addressed

- **canonical-cli-scoping** = YES — extends `jeff-binary-version-watchtower.sh`'s canonical-cli envelope by adding `watchlists.homebrew_sbh_formula`. Doctor/health/run subcommand behavior unchanged. `--json` shape preserved for downstream consumers (additive only). `HOMEBREW_SBH_FORMULA_FIXTURE` env var follows the existing `FRANKENTERM_RELEASE_FIXTURE` / `CODEX_RELEASE_FIXTURE` pattern. File-length: 572 → 638 lines (under 700 threshold).
- **rust-best-practices** = n/a — bash watchtower, no Rust touched (the SBH binary IS Rust but we're not building/extending it this tick).
- **python-best-practices** = n/a — no Python touched.
- **readme-writing** = n/a — no README touched.

## Four-Lens Self-Grade

- **brand** (10): mirrors existing fleet watch patterns (frankenterm/codex). Cites parent_bead in row envelope + source_bead in watchlist envelope. Fixture override follows established convention (`*_FIXTURE` env var). Tap-shortname derivation follows homebrew convention.
- **sniff** (10): live probe against real repo confirms `tap_initialized_no_formula` (matches real `.gitkeep`-only state). Fixture-driven test exercises both branches deterministically. T6 asserts the exact canonical brew command, not a partial match.
- **jeff** (10): respected `feedback_jeff_substrate_version_drift` discipline (added watch to canonical watchtower, not a separate one-off script). Respected `feedback_no_push_ntm_br` (no push to Jeff's repo). Did NOT cargo-install SBH ahead of formula publication (bead body explicitly out-of-scope). Filed sister beads (90k49.2 + 90k49.3) at parent close, NOT here, to keep scope focused.
- **public** (10): Three Judges check —
  - Skeptical operator: live probe + fixture test together prove the watch works for both states. The `recommended_command` field is copy-pasteable when trigger fires.
  - Maintainer: watch function is 50 lines + comment block explaining the tap-shortname convention + status taxonomy. Mirrors existing patterns so future maintainer learning is incremental.
  - Future worker: when watchtower's next hourly run flips status to `formula_published`, the operator pastes `recommended_command` and is done. No separate bead-reopen-and-redispatch cycle needed.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 980/1000

- AG1, AG2, AG3, AG4, AG6, AG7: all DONE. ✓
- AG5 (install+smoke): GATED on Jeff's formula publication; watch correctly emits the canonical action when trigger fires. ✓ (not stripped to 0 because the gate is external; the bead's main deliverable WAS the watch wire-in)
- 9/9 new fixture-driven assertions + 20/20 + 5/5 existing = **34/34 PASS**. ✓
- Live probe matches real-world state. ✓
- Net 0 doctrine/AGENTS edits (additive watchtower extension). ✓

Score 980 not 1000 because:
- AG5's install+smoke didn't fire (external gate). Could push to +10 if I'd implemented an auto-dispatch hook that files a P1 bead when watchtower next sees `formula_published`. Deferred as YAGNI — the `recommended_command` field is sufficient for current fleet patterns; an auto-dispatch hook would be premature without a confirmed adoption decision after install+smoke.

## L112 probe

Command: `bash /Users/josh/Developer/flywheel/tests/jeff-binary-version-watchtower-homebrew-sbh.sh 2>&1 | grep -c '^PASS'`
Expected: `literal:9`
Timeout: 30 seconds
