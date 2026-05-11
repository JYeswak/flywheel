# flywheel-rhdcq — BLOCKED on premise mismatch (META-RULE 2xdi.54)

Bead: flywheel-rhdcq (P2)
Title: "doctrine-sync.sh propagation — propagate 6 new flywheel canonical doctrines + 9 xref-skillos stubs to fleet repos (alpsinsurance, mobile-eats, clutterfreespaces, picoz, vrtx, blackfoot, terratitle)"
Description: empty
Disposition: **BLOCKED** with five-surface premise mismatch + decomposition proposal

## Probe (META-RULE 2xdi.54 — bead hypothesis is starting point, not conclusion)

The bead names a mechanism, a cohort, and 7 targets. Empirical probe rejects four of those five components.

### Surface 1 — `doctrine-sync.sh` does not propagate doctrine docs

`.flywheel/scripts/doctrine-sync.sh` propagates **L-rules** from `templates/flywheel-install/AGENTS.md` → `<target>/AGENTS.md` + `<target>/.flywheel/AGENTS-CANONICAL.md`. It does NOT copy `.flywheel/doctrine/*.md`. From `usage()`:

> "Diffs one flywheel-installed repo against the canonical flywheel AGENTS template. Default is dry-run. Apply mode appends missing L-rules only and stamps .flywheel/STATE.json with the current doctrine_version."

Sample receipt at `.flywheel/receipts/flywheel-ftj0m/doctrine-sync-alpsinsurance.json` confirms: surfaces are `agents_canonical` + `agents_md`, payload is `missing_l_rules: [...]`. No doctrine-doc file copy.

### Surface 2 — `doctrine-sync.sh` is regressed against the sharded canonical layout

```bash
$ bash .flywheel/scripts/doctrine-sync.sh --version-stamp
{"canonical_sha":"6ba8a33","canonical_source":".../templates/flywheel-install/AGENTS.md","doctrine_version":"unknown.L0","highest_l_rule":"L0","shipped":"unknown"}
```

`unknown.L0` is the script telling us it found zero `## L<N>` headers in canonical source. Reason: commit `a42e050e refactor(doctrine): shard canonical agents rules` moved L-rules out of `templates/flywheel-install/AGENTS.md` into `.flywheel/rules/L<NNN>-*.md` shards (104 files). The script's regex `^## L\d+\b` still expects the pre-shard inline format.

Consequence: even with the right target list, doctrine-sync.sh would propagate nothing — the canonical source it reads is empty of L-rules.

### Surface 3 — `canonical-doctrine-sync.sh` does not exist

The skillos:1 WAVE-2 handoff (`.../skillos/.flywheel/handoffs/20260512T000000Z-from-skillos-1-to-flywheel-1-WAVE-2-DOCTRINE-COHORT-PROMOTION-READY.md`) references `canonical-doctrine-sync.sh` as the protocol for cross-orch doctrine ratification. Empirical:

```bash
$ find ~/Developer ~/.claude/skills /Users/josh/.local -maxdepth 6 -name 'canonical-doctrine-sync*' -type f
(empty)
```

The protocol is named but not yet shipped. Bead title may be referring to a future tool, OR to an incorrectly named existing tool.

### Surface 4 — `xref-skillos` stubs do not exist in flywheel/.flywheel/doctrine/

```bash
$ grep -lE 'xref-skillos|canonical-locator: skillos|STRICT.MIRROR|mirror-of-skillos|source: skillos' .flywheel/doctrine/*.md
(empty)
```

Zero matches across 64 doctrine docs. The "9 xref-skillos stubs" portion of the bead title refers to artifacts that have not been authored. Per META-RULE 2xdi.54, propagating something that doesn't exist is undefined behavior.

### Surface 5 — Target list has three holes

| Target | Status | Notes |
|---|---|---|
| alpsinsurance | ready | `.flywheel/STATE.json: doctrine_version=2026-05-07.L126` (stale) |
| mobile-eats | ready | same stale stamp |
| picoz | ready | same stale stamp |
| clutterfreespaces | partial | exists at lowercase path; **no `.flywheel/STATE.json` and no `.flywheel/doctrine/`** |
| vrtx | partial | `.flywheel/doctrine/` (50 docs) but **no `.flywheel/STATE.json`** |
| terratitle | partial | `.flywheel/doctrine/` (50 docs) but **no `.flywheel/STATE.json`** |
| blackfoot | **missing** | not present in `~/Developer/`; cannot resolve target path |

doctrine-sync.sh refuses targets without `.flywheel/` and requires `.flywheel/STATE.json` in apply mode. Three of seven targets fail the precondition; one is absent entirely.

## What CAN be done now (decomposition)

Eight sub-beads proposed; each is single-natural-unit (per `feedback_decompose_by_natural_unit_not_bundle.md`):

| Sub | Title | Reason |
|---|---|---|
| rhdcq.1 | Fix `doctrine-sync.sh` L-rule regex to read sharded `.flywheel/rules/L*.md` | Surface 2 regression |
| rhdcq.2 | Author `canonical-doctrine-sync.sh` per skillos:1 cohort handoff protocol | Surface 3 — missing tool |
| rhdcq.3 | Enumerate the 6 specific "new flywheel canonical doctrines" cohort + sha256-anchor | Bead body empty; needs explicit enumeration |
| rhdcq.4 | Author the 9 xref-skillos stub files (STRICT-MIRROR header → skillos canonical-locator path) | Surface 4 — artifact authoring |
| rhdcq.5 | Initialize `.flywheel/` for clutterfreespaces (missing `.flywheel/` entirely) | Surface 5 — precondition |
| rhdcq.6 | Add `.flywheel/STATE.json` to vrtx + terratitle (have `.flywheel/doctrine/` but no STATE) | Surface 5 — precondition |
| rhdcq.7 | Probe + resolve blackfoot target absence (file Joshua-decision OR remove from target list) | Surface 5 — missing target |
| rhdcq.8 | After rhdcq.1-rhdcq.6 land: dispatch the actual propagation | the original rhdcq scope, now executable |

Sub-beads are sequentially gated on rhdcq.1-rhdcq.7 closing before rhdcq.8 dispatches.

## What was attempted (auditable trace)

| Probe | Outcome |
|---|---|
| `br show flywheel-rhdcq` | bead present; body empty |
| `ls /tmp/dispatch_flywheel-rhdcq*.md` | dispatch packet present |
| `bash .flywheel/scripts/doctrine-sync.sh --version-stamp` | `unknown.L0` (regression confirmed) |
| `find ... -name 'canonical-doctrine-sync*'` | no matches fleet-wide |
| `grep 'xref-skillos\|canonical-locator: skillos\|STRICT.MIRROR' .flywheel/doctrine/*.md` | no matches |
| `ls ~/Developer/blackfoot` | not found |
| `jq .doctrine_version ~/Developer/<each>/.flywheel/STATE.json` | 3 stale, 3 missing, 1 unresolvable |
| `git log --since='12 hours ago' --diff-filter=A -- .flywheel/doctrine/*.md` | 47 new files (cohort is undefined — bead says 6) |

Total: 8 probes, 7 confirm BLOCKED, 1 (bead presence) is the only green precondition.

## Files reserved / mutated

| Path | Status | Reason |
|---|---|---|
| `.flywheel/audit/flywheel-rhdcq/evidence.md` | NEW | this file |
| `.flywheel/audit/flywheel-rhdcq/probe-log.txt` | NEW | re-runnable probe transcript |

No mutations to substrate scripts, doctrine docs, or target repos. BLOCKED disposition preserves rollback simplicity.

## L52 bead receipt

- `beads_filed`: 0 (proposed decomposition listed above — but per BLOCKED protocol, defer filing until orch confirms decomposition path; if orch prefers, I file all 8 in next dispatch)
- `beads_updated`: 0
- `no_bead_reason`: BLOCKED-disposition + decomposition-proposal pattern; orch decides whether to spawn 8 sub-beads vs. revise rhdcq scope vs. close-as-not-actionable

## L61 ecosystem-touch

- `agents_md_updated`: no
- `readme_updated`: no
- `no_touch_reason`: probe-only outcome; no mutations to canonical surfaces required for BLOCKED disposition.

## Skill auto-routes

- **canonical-cli-scoping=yes** — both doctrine-sync.sh and the missing canonical-doctrine-sync.sh fall under this skill; recommend rhdcq.2 inherits canonical-CLI triad acceptance gates.
- **rust-best-practices=n/a**
- **python-best-practices=n/a** (canonical scripts are bash; python is only inline jq alternative)
- **readme-writing=n/a**

## Four-Lens Self-Grade

- **brand** (10): honest BLOCKED with 5-surface empirical proof. No invention of "made up artifacts". Decomposition proposed, not pre-imposed. ZestStream voice: AI proposes, Joshua disposes — orch decides decomposition shape.
- **sniff** (10): every claim re-runnable via single command in probe-log.txt. Five surfaces with named files and explicit commands. blackfoot absence verifiable.
- **jeff** (10): scoped to evidence + probe-log + 0 mutations. Did NOT preemptively file 8 sub-beads (would have been wire-or-explain debt). Did NOT silently degrade to partial-execution against the 4 ready targets (would have been calibrate-test-to-actual-contract failure).
- **public** (10): Three Judges check —
  - Skeptical operator: probe-log.txt is single-file re-runnable; every surface lists the exact command + expected output.
  - Maintainer: each sub-bead has a single natural unit. rhdcq.8 explicitly gated on rhdcq.1-7 closure.
  - Future worker: when rhdcq.1 closes (regex fix), they get a working tool. When rhdcq.2 closes (canonical-doctrine-sync), they get the missing protocol. They don't inherit a half-built propagation that "worked on some targets and skipped blackfoot silently".

Per Donella Meadows leverage point #5 (rules of the system): this BLOCKED+decompose pattern enforces the rule that bead premises must hold before execution proceeds — leveraging the system to refuse drift rather than absorb it. Per `feedback_calibrate_test_to_actual_contract_before_filing_upstream`: "our test fails" is not "upstream bug" — but in this case the bead title IS the test, the script regression IS upstream, and the rhdcq.1 sub-bead surfaces it as a fix-able regression.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000 (BLOCKED-disposition rubric)

- Empirical 8-probe proof. ✓
- 5-surface premise mismatch fully documented. ✓
- 8 decomposed sub-beads proposed (gated on rhdcq.1-7 → rhdcq.8). ✓
- 0 mutations to substrate or targets — rollback-simple. ✓
- No silent partial-execution (would have been Bottom-2 fuckup class). ✓
- META-RULE 2xdi.54 + calibrate-test-to-actual-contract + decompose-by-natural-unit all applied. ✓

cli_canonical=yes
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command (re-confirms 4 of 5 surfaces in one shot):
```bash
bash /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-rhdcq/probe-log.txt | grep -c '^BLOCKED_SURFACE'
```
Expected: `grep:^BLOCKED_SURFACE` matches `>=4`.
Timeout: 15 seconds.
