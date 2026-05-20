# Storage Philosophy — Fleet-Wide Foundation

**Status:** DRAFT v0.1 — 2026-05-20 — flywheel:1 authored, awaiting skillos:1 co-design
**Inheritance target:** Every Joshua-owned system (current 10 + future) MUST inherit this.

## I. The Core Axiom

**Storage health is a substrate-liveness invariant, not a chore.** When disk pressure crosses tier 3, every other failure (Docker, Qdrant, JSM, build, codex MCP startup) becomes a storage incident until proven otherwise. The cure cannot require the disease to be absent — janitors must run BEFORE pressure, not AFTER failure.

## II. The 5-Tier Pressure Model (promoted from zesttube → global)

| Tier | Free space | State | Automatic response |
|------|------------|-------|----------------------|
| 0 — Comfortable | >50% | Normal | Hourly janitor only |
| 1 — Monitor | 30–50% | Inspect | 15min janitor + report top accumulators |
| 2 — Soft prune | 15–30% | Reclaim ephemera | 5min janitor + emergency-threshold active + per-orch cap enforced |
| 3 — Critical | 5–15% | Halt new infra dispatch | 1min janitor + halt-on-disk-pressure for dispatches + cache evict |
| 4 — Fire | <5% | Manual incident | Page Joshua + kill heaviest accumulators + emergency reap regardless of age |
| 5 — Nuclear | Compaction fails / Docker.raw dominates | Migration | Joshua-approval required |

**Today's data: tier 4** (27Gi free / 926Gi, 98% used).

## III. The Three Pillars

### 1. MEASURE (single source of truth)

`flywheel/scripts/storage-health-probe.sh` returns `{tier, free_pct, accumulators[]}`:
- Free space % across /, /System/Volumes/Data
- Top 15 accumulators by `size × velocity` (size now + delta vs 1h ago)
- Per-surface-class size totals (build artifacts, ledgers, caches, transcripts, data, logs, media)
- Output: JSON + dashboard line + tier classification

Wires into:
- `/flywheel:status` (new line under Recovery SLO)
- doctor JSON `storage_health` key
- Every orch's tick — if tier ≥3, halt new dispatches

### 2. OPTIMIZE (retention contracts per surface class)

**Every accreting surface MUST declare a retention policy** in its repo's `.flywheel/STORAGE-MANIFEST.json`. CI fails if a substrate surface lacks a policy.

| Surface class | Retention rule | Today's worst offender |
|---------------|----------------|-------------------------|
| JSONL ledgers | Rolling window: max N days OR max N lines, whichever first | `doctrine-sync-ledger.jsonl` (358M, zero policy) |
| Daemon logs | Rotate at 50M, gzip, delete >7 days | `~/.local/state/flywheel/logs/` (3.4G unrotated) |
| Session transcripts | Cap N per project + delete >90d | `~/.claude/projects/` (2.8G unbounded) |
| Build artifacts (node_modules, target/, .next, .venv) | Reap if repo not git-touched in 30d | 14G node_modules + 14G target/ + 8G .venv across repos |
| Tool caches (npm, cargo, brew, pip) | Soft evict at tier 2 | 5.3G cargo/src, 3G .npm |
| Browser/playwright profiles | Reap on session end + cap at 1GB | 1.5G playwright, 467M claude-skills-sync |
| Codex MCP state | Reap >7d, never grow past 500MB | Currently fine |
| Application data (databases) — Joshua-owned apps | Per-app — declared by owner | (none currently) |
| **Vendor-owned data — upstream tool we consume** | Consumer-side size cap + archive-and-rotate at threshold. NEVER redesign upstream retention. Same shape as "scope-discriminate-don't-bundle" — respect upstream ownership, manage consumption footprint. | 21G agent_search.db (CASS DuckDB — bead flywheel-qdo7w); 669M ~/.socraticode/qdrant-data (socraticode Qdrant — sister substrate, same Dicklesworthstone stack — cap by dropping stale per-project collections) |
| Worker work-dirs (/private/tmp/<orch>-*) | Reap on task completion OR >6h | Covered (this morning's fix) |
| User dumps (Desktop, Downloads) | Quarterly audit + archive prompt | 54G Desktop, 6G Downloads |
| Git pack files | `git gc --aggressive` quarterly if pack >5G | zesttube 6.2G, coding_agent_session_search 6.4G |
| Media archives (video, audio) | Move to external storage when >1G | recovered-recordings 27M |

### 3. PRUNE (4-cadence pipeline)

| Cadence | Trigger | Action |
|---------|---------|--------|
| **Continuous** | On-write | Per-surface invariants: log rotation, ledger truncation, work-dir cleanup at task close |
| **Short-cycle** | Every 5min (cron) | `temp-janitor.sh` with tier-aware thresholds (already shipped this morning) |
| **Long-cycle** | Daily (cron) | Build-artifact janitor + stale-repo detector + Claude transcript pruner + ledger compactor |
| **Emergency** | tier ≥3 disk-pressure trigger | Aggressive reap regardless of age, kill heaviest accumulator, halt new dispatches |

## IV. Inheritance Mechanism (new systems adopt automatically)

When a new repo joins the fleet:
1. `flywheel-init` bootstrap copies `.flywheel/STORAGE-MANIFEST.json` template
2. Template requires declaring: every accreting surface in repo + its retention policy
3. CI gate: `storage-manifest-conformance.sh` — fails if a JSONL/log/cache exists without manifest entry
4. Universal axiom added to `~/.claude/CLAUDE.md`: "Storage philosophy is foundational. Surface = manifest = policy."
5. Doctor JSON exposes `storage_manifest_conformance` per repo for fleet-wide audit

## V. Failure-Mode Prevention (from overnight trauma)

| Prior failure | Structural prevention |
|----------------|-------------------------|
| Janitor died when disk full (couldn't write its log) | Emergency mode writes nothing, just unlinks |
| Workers retreated to idle on ENOSPC instead of escalating | `flywheel-9z20r` — 3× ENOSPC = halt + page, not retry |
| /private/tmp accreted to 45GB between hourly janitor runs | Cadence 3600s → 300s (shipped) + emergency threshold (shipped) |
| One worker's runaway work-dir filled disk | Per-orch 5GB hard cap (shipped) |
| Storage incidents recurring weekly with no learning | 3-strike → promote to STORAGE-PHILOSOPHY axiom (this doc) |

## VI. Founder-Dispose Threshold

| Tier | Page Joshua? |
|------|--------------|
| 0–2 | Never — fully automated |
| 3 | Notify only (dashboard + log) — auto-reaps already firing |
| 4 | Page immediately — automated work continues but new dispatch halts |
| 5 | Joshua approval required for nuclear/migration step |

## VII. Today's Recoverable Inventory (data-driven, not guesses)

**Immediate (no-risk, ~14GB):**
- Delete `~/Library/Application Support/vc/vc.duckdb.legacy-2026-04-30` (13G, explicitly legacy from 2026-04-30)
- Delete `~/Library/Application Support/vc/vc.duckdb.wal.legacy-2026-04-30` (paired WAL)
- Empty `~/.Trash` (715M)
- Delete `agent_search.corrupt.20260131_165120` (from Jan 31, fail-state)
- Rotate `~/.local/state/flywheel/logs/` (3.4G — keep last 7 days only)

**Substrate (low-risk, ~2GB ongoing reclaim/mo):**
- Truncate `doctrine-sync-ledger.jsonl` to last 14 days (358M → ~50M)
- Truncate `codex-stuck-detector.jsonl` to last 7 days (51M → ~10M)
- Prune session transcripts >90 days (700M → ~200M)

**Application-owned (needs caution):**
- `agent_search.db` 21G — CASS v2 search index. Owner: zesttube/coding-agent-search. Needs OWNER-side retention policy, not janitor delete.

**User-owned (needs Joshua review):**
- `~/Desktop` 54G — Joshua's content; needs quarterly archive triage
- `~/Downloads` 6G — same

**Repo build artifacts (~22GB regenerable):**
- 14G node_modules across repos — reap from repos not git-touched in 30d
- 14G target/ across Rust repos — `cargo clean` candidates
- 8G .venv across repos

**Total potential reclaim today: ~38GB without touching app data or user content.**

## VIII. Open Questions for skillos:1 Co-Design

1. Does skillos doctrine already encode any of these axioms? Where's the seam?
2. Manifest format: JSON schema for `.flywheel/STORAGE-MANIFEST.json` — universal vs per-repo extensible?
3. Inheritance: bootstrap script vs claude-skill vs both?
4. `storage-health` skill at `~/.claude/skills/storage-health/` — does it implement tier classification already? If so, wrap vs replace?
5. Where does the philosophy doc live canonically — both repos mirror, or one canonical + symlink?

## IX. Implementation Track (proposed beads)

| Bead | Track | Priority |
|------|-------|----------|
| storage-health-probe.sh tier classifier | MEASURE | P0 |
| log-rotation contract + janitor extension | PRUNE | P0 |
| ledger-retention enforcer (rolling window) | OPTIMIZE | P0 |
| STORAGE-MANIFEST.json schema + CI gate | INHERIT | P1 |
| stale-repo build-artifact janitor (daily cron) | PRUNE | P1 |
| Claude transcript pruner | PRUNE | P1 |
| storage-health dashboard line in /flywheel:status | MEASURE | P1 |
| ENOSPC halt-not-retry doctrine (flywheel-9z20r) | PREVENT | P0 (already filed) |
| meta-watchdog on janitor freshness (flywheel-xoy8k) | PREVENT | P0 (already filed) |
| ~/.claude/CLAUDE.md universal axiom add | INHERIT | P1 |

— flywheel:1 (drafted in parallel with skillos:1 joint investigation)
