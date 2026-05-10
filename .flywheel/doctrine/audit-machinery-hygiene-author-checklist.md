---
name: audit-machinery-hygiene-author-checklist
type: checklist
created: 2026-05-11
status: v1.0-author-facing-companion-to-audit-machinery-hygiene-discipline
source_doctrine: .flywheel/doctrine/audit-machinery-hygiene-discipline.md
authority: flywheel-c5ovc (codification bead for doctrine wire-in)
cluster: audit-machinery-hygiene-doctrine-cluster
sister_checklist: .flywheel/doctrine/doctor-invariant-author-checklist.md (flywheel-8n3ua)
applies_to: any audit-machinery surface that produces classification output with 2nd-order downstream cost
---

# Audit-Machinery Hygiene Author Checklist

**When to use:** before merging any audit-machinery surface that classifies substrate state and produces output that:
- spawns completion-debt beads, OR
- gates ship/merge decisions, OR
- triggers implementation work, OR
- feeds into operator sprint planning

Examples: compliance scorers, spec extractors, doctor invariants, close validators, lint gates with auto-file behavior.

**When NOT to use:** read-only diagnostic probes with no downstream cost (e.g., a doctor command operators inspect manually but no automation acts on). The 4 shapes here all involve 2nd-order cost; pure-diagnostic probes carry trivial trauma risk.

**Sister checklist:** `doctor-invariant-author-checklist.md` covers in-probe fragility (probe path / timeout / error code / umbrella). This checklist covers out-of-probe classification-output fragility. A probe can be Rules-1-3 compliant AND still trip Shapes A/B/C/D — the two checklists are complementary.

## The 4 shapes (one author commitment per shape)

### Shape A — Probe wrongly fires on benign substrate state

**The failure:** classification rule misfires; substrate is structurally fine but probe emits FAIL/violation.

**Author commitment — invertibility:**

> Given any FAIL/violation row this audit emits, an operator (or LLM-fork) must be able to:
> 1. Identify EXACTLY which classification rule fired
> 2. Look at the source artifact and verify the rule's premise on real state
> 3. Either confirm violation OR articulate why the rule's premise was wrong

If the audit's output is "FAIL: $skill missing telemetry" but the rule that fired is buried 6 levels deep in nested aggregations, the rule is **non-invertible** and Shape A risk is structural.

**Mitigation pattern:**
- Every emit row carries a `classification_rule_id` field (e.g., `"score_below_635_strict"`)
- Operator can grep audit output for that ID and find the rule's source line
- Rule source documents the inversion: "fires when X; verify by reading $artifact for Y"

**Canonical instance:**

| Repo | Exemplar | Closure |
|---|---|---|
| skillos | Phase 4 stub-mode scorer zeroed Required-tests when n/a (10 phantom beads filed) | criterion v1/v2 SAFE-BATCH-CLOSE 2026-05-10T20-23Z |
| flywheel | cross-pane-git-probe filed 141 race-violations on legacy single-pane sessions | flywheel-03aca triage (0 actual race, 146 benign serialized commits) + flywheel-a33xj queued noise-filter helper |

### Shape B — Spec-extractor over-extracts bead-text into fake requirements

**The failure:** spec-extractor emits category-bucket default requirements (`telemetry.primary`, `documentation.primary`, etc.) when the source bead never mentioned the category. Downstream scorer dings the bead for the phantom.

**Author commitment — textual grounding:**

> Every category-bucket requirement the extractor emits MUST cite a contiguous span of source-bead text that grounds the requirement. No span = no emit.

**Anti-pattern (skillos `scripts/extract-spec.py` pre-fix):**

```python
# WRONG — emits category default if any keyword family hits
if any(kw in bead_text.lower() for kw in TELEMETRY_KEYWORDS):
    spec["telemetry.primary"] = "Telemetry envelope shipping"
```

A bead mentioning "track" or "observe" once gets `telemetry.primary` injected even when no telemetry deliverable was promised.

**Canonical pattern:**

```python
# RIGHT — require explicit grounding-span citation
hits = []
for kw in TELEMETRY_KEYWORDS:
    for line_num, line in enumerate(bead_text.split('\n')):
        if kw in line.lower():
            hits.append({"keyword": kw, "line": line_num, "text": line.strip()})
if hits and verify_telemetry_promise(hits):
    spec["telemetry.primary"] = {
        "requirement": "Telemetry envelope shipping",
        "grounding": hits,    # CITATIONS REQUIRED
    }
# If hits is empty OR verify_telemetry_promise returns False → NO EMIT
```

`verify_telemetry_promise` is the LLM-fork or rule-based check that distinguishes "bead mentions telemetry as deliverable" from "bead happens to use telemetry-adjacent vocabulary".

**Canonical instance:** `skillos-t87q.1` closed via criterion v3 (LLM Phase 4 single-fork verdict `PARSER_OVER_EXTRACTION`, ~5 min wall) 2026-05-11T00:00Z.

### Shape C — Substrate exercises itself and surfaces own gaps

**The failure:** an audit gate, run on the substrate that AUTHORED the gate, surfaces gaps in the gate's own classification rule. Not a bug — operators must RESPOND by refining the rule, not suppressing the failure.

**Author commitment — refine, don't suppress:**

> When this audit surface is run against the substrate that owns it, and the audit surfaces a gap in its own classification rules:
> 1. Document the criterion version (v1, v2, v3…)
> 2. Refine the rule to handle the discovered edge case
> 3. Bump the criterion version (v1 → v2 → v3) with the rationale in the criterion doc
> 4. NEVER add a generic tolerance widen or suppress-by-allowlist; the refinement should be principled (covers a NEW pattern, not a SPECIFIC instance)

**Anti-pattern:**

```bash
# WRONG — suppress the specific failure
if [[ "$skill" == "specific-skill-that-failed" ]]; then
    return 0  # whitelist
fi
```

**Canonical pattern:**

```bash
# RIGHT — generalize the rule based on the discovered edge case
# Criterion v1: score == 635 strict
# Criterion v2: score in [620, 660]  # generalized for n/a credit
# Criterion v3: score in [620, 660] AND LLM-fork verifies grounding
```

Each version bump documents the NEW class of substrate the rule now correctly handles.

**Canonical instances:**

| Repo | Exemplar | Mitigation |
|---|---|---|
| skillos | Criterion v1 → v2 → v3 evolution under close-validator pressure | Refinement IS the artifact, not a bug |
| flywheel | `flywheel-8n3ua` doctor-invariant-author-checklist self-verification surfaced 4 agent.sh Rules-2+3 violations | `flywheel-ffyyx` shipped 990/1000; criterion was the checklist's own grep predicate |

### Shape D — Phantom requirement causes phantom implementation

**The failure (2nd-order):** a Shape B parser-over-extraction propagates downstream — an engineer treats the phantom requirement as load-bearing, ships real code, commit lands on main. **Cost is permanent.**

**Author commitment — freeze-downstream-until-criterion-run:**

> Any implementation work attributed to an audit-machinery finding MUST wait for a Shape B criterion run on the source bead before commit.
>
> 1. Audit-machinery output identifies a "missing" deliverable
> 2. Engineer planning to ship work for the missing deliverable
> 3. **BEFORE commit**: run criterion v3 LLM Phase 4 fork on the source bead
> 4. If verdict is `PARSER_OVER_EXTRACTION`: either skip the work OR ship intentionally as "over-and-above" enrichment with explicit attribution that DECOUPLES from the phantom requirement
> 5. NEVER treat audit-machinery output as load-bearing without verification

**Anti-pattern (skillos `7ac8381`, pre-doctrine):**

```
commit 7ac8381
    Author: skillos-2
    Title: ship skillos.replay_verify_telemetry.v1 envelope

    "Closes phantom telemetry.primary requirement from extract-spec.py"
```

Commit lands on main. The telemetry was never a real bead requirement. Cost: permanent code addition + commit-graph permanence + developer-attention spent on phantom work.

**Canonical pattern (post-doctrine):**

```
commit XXX
    Author: skillos-2
    Title: ship skillos.replay_verify_telemetry.v1 (over-and-above enrichment)

    Criterion v3 LLM fork on skillos-t87q verdict: PARSER_OVER_EXTRACTION
    (telemetry.primary was extract-spec.py false-positive, not a real bead
    requirement).

    Shipping this work intentionally as OVER-AND-ABOVE enrichment, NOT
    as completion-debt resolution. The replay-verify envelope is net-positive
    for the substrate even though the originating requirement was phantom.
```

The commit message explicitly DECOUPLES the work from the phantom requirement.

**Canonical instance:** `skillos-2j7.1` commit `7ac8381` — added `scripts/skillos_replay_verify.py` attributed to phantom `telemetry.primary` requirement. Cost permanent but net-positive; named as the canonical Shape D exemplar.

## SAFE-BATCH-CLOSE criterion templates (per shape)

Borrowed from skillos's criterion v1 → v2 → v3 evolution. Use when batch-closing audit-machinery completion-debt beads.

### Criterion v1 (Shape A, strict)

1. Score exactly 635/1000
2. Missing items: `(none — all spec items satisfied)`
3. Implementation-completeness 200/200 (n/a — full credit)
4. Original closure has concrete close-reason + pane2 validation + SAFE_TO_CLOSE

### Criterion v2 (Shape A, generalized)

1. Score ∈ [620, 660]
2. Missing items: `(none — all spec items satisfied)`
3. Implementation-completeness 200/200 or 300/300 (n/a — full credit)
4. Original closure has concrete close-reason + pane2 validation + SAFE_TO_CLOSE

### Criterion v3 (Shape B, LLM-fork-required)

1. Parent scorecard has Implementation full + ≤1 missing item from category-bucket
2. Missing item description is generic category-bucket phrase with EMPTY citations
3. **LLM Phase 4 single-fork verifies bead body has no category-word grounding**
4. Original closure shipped all explicitly-acceptance-criteria deliverables

**Key distinction:** v1/v2 are deterministic batch-close (no LLM call). v3 requires one LLM fork per bead — bounded ~5 min wall, single-bead read-only investigation, 4 possible verdicts: `PARSER_OVER_EXTRACTION | REAL_COMPLETION_DEBT | SHIPPED_EVIDENCE_PRESENT | AMBIGUOUS`.

**Don't conflate.** Shape A audit-noise can batch-close deterministically. Shape B requires LLM-fork — cannot batch-close without verification.

## 4 operator responsibilities (per-audit-pass)

Every audit-machinery operator MUST:

### 1. Triage scorecard BEFORE bead-creation

> Don't auto-file completion-debt beads from raw audit output. Run the 4-condition SAFE-BATCH-CLOSE check first; auto-file only the verified-real-debt subset.

If the audit emits 50 violation rows, the auto-bead-filer should NOT create 50 completion-debt beads. Run criterion v1/v2 on the deterministic-close subset; run criterion v3 LLM-fork on the category-bucket subset; auto-file only the post-triage REAL_COMPLETION_DEBT beads.

### 2. Run criterion v3 LLM forks in BATCHES

> Don't dispatch one LLM fork per bead serially; batch similar-shape candidates per fork to amortize the 5-min wall.

If 8 beads have the same category-bucket phantom-requirement shape (e.g., all 8 dinged for `telemetry.primary`), a single LLM fork can investigate the parser's classification rule once and apply the verdict to all 8 beads. Don't pay the 5-min wall × 8 unless the substrates are genuinely independent.

### 3. FREEZE downstream implementation pending criterion run

> Any planned implementation work attributed to an audit-machinery finding MUST wait for criterion run before commit. Stop the Shape D cascade at the cost-of-real-code stage.

This is the strongest discipline of the four. The cost of Shape D is permanent (commit on main, file added, history written). The cost of pausing 5 min to run a criterion-v3 fork is trivial. Always pay the 5-min cost.

### 4. REFINE, don't suppress

> When a substrate self-test surfaces a design gap (Shape C), respond by refining the rule (criterion v1 → v2 → v3 pattern). Don't suppress the failure, don't waive without rationale, don't widen tolerance generically.

A specific-skill allowlist or a generic tolerance bump is the wrong response. The right response is principled rule-refinement that explains WHY the previous rule version mis-handled this class of substrate.

## Quick verification (run before merging an audit-machinery surface)

```bash
# 1. Shape A — every emit row has a classification_rule_id field
grep -nE '(classification_rule_id|rule_id)' your-audit-machinery.{sh,py}
# Empty result = Shape A risk: classifications are not invertible

# 2. Shape B — every category-bucket emit requires textual grounding
grep -nE '(grounding|citation|source_span)' your-spec-extractor.{sh,py}
# Empty result = Shape B risk: parser may emit category defaults without source text

# 3. Shape C — substrate-self-test pattern is documented
grep -nE '(criterion[_-]v[0-9]|criterion[_-]version)' your-audit-evidence-doc.md
# Empty result = Shape C risk: no version-bump mechanism documented

# 4. Shape D — downstream-implementation commits cite criterion-run verdict
git log --grep='criterion.v3\|PARSER_OVER_EXTRACTION\|over-and-above'
# Required for any commit attributed to an audit-machinery finding
```

## Anti-patterns at a glance

| Shape | Anti-pattern signature | Canonical replacement |
|---|---|---|
| A | scorer emits FAIL with no `classification_rule_id` | every emit row carries the rule ID; rule source documents inversion |
| B | extractor emits `<category>.primary` based on keyword-family hit | extractor requires `grounding: [{line, text}]` citation; LLM-fork verifies for ambiguous keyword families |
| C | suppress specific failure via skill-name allowlist | bump criterion version (v1→v2→v3) covering the discovered edge case as a principled class |
| D | commit shipping work attributed to "missing X" audit finding | commit message includes criterion-v3 verdict + DECOUPLES from phantom requirement OR skips the work entirely |

## Author self-check before merging audit-machinery code

1. Pick a recent FAIL/violation row from real audit output
2. Identify which classification rule fired (Shape A invertibility test)
3. Trace the rule source to its premise
4. Verify the premise on the actual source artifact
5. If you can do all 4 in <60 seconds, Shape A is mitigated
6. Repeat for a category-bucket requirement (Shape B textual-grounding test)
7. Read your evidence doc for criterion-version markers (Shape C refine-not-suppress test)
8. Grep your commit history for criterion-v3 attribution patterns (Shape D phantom-implementation test)

If any step fails, the audit-machinery has a corresponding-shape risk and needs the mitigation pattern applied.

## Cross-references

- **Source doctrine:** `.flywheel/doctrine/audit-machinery-hygiene-discipline.md` (v0.1 drafted 2026-05-11T00:0XZ by skillos:1; ratification window closes 2026-05-11T06:0XZ under cross-orch-anti-divergence-v1.0.0 P3-trivial)
- **Sister checklist (in-probe fragility):** `.flywheel/doctrine/doctor-invariant-author-checklist.md` (flywheel-8n3ua) — the 3 design rules for doctor-invariant authors. Complementary, not overlapping.
- **Sister doctrines:** `cross-pane-git-discipline.md`, `blocker-discipline.md`, `git-stash-discipline.md`
- **Canonical instance bundles (Shape A):** skillos parser-artifact arc — 10 closures via criterion v1+v2 SAFE-BATCH-CLOSE (`jlt.1`, `psv.2`, `psv.1.9`, `k46.1`, `o9a.1`, `wgh.1`, `yi6.1`, `23fj.1`, `31l.1.1`, `hhx2.1`); flywheel `flywheel-03aca` cross-pane-git-probe triage (141 reports, 0 actual race)
- **Canonical instance (Shape B):** `skillos-t87q.1` (criterion v3 LLM Phase 4 single-fork verdict PARSER_OVER_EXTRACTION 2026-05-11T00:00Z)
- **Canonical instances (Shape C):** skillos criterion v1→v2→v3 evolution; flywheel `flywheel-8n3ua` → `flywheel-ffyyx` doctor-invariant self-verification arc
- **Canonical instance (Shape D):** `skillos-2j7.1` commit `7ac8381` — phantom `telemetry.primary` requirement → real `replay_verify_telemetry.v1` envelope shipped (cost permanent; benign-net-positive but the LESSON is don't replicate)
- **Skill discoveries enrolled:**
  - `sd-checklist-self-verification-surfaces-real-audit-gaps-by-design` (8n3ua → ffyyx)
  - `sd-checklist-rule3-grep-widen-to-error_code-variable-form-v1.1-refinement` (ffyyx; widened in 0qkjj to v1.2)
  - `sd-criterion-version-bump-via-close-validator-pressure-pattern` (skillos parser-artifact arc v1→v2→v3)
  - `sd-shape-aware-criterion-application-pattern-rule-only-applies-when-shape-conditions-met` (skillos 2026-05-11T00:15Z Shape C self-iteration)
  - `sd-schema-divergent-invariants-as-sub-audit-finding-class` (flywheel-jyfjf)

## Trauma-class lineage — 4-instance shape ladder (promoted 2026-05-11T00:0XZ)

| Shape | Earliest exemplar | Latest exemplar | Mitigation pattern |
|---|---|---|---|
| A | skillos `jlt.1` (2026-05-10T~22:00Z) | flywheel `03aca` triage (2026-05-10T23:0XZ) | criterion v1/v2 SAFE-BATCH-CLOSE (deterministic) |
| B | skillos `t87q.1` (2026-05-11T00:00Z) | (same) | criterion v3 LLM Phase 4 single-fork (~5 min wall) |
| C | skillos criterion v1→v2 (2026-05-10T~22:30Z) | flywheel `8n3ua`→`ffyyx`→`0qkjj` grep-widen lineage | refine-don't-suppress (criterion version bump) |
| D | skillos `7ac8381` (2026-05-10T~22:00Z) | (same) | FREEZE-DOWNSTREAM-UNTIL-CRITERION-RUN |

Cluster origination: 2026-05-10T19:55Z (skillos-ubh3 5-way cross-link cycle began). Total origination-to-doctrine-ship: ~4h 10min. Within-cycle exemplars: 11 closures (10 Shape A + 1 Shape B) + 1 Shape C exemplar pair + 1 Shape D exemplar.

## How this checklist relates to the doctor-invariant-author-checklist (sister)

| Concern | doctor-invariant-author-checklist | audit-machinery-hygiene-author-checklist |
|---|---|---|
| Surface class | doctor probe functions that shell out | scorers / extractors / validators / lint gates with 2nd-order cost |
| Failure axis | in-probe (path, timeout, error code) | out-of-probe (classification output, downstream cost) |
| Rule count | 3 (+ provisional 4th) | 4 shapes (A/B/C/D) |
| Self-verification | grep predicate against source code | run audit + inspect output for each shape |
| Failure cost | wrong status row (substrate looks unhealthy) | phantom-debt beads + phantom implementations (real code shipped) |
| Mitigation primitive | strict shell + rc=124 split | criterion versioning + LLM-fork + freeze-downstream |
| Canonical instance | `flywheel-3ycjw` identity probe | skillos parser-artifact arc (10 closures) |
| Audit pass bead | `flywheel-jyfjf` | (sister to this checklist; separate wire-in) |

The two checklists cover orthogonal failure axes for the same broad "audit surface" category. A probe can be fully Rules-1-3 compliant AND still trip Shapes A/B/C/D — the rule applies to in-probe code; the shape applies to classification output.
