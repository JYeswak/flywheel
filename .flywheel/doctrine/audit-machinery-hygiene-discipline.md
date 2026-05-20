---
name: audit-machinery-hygiene-discipline
type: doctrine
created: 2026-05-11
version: v0.1.9
status: ratified-bilateral-flywheel-skillos-2026-05-11T05:09Z (v0.1.9 enrollment manifest locked: sd-synthesis-supersede-correct-scope refinement + sd-substrate-exercises-itself-and-surfaces-own-gaps Shape C + tri-mirror meta-pattern; ADDITIVE to v0.1.8)
authority: skillos-1-derived-from-11-parser-artifact-closures-2026-05-10T19:55Z-to-23:30Z + flywheel-1-shape-D-promotion-argument-2026-05-11T00:03Z + flywheel-1-sd-synthesis-supersede-enrollment-proposal-2026-05-11T04:35Z + skillos-1-endorsement-2026-05-11T04:38Z + skillos-1-d19c747-retraction-2026-05-11T04:58Z + skillos-1-two-cycle-routing-decision-2026-05-11T05:04Z + skillos-1-Shape-C-endorsement-2026-05-11T05:07Z + bilateral-v0.1.9-enrollment-manifest-lock-2026-05-11T05:09Z
ratification_target: bilateral (flywheel:1 + skillos:1 co-ratified v0.1.8 2026-05-11T04:35Z–04:38Z and v0.1.9 manifest 05:09Z; v0.1.8 mirror authored by flywheel-uo931 / v0.1.9 ADDITIVE refinement authored by flywheel-o9wx0)
cluster: audit-machinery-hygiene-doctrine-cluster
sisters:
  - doctor-invariant-design-discipline.md (sister cluster — doctor-substrate-robustness)
  - cross-pane-git-discipline.md (sister cluster — substrate-hygiene)
trauma_class_promotion: 4-instance-shape-threshold-MET (single 4-hour cycle 2026-05-10T19:55Z → 2026-05-11T00:00Z surfaced all 4 shapes); Shape A re-confirmed 2026-05-11T04:25Z via 11-instance synthesis-supersede-timestamp-only batch (single skillos synthesis cycle); Shape C added 2026-05-11T05:09Z (substrate-exercises-itself-and-surfaces-own-gaps; the v0.1.8 → v0.1.9 chain is ITSELF the canonical Shape C exemplar — the doctrine eating its own dogfood at commit time)
default_accept_window: 6h from skillos-1 ratification packet send (per cross-orch-anti-divergence-v1.0.0 P3-trivial protocol); v0.1.8 mirror window 2026-05-11T10:35Z; v0.1.9 mirror window 2026-05-11T11:09Z (6h from manifest lock at 05:09Z)
---

# Audit Machinery Hygiene Discipline (Fleet-Wide)

## Paradigm — audit machinery is itself substrate that needs hygiene

When a project has substantial audit/probe infrastructure (compliance scorers, spec extractors, doctor invariants, close validators, lint gates), that machinery becomes a substrate-class concern in its own right. Audit-machinery artifacts (scorecards, spec.json files, completion-debt beads, validator verdicts) can be wrong in characteristic ways that pollute downstream decision-making.

The Meadows-lens leverage point: **#5 rules of the system, scope of authority** (the audit-machinery's rules-of-classification can mis-classify), and **#6 information flow** (mis-classifications propagate downstream into bead-creation, sprint-planning, even real substrate motion).

The four shapes catalogued here are all variations on a single root paradigm: **AUDIT-MACHINERY ARTIFACTS NEED LIVE-CONCURRENCY/REAL-STATE PROBE BEFORE PROMOTION TO BLOCKER-CLASS**. Acting on raw audit output without verification is what causes the cost.

## Mandate

Every audit/probe surface in flywheel-installed substrate MUST satisfy:
1. Each classification rule is **invertible** — given a result, you can explain which rule fired and verify on real state.
2. Synthetic/default category-buckets in spec-extractors require **textual grounding** in the source artifact (not just category presence).
3. Audit-machinery surfaces with **2nd-order downstream cost** (e.g., spawn completion-debt beads, gate ship/merge, trigger implementation work) require **human or LLM-fork sign-off** before the downstream action fires.
4. Substrate self-tests must surface their own design gaps under closure pressure — and operators must respond by REFINING the rule (criterion v1→v2→v3), not by SUPPRESSING the failure.

## Trauma class — 5-instance-shape ladder (promoted 2026-05-11T00:0XZ; Shape E added 2026-05-11T00:35Z)

Per cross-orch consistency rule (4-instance-shape threshold from cross-pane-git-discipline.md ladder logic), this cluster crosses the threshold:

### Shape A — Probe wrongly fires on benign substrate state

The audit/probe surface emits FAIL/violation rows when the substrate is structurally fine. Root cause is in the probe's classification rule, not in the substrate it's auditing.

**Exemplars (across fleet):**

| Repo | Exemplar | Closure / Disposition |
|------|----------|----------------------|
| skillos | Phase 4 stub-mode scorer zeroed Required-tests dimension when n/a (10 completion-debt beads filed phantom) | `jlt.1` + `psv.2` + `psv.1.9` + `k46.1` + `o9a.1` + `wgh.1` + `yi6.1` + `23fj.1` + `31l.1.1` + `hhx2.1` closed via criterion v1/v2 SAFE-BATCH-CLOSE 2026-05-10T20-23Z |
| flywheel | cross-pane-git-probe filed 141 race-violation reports on legacy single-pane sessions | `flywheel-iro0k` (filing) → `flywheel-03aca` triage (score 970/1000, 0 actual race, 146 benign serialized commits) + `flywheel-a33xj` queued canonical noise-filter helper |

**Mitigation (canonical):** criterion v1 ("score=635 strict" + "no missing items" + "Implementation full") → criterion v2 ("score ∈ [620, 660]" generalization). Batch-close deterministic; no LLM call required.

**Canonical reference instance (Shape A discipline):** `.flywheel/scripts/canonical-cli-lint.sh` (flywheel-side) carries the L1-L9 `classification_rule_id` pattern that is the canonical reference for Shape A classification discipline. Sister surfaces in any flywheel-installed substrate that emit FAIL/violation rows MUST carry an equivalent `classification_rule_id` field for traceability (so probe-over-flag claims can be classified against the named rule rather than inferred). Wire-in scope flagged via `flywheel-5svdg` 2026-05-11T00:36Z for `validate-callback.py` + `quality-bar-close-gate.sh`.

### Shape B — Spec-extractor over-extracts bead-text phrases into fake requirements

The audit-machinery's spec-extractor emits category-bucket default requirements (`telemetry.primary`, `documentation.primary`, etc.) without verifying the source bead actually requires the deliverable. Downstream scorers then ding the bead for "missing" the phantom requirement.

**Exemplar (LLM-verified):**

| Repo | Exemplar | Closure / Disposition |
|------|----------|----------------------|
| skillos | `scripts/extract-spec.py` emitted `telemetry.primary` on `skillos-t87q` (replay-verify bead) despite bead text never containing "telemetry" | `skillos-t87q.1` closed via criterion v3 (LLM Phase 4 single-fork verdict PARSER_OVER_EXTRACTION, ~5 min wall) 2026-05-11T00:00Z |

**Mitigation (canonical):** criterion v3 — LLM Phase 4 single-fork required for each candidate. Cannot batch-close deterministically. Each fork: bounded ~5 min wall, single-bead read-only investigation, 4 possible verdicts (PARSER_OVER_EXTRACTION | REAL_COMPLETION_DEBT | SHIPPED_EVIDENCE_PRESENT | AMBIGUOUS).

### Shape C — Substrate-exercises-itself-and-surfaces-own-gaps

A substrate gate, run on the substrate itself, surfaces gaps in the substrate's own design rules (not in target code). The gap-surfacing is FEATURE, not bug — but operators must respond by REFINING the rule, not SUPPRESSING the failure.

**Exemplars:**

| Repo | Exemplar | Closure / Disposition |
|------|----------|----------------------|
| skillos | Criterion v1 (strict 635) → v2 ([620,660] generalized) → v3 (LLM-fork-required) evolution under close-validator pressure | criteria documented in batch evidence files; refinement IS the artifact, not a bug |
| flywheel | `flywheel-8n3ua` doctor-invariant-author-checklist self-verification surfaced 4 agent.sh sister-invariants Rules-2+3 violations | `flywheel-ffyyx` (P2 fix) shipped 990/1000; 5/5 invariants now compliant; sd-checklist-rule3-grep-widen-to-error_code-variable-form-v1.1-refinement skill discovery |

**Mitigation (canonical):** RESPOND by refining the rule (criterion v1→v2→v3 evolution; grep widening v1.0→v1.1). Do NOT suppress the failure or weaken the gate.

### Shape D — Phantom-requirement-causes-phantom-implementation

The 2nd-order failure mode where a Shape B parser-over-extraction propagates into REAL substrate motion: an engineer treats the phantom requirement as load-bearing, ships real code, commit lands on main. Cost is permanent (code shipped, file added, history written). Distinct from Shape B because:
- Downstream of Shape B, not local to it
- Involves real substrate motion (cost > validator-noise cost)
- Identifies WHERE the BUSINESS COST is (developer-attention + commit-graph permanence)
- Mitigation differs: Shape B mitigates by criterion-v3-LLM-fork; Shape D mitigates by **FREEZE-DOWNSTREAM-IMPLEMENTATION-UNTIL-CRITERION-RUN**

**Exemplar:**

| Repo | Exemplar | Closure / Disposition |
|------|----------|----------------------|
| skillos | `skillos-2j7.1` commit `7ac8381` added `scripts/skillos_replay_verify.py` with `skillos.replay_verify_telemetry.v1` envelope — explicitly attributed to the phantom `telemetry.primary` requirement | Commit landed on main 2026-05-10; cost permanent but enrichment is benign-net-positive (the work is real even if the requirement wasn't); a CASS skill-discovery candidate: "evidence-driven-shipping-can-treat-phantom-requirements-as-real-if-the-work-is-still-net-positive" |

**Mitigation (canonical):** Before shipping ANY implementation work attributed to a completion-debt finding, run criterion v3 LLM Phase 4 fork on the source bead. If verdict is PARSER_OVER_EXTRACTION, either (a) close the debt bead and skip the work entirely, OR (b) ship the work intentionally as "over-and-above" enrichment with explicit attribution that DECOUPLES the work from the phantom requirement. Never treat the audit-machinery output as load-bearing without verification.

### Shape E — Non-filesystem-token-as-path-hint (spec-extractor TOKEN-AS-PATH mis-extraction)

The audit-machinery's spec-extractor pulls a non-filesystem token (bead-ID, JSON-path accessor, `~/.local/state/` data-file name, refactored-away symbol) as `code.primary`. Phase 4 stub-mode FIND-heuristic then searches for that literal as a filesystem path and misses the actual shipped substrate. Verdict shape: `SHIPPED_BUT_STUB_BLIND`. Distinct from Shape B (which over-extracts a category-bucket label like `telemetry.primary`) because Shape E mis-extracts a TOKEN-AS-PATH from textually-grounded bead content — the token is real but it's not a path.

**Exemplars (LLM-verified, single batch-fork agent_id `aced30fd6ef0e0788` 2026-05-11T00:35Z):**

| Repo | Exemplar | Token mis-extracted | Real substrate (shipped) | Closure |
|------|----------|---------------------|--------------------------|---------|
| skillos | `skillos-3kz.1` Beads serialization | sibling bead-ID `skillos-psv.1.2` | `.flywheel/rules/L048-L94-shared-sqlite-writes-must-serialize.md` + `L088-L137-beads-mutations-use-a-serial-write-lane.md` + `scripts/skillos_jsm_sync_serialize_wrapper.sh` | closed 2026-05-11T00:36Z |
| skillos | `skillos-g1j.1` JSONL integrity | JSON path accessor `.summary.invalid_rows` | `scripts/skillos_bridge_pkg/cmd_scan.py:103,117` + `cmd_doctor.py:12,17,67` | closed 2026-05-11T00:36Z |
| skillos | `skillos-q10.1` bridge classifier | data-file name `skillos-routed.jsonl` (lives in `~/.local/state/`) | `scripts/skillos_bridge_pkg/_shared.py:115-118` (post-refactor commits 2a28fce + 6ec7692) | closed 2026-05-11T00:36Z |

**Mitigation (canonical):** criterion v3-extended LLM Phase 4 single/batch-fork required. Verdict format `SHIPPED_BUT_STUB_BLIND` is canonical for Shape E. Cite file:line evidence in close reason. Same LLM-fork requirement as Shape B; the distinguishing signal is fork verdict (`PARSER_OVER_EXTRACTION` for Shape B vs `SHIPPED_BUT_STUB_BLIND` for Shape E).

**Severe-band ratio observation (batch of 5 score=385 candidates):** 3 Shape E (60%) + 1 REAL_COMPLETION_DEBT (20%) + 1 AMBIGUOUS (20%). If this ratio holds across more severe-band candidates, spec-extractor's `expected_path_hints` extraction logic needs amendment — sister to the audit-substrate-hygiene amendment proposal queued for `scripts/extract-spec.py`.

## 4-condition SAFE-BATCH-CLOSE criterion (canonical, across all shapes)

Borrowed from skillos's criterion v1→v2 evolution. For Shapes A + B (where deterministic close OR LLM-fork close is possible):

**Criterion v1 (Shape A, strict):**
1. Score exactly 635/1000
2. Missing items: `(none — all spec items satisfied)`
3. Implementation-completeness 200/200 (n/a — full credit)
4. Original has concrete close-reason + pane2 validation + SAFE_TO_CLOSE

**Criterion v2 (Shape A, generalized):**
1. Score ∈ [620, 660]
2. Missing items: `(none — all spec items satisfied)`
3. Implementation-completeness 200/200 or 300/300 (n/a — full credit)
4. Original has concrete close-reason + pane2 validation + SAFE_TO_CLOSE

**Criterion v3 (Shape B, LLM-fork-required):**
1. Parent scorecard has Implementation full + ≤1 missing item from category-bucket
2. Missing item description is generic category-bucket phrase with EMPTY citations
3. LLM Phase 4 single-fork verifies bead body has no category-word grounding
4. Original closure shipped all explicitly-acceptance-criteria deliverables

**Criterion v3-extended (Shape E, LLM-fork-required):**
1. Parent scorecard has Implementation full + missing items reference a TOKEN that is NOT a filesystem path (bead-ID, JSON accessor, `~/.local/state/` data-file name, or symbol that was refactored away)
2. Phase 4 stub-mode FIND-heuristic returns "no file matched" for the literal token
3. LLM Phase 4 single/batch-fork verdict is `SHIPPED_BUT_STUB_BLIND` with concrete file:line substrate citations
4. Original closure shipped real substrate at the verified locations (executable proofs: `ls -la`, `grep -n`)

**Criterion v3-waived (substrate-verified-live, LLM-fork-redundant):**
1. Substrate IS the active-enforcement-surface of the auditor's own tick (receipt-recorded field, contract-test-asserted invariant, or runner-prompt section directly enforced) OR substrate lives outside audited repo at canonical-handle-accessible location (e.g., `~/.claude/skills/<id>/SKILL.md`, `~/.local/bin/<canonical-tool>`)
2. Direct verification path: `ls -la` + `grep -n` substrate citation + contract-test file:line citation
3. Substrate verification is bilaterally observable: the auditor running this tick can confirm substrate presence via the same enforcement surface that gates their own tick
4. 3-exemplar threshold for adoption: 2c8.1 (source-refresh-single-writer) + 2kj.1 (heredoc-literal-preservation) + 2w2.1 (supabase-api skill outside repo) confirmed pattern stability before doctrine codification

## Pre-migration gate (Rust P3) — extension

Audit-machinery-hygiene clean state required for Rust P3 pre-migration gate (additional to the criteria already documented in `cross-pane-git-discipline.md`):

- Zero Shape A parser-artifact false-positives outstanding in br ready (≥620 score + no missing items + Implementation full)
- Zero Shape B fake-category-requirement false-positives outstanding (would require LLM Phase 4 sweep across remaining completion-debt beads)
- All known Shape C refinement opportunities have been EXERCISED at least once (criterion-version-bump pattern proven)
- Zero outstanding Shape D phantom-implementation candidates without explicit "over-and-above" attribution in commit message
- Zero Shape E `SHIPPED_BUT_STUB_BLIND` candidates outstanding in severe-band br ready (score ≤ 400 + missing items naming a non-filesystem token + LLM Phase 4 verdict pending)

Authority: skillos-1 draft 2026-05-11T00:0XZ + flywheel:1 ratification (pending).

## Operator responsibilities (per-audit-pass — 5)

The audit operator MUST:

1. **Triage scorecard before bead-creation.** Don't auto-file completion-debt beads from raw scores. Run the 4-condition SAFE-BATCH-CLOSE check first; auto-file only the verified-real-debt subset.

2. **Run criterion v3 LLM forks in batches.** Don't dispatch one LLM fork per bead serially; batch similar-shape candidates (category-bucket fake requirements) per fork to amortize the 5-min wall.

3. **Freeze downstream implementation pending criterion run.** Any planned implementation work attributed to an audit-machinery finding MUST wait for criterion run before commit. Stop the Shape D cascade at the cost-of-real-code stage.

4. **Refine, don't suppress.** When a substrate self-test surfaces a design gap (Shape C), respond by refining the rule (criterion v1→v2→v3 pattern). Don't suppress the failure, don't waive without rationale, don't widen tolerance generically.

5. **Synthesis-supersede surfaces require citation verification, not timestamp comparison.** When a synthesis layer marks a finding as `superseded` (because a later artifact appears to address it), the predicate MUST be the LATER ARTIFACT CITES THE EARLIER FINDING — not "the later artifact is newer." Timestamp-only supersede is a Shape A parser-artifact false-up: it lets stale findings flip to `superseded=true` without any actual remediation, and the cadence p50 metric reads OK while the underlying queue is silently growing. **Applies fleet-wide:** mission_claim_unwired AND blocker resolution AND doctor subsystem transitions AND bead state updates. **Verification predicate (canonical, byte-identical with skillos commits 974fb36 + 7f938ba):** the superseding artifact MUST contain a textual reference to the earlier finding's gap_hash / id / canonical handle. If no citation, the finding stays `draft` regardless of timestamp ordering. **Sub-rule 5a — citation must be on the CONSUMER side, not the AUDITOR side.** A receipt that cites the auditor's own wiring (e.g., `scripts/trust_gate_check.sh` in the audit pod) is a false-up wearing a verification disguise: the predicate's *purpose* is to verify the consumer remediated, so citing the auditor satisfies the textual-presence check while violating the consumer-remediation intent. Consumer-side wiring requires probing the consumer pod (e.g., `SKILLOS_TARGET_REPO_ROOT=/path/to/consumer bin/skillos doctor`); the auditor's doctor invariant MUST be env-var-aware so it can switch repo context. Reference: skillos commit d19c747 (2026-05-11T04:58Z) retracted the first claimed baseline (49.76h, since the verified receipt cited auditor-side wiring not consumer-side) and re-shipped the doctor invariant as env-var-aware. Honest current state: `cadence rows_with_pairs=0, rows_orphaned=11, status=INFO`. The genuine first measured `finding_to_pack_update_cadence_p50` lands when consumer pods commit consumer-side wiring; that — not the retracted auditor-side baseline — is the GOAL rev-5 `undefined → measured` transition.

   **Note (v0.1.8 framing PRESERVED for documentary evidence — see v0.1.9 sd-synthesis-supersede-correct-scope below for refined predicate v2):** A scope-clause refinement to this responsibility ("verification AT THE CORRECT SCOPE, not any-scope citation") shipped in v0.1.9 (this revision) as an ADDITIVE skill discovery, NOT as a rewrite of this responsibility. The two-revision pattern is intentional and load-bearing: collapsing both refinements into a single rev would HIDE the second-order miss (the predicate v1 was necessary-but-insufficient; predicate v2 catches the auditor-side-citation false-up the v1 predicate missed). The v0.1.8 → v0.1.9 chain is itself the canonical Shape C exemplar (substrate-exercises-itself-and-surfaces-own-gaps): the doctrine eating its own dogfood at commit time.

## Skill discoveries enrolled

- `sd-checklist-self-verification-surfaces-real-audit-gaps-by-design` (flywheel-8n3ua → ffyyx)
- `sd-checklist-rule3-grep-widen-to-error_code-variable-form-v1.1-refinement` (flywheel-ffyyx)
- `sd-criterion-version-bump-via-close-validator-pressure-pattern` (skillos parser-artifact arc v1→v2→v3)
- `sd-shape-aware-criterion-application-pattern-rule-only-applies-when-shape-conditions-met` (skillos 2026-05-11T00:15Z Shape C self-iteration: Rule 3 only applies when probe USES timeout pattern; inline-Python probes + no-timeout shell probes are N/A not PARTIAL)
- `sd-schema-divergent-invariants-as-sub-audit-finding-class` (flywheel-jyfjf 2026-05-11T00:18Z full-substrate audit: invariants emitting `errors` as STRING vs ARRAY-OF-OBJECT slip past Rule-3 grep entirely; needs v1.2 grep extension after ffyyx's v1.1 widen-error_code-variable-form; same Shape C class as skillos's shape-aware refinement but on a different axis — schema-shape rather than rule-applicability-shape)
- `sd-checklist-v1.1-grep-widen-to-4-emission-shapes-3rd-confirmation` (flywheel-0qkjj 2026-05-11T00:32Z post-fix verification: v1.1 grep-widen-error_code-variable-form pattern confirmed across 3 exemplars (ffyyx + jyfjf + 0qkjj); operationally robust across 3 distinct emission shapes in a single arc; ratifies the v1.1 refinement is the right baseline for fleet-wide checklist application)
- `sd-non-filesystem-token-as-path-hint-mis-extraction-shape` (skillos batch-4 fork 2026-05-11T00:35Z 3 Shape E exemplars: bead-ID + JSON-path-accessor + data-file-name all extracted as `code.primary` path hints; 60% severe-band ratio suggests spec-extractor `expected_path_hints` logic needs `requires_textual_filesystem_grounding=true` constraint)
- `sd-llm-batch-fork-cost-efficiency-3-verdicts-per-2min-wall` (skillos batch-4 2026-05-11T00:35Z: 5 severe-band candidates verified in ~2min 10sec wall single batch fork vs 5×5min serial single-forks = 5× cost reduction with PER_BEAD_VERDICT_REQUIRED prompt pattern)
- `sd-canonical-cli-lint-L1-L9-pattern-as-Shape-A-canonical-reference-instance` (flywheel-3nsp1 2026-05-11T00:36Z full-substrate audit: `.flywheel/scripts/canonical-cli-lint.sh` carries the L1-L9 classification-rule-id pattern that is the canonical reference for Shape A discipline; sister surfaces missing the `classification_rule_id` field — `validate-callback.py` + `quality-bar-close-gate.sh` — were flagged for wire-in via `flywheel-5svdg`. Reference-instance pattern: when a substrate is exemplary at a particular shape's classification discipline, it serves as the canonical reference for other audit-machinery surfaces in the cluster.)
- `sd-4-stage-wire-in-pattern-as-meta-pattern-across-clusters` (flywheel 2026-05-11T00:36Z: doctor-invariant cluster (8n3ua-checklist → ffyyx-sister-fix → jyfjf-audit → 0qkjj-fix-bundle) and audit-machinery-hygiene cluster (c5ovc-checklist → 3nsp1-audit → 5svdg-fix-bundle, in flight) share the same 4-stage wire-in chain, same compliance score range ~985-990, and same skill-discovery surfacing rate per stage. The wire-in chain pattern is itself becoming a fleet-wide meta-pattern for cluster propagation.)
- `sd-audit-pilot-continuation-split-pattern-when-fix-exceeds-tick-budget` (flywheel-5svdg 2026-05-11T00:54Z PARTIAL close 4/5: when wire-in scope exceeds single-tick budget, split into pilot-implementation (one surface DONE + methodology proven) + continuation-bead (sister surfaces apply same methodology). Preserves single-tick discipline AND maintains forward motion. Pilot: `validate-callback.py` DONE with FAILURE_CODE_REGISTRY 21 entries + --why-code CLI 3 modes live-verified. Continuation: `flywheel-bg06b` filed with ~2-3hr estimated effort for `quality-bar-close-gate.sh`. Pattern shape: original bead closes PARTIAL with did=N/M + pilot-substrate DONE + methodology proven + continuation bead filed with explicit estimated effort + next-phase recommendation in callback.)
- `sd-3-class-classification-extension-of-binary-filter-when-spec-undercaptures-live-patterns` (flywheel-a33xj 2026-05-11T01:08Z close 990/1000: when an audit's spec captures binary (violation vs not) and live data shows the binary is too coarse — conflates multiple shapes within "violation" — extend to N-class classification. Same paradigm as criterion v1 (strict) → v2 (generalized) → v3 (LLM-fork) evolution: the audit refines from coarse to fine as live data accumulates. a33xj exemplar: cross-pane-git-probe 181 "violations" split into 3 classes (benign_serialized_pair=60 + same_author_serialized=121 + candidate_race=0), verdict flipped warn→PASS on healthy fleet, backwards-compatible field preservation. Meta-doctrine: probe spec evolution mirrors trauma-class taxonomy evolution.)
- `sd-criterion-v3-LLM-fork-waivable-when-substrate-is-active-enforcement-surface-or-canonical-handle-accessible` (skillos 2026-05-11T~03:15Z 3-exemplar accumulation: 2c8.1 + 2kj.1 + 2w2.1. When the substrate IS the active-enforcement-surface of the auditor's own tick (e.g., source_refresh_single_writer_mode field actively enforced in this-tick's receipt) OR substrate lives outside the audited repo at a canonical-handle-accessible location (e.g., ~/.claude/skills/<id>/SKILL.md), LLM Phase 4 fork is REDUNDANT and may be waived. Verification path becomes: direct `ls -la` + `grep -n` + contract-test citation. Note Shape A sub-case discovered through 2w2.1: audit-probe HOME-context-dependent path-resolution failure for substrate outside repo — audit machinery hardening candidate: probe should explicitly HOME-context-probe absolute paths outside repo-root, not rely on os.path.exists from audit CWD. Bilaterally applicable: any orchestrator running an audit can apply this waiver when the substrate is operationally observable in the audit's own enforcement surface.)
- `sd-synthesis-supersede-correct-scope` (Shape A — REFINES sd-synthesis-supersede-timestamp-only-false-up below; bilateral v0.1.9 enrollment 2026-05-11T05:09Z; **PRESERVED v0.1.8 sd retained verbatim as documentary evidence of the second-order miss**). **Refined framing (predicate v2):** "synthesis-supersede surfaces require citation verification AT THE CORRECT SCOPE, not any-scope citation." **Asymmetry (load-bearing):** *predicate easy, scope-correct-verification hard* — writing a predicate that requires *some* verification is straightforward; writing one that pins down *the correct scope* requires understanding what the predicate is *for* (consumer remediation, not audit-machinery presence). **2-instance trauma ladder (META-EXTRACTION-DRIFT class — Joshua-ratified 2026-05-10):** Instance 1 (2026-05-09 11x findings) — timestamp-only supersede masked gap; predicate v1 (require textual citation, skillos commit 974fb36) catches it. Instance 2 (2026-05-11 skillos B4 receipt) — correct-shape-but-wrong-scope verification masked gap (citation present but pointed at auditor-side `scripts/trust_gate_check.sh` instead of consumer-side wiring); predicate v2 (require citation AT CONSUMER SCOPE, skillos commit d19c747 + Sub-rule 5a) catches it. Same canonical pattern; refined understanding via second-order miss. **The naive predicate (verification-required) is necessary-but-insufficient. The scope-aware predicate (verification-at-correct-scope) is the actually-correct form.** Future v3+ refinements expected as new mask shapes surface; the META-EXTRACTION-DRIFT class predicts that each method-iteration will surface a NEW leak shape the prior iteration didn't catch. Cross-reference: tri-mirror meta-pattern below.
- `sd-substrate-exercises-itself-and-surfaces-own-gaps` (Shape C — bilateral v0.1.9 enrollment 2026-05-11T05:09Z; **canonical Shape C exemplar = the v0.1.8 → v0.1.9 chain itself**). **Verbatim:** *"if the doctrine couldn't surface its own miss it couldn't surface anyone else's."* The doctrine eating its own dogfood IS the validation pattern: recursive predicate-validation where the audit-machinery-hygiene cluster is self-bootstrapping. Maps cleanly onto existing cluster shapes — Shape A (probe-wrongly-fires-on-benign) + Shape B (spec-extractor-over-extracts) + Shape D (phantom-requirement-causes-phantom-implementation) + Shape E (criterion-v3-waived) + new Shape C (substrate-exercises-itself-and-surfaces-own-gaps). **Worker-tier exemplar:** CloudyMill 11-streak chain (2026-05-11) produced 4 organic SD enrollments: function-hoist-when-positional-intercept-precedes-definitions, two-doctor-surfaces-coexistence-pattern, jq-pipefail-capture-pattern, dual-mode-positional-intercept-pattern. The chain itself is the doctrine being exercised; the discoveries are the exercise surfacing prior unknown-unknowns. **Doctrine-tier exemplar:** v0.1 → v0.1.8 → v0.1.9 chain — the v0.1.8 cycle surfaced the second-order scope-collapse miss that v0.1.9 enrolls as canonical refinement. If v0.1.8 had collapsed both refinements into one rev, the second-order miss would never have surfaced as documentary evidence. **Operational signal:** any audit-machinery cluster that ratifies a refinement on cycle N+1 of the same canonical pattern is a Shape C event; preserve cycle N as documentary evidence rather than rewriting it forward.
- `meta-pattern: tri-mirror cross-reference (audit-method-evolution ↔ trauma-class-taxonomy-evolution ↔ predicate-spec-evolution)` (META-doctrine — bilateral v0.1.9 enrollment 2026-05-11T05:09Z). **The three evolutions are co-iterative:** each iteration of audit-method (e.g., criterion v1→v2→v3 LLM-fork → v3-waived for self-enforcement substrates) surfaces a new instance-shape (e.g., Shape A → B → C → D → E) which in turn requires a refinement of the predicate-spec (e.g., predicate v1 → v2 scope-aware). The three are not three separate evolutions but three perspectives on the same single underlying drift: the audit-machinery-hygiene cluster's understanding of itself. **Connection to META-EXTRACTION-DRIFT trauma class (Joshua-ratified 2026-05-10):** each method-iteration surfaces a NEW leak shape the prior iteration didn't catch. The tri-mirror meta-pattern is the canonical name for this co-iteration. **Predictive use:** when any one of the three evolves (e.g., a new predicate-spec refinement is proposed), expect a sister evolution in the other two (a new instance-shape will be enumerable; a new audit-method gap will be surfaced). The tri-mirror is operational guidance, not just retrospective taxonomy.
- `sd-synthesis-supersede-timestamp-only-false-up` (Shape A — bilateral 2026-05-11T04:25Z–04:58Z; flywheel:1 enrollment proposal + skillos:1 endorsement + skillos commits 974fb36 + 62823a4 + 7f938ba + d19c747 shipped Phase A predicate + Phase B B4 wiring + target_gap_hashes precision + retraction-of-auditor-side-baseline + doctor-invariant-env-var-awareness. **PRESERVED VERBATIM IN v0.1.9 AS DOCUMENTARY EVIDENCE OF THE SECOND-ORDER MISS — see sd-synthesis-supersede-correct-scope above for the predicate v2 refinement.** **Trigger:** 11 mission_claim_unwired findings stale 96h+ while doctor B1 cadence reported OK (p50=0.9h). **Root cause:** synthesis layer's `superseded` flag was set on TIMESTAMP comparison alone — any later parser-bumped row tripped supersede on every prior row regardless of remediation. **Fix v1 (974fb36 + 62823a4):** supersede predicate now requires the later artifact to cite the earlier finding's `gap_hash` / `id` / canonical handle. **Mid-arc retraction (d19c747):** the first verified receipt CITED AUDITOR-SIDE WIRING (`scripts/trust_gate_check.sh` inside the audit pod) — same trauma class the predicate was designed to detect, just wearing a verification disguise. Skillos retracted the 49.76h baseline (marked applied=false with retraction_reason; cadence ignores retracted rows) and shipped the doctor invariant as env-var-aware (`SKILLOS_TARGET_REPO_ROOT=/path/to/consumer`) so it correctly probes consumer pods. **Honest state post-retraction:** triage drafts=10 + superseded=1 (B4 only, verified) but cadence rows_with_pairs=0, rows_orphaned=11, status=INFO; the genuine first measured `finding_to_pack_update_cadence_p50` lands when consumer pods commit consumer-side wiring (mobile-eats:1 dispatch in flight). **Sub-discovery (Sub-rule 5a):** verification predicates can themselves false-up by checking auditor-side wiring instead of consumer-side; the cure is env-var-aware doctor invariants that probe the consumer pod, not the auditor pod. **Cross-orch reflective discipline MOAT:** caught the false-up before it became canonical truth (skillos:1 self-reported within ~20min of joint acknowledgment; v0.1.8 doctrine corrected before commit). **Cross-orch artifact:** flywheel-uo931 + skillos audit-machinery-hygiene v0.1.8 byte-identical mirror cycle.)

Future discoveries belong here, not in sister doctrines.

## Cross-references

- `.flywheel/doctrine/doctor-invariant-design-discipline.md` — sister cluster (doctor-substrate-robustness): rules IN-PROBE design; this doctrine rules OUT-OF-PROBE classification artifact + downstream cost
- `.flywheel/doctrine/cross-pane-git-discipline.md` — sister cluster (substrate-hygiene)
- `.flywheel/doctrine/blocker-discipline.md` — sister cluster (substrate-hygiene)
- `.flywheel/doctrine/git-stash-discipline.md` — sister cluster (substrate-hygiene)
- `cross-orch-anti-divergence-v1.0.0` (ratified 2026-05-10T16:48Z) — protocols this doctrine is ratified under
- skillos batch evidence files (parser-artifact arc):
  - `/tmp/skillos-jlt.1-closure-evidence-20260510T2310Z.md`
  - `/tmp/skillos-psv-batch-closure-evidence-20260510T2325Z.md`
  - `/tmp/skillos-four-lens-rework-batch-closure-evidence-20260510T2335Z.md`
  - `/tmp/skillos-batch-3-closure-evidence-20260510T2345Z.md`
  - `/tmp/skillos-t87q.1-closure-evidence-20260511T0000Z.md`
  - `state/skillos-batch-4-shape-E-closure-evidence-20260511T0035Z.md` (Shape E exemplar batch: 3kz.1 + g1j.1 + q10.1; persisted to repo per `feedback_stash_discipline_meadows_lens` reference-grade-evidence rule)
- flywheel substrate-self-verification arc: 8n3ua → ffyyx (commits referenced in flywheel:1 packet 2026-05-10T23:52Z + 2026-05-11T00:00Z)

## Implementation status

Doctrine v0.1 drafted skillos-side 2026-05-11T00:0XZ. Ratification packet to flywheel:1 sent same tick. Default-accept window: 6h (until 2026-05-11T06:0XZ) unless amendment.

**v0.1.8 bilateral mirror cycle (2026-05-11T04:25Z–04:58Z):** skillos:1 surfaced 11-instance synthesis-supersede-timestamp-only false-up (Phase 0 surfacing); flywheel:1 ratified at 04:35Z with `sd-synthesis-supersede-timestamp-only-false-up` enrollment proposal (Shape A, fleet-wide operator-responsibility statement); skillos:1 endorsed at 04:38Z (Phase A+B shipped commits 974fb36 + 62823a4 + 7f938ba; provisionally claimed first measured cadence baseline 49.76h). **Mid-arc retraction (skillos commit d19c747, 04:58Z):** the verified phase-B receipt cited auditor-side wiring not consumer-side — same trauma class the predicate was designed to detect, wearing a verification disguise. Skillos retracted the 49.76h baseline (applied=false + retraction_reason; cadence ignores) and shipped the doctor invariant as env-var-aware (`SKILLOS_TARGET_REPO_ROOT=/path/to/consumer`) so it correctly probes consumer pods (verified: against mobile-eats target = WARN 1/3, missing gate-truth-separation + agent-sandboxing). flywheel-uo931 worker tick authored v0.1.8 doctrine update incorporating the retraction (Sub-rule 5a: citation must be on consumer-side, not auditor-side) with byte-identical mirror to skillos-side. AG4 sister-check: shasum -a 256 byte-identical between `flywheel:.flywheel/doctrine/audit-machinery-hygiene-discipline.md` and `skillos:.flywheel/doctrine/audit-machinery-hygiene-discipline.md` (verified in this tick). **Cross-orch reflective discipline MOAT:** caught the auditor-side false-up before it became canonical truth in v0.1.8.

**v0.1.9 ADDITIVE refinement cycle (2026-05-11T05:01Z–05:10Z):** mid-arc within v0.1.8 authoring, skillos:1 proposed scope-clause refinement at 05:01Z (predicate v2: "verification AT THE CORRECT SCOPE, not any-scope citation"). At 05:04Z skillos:1 reversed to a TWO-CYCLE plan — v0.1.8 ships verifiable substrate with original framing + v0.1.9 ships refinement on a follow-up bead so the second-order miss stays visible as documentary evidence (Shape C exemplar of why we're enrolling Shape C). At 05:07Z skillos:1 endorsed Shape C enrollment (`sd-substrate-exercises-itself-and-surfaces-own-gaps`); at 05:09Z bilateral enrollment manifest locked for v0.1.9 (three additive entries: refined sd-synthesis-supersede-correct-scope + Shape C sd-substrate-exercises-itself + tri-mirror meta-pattern). flywheel-o9wx0 worker tick authored v0.1.9 doctrine update as ADDITIVE refinement (preserves all v0.1.8 enrollments verbatim) with byte-identical mirror to skillos-side. Sister-check sha256 captured in `.flywheel/audit/flywheel-o9wx0/v0.1.9-flywheel-sha256.txt` and `.flywheel/audit/flywheel-o9wx0/v0.1.9-skillos-sha256.txt`. **The v0.1.8 → v0.1.9 chain is itself the canonical Shape C exemplar:** the doctrine eating its own dogfood at commit time, where the validation pattern surfaces the prior cycle's second-order miss as the next cycle's enrollment.

Wire-in (separate beads):
- audit-machinery-hygiene-class-author-checklist (sister to doctor-invariant-author-checklist; same surface, different rules)
- existing-audit-machinery-audit-against-4-shape-taxonomy (sister to existing-invariant-audit-against-3-rules)
- synthesis-supersede-citation-predicate (canonical reference: skillos commits 974fb36 Phase-A predicate + 62823a4 Phase-B B4 wiring + 7f938ba target_gap_hashes precision); flywheel currently has NO consuming surface for synthesis receipts — predicate is doctrine-only fold-in until/unless flywheel grows pack-feedback substrate (per cross-orch P3-trivial anti-pattern guard: don't author skillos-specific schema/code into flywheel)

## Cycle stats (this doctrine)

- Cluster origination: 2026-05-10T19:55Z (skillos-ubh3 5-way cross-link cycle began)
- 1st instance-shape (Shape A) observed: 2026-05-10T~22:00Z (criterion v1 emerged from skillos-jlt.1 close)
- 4th instance-shape (Shape D) named: 2026-05-11T00:03Z (flywheel:1 promotion argument)
- Doctrine v0.1 drafted (skillos): 2026-05-11T00:0XZ
- 5th instance-shape (Shape E) confirmed via LLM batch-fork: 2026-05-11T00:35Z (3-exemplar verdict from 5-candidate fork)
- Bilateral substrate-audit-validity confirmed: 2026-05-11T00:36Z (flywheel-3nsp1 990/1000 — Shape A + C structurally present in flywheel; Shape B + D forward-compatible-absent; doctrine codifies fleet-wide patterns whose specific instance-shapes depend on substrate architecture)
- Pilot-continuation-split pattern enrolled: 2026-05-11T00:54Z (flywheel-5svdg PARTIAL 4/5 → flywheel-bg06b continuation; pilot-implementation DONE + methodology proven, continuation-bead filed with explicit estimated effort)
- 3-class-classification-extension pattern enrolled: 2026-05-11T01:08Z (flywheel-a33xj 990/1000; cross-pane-git-probe 181 "violations" split into 3 classes; verdict flipped warn→PASS; meta-doctrine: probe spec evolution mirrors trauma-class taxonomy evolution)
- Both doctrine clusters propagation COMPLETE flywheel-side: 2026-05-11T01:08Z (doctor-invariant 4-stage chain + audit-machinery-hygiene 5-stage chain via pilot-continuation-split)
- v3-waived criterion enrolled: 2026-05-11T~03:15Z (skillos 3-exemplar accumulation 2c8.1 + 2kj.1 + 2w2.1; substrate-verified-live LLM-fork-waiver rule)
- v0.1.8 bilateral mirror cycle (sd-synthesis-supersede-timestamp-only-false-up enrollment): 2026-05-11T04:25Z surfacing (skillos), 04:35Z flywheel ratification + enrollment proposal, 04:38Z skillos endorsement + Phase A+B shipped (commits 974fb36 + 62823a4 + 7f938ba; provisionally claimed cadence baseline 49.76h), 04:58Z mid-arc retraction (skillos commit d19c747; 49.76h baseline RETRACTED — citation was auditor-side not consumer-side, same trauma class the predicate detects; doctor invariant re-shipped as env-var-aware), 04:59Z flywheel-uo931 worker tick authored v0.1.8 doctrine update incorporating Sub-rule 5a (commit 618e9cb at sha f90dea38e...)
- v0.1.9 ADDITIVE refinement cycle (sd-synthesis-supersede-correct-scope + sd-substrate-exercises-itself-and-surfaces-own-gaps + tri-mirror meta-pattern): 2026-05-11T05:01Z scope-clause proposal (skillos), 05:04Z two-cycle routing decision (skillos), 05:07Z Shape C endorsement (skillos), 05:09Z bilateral enrollment manifest lock, 05:10Z flywheel-o9wx0 worker tick authored v0.1.9 ADDITIVE doctrine update preserving v0.1.8 verbatim (this commit)
- Total origination-to-doctrine-ship-with-5-shapes-and-bilateral-validity-and-12-skill-discoveries-and-criterion-v3-waived-and-bilateral-mirror-cycle-with-mid-arc-retraction-and-Shape-C-self-exercise-via-additive-v0.1.9: ~9h 15min
- Within-cycle exemplars: 11 closures (10 Shape A + 1 Shape B) + 1 Shape C exemplar pair + 1 Shape D exemplar + 11-instance Shape A synthesis-supersede batch (skillos triage drafts=10 + superseded=1)


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
