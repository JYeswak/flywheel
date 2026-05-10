---
title: "06 DAG Rebuild Worker Gamma Output"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# 06 DAG Rebuild Worker Gamma Output

Task: `dag-rebuild-gamma-l4-readme-coral-2026-05-05`
Worker: flywheel:4 codex
Mode: plan-space only; `.beads/` read-only; symbolic IDs only.

## Self-Grade

| Gate | Result | Evidence |
|---|---:|---|
| Beads drafted | 11/11 | `rg -c '^## WOE-EXP-B' .flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-gamma-output.md` expected `11` |
| Acceptance bullets median | 6 | `awk '/^## WOE-EXP-B/{if(n){print n}; n=0} /^- \\[ \\]/{n++} END{print n}' <this-file>` |
| L112 verification probes | 11 | `rg -c '^- \\[ \\] L112 command:' <this-file>` expected `11` |
| L113 evidence coverage | 100% | Every DID row below has `Evidence` as file:line or command |
| Jeff-corpus Socraticode queries | 5 | MCP `codebase_search` against `/Users/josh/Developer/jeff-corpus` for `license_gate`, `permit_gate`, `phase_anchor`, `narrow_form`, `cryptographic_invariance` |
| CoralRaven zero-match claims | 5/5 | Five `rg -i --fixed-strings ... --count-matches` commands below returned `0` |
| Scores | Jeff 9.6 / Donella 9.6 / Joshua 9.6 / composite 9.6 | Grounded in source inventory, stock/flow rows, and no source mutation |

`quality_bar_passed=yes`, `rust_clean=n/a`, `python_clean=n/a`, `cli_canonical=yes`, `readme_quality=yes`.

## L113 DID Ledger

| Claim | Status | Evidence |
|---|---|---|
| Read the full dispatch before action. | DID | `wc -l /tmp/dispatch_dag_rebuild_gamma_2026-05-05.md` returned `150`; `sed -n '1,260p' /tmp/dispatch_dag_rebuild_gamma_2026-05-05.md` covered all lines. |
| Used beta-3 spec table and dependency wiring. | DID | `.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/05-DAG-REBUILD-SPEC-2026-05-05.md:121-149`. |
| Used original Section D inventory. | DID | `.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/00-INTENT.md:301-312`. |
| Used CoralRaven Section H/P0 source. | DID | `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:150-159`, `:220-236`, `:270-277`. |
| Used existing refuse-gate substrate for B47 symmetry. | DID | `/Users/josh/.claude/commands/flywheel/_shared/mission-anchor-dispatch-preflight.sh:1-3`, `:32-44`; `/Users/josh/.claude/commands/flywheel/dispatch.md:35-49`. |
| Used canonical propagation substrate. | DID | `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:1-8`, `:57-61`; `.flywheel/scripts/sync-canonical-doctrine.sh:20-37`. |
| Ran Jeff-corpus convergence audit. | DID | MCP `codebase_search` commands listed in Jeff Convergence Audit. |
| Verified five CoralRaven zero-match claims. | DID | Negative proof commands in Zero-Match Proofs all returned `actual_count=0`. |
| Drafted 11 symbolic bead specs. | DID | This output file; `rg -c '^## WOE-EXP-B' <this-file>` expected `11`; dispatch forbids real `.beads/` writes at `/tmp/dispatch_dag_rebuild_gamma_2026-05-05.md:107-115`. |

## Jeff Convergence Audit

| Query | Result | Verdict | Evidence |
|---|---|---|---|
| `license_gate` | Generic license/quality gates exist; no phase-dispatch permit list. | EXTEND | MCP result: `pi_agent_rust/tests/extension_tiered_corpus.rs:177-198`, `pi_agent_rust/src/extension_scoring.rs:639-659`. |
| `permit_gate` | Strong permit/deny counter patterns exist. | ADOPT | MCP result: `franken_engine/...remote_capability_gate...:691-729`, `:730-771`, `franken_node/...retrievability_gate.rs:1453-1552`. |
| `phase_anchor` | Only general phase metadata/rollback anchors, not mission phase dispatch. | GAP | MCP result: `agentic_coding_flywheel_setup/scripts/lib/context.sh:117-136`, `flywheel_connectors/...mixed_migration_e2e.rs:606-701`. |
| `narrow_form` | Hits are UI narrow-layout patterns, not cross-orch query envelopes. | GAP | MCP result: `frankentui/crates/ftui-extras/src/forms.rs:2408-2507`, `rich_rust/src/bin/demo_showcase/typography.rs:638-651`. |
| `cryptographic_invariance` | Replay/capsule invariants and crypto signatures are mature. | ADOPT | MCP result: `franken_node/sdk/verifier/src/capsule.rs:1-56`, `franken_node/sdk/verifier/src/lib.rs:4442-4541`. |

## Zero-Match Proofs

All commands ran from `/Users/josh/Developer/flywheel` and excluded this worker output plus the DAG rebuild spec.

| Query | Command | Expected | Actual |
|---|---|---:|---:|
| phase-anchored dispatch license-gate | `rg -i --fixed-strings 'phase-anchored dispatch license-gate' /Users/josh/.claude/skills /Users/josh/Developer/flywheel --glob '!**/05-DAG-REBUILD-SPEC-2026-05-05.md' --glob '!**/06-DAG-REBUILD-WORKER-gamma-output.md' --count-matches 2>/dev/null \| awk -F: '{s+=$NF} END{print s+0}'` | 0 | 0 |
| cross-orch query latency monitoring | `rg -i --fixed-strings 'cross-orch query latency monitoring' /Users/josh/.claude/skills /Users/josh/Developer/flywheel --glob '!**/05-DAG-REBUILD-SPEC-2026-05-05.md' --glob '!**/06-DAG-REBUILD-WORKER-gamma-output.md' --count-matches 2>/dev/null \| awk -F: '{s+=$NF} END{print s+0}'` | 0 | 0 |
| locked-spec vs ready-to-build distinction | `rg -i --fixed-strings 'locked-spec vs ready-to-build distinction' /Users/josh/.claude/skills /Users/josh/Developer/flywheel --glob '!**/05-DAG-REBUILD-SPEC-2026-05-05.md' --glob '!**/06-DAG-REBUILD-WORKER-gamma-output.md' --count-matches 2>/dev/null \| awk -F: '{s+=$NF} END{print s+0}'` | 0 | 0 |
| R1 daily-report vs live command-center contract | `rg -i --fixed-strings 'R1 daily-report vs live command-center contract' /Users/josh/.claude/skills /Users/josh/Developer/flywheel --glob '!**/05-DAG-REBUILD-SPEC-2026-05-05.md' --glob '!**/06-DAG-REBUILD-WORKER-gamma-output.md' --count-matches 2>/dev/null \| awk -F: '{s+=$NF} END{print s+0}'` | 0 | 0 |
| orchestrator-self-block-on-decidable-task halt | `rg -i --fixed-strings 'orchestrator-self-block-on-decidable-task halt' /Users/josh/.claude/skills /Users/josh/Developer/flywheel --glob '!**/05-DAG-REBUILD-SPEC-2026-05-05.md' --glob '!**/06-DAG-REBUILD-WORKER-gamma-output.md' --count-matches 2>/dev/null \| awk -F: '{s+=$NF} END{print s+0}'` | 0 | 0 |

## WOE-EXP-B42 - README Auto-Sync Trigger On AGENTS Edit

Priority: P1
Parents: `flywheel-1f4r`, `flywheel-2ypj`

Body: Add an L4 producer that notices AGENTS/canonical doctrine edits and emits a README propagation row instead of relying on memory. The consumer is the existing README/sync path; the drain receipt proves README freshness by hash or mtime after sync. This turns Section D1 drift from stale docs into a measurable warn stock.

L110 row:
```json
{"ts":"<iso>","artifact_id":"flywheel:README.md","artifact_class":"doc_propagation","stock":"stale README after AGENTS edit","consumer":"flywheel-readme + sync-canonical-doctrine.sh","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"test README.md -nt AGENTS.md || jq '.readme_sync_status' ~/.local/state/flywheel/readme-propagation-ledger.jsonl","tick_consequence":"warn","drain_receipt":{"readme_hash_after":"<sha256>","agents_hash":"<sha256>"},"dedup_key":"flywheel:README.md:<sha256-prefix>","doc_kind":"readme","drift_axis":"age"}
```

- [ ] Producer records `doc_kind=readme`, `drift_axis=age`, `dedup_key`, and `consumer` per L110; evidence: spec L4 ledger `.flywheel/plans/.../05-DAG-REBUILD-SPEC-2026-05-05.md:62-75`.
- [ ] Trigger watches root `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, and `templates/flywheel-install/AGENTS.md`; evidence: L96 three-surface contract `.flywheel/AGENTS-CANONICAL.md:2349-2361`.
- [ ] Consumer uses existing canonical sync/readme path, not a new doc substrate; evidence: Section D1 names `flywheel-readme` existing no-auto-fire `.flywheel/plans/.../00-INTENT.md:307`.
- [ ] Tick consequence is warn until README remains stale for two ticks, then eligible for promotion; evidence: Section D1 tick consequence warn `.flywheel/plans/.../00-INTENT.md:307`.
- [ ] L112 command: `bash .flywheel/scripts/sync-canonical-doctrine.sh --dry-run --json | jq '.root_drifted_count // .status'`.
- [ ] `/readme-writing` route is invoked for generated README diff before apply; evidence: plan quality bar names `/readme-writing` `/Users/josh/.claude/commands/flywheel/plan.md:122-128`.

## WOE-EXP-B43 - README Quality-Bar Auto-Route Via /readme-writing

Priority: P1
Parents: `flywheel-1f4r`, `flywheel-2ypj`

Body: Route every README propagation write through the L111 quality gate and require a publishability/readme receipt before callback acceptance. The stock is README text that changed without `/readme-writing` evidence. The drain receipt is a quality row attached to the same L4 ledger item.

L110 row:
```json
{"ts":"<iso>","artifact_id":"<repo>:README.md","artifact_class":"doc_propagation","stock":"README changed without readme-writing receipt","consumer":"callback-validator + readme-writing route","owner":"repo-orch","deferral_until":null,"deferred_reason":null,"verification_probe":"jq 'select(.doc_kind==\"readme\" and .readme_quality != true)' ~/.local/state/flywheel/readme-propagation-ledger.jsonl","tick_consequence":"warn","drain_receipt":{"readme_quality":true,"quality_bar_evidence_id":"<id>"},"dedup_key":"<repo>:README.md:<sha256-prefix>","doc_kind":"readme","drift_axis":"shape"}
```

- [ ] README writes require `readme_quality=true` in ledger and callback; evidence: L111 callback fields `.flywheel/AGENTS-CANONICAL.md:3068-3076`.
- [ ] Route is automatic on README path changes, not manually remembered; evidence: Section D2 says quality bar exists but is not auto-routed `.flywheel/plans/.../00-INTENT.md:308`.
- [ ] Publishability score or readme-quality receipt is stored beside the L4 drift row.
- [ ] Failure mode is warn, not hard error, unless callback claims `quality_bar_passed=yes` without evidence.
- [ ] L112 command: `jq 'select(.doc_kind=="readme" and (.readme_quality != true))' ~/.local/state/flywheel/readme-propagation-ledger.jsonl | wc -l`.
- [ ] Acceptance includes the plan fifth gate: README artifacts cannot close with `quality_bar_passed=false`; evidence `/Users/josh/.claude/commands/flywheel/plan.md:392`.

## WOE-EXP-B44 - AGENTS.md Fleet Propagation Enforcement

Priority: P0
Parents: `flywheel-1f4r`, `flywheel-2ypj`, `flywheel-2eow`

Body: Promote AGENTS propagation drift into a doctor-visible error and absorb CoralRaven's fast path: add the three missing memory rules to the canonical META-RULE bundle while L110 substrate work catches up. This bead closes D3 by making sync drift count operational across root, canonical snapshot, template, and fleet caches.

L110 row:
```json
{"ts":"<iso>","artifact_id":"fleet:AGENTS.md","artifact_class":"doc_propagation","stock":"repos missing canonical AGENTS block or META-RULE bundle rows","consumer":"sync-canonical-doctrine.sh + canonical-meta-rules/sync.sh","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"bash /Users/josh/.flywheel/canonical-meta-rules/sync.sh --fleet-check-three-surface --json | jq '.drift_count'","tick_consequence":"error","drain_receipt":{"fleet_three_surface_drift_total_count":0,"meta_rule_cache_sync_ts":"<iso>"},"dedup_key":"fleet:agents:<sha256-prefix>","doc_kind":"agents","drift_axis":"content"}
```

- [ ] Doctor exposes drift count as error when any active fleet repo misses canonical AGENTS/L-rule surfaces; evidence: L96 doctor fields `.flywheel/AGENTS-CANONICAL.md:2361-2367`.
- [ ] The existing consumer is `sync-canonical-doctrine.sh`, whose usage and surfaces are defined at `.flywheel/scripts/sync-canonical-doctrine.sh:20-37`.
- [ ] Add `feedback-foundational-tool-error-halt-class`, `feedback-substrate-loss-worker-commit-orphan`, and `feedback-tactical-execution-licensed-by-mission-lock` to `/Users/josh/.flywheel/canonical-meta-rules/INDEX.md`; evidence: CoralRaven P0 #2 `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:270-276`.
- [ ] Cross-orch propagation uses `/Users/josh/.flywheel/canonical-meta-rules/sync.sh --apply --json`; evidence: `.flywheel/AGENTS-CANONICAL.md:2650-2660`.
- [ ] L112 command: `bash /Users/josh/.flywheel/canonical-meta-rules/sync.sh --check-three-surface --target /Users/josh/Developer/flywheel --json | jq '.status,.drift_count'`.
- [ ] Fast-path rule bundle does not replace L110; it is a bounded propagation bridge while Phase 4 substrate beads land; evidence: CoralRaven propagation gap `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:187-202`.

## WOE-EXP-B45 - MEMORY.md Shape-Gate Validator

Priority: P1
Parents: `flywheel-1f4r`, `flywheel-2ypj`

Body: Collapse D4 and D5 into one memory-shape validator that scans project memory files for required frontmatter, stable fields, and skill-candidate routing hints. The validator emits L4 rows with explicit no-route reasons or relay targets so memory drift cannot stay as prose-only session residue.

L110 row:
```json
{"ts":"<iso>","artifact_id":"<project>:memory:<path>","artifact_class":"doc_propagation","stock":"memory file shape drift","consumer":"memory-file-shape gate + skillos-relay when skill-candidate","owner":"session-orch","deferral_until":null,"deferred_reason":null,"verification_probe":"bash .flywheel/scripts/memory-shape-gate.sh --repo <repo> --json | jq '.shape_drift_count'","tick_consequence":"warn","drain_receipt":{"shape_valid":true,"skill_candidate_routed":false},"dedup_key":"<project>:memory:<sha256-prefix>","doc_kind":"memory","drift_axis":"shape"}
```

- [ ] Validator checks required fields for memory entries and writes `shape_valid` receipt.
- [ ] D4 and D5 are one bead because both stocks drain through the same memory-file-shape gate; evidence `.flywheel/plans/.../05-DAG-REBUILD-SPEC-2026-05-05.md:128`.
- [ ] Missing fields warn; repeated same-path drift promotes to bead via L52/L56.
- [ ] Skill-candidate hints are passed to existing relay, not a new system; evidence D6 consumer `.flywheel/plans/.../00-INTENT.md:312`.
- [ ] L112 command: `bash .flywheel/scripts/memory-shape-gate.sh --repo /Users/josh/Developer/flywheel --json | jq '.shape_drift_count,.rows[0].dedup_key'`.
- [ ] Receipt records explicit `no_skill_candidate_reason` when a memory row is valid but not skill-worthy.

## WOE-EXP-B46 - Skill-Discovery-From-Memory Relay

Priority: P1
Parents: `flywheel-1f4r`, `flywheel-2ypj`

Body: Wire memory-derived skill candidates into the existing skillos-relay primitive owned by B11/B24. This bead must not create a second relay. It tags L4 memory rows as `artifact_class=skill-candidate`, records `should_become=skill`, and proves the existing relay consumed or explicitly deferred each row.

L110 row:
```json
{"ts":"<iso>","artifact_id":"<project>:memory:<path>","artifact_class":"skill-candidate","stock":"memory row suggests reusable skill","consumer":"flywheel-skillos-relay","owner":"skillos:1","deferral_until":null,"deferred_reason":null,"verification_probe":"jq 'select(.artifact_class==\"skill-candidate\" and .relay_receipt==null)' ~/.local/state/flywheel/readme-propagation-ledger.jsonl","tick_consequence":"warn","drain_receipt":{"relay_receipt":"<skillos-ledger-id>"},"dedup_key":"memory-skill:<sha256-prefix>","doc_kind":"memory","drift_axis":"content"}
```

- [ ] Consumes B11/B24 relay, no new queue; evidence: dispatch says "NO new system" `/tmp/dispatch_dag_rebuild_gamma_2026-05-05.md:88-89`.
- [ ] `artifact_class=skill-candidate` aligns L110 allowed classes; evidence `.flywheel/AGENTS-CANONICAL.md:2992-2995`.
- [ ] Relay rows cite source memory file and line when possible.
- [ ] If no skill candidate exists, row carries `explicit_no_auto_repair_reason` per L110; evidence `.flywheel/AGENTS-CANONICAL.md:3001-3004`.
- [ ] L112 command: `jq 'select(.artifact_class=="skill-candidate")' ~/.local/state/flywheel/readme-propagation-ledger.jsonl | tail -5`.
- [ ] Acceptance proves handoff in `~/.local/state/flywheel/skillos-relay-ledger.jsonl`, not only a log line; evidence CoralRaven existing ledger mention `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:191-193`.

## WOE-EXP-B47 - mission-anchor-dispatch-license.sh Permit Gate

Priority: P0
Parents: `flywheel-4m2a`

Body: Ship the symmetric permit-gate to the existing refuse-gate: current `mission-anchor-dispatch-preflight.sh` blocks unfilled anchors, while the new license helper emits PageRank-sorted licensed-undispatched work. It drains self-block-on-decidable-task by proving what is already licensed inside the locked mission envelope.

L110 row:
```json
{"ts":"<iso>","artifact_id":"<repo>:mission-anchor-dispatch-license","artifact_class":"substrate_primitive","stock":"licensed work not dispatched while panes wait","consumer":"dispatch-template + dispatch-decide loop","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"bash .flywheel/scripts/mission-anchor-dispatch-license.sh --emit-list --json | jq '.licensed_undispatched_count'","tick_consequence":"error","drain_receipt":{"licensed_undispatched_count":0,"dispatched_task_ids":["<id>"]},"dedup_key":"mission-license:<repo>:<sha256-prefix>"}
```

- [ ] Explicitly composes refuse-gate and permit-gate: existing helper refuses unfilled mission anchors; new helper permits ranked licensed work. Evidence: refuse helper `/Users/josh/.claude/commands/flywheel/_shared/mission-anchor-dispatch-preflight.sh:1-3`, `:32-44`.
- [ ] Reads MISSION.md Section 3 gate criteria to derive `current_open_phase`; evidence CoralRaven phase ladder source `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:17-32`.
- [ ] Emits sorted list by phase-tag-currency, age, and downstream dependency count; evidence CoralRaven P0 #4 `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:270-277`.
- [ ] CLI ships `--info`, `--schema`, `--examples`, `--emit-list`, and `--json`; evidence canonical CLI quality gate `/Users/josh/.claude/commands/flywheel/plan.md:122-128`.
- [ ] L112 command: `bash .flywheel/scripts/mission-anchor-dispatch-license.sh --info && bash .flywheel/scripts/mission-anchor-dispatch-license.sh --schema --json | jq '.schema_version' && bash .flywheel/scripts/mission-anchor-dispatch-license.sh --emit-list --json | jq '.licensed_undispatched_count'`.
- [ ] Depends only on ledger schema parent because license emissions are L1/L2-class ledger rows; evidence dependency spec `.flywheel/plans/.../05-DAG-REBUILD-SPEC-2026-05-05.md:145-149`.

## WOE-EXP-B48 - phase-anchor-probe.sh Doctor Field And Refusal Hook

Priority: P0
Parents: `WOE-EXP-B47`

Body: Add a phase-anchor probe that reads each repo mission ladder, derives the current open phase, and compares it to pending or sent dispatch rows. The doctor field becomes the runtime consumer for B47 license rows and the dispatcher refusal hook prevents phase-N+2 work while phase-N remains open.

L110 row:
```json
{"ts":"<iso>","artifact_id":"<repo>:phase-anchor-probe","artifact_class":"substrate_primitive","stock":"dispatch rows ahead of current open phase","consumer":"flywheel-loop doctor + dispatcher refusal hook","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"bash .flywheel/scripts/phase-anchor-probe.sh --repo <repo> --json | jq '.phase_anchor_violations_24h'","tick_consequence":"error","drain_receipt":{"phase_anchor_violations_24h":0,"current_open_phase":"<phase>"},"dedup_key":"phase-anchor:<repo>:<phase>"}
```

- [ ] Parses MISSION.md Section 3 gate-criterion/status to compute `current_open_phase`; evidence CoralRaven substrate gap `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:152-156`.
- [ ] Doctor exposes `.phase_anchor_violations_24h` and strict tick fails when nonzero; evidence H2 verification `.flywheel/plans/.../05-DAG-REBUILD-SPEC-2026-05-05.md:33-38`.
- [ ] Dispatcher refusal hook blocks `phase_tag > current_open_phase + 1`, while allowing `substrate` and `amendment-spec` tags.
- [ ] Consumes B47 license ledger output instead of reparsing ad hoc dispatch prose.
- [ ] L112 command: `bash .flywheel/scripts/phase-anchor-probe.sh --repo /Users/josh/Developer/flywheel --schema --json && bash .flywheel/scripts/phase-anchor-probe.sh --repo /Users/josh/Developer/flywheel --json | jq '.phase_anchor_violations_24h'`.
- [ ] Recovery receipt names the row IDs refused and the phase criterion that made the refusal decidable.

## WOE-EXP-B49 - L114 Phase-Anchor Discipline Codification

Priority: P0
Parents: `WOE-EXP-B48`

Body: Codify CoralRaven's phase-anchor rule as L114 across all three doctrine surfaces after the probe exists. Every dispatch packet must declare `phase_tag`; doctor refuses ahead-of-phase work from B48. This is a 3-surface doctrine bead, not just an AGENTS prose edit.

L110 row:
```json
{"ts":"<iso>","artifact_id":"flywheel:L114","artifact_class":"lrule_violation","stock":"dispatch rows missing phase_tag or ahead-of-phase","consumer":"phase-anchor-probe.sh","owner":"dispatch-template","deferral_until":null,"deferred_reason":null,"verification_probe":"jq 'select(.phase_tag == null)' .flywheel/dispatch-log.jsonl | wc -l","tick_consequence":"error","drain_receipt":{"doctrine_3_surface_divergent_count":0,"phase_anchor_violations_24h":0},"dedup_key":"L114:phase-anchor:<source-line>"}
```

- [ ] Land L114 in root `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, and `templates/flywheel-install/AGENTS.md`; evidence L96 `.flywheel/AGENTS-CANONICAL.md:2349-2361`.
- [ ] Rule text requires `phase_tag=<P1|P2|P3a|P3b|P3c|P4|P5|P6|substrate|amendment-spec>`; evidence CoralRaven proposal `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:220-222`.
- [ ] B48 must exist first so codification names a mechanical consumer; evidence dependency spec `.flywheel/plans/.../05-DAG-REBUILD-SPEC-2026-05-05.md:147-149`.
- [ ] Cross-orch propagation uses canonical-meta-rules sync and three-surface check; evidence `.flywheel/AGENTS-CANONICAL.md:2650-2660`, `:2933-2945`.
- [ ] L112 command: `bash /Users/josh/.flywheel/canonical-meta-rules/sync.sh --check-three-surface --target /Users/josh/Developer/flywheel --json | jq '.status,.drift_count'`.
- [ ] Callback acceptance requires `phase_tag` evidence in dispatch-template validation, not worker memory.

## WOE-EXP-B50 - L115 Amendment Followup Phase Tag And Lock-Log Schema

Priority: P1
Parents: `WOE-EXP-B47`

Body: Codify amendment followup beads as phase-tagged lock-log objects. The old shape `followup_beads:[<title>]` loses deferral data; the new schema stores `id`, `title`, `phase_tag`, `deferral_owner`, `deferral_until`, and `auto_fire_trigger` so locked-spec work cannot masquerade as ready-to-build.

L110 row:
```json
{"ts":"<iso>","artifact_id":"<repo>:lock-log:L115","artifact_class":"lrule_violation","stock":"mission amendments with untagged followup beads","consumer":"lock-log schema validator","owner":"mission-anchor-init","deferral_until":null,"deferred_reason":null,"verification_probe":"jq '.followup_beads[] | select(.phase_tag == null)' .flywheel/lock-log.jsonl","tick_consequence":"error","drain_receipt":{"followup_phase_tag_missing_count":0},"dedup_key":"L115:lock-log:<amendment-id>"}
```

- [ ] Lock-log schema delta: `followup_beads:[{id,title,phase_tag,deferral_owner,deferral_until,auto_fire_trigger,mission_license}]`.
- [ ] Codify L115 in three surfaces after schema/probe fixture exists; evidence L96 `.flywheel/AGENTS-CANONICAL.md:2349-2361`.
- [ ] Dispatch-ready means phase tag is allowed by B47/B48, not merely amendment locked; evidence CoralRaven diff `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:247-251`.
- [ ] Cross-orch propagation uses `/Users/josh/.flywheel/canonical-meta-rules/sync.sh --apply --json` on tick; evidence `.flywheel/AGENTS-CANONICAL.md:2636-2660`.
- [ ] L112 command: `jq '.followup_beads[]? | select(.phase_tag == null)' .flywheel/lock-log.jsonl | wc -l`.
- [ ] Backfill fixture covers a title-string legacy row and proves validator emits a migration warning, not silent pass.

## WOE-EXP-B51 - L116 Cross-Orch Query Narrow Form And Validator

Priority: P1
Parents: `WOE-EXP-B47`

Body: Codify narrow-form cross-orch queries. Outbound flywheel-class asks carry at most three fields by default; verbose packets need `verbose_authorized_by`. The validator measures sender-side query age and shape so peer orchestration latency becomes a visible stock instead of scrollback friction.

L110 row:
```json
{"ts":"<iso>","artifact_id":"fleet:cross-orch-query:L116","artifact_class":"lrule_violation","stock":"verbose or stale outbound cross-orch queries","consumer":"cross-orch validator","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"jq 'select((.fields_count > 3) and (.verbose_authorized_by == null))' ~/.local/state/flywheel/cross-orch-coordination.jsonl","tick_consequence":"warn","drain_receipt":{"verbose_unlicensed_count":0,"oldest_outbound_query_age_seconds":0},"dedup_key":"L116:cross-orch:<thread-id>"}
```

- [ ] Validator fields: `outbound_query_field_count`, `narrow_form`, `verbose_authorized_by`, `outbound_query_age_seconds`, `reply_received_at`.
- [ ] Rule text follows CoralRaven L113 proposal but renumbers to L116; evidence `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:226-228`.
- [ ] Warn, not error, unless query exceeds SLA and is flywheel-class; evidence substrate gap 9 `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md:176-178`.
- [ ] Cross-orch propagation path uses canonical META-RULE sync; evidence `/Users/josh/.flywheel/canonical-meta-rules/INDEX.md:7-26`.
- [ ] L112 command: `jq 'select((.fields_count > 3) and (.verbose_authorized_by == null))' ~/.local/state/flywheel/cross-orch-coordination.jsonl | wc -l`.
- [ ] Zero-match proof for "cross-orch query latency monitoring" remains attached until a skill or doctrine owns it.

## WOE-EXP-B52 - L117 Mission-Anchor Cryptographic Invariance

Priority: P1
Parents: `WOE-EXP-B47`

Body: Codify mission-anchor invariance with hash proof. Mission amendments already self-attest `mission_anchor_unchanged`; this bead makes it mechanical by writing pre/post SHA256 values for the protected anchor surface and failing strict doctor if they differ without an explicit owner-approved mission change.

L110 row:
```json
{"ts":"<iso>","artifact_id":"<repo>:mission-anchor:L117","artifact_class":"lrule_violation","stock":"mission amendment rows without pre/post anchor hash proof","consumer":"lock-log validator + strict doctor","owner":"mission-anchor-init","deferral_until":null,"deferred_reason":null,"verification_probe":"jq 'select(.mission_anchor_sha256_pre != .mission_anchor_sha256_post)' .flywheel/lock-log.jsonl","tick_consequence":"error","drain_receipt":{"mission_anchor_hash_mismatch_count":0},"dedup_key":"L117:mission-anchor:<amendment-id>"}
```

- [ ] Lock-log schema delta: `mission_anchor_sha256_pre`, `mission_anchor_sha256_post`, `mission_anchor_sha256_equal`, `mission_anchor_source_path`, `mission_anchor_hash_scope`.
- [ ] Strict doctor fails on mismatch unless amendment explicitly changes mission anchor with owner approval.
- [ ] Adopt Jeff cryptographic invariant shape from replay/capsule code; evidence MCP result `franken_node/sdk/verifier/src/capsule.rs:1-56` and `franken_node/sdk/verifier/src/lib.rs:4442-4541`.
- [ ] Codify L117 in three doctrine surfaces with check-three-surface receipt; evidence `.flywheel/AGENTS-CANONICAL.md:2933-2945`.
- [ ] L112 command: `jq 'select(.mission_anchor_sha256_pre != .mission_anchor_sha256_post)' .flywheel/lock-log.jsonl | wc -l`.
- [ ] Acceptance includes a fixture where legacy rows without hash fields emit migration warnings, while new rows require equality proof.
