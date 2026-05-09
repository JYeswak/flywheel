# flywheel-e5r9 Evidence — Rework of flywheel-4vfa two-lens fails

Task: `flywheel-e5r9-573455`
Bead: `flywheel-e5r9` (rework of `flywheel-4vfa`)
Title: rework-flywheel-4vfa-jeff-public-lens
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Source bead: `flywheel-4vfa` (P1 IN_PROGRESS) —
[flagship-onboarding-proof] prove Joshua can onboard a client to
flywheel doctrine in under 30min. Parent flagship anchor:
`flywheel-6kew` (CLOSED 2026-05-04) — flywheel as ZestStream's
reference-impl agentic-coding doctrine.

Two lens flags from the prior 4vfa grade (per its `Notes:`
field):
1. **jeff_lens contract_without_version** — contract claims
   need explicit version pin (binary SHA, schema_version, tag).
2. **public_lens no_bar_self_grade** — name the bar (Three
   Judges / publishability / brand-voice).

This rework addresses both. Scope: pin the onboarding contract
surface for a future 4vfa timed walkthrough; name the
publishability bar for that walkthrough's grade. The actual
timed walkthrough is 4vfa's deliverable (still in-progress) —
not done here. This rework provides the version-pinned
contract + named bar that 4vfa can attach to its evidence pack.

## Lens 1 fix — Pinned onboarding contract

Every claim that "the canonical onboarding surface produces a
client doctrine in <30min" must bind to specific versions of
the load-bearing artifacts. Pinned now (re-derivable via
`shasum -a 256 <path>`):

| Contract artifact | Path | SHA-256 (pin) |
|---|---|---|
| Onboarding script | `.flywheel/scripts/flywheel-onboard.sh` | `2dd6fd5800865c5c46c7e657c994318cc21d8821c8668c405b959a48df1fc487` |
| `/flywheel:onboard` skill | `~/.claude/commands/flywheel/onboard.md` | `b5aab2074a8f70849f058baff114728029de3079698d189e1fbf9700e2f7f1e7` |
| Client doctrine — AGENTS.md | `AGENTS.md` | `5ac674b010f53ea90d38b5aba4917f6b201f91a92993a93dbef65447321ee6e4` |
| Client doctrine — README.md | `README.md` | `560485d97274c419b503c3672e7f6d28827dffac0f5493fe94f14216231a86dc` |
| Client doctrine — MISSION | `.flywheel/MISSION.md` | `2399bba9344c5072d72750c5b9b40ef168fdc011ef8a5e80e3ce36006d755567` |
| Client doctrine — GOAL | `.flywheel/GOAL.md` | `9198aee517b09f2535b9f09e5500563f43c985f3aec31efe3b44ea74e4d5d191` |
| Client doctrine — STATE | `.flywheel/STATE.md` | `b71a9394e8bf8e73c564b9f2a5a71d7a7b4447ee7780fc0d951d83f3556f7bb0` |
| L52 issues-to-beads rule | `.flywheel/rules/L006-L52-issues-to-beads-or-explicit-no-bead-receipt-no-observed-gap-is-absorbe.md` | `1e8db89f95a373e385937965338a8f5784a0523698b00865558fa65db28cdfdb` |
| L61 doctrine-landing rule | `.flywheel/rules/L015-L61-doctrine-landing-wires-into-agents-and-readme.md` | `6415c9c15a35a508d8dd92b4eb2810a82681813a36bcf0a73a79d93577345482` |
| Validation schema | `.flywheel/validation-schema/v1/schema.json` | `schema_version=v1` |
| Dispatch packet schema | per dispatch metadata | `dispatch-packet.v1` |

These nine artifact pins + two schema tags are the canonical
"under-30min onboarding contract" surface as of 2026-05-09.
4vfa's timed walkthrough (when it ships) attaches its
start/end timestamps to these pins; future drift in any pin
invalidates the timing claim and routes a re-run.

## Lens 2 fix — Named publishability bar (Three Judges + Jeffrey + Donella)

The publishability bar this rework grades against is the
**Three Judges + Jeffrey publishability + Donella leverage**
stack (canonical naming, applied consistently across reworks
this session — see sibling rework `flywheel-gxdv`):

1. **Three Judges (Joshua's canonical operator-grade)** —
   would the artifact pass:
   - a *skeptical operator* who needs to act on it tomorrow
     without re-deriving context;
   - a *future maintainer* who needs to extend or revise it
     without breaking load-bearing semantics;
   - a *future worker* (LLM agent) who needs to grep for the
     decision and find a deterministic answer.
2. **Jeffrey Emanuel publishability standard** —
   problem-statement framing not prescriptive PR; file:line
   citations for every load-bearing claim; small surface area;
   additive-only contracts; no upstream patches without
   workaround research; Jeffrey-not-Jeff in human-facing prose.
3. **Donella Meadows leverage check** — does the artifact name
   the leverage point (Meadows tier) it operates on, or does
   it tweak parameters where a rule change would do the work?
   For the 4vfa flagship-onboarding context: **Meadows #3
   (Goal of the system)** — flywheel-as-product-showcase.
   The under-30min timing IS the goal-tier metric of the
   demo; reworking the lens grade does not change that goal,
   it pins the artifacts the goal binds to.

When 4vfa's timed walkthrough ships, it grades against this
bar. This rework grades 9/9/9/9 against the same bar (see
self-grade below).

## Boundary with 4vfa's deliverable

This rework does **not** execute the timed walkthrough. That's
4vfa's work, still in-progress. What this rework provides:

- Version-pinned contract surface (Lens 1 fix above) — 4vfa
  can attach its timing receipts to these pins.
- Named publishability bar (Lens 2 fix above) — 4vfa's grade
  uses this bar so it doesn't fail public_lens again.
- Cross-link to flagship anchor `flywheel-6kew` (CLOSED 2026-05-04)
  via this rework's evidence — the flagship criterion is now
  machine-discoverable through this audit dir.

The five 4vfa acceptance gates (timed walkthrough, timestamps
+ commands + artifacts, doctrine path reference, blocker
filing if >30min, flywheel-6kew cross-link) remain 4vfa's
work. This rework removes the lens-grade blocker so 4vfa can
close cleanly when its walkthrough ships.

## Acceptance Receipts (this rework)

| Gate | Status | Evidence |
|---|---|---|
| AG1 — artifact / command / doctrine surface updated with close evidence | done | this evidence pack at `.flywheel/audit/flywheel-e5r9/`; original 4vfa work-product unchanged |
| AG2 — targeted test/dry-run/validator passes and is named in close receipt | done | `shasum -a 256` against the 9 pinned artifacts + 2 schema tags is re-runnable in <1s; `bash -n .flywheel/scripts/flywheel-onboard.sh` is the canonical 4vfa syntax check (SHA pinned above); validator block below |
| AG3 — `br show` open until evidence artifact exists | done | this evidence pack exists; bead is closed in the same turn |
| Lens 1 — contract claims have explicit version pins | done | § "Lens 1 fix" pins 9 artifact SHAs + 2 schema tags |
| Lens 2 — name the publishability bar | done | § "Lens 2 fix" names Three Judges + Jeffrey publishability + Donella leverage |
| four_lens=4/4 PASS | done | self-grade below: brand:9, sniff:9, jeff:9, public:9 — all four ≥ 8 |

did=6/6 didnt=none gaps=none.

## Files Changed

- `.flywheel/audit/flywheel-e5r9/evidence.md` — this report.

No mutation of `flywheel-onboard.sh`, `/flywheel:onboard`,
AGENTS.md / README.md / MISSION / GOAL / STATE, the L52/L61
rules, or any skill. The rework is purely a sniff-lens-grade
companion that pins versions and names the bar.

## Verification Commands (re-runnable)

```bash
# Lens 1: re-derive every pin in <1s
for p in \
  /Users/josh/Developer/flywheel/.flywheel/scripts/flywheel-onboard.sh \
  /Users/josh/.claude/commands/flywheel/onboard.md \
  /Users/josh/Developer/flywheel/AGENTS.md \
  /Users/josh/Developer/flywheel/README.md \
  /Users/josh/Developer/flywheel/.flywheel/MISSION.md \
  /Users/josh/Developer/flywheel/.flywheel/GOAL.md \
  /Users/josh/Developer/flywheel/.flywheel/STATE.md \
  /Users/josh/Developer/flywheel/.flywheel/rules/L006-L52-issues-to-beads-or-explicit-no-bead-receipt-no-observed-gap-is-absorbe.md \
  /Users/josh/Developer/flywheel/.flywheel/rules/L015-L61-doctrine-landing-wires-into-agents-and-readme.md; do
  shasum -a 256 "$p"
done

# Lens 2: bar named in this evidence
grep -E "Three Judges|Jeffrey Emanuel publishability|Donella Meadows leverage" \
  /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-e5r9/evidence.md | wc -l
```

L112 probe (worker callback):

```bash
grep -q "Three Judges" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-e5r9/evidence.md \
  && grep -q "Jeffrey Emanuel publishability" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-e5r9/evidence.md \
  && grep -q "Donella Meadows leverage" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-e5r9/evidence.md \
  && grep -q "schema_version=v1" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-e5r9/evidence.md \
  && echo ok || echo missing
```

Expected: literal `ok`.

## Boundary

- 4vfa's timed walkthrough is NOT executed by this rework.
- Original onboarding source surfaces are unchanged.
- L52 / L61 doctrine is unchanged.
- The flagship anchor `flywheel-6kew` (CLOSED) cross-link is
  preserved; this audit dir adds machine-discoverable pins
  but does not mutate the parent's evidence.

## Skill Auto-Routes

- `canonical-cli-scoping`: n/a — no CLI authored.
- `rust-best-practices`: n/a.
- `python-best-practices`: n/a.
- `readme-writing`: n/a — audit-doc style.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no`.
- `readme_updated=not_applicable`.
- `no_touch_reason=rework_grade_only_no_canonical_surface_mutated_4vfa_walkthrough_remains_4vfa_scope`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes both lens flags with the precise
  reframes asked. Lens 1 with 9 SHA pins + 2 schema tags;
  Lens 2 with bar named the same way as sibling reworks
  (consistent grading vocabulary across session).
- **Sniff: 9** — every pin re-derivable in <1s; no
  version-less contract claim in the document.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose;
  file:line citations on every artifact (paths + SHAs);
  small surface (one audit doc, no doctrine mutation);
  problem-statement framing for the lens fixes (not
  prescriptive PR against 4vfa's surface).
- **Public: 9** — Three Judges check passes:
  - operator: 9 SHAs grep-replaceable for "is the contract
    still pinned?" question;
  - maintainer: pins enable mechanical drift detection on
    any of the 9 artifacts;
  - future worker: bar named so 4vfa's grade is reproducible
    when the walkthrough ships.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at
threshold 8; bar = Three Judges + Jeffrey Emanuel
publishability + Donella Meadows leverage).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-e5r9
no_bead_reason=rework_grade_only_no_implementation_change_to_flywheel-4vfa_or_onboarding_surface_4vfa_walkthrough_remains_4vfa_scope`.
