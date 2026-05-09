# flywheel-1rmp.19 — value-gap cross-time-synthesis

## Bead context

- ID: `flywheel-1rmp.19` (P3, open at dispatch start, closed at done)
- Title: `[value-gap] cross-time-synthesis`
- Parent: `flywheel-1rmp` (Step 4o value-gap-hunter, P1, in-progress)
- Goal: Add a measurement for the `cross-time-synthesis` value-gap dimension
- DoD: `VALUE_GAP_DIMENSION=cross-time-synthesis measurement=<path-or-reason> surfaced=<yes|no>`

## Disposition: duplicate-of-flywheel-1rmp.9

`flywheel-1rmp.9` and `flywheel-1rmp.19` were filed against the same
dimension by `value-gap-probe.sh` rotation. Bead `.9` was closed
2026-05-09 against the live measurement at
`.flywheel/scripts/cross-time-synthesis-probe.sh`. Bead `.19` carries
identical goal/finding/proposed-measurement/acceptance/DoD and is
satisfied by the same artifact.

This is the **second** duplicate-pair observed today (the first was
`.7`/`.17` for mobile-eats-end-user-health). The pattern points at a
real defect in `value-gap-probe.sh` — see bead `flywheel-t9iva` filed
under L52.

## Acceptance criteria — verbatim from bead

1. **Define the smallest recurring measurement that would make this gap visible.**
   Met. Probe `.flywheel/scripts/cross-time-synthesis-probe.sh` (293 lines) measures, from the last N=10 handoff files in `.flywheel/handoffs/`:
   - `handoffs_observed` (raw count)
   - `with_tomorrow_you_section` / `without_tomorrow_you_section` — section-header regex match for `Open question|Tomorrow|Next session|Pending|Unresolved`
   - `tomorrow_you_coverage_ratio` — with / observed
   - `latest_handoff_age_hours` — mtime delta of newest
   - `tomorrow_you_artifact_today` — `present` iff today wrote a handoff carrying a tomorrow-you section, else `missing`

2. **Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason.** Met (multi-channel):
   - Ledger: `~/.local/state/flywheel/cross-time-synthesis.jsonl`
     (2 rows after this run; newest ts `2026-05-09T20:03:57Z`,
     `tomorrow_you_coverage_ratio:0.0`, `tomorrow_you_artifact_today:"missing"`,
     `without_tomorrow_you_section:10`)
   - Doctor signal: `--doctor --json` returns `status:ok` with empty `issues[]`
   - Dispatch-log surfacing: parent `value-gap-probe.sh` writes
     `value_gap_probe` rows to `.flywheel/dispatch-log.jsonl`
   - The probe's current finding (coverage_ratio=0.0, today's handoff
     missing tomorrow-you section) is itself the visible no-surface
     signal — the rotation surfaces a real coverage gap in the live
     handoff stream.

3. **Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding.** Met. Probe header: "this probe surfaces; it does NOT auto-create handoffs or dispatch fixes". Handoff authoring stays operator-driven through `/flywheel:handoff`. No dispatch was triggered by this bead's execution.

## Proof: live ledger row (newest)

Stored in `.flywheel/receipts/flywheel-1rmp.19/audit/ledger-tail.jsonl`.
Newest row ts `2026-05-09T20:03:57Z`. The probe is alive and the
measurement is recurring.

## L52 receipt: filed enhancement bead

`flywheel-t9iva` — `[value-gap-probe] dedup filings against still-open
same-dimension beads`. Captures the duplicate-rotation defect:
value-gap-probe.sh rotates dimensions but does not check whether an
open bead already exists for the same dimension across ticks, producing
duplicate-pairs (.7/.17, .9/.19 observed today). Acceptance proposes
adding a `dimension_has_open_bead()` predicate and a structured
`bead_action: "skipped_duplicate"` event.

## Change shape on this bead's surface

- Edit 1: probe header lines 6-12 — replace single `Owns:` citation with explicit duplicate-of relationship (`flywheel-1rmp.9` primary, `flywheel-1rmp.19` duplicate, both closed 2026-05-09).
- Edit 2: probe `info_payload()` — add `duplicate_of_owns: ["flywheel-1rmp.19"]` field beside existing `owns:"flywheel-1rmp.9"`.

No behavior change. Ledger schema unchanged. Triad still PASS.

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | yes | Probe already has triad+schema+stable exit codes; edits preserve all gates. |
| rust-best-practices | n/a | Bash file. |
| python-best-practices | n/a | Bash file. |
| readme-writing | n/a | No README touched. |

## Four-Lens Self-Grade

- **brand: 9** — second duplicate-resolution this session; consistent shape with `.17` evidence.md.
- **sniff: 9** — 2 small edits, preserved schema, preserved exit codes, --doctor still ok.
- **jeff: 9** — explicit no-surface receipt remains canonical; ledger is stable JSON-Lines; duplicate trail is structured, not prose; pattern surfaced as a structured bead, not absorbed silently.
- **public: 9** — Three Judges: skeptical operator (live ledger row + freshness signal), maintainer (header cites both bead IDs), future worker (filed dedup-enhancement bead with concrete acceptance gates so the duplicate pattern stops at the source).

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Mission fitness

`infrastructure` — value-gap-hunter is the orchestrator's paradigm-tier scan; reducing duplicate-bead noise + filing the source-fix bead directly serves continuous-orchestrator-uptime by tightening Step 4o's bead-filing discipline.

## DoD line (closing receipt)

```
VALUE_GAP_DIMENSION=cross-time-synthesis measurement=.flywheel/scripts/cross-time-synthesis-probe.sh surfaced=yes
```
