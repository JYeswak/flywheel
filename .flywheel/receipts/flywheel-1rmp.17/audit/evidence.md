# flywheel-1rmp.17 — value-gap mobile-eats-end-user-health

## Bead context

- ID: `flywheel-1rmp.17` (P3, open at dispatch start, closed at done)
- Title: `[value-gap] mobile-eats-end-user-health`
- Parent: `flywheel-1rmp` (Step 4o value-gap-hunter, P1, in-progress)
- Goal: Add a measurement for the `mobile-eats-end-user-health` value-gap dimension
- DoD: `VALUE_GAP_DIMENSION=mobile-eats-end-user-health measurement=<path-or-reason> surfaced=<yes|no>`

## Disposition: duplicate-of-flywheel-1rmp.7

`flywheel-1rmp.7` and `flywheel-1rmp.17` were filed against the same dimension by `value-gap-probe.sh` rotation (the dimension scan ran twice over the brainstorm rotation cycle and value-gap-probe filed two beads with identical body text). Bead `.7` was closed 2026-05-09 against the live measurement at `.flywheel/scripts/mobile-eats-end-user-health-probe.sh`. Bead `.17` carries identical goal/finding/proposed-measurement/acceptance/DoD and is therefore satisfied by the same artifact.

This bead `.17` closes against the same probe path with header annotation
upgraded to call out the duplicate relationship explicitly so the next
duplicate-detector pass has the trail.

## Acceptance criteria — verbatim from bead

1. **Define the smallest recurring measurement that would make this gap visible.**
   Met. Probe `.flywheel/scripts/mobile-eats-end-user-health-probe.sh` (307 lines) measures:
   - artifact presence for the canonical 4 SaaS-tier KPI source files
     (`saas-kpi-strip.ts`, `saas-metrics.ts`, `mrr-rollup.ts`,
     `community-health-metrics.ts`)
   - paired `*.test.ts` presence for 3 of the 4 surfaces
   - mtime freshness (newest source mtime against 72h budget)
   - explicit `actual_user_health: "no_db_surface_yet"` enum value with a
     prose `actual_user_health_no_surface_reason` describing the missing
     first-party DB telemetry path

2. **Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason.** Met (multi-channel):
   - Ledger: `~/.local/state/flywheel/mobile-eats-end-user-health.jsonl`
     (2 rows, newest ts `2026-05-09T20:00:02Z`, freshness=fresh,
     surfaces=4/4, tests=3/3)
   - Doctor signal: `--doctor --json` returns `status:ok` with empty
     `issues[]` when repo + ledger writable
   - Dispatch-log surfacing: `value-gap-probe.sh` invocations write
     `value_gap_probe` events to `.flywheel/dispatch-log.jsonl` (see
     2026-05-04T06:06:37Z entry citing this dimension as scanned with
     `bead_filed_id=flywheel-1rmp.7`)
   - Explicit no-surface receipt: every ledger row carries
     `actual_user_health="no_db_surface_yet"` with a prose reason — the
     first-party DB telemetry wireup is intentionally a separate
     value-gap-followup bead, not in scope here.

3. **Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding.** Met. Probe header explicitly states "this probe SURFACES the gap; it does NOT auto-create beads or dispatch fixes". Parent `value-gap-probe.sh` enforces the contract. No dispatch was triggered by this bead's execution.

## Proof: live ledger row (newest)

```json
$(cat ledger-tail.jsonl | tail -1)
```

(stored in `.flywheel/receipts/flywheel-1rmp.17/audit/ledger-tail.jsonl`)

## Change shape

- Edit 1: probe header lines 6-11 — replace single `Owns:` citation with explicit duplicate-of relationship (`flywheel-1rmp.7` primary, `flywheel-1rmp.17` duplicate, both closed 2026-05-09).
- Edit 2: probe `info_payload()` — add `duplicate_of_owns: ["flywheel-1rmp.17"]` field beside existing `owns:"flywheel-1rmp.7"` for machine-readable trail.

No behavior change. Ledger schema unchanged. Triad (`--info`/`--schema`/`--doctor`) still PASS.

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | yes | Probe already has triad+schema+stable exit codes; edits preserve all gates; no new flags introduced. |
| rust-best-practices | n/a | Bash file. |
| python-best-practices | n/a | Bash file. |
| readme-writing | n/a | No README touched; in-file header serves as docs. |

## Four-Lens Self-Grade

- **brand: 9** — Joshua-style duplicate-resolution receipt + machine-readable `duplicate_of_owns` field.
- **sniff: 9** — 2 small edits, preserved schema, preserved exit codes, --doctor still ok.
- **jeff: 9** — explicit no-surface receipt remains canonical; ledger is stable JSON-Lines; duplicate trail is structured, not prose.
- **public: 9** — Three Judges: skeptical operator (live ledger row + freshness=fresh), maintainer (header cites both bead IDs), future worker (prevents next duplicate-detector pass from re-litigating).

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Mission fitness

`infrastructure` — value-gap-hunter is the orchestrator's paradigm-tier scan; keeping its outputs duplicate-clean (and probes machine-traceable to multiple bead IDs) directly serves continuous-orchestrator-uptime by reducing duplicate-bead dispatch noise.

## DoD line (closing receipt)

```
VALUE_GAP_DIMENSION=mobile-eats-end-user-health measurement=.flywheel/scripts/mobile-eats-end-user-health-probe.sh surfaced=yes
```
