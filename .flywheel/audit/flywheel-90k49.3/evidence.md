# flywheel-90k49.3 — Evidence Pack

**Bead:** flywheel-90k49.3 (P4)
**Title:** [homebrew-sbh-substrate-inventory-add] add sbh + homebrew-sbh to canonical Jeff substrate inventory + watchtower
**Mission fitness:** `adjacent` — adds drift-watch for an emerging Jeff dependency before it's load-bearing.

## Acceptance gates (3 listed, 2 actionable, 1 deferred-by-bead-constraint)

| # | Gate | Status |
|---|---|---|
| 1 | Add `sbh` to `.flywheel/scripts/jeff-binary-version-watchtower.sh` with version probe (`sbh --version`) + upstream release check | DONE |
| 2 | Add `homebrew-sbh` tap to corpus inventory + daily-delta watch (Formula .rb signal) | ALREADY DONE by flywheel-90k49.1 (see evidence) |
| 3 | Update memory `reference_jeff_substrate_inventory.md` row for sbh | DEFERRED per bead constraint "No memory edit before SBH is actually load-bearing" — filed `flywheel-tymgr` |

## Gate 1 detail — watchtower wire-in

Added `sbh_binary_version_watch` function paralleling `ntm` canonical-binary probing:
- `command -v sbh` gating → emits `status=not_installed` cleanly when SBH absent
- `sbh --version` parsed via existing `normalize_version` helper
- `gh api repos/Dicklesworthstone/storage_ballast_helper/releases/latest` for upstream tag
- `relation()` helper reused for current/behind/ahead semantics
- Two fixture env vars (`SBH_VERSION_FIXTURE`, `SBH_RELEASE_FIXTURE`) for deterministic testing
- CLI flags `--sbh-version-fixture`, `--sbh-release-fixture`, `--sbh-bin` added

Wired into result JSON:
- `rows[]`: includes sbh row when installed (excluded when not_installed, keeping `canonical_binary_count` honest)
- `watchlists.sbh_binary_release`: new daily-cadence row with full state
- `stale[]`: includes sbh when `relation=behind` (drift-class promotion candidate)
- `canonical_binary_count`: 1 (sbh excluded) or 2 (sbh included)
- `stale_count` + `highest_priority`: increment when sbh is behind

## Gate 2 detail — already done by 90k49.1

The bead asks for "homebrew-sbh tap to corpus inventory + daily-delta watch (signal: new .rb files in Formula/)". Both parts already exist:

- **Corpus inventory:** `storage_ballast_helper` is enumerated in `.flywheel/PLANS/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-B-PRIME.md:283` and `.flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/01-repo-inventory.md` (130, 320, 365). Both repo dirs are present in the Jeff corpus ingestion.
- **Daily-delta watch:** `homebrew_sbh_formula_watch` in `.flywheel/scripts/jeff-binary-version-watchtower.sh` (added by 90k49.1) polls `Dicklesworthstone/homebrew-sbh/Formula/` and emits `formula_published | tap_initialized_no_formula | unknown`. Currently reports `formula_published` since `Formula/sbh.rb` is now live (see flywheel-90k49.2 + flywheel-bx592 for the install-now-actionable follow-up).

No-op for this bead. Result: no duplicate function added.

## Gate 3 detail — deferred memory edit

Bead constraint: "No memory edit before SBH is actually load-bearing." SBH is NOT load-bearing (not installed; no flywheel script depends on it yet). Filed `flywheel-tymgr` (P4) with explicit acceptance: SBH installed + ≥1 flywheel script imports SBH as load-bearing. Triggered when both conditions hold.

## Verification

| Gate | Command | Result |
|---|---|---|
| Syntax | `bash -n .flywheel/scripts/jeff-binary-version-watchtower.sh` | OK |
| Live probe (no sbh) | `... --dry-run --json \| jq .watchlists.sbh_binary_release.status` | `"not_installed"` |
| Live probe (no sbh) | `... \| jq .canonical_binary_count` | `1` (correctly excludes sbh) |
| Fixture CURRENT | `SBH_VERSION_FIXTURE=sbh-0.4.6 SBH_RELEASE_FIXTURE=tag-v0.4.6 ...` | `status=ok relation=current` |
| Fixture BEHIND | `SBH_VERSION_FIXTURE=sbh-0.4.5 SBH_RELEASE_FIXTURE=tag-v0.4.6 ...` | `status=stale relation=behind, stale_count=1, P1, canonical=2` |
| New regression | `bash tests/jeff-binary-version-watchtower-sbh-binary.sh` | 11/11 PASS |
| Sister: watchtower main | `bash tests/jeff-binary-version-watchtower.sh` | PASS |
| Sister: 90k49.1 formula watch | `bash tests/jeff-binary-version-watchtower-homebrew-sbh.sh` | 9/9 PASS |
| Sister: canonical-cli | `bash tests/jeff-binary-version-watchtower-canonical-cli.sh` | 20/20 PASS |

## DID / DIDNT / GAPS

- **DID 2/3** — Gate 1 watchtower wire-in DONE; Gate 2 already-done acknowledged (no work needed)
- **DIDNT 1/3** — Gate 3 deferred per bead constraint (reason: `not-load-bearing`); recorded as `flywheel-tymgr`
- **GAPS none** — no newly discovered work beyond `tymgr`

## Files Changed

- `.flywheel/scripts/jeff-binary-version-watchtower.sh` — `sbh_binary_version_watch` function + 3 new CLI flags + result-JSON wiring (rows/watchlists/stale/counts)
- `tests/jeff-binary-version-watchtower-sbh-binary.sh` — new regression, 11/11 PASS

## L112 Probe

- `l112_probe_command`: `bash .flywheel/scripts/jeff-binary-version-watchtower.sh --dry-run --json | jq -r '.watchlists.sbh_binary_release.status'`
- `l112_probe_expected`: `literal:not_installed`
- `l112_probe_timeout_sec`: `30`

(Will flip to `ok` after flywheel-bx592 + brew install land; that's the success signal for the GATING_BEAD chain to complete.)

## Four-Lens Self-Grade

- **brand:** 9 — parallels ntm canonical-binary pattern; honors load-bearing memory constraint
- **sniff:** 10 — fixture-driven tests cover all four states (not_installed/current/behind/ahead); live probe matches reality
- **jeff:** 10 — adds Jeff binary to watchtower per `feedback_jeff_substrate_version_drift` doctrine; preserves load-bearing gate
- **public:** 9 — future workers reading the watchtower see clear function pattern + status taxonomy + fixture support
