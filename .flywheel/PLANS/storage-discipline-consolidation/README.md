# Storage Discipline Consolidation — flywheel scripts vs SBH

**Bead:** flywheel-90k49.2 (P4)
**Sister beads:** flywheel-90k49 (parent jeff-signal-action), flywheel-90k49.1 (formula-watch — see Gate Status below)
**Date:** 2026-05-11
**Author:** MistyCliff (flywheel:0.4)

## Gate status

The bead's trigger says "when SBH is installed locally (gated on 90k49.1 firing first)". Live state at this writing:

| Component | State | Probe |
|---|---|---|
| `Dicklesworthstone/homebrew-sbh` Formula | `Formula/sbh.rb` is now PUBLISHED (was `.gitkeep` at 90k49.1 close) | `gh api repos/Dicklesworthstone/homebrew-sbh/contents/Formula \| jq -r '.[].name'` → `.gitkeep`, `sbh.rb` |
| `sbh` on PATH | NOT installed | `which sbh` → `sbh not found` |
| brew tap | NOT tapped | `brew tap \| grep sbh` → empty |

**Implication:** the install action gated by 90k49.1 is NOW actionable (Formula published) but has not been triggered. This work proceeds analytically from public surface docs because:
1. The bead lists the SBH verb surface explicitly (`check / status / scan / clean / explain / blame / emergency / stats / dashboard / install`).
2. The deliverable is a classification + consolidation plan, not an empirical smoke test.
3. The follow-up consolidation bead (which the bead body promises) is the place where actual install/migration happens.

**Follow-up surfaced:** `flywheel-90k49.1` should be reopened (or a fresh sub-bead filed) to trigger `brew tap Dicklesworthstone/sbh && brew install sbh` per its own AG5. Filed in the GAPS section of this bead's callback.

## Inputs

### Flywheel storage scripts (8) — locally discovered

| # | Script | Path | Purpose |
|---|---|---|---|
| 1 | `private-tmp-prune.sh` | `.flywheel/scripts/` | Prune `/private/tmp/` accretion (test sandboxes hit 312GB in one observed incident). Age-based + path-allowlist. |
| 2 | `storage-headroom-watcher.sh` | `.flywheel/scripts/` | Watch disk headroom against `BUFFER_GB` threshold. Reports + ledgers status. Doctor/health/repair triad scaffolded. |
| 3 | `storage-pause-auto-resume.sh` | `.flywheel/scripts/` | Pause flywheel fleet under storage pressure; auto-resume when recovers. Owns flywheel-fleet pause-state contract. |
| 4 | `jeff-corpus-storage-projection.sh` | `.flywheel/scripts/` | Project jeff-corpus storage growth trajectory (Python wrapper). Corpus-specific math. |
| 5 | `beads-mem-tmp-cleanup.py` | `.flywheel/scripts/` | Clean `beads_mem_[0-9]+_0.db{,-wal,-shm}` temp DBs left by beads-mem ops. Pattern-bound. |
| 6 | `promotion-candidate-stale-fire-reaper.sh` | `.flywheel/scripts/` | Close stale-fired promotion-candidate beads (bead-DB hygiene, NOT storage — see note below). |
| 7 | `session-residue-prune.sh` | `.flywheel/scripts/` | Clear `.preview` / `.bak.*` / `.beads.bak.*` in flywheel repo. Tight safety contract (`--apply` requires `--idempotency-key`; refuses outside `~/Developer/flywheel`). |
| 8 | `stale-in-progress-reaper.sh` | `.flywheel/scripts/` | Close stale `in_progress` beads with no signal for 7+ days. Label-based carve-outs. Bead-DB hygiene, NOT storage. |

**Note (sub-discovery):** Three of the eight scripts in the bead's enumeration are bead-DB / flywheel-repo hygiene rather than disk-storage discipline (#6, #8 close stale beads; #7 prunes flywheel repo artifacts not user disk). They are co-located in `.flywheel/scripts/` and conceptually adjacent, but SBH's domain (raw disk pressure) does not overlap with them. They are classified `STILL NEEDED — out-of-domain` below.

### SBH capability surface (from public README)

| Verb | What it does |
|---|---|
| `install` | bootstrap service (e.g., `--systemd`) |
| `check` | inspect pressure + forecast (`--target-free N`) |
| `status` | structured status (JSON) |
| `scan` | enumerate cleanup candidates with scoring (`--top N --min-score F`) |
| `clean` | execute safe cleanup with confirmation (`--target-free N`) |
| `explain` | trace why a decision happened (`--id <decision-id>`) |
| `blame` | attribute disk consumption (`--json`) |
| `emergency` | zero-write recovery mode for near-full disks (`<path> --target-free N --yes`) |
| `stats` | trend metrics (`--window 24h`) |
| `dashboard` | observability surface |
| `ballast provision` | per-volume ballast pools |
| `protect <path>` | mark project paths for non-cleanup |

Capabilities cited in the README:
- Predictive: EWMA + PID for pre-emptive pressure response.
- Multi-volume ballast pools.
- Deterministic scoring + hard safety vetoes (`.git`, protected paths, too-recent, open files).
- Zero-write emergency mode for near-100%-full disks.
- Continuous monitoring (1s polls) — replaces cron-driven reactive scripts.
- Evidence ledger + `explain` (vs flywheel's per-script JSONL ledgers).
- Shadow → canary → enforce rollout modes.

## Classification matrix

| # | Flywheel script | Classification | Rationale | Recommended migration |
|---|---|---|---|---|
| 1 | `private-tmp-prune.sh` | **SUPERSEDED** | SBH's `scan` + `clean` with deterministic scoring + open-file vetoes + multi-volume awareness is strictly better than flywheel's path-allowlist + age threshold. The `/private/tmp` accretion class (jsm/beads/alps test sandboxes hitting 312GB) is exactly SBH's target domain. | After SBH install: dry-run `sbh scan /private/tmp` to confirm parity, then retire `private-tmp-prune.sh` (or thin it to a `.sbh-protect` enforcer for paths SBH should ignore). |
| 2 | `storage-headroom-watcher.sh` | **SUPERSEDED** | Continuous `sbh check` / `sbh status` with predictive EWMA + PID is more responsive than the flywheel `BUFFER_GB` reactive watcher. SBH's ledger + `explain` replaces flywheel's per-watcher JSONL audit log. | Retire watcher; subscribe flywheel orch to `sbh status --json` polls (or SBH event hook) for the trigger that drives `storage-pause-auto-resume.sh`. |
| 3 | `storage-pause-auto-resume.sh` | **COMPLEMENT** | SBH owns disk-pressure detection; flywheel owns fleet pause/resume semantics (which orch panes to halt, when to fire `caam` profile swaps, etc.). SBH cannot pause workers — it can only signal. | Refactor: read pressure signal from `sbh status` (or SBH hook), keep the flywheel-fleet pause/resume contract. Net code reduction: drop the bespoke headroom probe; keep the fleet-state machine. |
| 4 | `jeff-corpus-storage-projection.sh` | **STILL NEEDED** | Corpus-specific projection: forecasts how `~/.socraticode/qdrant-data` + `~/.knowledge/qdrant_*` grow as jeff-corpus ingests. SBH's `scan`/`clean` would treat the corpus dirs as cleanup candidates (wrong domain) absent `.sbh-protect` markers. | Add `.sbh-protect` markers to `~/.socraticode/` and `~/.knowledge/` before SBH `clean` runs. Keep the projection script — it's a different concern (growth forecasting vs reactive cleanup). |
| 5 | `beads-mem-tmp-cleanup.py` | **COMPLEMENT (lean SUPERSEDED-IF-PATTERN-WIRED)** | SBH would score `beads_mem_*_0.db*` files by structure if pointed at the right scan path. The flywheel script has pattern-bound knowledge (`FILENAME_RE = beads_mem_[0-9]+_0\.db(?:-wal|-shm)?`) that SBH can replicate via config glob. | Option A (preferred): retire script after adding a flywheel-specific SBH config glob. Option B: keep script as a narrow safety net for pre-SBH adoption window. Decide post-install. |
| 6 | `promotion-candidate-stale-fire-reaper.sh` | **STILL NEEDED — out-of-domain** | Bead-DB hygiene (closes stale `promotion-candidate-*` beads). Not disk storage. | No migration; keep as-is. Out of SBH scope. |
| 7 | `session-residue-prune.sh` | **COMPLEMENT** | Project-scoped repo cleanup (refuses outside `~/Developer/flywheel`; requires `--idempotency-key`). SBH could enumerate the `.preview` / `.bak.*` files via scan, but the flywheel-specific safety contract (no tracked files; min-age default; idempotency receipt) is load-bearing. | Keep the safety contract; consider hooking flywheel session-end ticks to invoke `sbh scan` against the repo with a tight protect-list as a sanity layer. |
| 8 | `stale-in-progress-reaper.sh` | **STILL NEEDED — out-of-domain** | Bead-DB hygiene (closes stale `in_progress` beads with label carve-outs). Not disk storage. | No migration; keep as-is. Out of SBH scope. |

## Summary by class

- **SUPERSEDED (2):** private-tmp-prune, storage-headroom-watcher
- **COMPLEMENT (3):** storage-pause-auto-resume, beads-mem-tmp-cleanup, session-residue-prune
- **STILL NEEDED (3):** jeff-corpus-storage-projection (corpus-specific), promotion-candidate-stale-fire-reaper (out-of-domain), stale-in-progress-reaper (out-of-domain)

**Net consolidation potential:** ~2 scripts retirable post-SBH install + smoke; 3 scripts thinned to delegate detection to SBH but keep their flywheel-specific orchestration. ~3 untouched.

## Recommended migration order (follow-up beads, not this one)

1. **Pre-install prep (P3):** Add `.sbh-protect` markers to `~/.socraticode/`, `~/.knowledge/`, `~/Developer/flywheel/.beads/`, `~/.local/state/flywheel/`. Confirms SBH won't touch corpus, beads DB, or flywheel state.
2. **Install + smoke (P3, sister-to-90k49.1):** `brew tap Dicklesworthstone/sbh && brew install sbh && sbh --version && sbh status --json`. Capture install receipt. Confirms `sbh` on PATH.
3. **Shadow mode validation (P3):** Run `sbh` in shadow mode for 7+ days alongside flywheel scripts. Compare decisions: SBH's `scan` candidates vs `private-tmp-prune.sh` candidates against the same `/private/tmp` state. Expect overlap + SBH-only-finds + flywheel-only-finds; investigate the gaps.
4. **Retire `private-tmp-prune.sh` (P4):** if shadow mode confirms parity, delete the script. Keep one regression test that asserts `sbh scan /private/tmp` reports expected categories.
5. **Retire `storage-headroom-watcher.sh` (P4):** replace the headroom-probe step in flywheel orch tick with `sbh status --json` parse.
6. **Refactor `storage-pause-auto-resume.sh` (P4):** keep fleet pause/resume state machine; drop bespoke headroom probe; consume `sbh status` instead.
7. **Decide `beads-mem-tmp-cleanup.py` (P5):** post-shadow, decide A vs B per matrix row 5.

## Decision boundaries (caveats)

- All SUPERSEDED / COMPLEMENT classifications assume SBH's shadow mode validates flywheel-equivalent decisions for `/private/tmp` and disk-headroom triggers. If shadow reveals divergence, flywheel scripts stay until SBH config closes the gap.
- The "out-of-domain" classifications (#6, #8) intentionally remain even after a fully successful SBH adoption. They aren't storage scripts; they're co-located.
- The corpus-projection script (#4) is forecast-class, not cleanup-class. SBH's `stats --window 24h` is a different shape (trends, not growth-trajectory projection).

## Memory anchors

This plan honors three project memories:
- `feedback_private_tmp_accretes_until_disk_dies` — SBH directly addresses this. Adoption supports the 2026-05-07 META-rule.
- `feedback_retention_policy_by_default_for_accreting_surfaces` — SBH `.sbh-protect` markers + ballast pools formalize the retention default the rule requires.
- `feedback_storage_pressure_blocks_substrate` — SBH's continuous monitoring + emergency zero-write mode is exactly the substrate-protection layer this rule asked for.
