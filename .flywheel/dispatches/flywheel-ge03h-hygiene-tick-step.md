# flywheel-ge03h — Hygiene tick step: auto-bead-filer for 5-metric repo hygiene across the fleet

## Context

Joint deep-dive synthesis with mobile-eats:1 (2026-05-20T04:05Z) identified this as P0. Mobile-eats already shipped the foundation: `repo-hygiene-doctor.sh` (commit 45f55933 + merge c01e7c3e on main) — a canonical 5-metric probe. Evidence pack at `/Users/josh/Developer/mobile-eats/.repo_janitor_workspace/JANITOR-FINAL-REPORT.md` (before: 21 branches / 19 worktrees / 14 stashes / multiple .bak tracked / main drift; after: 1 branch / 1 worktree / 0 stashes / 0 .bak / 0 drift / 0/5 alerts).

THIS BEAD: integrate that probe into the flywheel tick step so every repo in the fleet gets continuous hygiene measurement + auto-bead-filing when thresholds breach.

## Deliverables

### A. Adopt mobile-eats's repo-hygiene-doctor.sh as flywheel canonical
- Mirror script to .flywheel/scripts/repo-hygiene-doctor.sh (if mobile-eats version is portable) OR write a flywheel-canonical version that calls the same metrics
- 5 metrics: worktree-count, stash-count, branch-count (local-only-merged), main-FF-drift, tracked-substrate-bloat (.flywheel/runtime|state|evidence size)
- Per-repo threshold config at .flywheel/hygiene-thresholds.yaml (defaults documented; per-repo override allowed)

### B. Tick-step integration
- Add hygiene probe to /flywheel:tick (or its tick-driver)
- Cadence: every tick (5-15min), per-repo
- Output: JSON envelope {repo, ts, metrics, alerts: [{class, current, threshold, severity}]}
- Ledger: ~/.local/state/flywheel/repo-hygiene-tick.jsonl

### C. Auto-bead-filer
- When alert.severity >= P2, auto-file a bead in the affected repo's beads queue
- Bead title format: "hygiene-tick: <class> exceeds threshold (current=<X> threshold=<Y>) at <repo>"
- Bead description: full metrics envelope + remediation hint
- Idempotent: don't file duplicate bead within 24h for same class+repo (check existing open beads)
- Per-class severity: worktree >5=P2, >10=P1, >20=P0; stash >5=P2, >10=P1, >20=P0; main-drift >50=P2, >100=P1, >500=P0; etc.

### D. Per-repo opt-in/out
- Repos with .flywheel/hygiene-tick.disabled file = SKIP (operator override)
- Repos with .flywheel/hygiene-thresholds.yaml = use overrides
- Default: enabled for all 8 fleet orchs

### E. tests/repo-hygiene-tick-smoke.sh
- 6+ assertions:
  1. Probe a synthetic repo with N=5 worktrees → metrics envelope correct
  2. Probe a synthetic repo with main-FF-drift → drift detected
  3. Probe a synthetic repo over threshold → alert fired
  4. Auto-file triggers under threshold breach → bead created
  5. Idempotent re-run within 24h → no duplicate bead
  6. .hygiene-tick.disabled opt-out → no probe, no alert, no bead

### F. Doctrine
.flywheel/doctrine/repo-hygiene-tick-discipline.md citing:
- mobile-eats's before/after evidence pack as the canonical motivation
- The 4 trauma classes the tick prevents: worktree-orphan, stash-buildup, branch-debt, main-FF-divergence, tracked-substrate-bloat
- Per-repo threshold tuning rationale
- Cross-link to flywheel-8ont6 (runtime-vs-doctrine separation — pairs with this work)

## Acceptance

- Probe script ships at .flywheel/scripts/repo-hygiene-doctor.sh (or equivalent integration point)
- Tick integration writes to ledger every cadence
- Auto-bead-filer creates beads in affected repos
- shellcheck PASS
- Smoke fixture 6+ assertions PASS
- Initial probe across 5 flywheel-managed repos (flywheel, skillos, zesttube, mobile-eats verified clean, clutterfreespaces) generates first ledger rows
- Doctrine doc citing mobile-eats's evidence
- Bead flywheel-ge03h closed

## Out of scope

- Actually EXECUTING cleanup — separate bead (flywheel-68cvz: /flywheel:repo-hygiene weekly Joshua-kicked supervised cleanup)
- Runtime/doctrine separation per-repo migration — separate bead (flywheel-8ont6)
- Per-orch propagation to non-flywheel repos — that's skillos canonical-locator lane

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- socraticode K>=10 with 2 phrasings on existing tick-driver structure + mobile-eats repo-hygiene-doctor.sh shape + beads auto-filing patterns
- Bridge daemon LIVE
- SCR event: C7_verification_density + C6_trauma_outflow
- STOP on Track 1/2 breach, BLOCKED, >3h hard cap
- DEEP-WORK validate: shellcheck + smoke + initial 5-repo probe run

## FIRST ACTION

1. br show flywheel-ge03h.
2. Read /Users/josh/Developer/mobile-eats/.repo_janitor_workspace/JANITOR-FINAL-REPORT.md.
3. Read mobile-eats repo-hygiene-doctor.sh source (cross-repo READ allowed via existing authorization paths) — find its location via gh search or git log -- '*hygiene-doctor*'.
4. ACK row.
5. Implement integration + auto-bead-filer + smoke + doctrine.
6. Self-validate (smoke + 5-repo dry-run).
7. Commit + close bead + DIRECT pane-1 ntm send.
