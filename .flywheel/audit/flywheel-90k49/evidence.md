# flywheel-90k49 — Jeff signal evaluation: github-repos/homebrew-sbh

Bead: flywheel-90k49 (P3)
Lane: jeff-signal-triage
mutates_state: no (evaluation + sister-bead filing only; no script changes; no install actions)
Source: github-repos signal class, detected 2026-05-10T12:04:06Z
Signal: new Jeff repo at `Dicklesworthstone/homebrew-sbh` (initialized 2026-05-10)

## What the signal is

`Dicklesworthstone/homebrew-sbh` is a Homebrew tap published by Jeff Emanuel for distributing `sbh` (Storage Ballast Helper). The repo was initialized 2026-05-10 with two commits: "Initial commit" and "Initialize Formula directory".

```
/Users/josh/Developer/jeff-corpus/homebrew-sbh/
├── README.md       ("Homebrew tap for sbh (Storage Ballast Helper)")
└── Formula/
    └── .gitkeep    (placeholder; NO actual .rb formula file yet)
```

**Current readiness state**: tap exists but is **NOT yet brew-installable**. The `Formula/` directory contains only a `.gitkeep` placeholder. Until Jeff publishes a `Formula/sbh.rb` (or similar), `brew tap Dicklesworthstone/sbh && brew install sbh` would fail. The tap is a placeholder ahead of formula publication.

## What SBH itself is (sister-repo context)

`Dicklesworthstone/storage_ballast_helper` is the main project — a Rust daemon for cross-platform disk-pressure defense. Currently at **v0.4.6** (per `gh api releases/latest`). Already cloned at `~/Developer/storage_ballast_helper`. NOT currently installed on flywheel-1 PATH (`which sbh` → "not found").

From the SBH README:

> Cross-platform disk-pressure defense for AI coding workloads: predictive monitoring, safe cleanup, ballast release, and explainable policy decisions.

Headline capabilities:
- Predictive pressure control (EWMA + PID reacts before disks hit critical levels)
- Multi-volume ballast pools (frees space on the exact filesystem under pressure)
- Safe artifact cleanup (deterministic scoring + hard vetoes for `.git`, protected paths, too-recent, open files)
- Zero-write emergency mode (recover from near-100% disks without DB/config writes)
- Project protection (`.sbh-protect` markers)
- Explainable decisions (evidence ledger + `sbh explain`)
- Production rollout safety (shadow → canary → enforce modes)

## Why actionable for flywheel

SBH directly addresses a known **recurring** flywheel pain class. Memory rules anchor the pain:

| Memory rule | The pain |
|---|---|
| `feedback_private_tmp_accretes_until_disk_dies` | "jsm/beads/alps test sandboxes hit 312GB on 926GB disk at -7GB/hr burn rate before flywheel noticed" |
| `feedback_retention_policy_by_default_for_accreting_surfaces` | "ALPS accreted 197 GiB in /private/tmp/alps.* (773 entries) before flywheel noticed" |
| `feedback_storage_pressure_blocks_substrate` | "below 5% free, auto-prune sidecars/recovery/corpus bloat before WAL/JSONL writes degrade" |
| `feedback_jeff_corpus_indexed_data_separates_from_source` | jeff-corpus source repos are 78 entries, separately ~/.socraticode/qdrant-data accretes |

Flywheel's CURRENT approach is REACTIVE: 8+ ad-hoc storage scripts (private-tmp-prune, storage-headroom-watcher, storage-pause-auto-resume, jeff-corpus-storage-projection, beads-mem-tmp-cleanup, promotion-candidate-stale-fire-reaper, session-residue-prune, stale-in-progress-reaper) + 5 launchd plists (tmp-prune, storage-health, tmp-aggressive-prune, weekly-cache-prune, storage-prune). Each fires after-the-fact on a cadence or threshold.

SBH's approach is PREDICTIVE (EWMA + PID forecasts pressure before critical) and offers a SINGLE consolidated tool with explicit shadow→canary→enforce rollout discipline, deterministic decisions, and explainability — properties that match flywheel doctrine values.

## Disposition: PRE-INSTALL EVALUATION + WATCH for Formula

The signal is HIGH-VALUE but NOT IMMEDIATELY ACTIONABLE because the tap is empty (no Formula recipe). Adoption needs Jeff's Formula publication.

Three sister beads filed to capture the action plan:

| # | Bead | Purpose | Priority |
|---|---|---|---|
| 1 | `flywheel-90k49.1` | Watch `homebrew-sbh/Formula/` for first `.rb` publication; install + smoke when published | P3 |
| 2 | `flywheel-90k49.2` | Inventory matrix: 8 flywheel storage scripts vs SBH capability surface — identify consolidation candidates + which flywheel-specific scripts should stay (e.g., `jeff-corpus-storage-projection.sh` is jeff-corpus-specific, likely stays) | P4 |
| 3 | `flywheel-90k49.3` | Add SBH to canonical Jeff substrate inventory (`reference_jeff_substrate_inventory.md` memory + watchtower) | P4 |

Per memory rule `feedback_jeff_substrate_version_drift`, the SBH binary should be added to `jeff-binary-version-watchtower.sh` once installed locally. Bead .3 captures that wire-in.

Per memory rule `feedback_accretive_corpus_ingestion`: jeff-corpus already has both repos (`storage_ballast_helper` + `homebrew-sbh`); ongoing corpus ingestion handles the watch side via daily delta. Bead .1 makes the formula-publication signal explicit + actionable.

## Acceptance gates

Bead has no explicit AC list (Title-only "[jeff-signal-action] github-repos: homebrew-sbh" + Description triages this as a new-tool signal class). Inferred AGs from the dispatch packet's bead description ("Apply-to-flywheel hypothesis: evaluate this Jeff signal for doctrine, skill, or substrate upgrade"):

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Identify the Jeff signal concretely | **DONE** | `Dicklesworthstone/homebrew-sbh`, initialized 2026-05-10, Formula dir empty (only .gitkeep). Sister substrate: `storage_ballast_helper` v0.4.6. Both repos already in jeff-corpus. |
| AG2 | Evaluate for doctrine implications | **DONE** | SBH addresses a recurring flywheel pain class (4 memory rules anchor the pain). Current flywheel approach: 8 reactive scripts; SBH approach: 1 predictive daemon. Doctrine implication is potential consolidation + adoption of SBH's shadow→canary→enforce discipline. |
| AG3 | Evaluate for skill implications | **DONE** | Skill: SBH's `.sbh-protect` marker convention + evidence-ledger pattern could inform `storage-discipline` skill if/when SBH adopts. Premature to author the skill before SBH installed + tested. |
| AG4 | Evaluate for substrate-upgrade implications | **DONE** | If SBH gets installed, it becomes a load-bearing Jeff substrate binary requiring version-drift monitoring per `feedback_jeff_substrate_version_drift`. Should be added to `jeff-binary-version-watchtower.sh` (bead .3) and `reference_jeff_substrate_inventory.md` memory. |
| AG5 | File next-actions per L52 | **DONE** | 3 sister beads filed (.1 watch-formula, .2 capability-matrix, .3 substrate-inventory-update). All P3-P4 reflecting non-urgency (current pain is manageable; SBH adoption is enhancement, not blocker). |
| AG6 | Confirm readiness gating | **DONE** | Adoption is BLOCKED on Jeff publishing `Formula/*.rb`. The current state (empty Formula/) means `brew tap Dicklesworthstone/sbh && brew install sbh` would fail. Bead .1 watches for the formula publication. |

## What was NOT done (deliberately, per scope)

- **No install of sbh locally**: tap is empty; nothing to install. Pre-formula install via `cargo install --git` is possible but premature — Jeff's homebrew path signals intended distribution channel.
- **No flywheel storage-script refactor**: consolidation is bead .2's scope; requires SBH installed first.
- **No watchtower wire-in**: bead .3's scope; predicated on SBH being in active use.
- **No Jeff issue filed**: per memory rule `feedback_jeff_issue_requires_full_workaround_research_first`, no observed bug to file. Jeff's empty-tap state is intentional (placeholder ahead of formula).
- **No memory edit** to `reference_jeff_substrate_inventory.md`: deferred to bead .3 once SBH is actually a load-bearing binary on flywheel-1.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/audit/flywheel-90k49/evidence.md` | NEW (this file) |
| `.beads/issues.jsonl` (via `br create`) | +3 sister beads filed |

No production scripts touched. No memory edits.

## L52 bead receipt

- `beads_filed`: `flywheel-90k49.1`, `flywheel-90k49.2`, `flywheel-90k49.3`
- `beads_updated`: none
- `no_bead_reason`: n/a (action items surfaced as sister beads)

## Skill auto-routes addressed

- **canonical-cli-scoping** = n/a — evaluation bead, no CLI surface authored.
- **rust-best-practices** = n/a — SBH is Rust but flywheel isn't installing/extending it this tick.
- **python-best-practices** = n/a — no Python touched.
- **readme-writing** = n/a — no README touched; SBH's own README is sufficient and referenced inline.

## Four-Lens Self-Grade

- **brand** (9): evaluation respects ZestStream's Jeff-substrate-version-drift discipline + filers' separate-from-substrate stance (no push to Jeff's repos per `feedback_no_push_ntm_br`). Sister beads use canonical dotted form (`flywheel-90k49.1`).
- **sniff** (9): empirical signal verification (homebrew-sbh Formula/ inspected; only .gitkeep present), gh API queried for SBH release tag (v0.4.6), `which sbh` confirms not-installed, memory-rule anchors cited verbatim.
- **jeff** (10): respected the deferral signal (tap empty → can't install via brew → don't pre-install via cargo). No premature wire-in. No premature memory edit. Three P3-P4 sister beads precisely scope the future action without forcing implementation now.
- **public** (9): Three Judges check —
  - Skeptical operator: signal facts are verifiable (`ls Formula/` shows .gitkeep only; `gh api` shows v0.4.6; `which sbh` shows not-found).
  - Maintainer: evaluation links the signal to 4 documented memory-rule pain points; capability comparison preserved for future consolidation decision.
  - Future worker: when SBH formula lands, bead .1 fires; when SBH is installed, bead .3 adds substrate-watchtower entry; when both done, bead .2's consolidation matrix becomes actionable.

four_lens=brand:9,sniff:9,jeff:10,public:9

## Compliance: 970/1000

- AG1-AG6: all DONE. ✓
- Signal verified empirically. ✓
- 4 memory-rule anchors cited for pain class. ✓
- 3 sister beads filed (action plan staged). ✓
- No premature install / refactor / memory-edit. ✓
- Readiness gate (empty Formula/) documented as the natural pacing constraint. ✓

Score 970 not 1000 because:
- A capability-comparison matrix (flywheel's 8 storage scripts vs SBH's capability surface) could have been authored inline in this evidence pack at +20 detail. Deferred to bead .2's scope per separation-of-concerns. Operator can read the README + flywheel script list to reconstruct.

## L112 probe

Command: `[ -f /Users/josh/Developer/jeff-corpus/homebrew-sbh/README.md ] && ls /Users/josh/Developer/jeff-corpus/homebrew-sbh/Formula/ | grep -v gitkeep | wc -l`
Expected: `literal:0` (Formula dir contains only .gitkeep; no .rb yet)
Timeout: 5 seconds
