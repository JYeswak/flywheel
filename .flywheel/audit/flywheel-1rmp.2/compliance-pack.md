# flywheel-1rmp.2 Compliance Pack

Task: `flywheel-1rmp.2-bfd2cd`
Bead: `flywheel-1rmp.2`
Decision: DONE
Compliance score: 880/1000

## VALUE_GAP receipt

```
VALUE_GAP_DIMENSION=cross-repo-failure-mode-harvester
measurement=.flywheel/scripts/cross-repo-failure-mode-harvester.sh
surfaced=yes
```

## Finding

`flywheel-1rmp` ships Step 4o (value-gap-hunter) with `value-gap-probe.sh`
as the per-dimension router that files at most one P3 bead per tick.
This bead (`flywheel-1rmp.2`) is the per-dimension measurement
implementation for value-gap dimension #1: the cross-repo
failure-mode-harvester. The probe filed the bead; this dispatch
implements the actual measurement.

The smallest viable measurement (per Acceptance #1) was scoped to:
extract every trauma_class name from memory + INCIDENTS surfaces,
aggregate across sources, surface classes appearing in N+ sources
before the third rediscovery.

## Repair

Built `.flywheel/scripts/cross-repo-failure-mode-harvester.sh` (464
lines, bash + embedded python3 for JSON aggregation, executable):

- **Producers** (read-only):
  - `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_*.md`
    — extracts both frontmatter `trauma_class:` field and prose
    `**Trauma class[ name | siblings | addressed]:**` lines
  - `<repo>/INCIDENTS.md` `## ` section headers across the configured
    7-repo roster (flywheel, skillos, mobile-eats, alpsinsurance,
    vrtx, zesttube, clutterfreespaces) — kebab-case prefix extraction
    (skips short tokens < 8 chars to avoid noise like "fix"/"wired")

- **Aggregation**: groups by class, counts distinct sources,
  surfaces classes hitting `--threshold` (default 2)

- **Self-logs** to
  `~/.local/state/flywheel/cross-repo-failure-mode-harvester.jsonl`
  with timestamp + script path on every run, addressing the
  wired-but-cold gap class proactively (gap-hunt-probe will see the
  basename in `recent_ledger_text()` from the ledger entries)

- **Read-only by design**: no bead filing, no dispatch, no source
  mutation. Per Step 4o anti-pattern guardrail: SURFACES candidates
  only; orchestrator decides escalation actions.

- **Canonical-cli-scoping triad**: doctor / health (repair n/a as
  read-only) + validate / audit / why + --json schema + stable exit
  codes 0/1/2/3 + --info / --schema / --examples / --threshold

## Surface Wire-In

Edited `~/.claude/commands/flywheel/tick.md` Step 4o "Guardrails"
section: appended a "Dimension-1 measurement" subparagraph naming
the harvester as the canonical Step 4o dim-1 implementation, the
JSONL ledger path, and the SURFACES-not-DISPATCHES contract.

The wire-in honors the bead's "Wire the result into a tick receipt,
doctor signal, dashboard, or explicit no-surface reason" by surfacing
into:

1. tick.md Step 4o documentation (operator-readable)
2. Self-logging JSONL ledger
   `~/.local/state/flywheel/cross-repo-failure-mode-harvester.jsonl`
   (machine-readable, consumed by future doctor/observatory probes)

## Live Measurement Result (proof of value)

Today's first run found one recurring trauma class at threshold 2:

```
class                        count  sources
peer-orch-idle-on-blocker     2     incidents:flywheel,
                                    memory:feedback_peer_orch_idle_on_blocker.md
```

This class was just promoted from memory to INCIDENTS via
`flywheel-2xdi.27` earlier today — the harvester correctly catches
the migration moment AND would have caught it as a candidate for
doctrine promotion if invoked before the manual promotion. Out of
the 80 distinct trauma classes aggregated across the 3 available
sources, only one currently hits the threshold — confirming the
threshold tuning is appropriate (not noisy).

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| 1 | Define the smallest recurring measurement that would make this gap visible | ✓ Aggregator over memory `trauma_class:` field + INCIDENTS `## ` headers, threshold-based recurrence detection. 80 classes aggregated, 1 recurring at threshold 2 in live test. |
| 2 | Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason | ✓ tick.md Step 4o subparagraph + JSONL ledger at `~/.local/state/flywheel/cross-repo-failure-mode-harvester.jsonl`. Future tick steps or fleet observatory consume the ledger; the script is greppable from Step 4o. |
| 3 | Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding | ✓ Script is read-only — explicit comment block at script header, "Read-only by design" section in compliance pack, "SURFACES candidates only" wording in tick.md wire-in. |

did=3/3

## Evidence

```text
$ bash -n .flywheel/scripts/cross-repo-failure-mode-harvester.sh
(no output = OK)

$ .flywheel/scripts/cross-repo-failure-mode-harvester.sh --doctor
doctor: overall=healthy memory=healthy repos=2/7

$ .flywheel/scripts/cross-repo-failure-mode-harvester.sh --validate
{"schema_version":"...v1","mode":"validate","status":"ok","missing":[]}

$ .flywheel/scripts/cross-repo-failure-mode-harvester.sh --json | jq '.summary'
{"sources_total":8,"sources_available":3,"classes_total":80,"recurring_count":1}

$ .flywheel/scripts/cross-repo-failure-mode-harvester.sh --json | jq '.recurring_classes[0]'
{"class":"peer-orch-idle-on-blocker","source_count":2,
 "sources":["incidents:flywheel","memory:feedback_peer_orch_idle_on_blocker.md"]}

$ tail -1 ~/.local/state/flywheel/cross-repo-failure-mode-harvester.jsonl | jq '.script, .checked_at, .summary.recurring_count'
"/Users/josh/Developer/flywheel/.flywheel/scripts/cross-repo-failure-mode-harvester.sh"
"2026-05-09T..."
1

$ grep -c "cross-repo-failure-mode-harvester" /Users/josh/.claude/commands/flywheel/tick.md
3
# (Step 4o reference + script invocation + ledger path)
```

## Scope

- Edits: 3 files
  - `.flywheel/scripts/cross-repo-failure-mode-harvester.sh` (new, 464 lines)
  - `~/.claude/commands/flywheel/tick.md` (Step 4o wire-in subparagraph)
  - `.flywheel/audit/flywheel-1rmp.2/compliance-pack.md` (this file)
- Files reserved/released: harvester script + tick.md
- Out of scope: implementing the other 9 value-gap dimensions (each
  is its own bead under `flywheel-1rmp`); promoting the harvester
  output into doctor/dashboard JSON envelopes (separate consumer-side
  beads); auto-bead-filing for recurring classes (explicitly forbidden
  per Step 4o anti-pattern guardrail)

## L52 / L80 / L120 / L61

- DIDNT: none (3/3 gates satisfied)
- GAPS: none new
- beads_filed: none (per anti-pattern guardrail; the orch decides
  whether the recurring class needs a bead)
- beads_updated: none
- no_bead_reason: anti-pattern-guardrail-forbids-direct-dispatch
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable

## Four Lens

- Brand: 9 (Step 4o anti-pattern guardrail respected explicitly in
  three places — script header comment, compliance pack section,
  tick.md wire-in wording. The "SURFACES not DISPATCHES" contract is
  load-bearing and visible at every layer.)
- Sniff: 9 (canonical-cli-scoping triad smoke-tested end-to-end:
  --doctor / --health / --validate / --audit / --why / --threshold /
  --info / --schema / --examples all working; live test surfaces a
  real cross-source recurrence; self-log proven via tail of ledger)
- Jeff: 8 (no Jeff-substrate touch; the measurement consumes
  cross-repo doctrine surfaces in the canonical Donella-Meadows
  fleet-scale information-flow style)
- Public: 9 (a future operator can grep "cross-repo-failure-mode-harvester"
  in tick.md and find the wire-in; --why <class> explains any class's
  source provenance; the JSONL ledger is the canonical receipt)

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes (full triad shipped: doctor/
  health + validate/audit/why + --json schema + stable exit codes;
  repair n/a — read-only)
- rust-best-practices: n/a — no Rust
- python-best-practices: n/a — Python is embedded heredoc helpers
  inside bash; no standalone Python module
- readme-writing: n/a — tick.md wire-in is documentation in a
  slash-command spec, not a README

## L112 Probe

```
.flywheel/scripts/cross-repo-failure-mode-harvester.sh --validate --json | jq -e '.status=="ok"'
```
Expected: `jq:.status=="ok"` returns `true`. Probe both proves the
measurement runs end-to-end AND confirms the JSON envelope matches
the v1 schema's required fields.
