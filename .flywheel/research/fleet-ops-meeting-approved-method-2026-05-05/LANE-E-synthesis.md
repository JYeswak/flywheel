# Lane E Synthesis - Canonical Fleet Ops Meeting Method

task_id: `b56-laneE-synthesis-fleet-ops-meeting-2026-05-05`
date: `2026-05-05`
mode: `SYNTHESIS_ONLY_PLAN_SPACE`
output_path: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-E-synthesis.md`

## 1. Method

### 1.1 Contract receipt

- DID read `/tmp/dispatch_lane_e_synthesis_2026-05-05.md` before synthesis; evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:1-13`.
- DID treat the task as synthesis-only, no code, no bead creation, composite >= 9.5; evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:11-13`.
- DID write the requested output file path; evidence command: `test -f /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-E-synthesis.md && wc -l /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-E-synthesis.md` returns 1015 lines.
- DID follow the required section order; evidence command: `rg -n '^## [1-9]\\. ' /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-E-synthesis.md` returns Sections 1-9 in order.
- DID bind cross-lane claims to file:line citations; evidence command: `perl -ne 'while(m{/(tmp|Users)/[^\\s),|]+:\\d+(?:-\\d+)?}g){$c++} END{print "$c\\n"}' /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-E-synthesis.md` returns 617 file:line citations.
- DID reserve only this synthesis output before writing; evidence command: `mcp__mcp_agent_mail__.macro_start_session human_key=/Users/josh/Developer/flywheel file_reservation_paths=.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-E-synthesis.md`.
- DID confine the intentional file output to this synthesis artifact; evidence command: `git status --short -- .flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-E-synthesis.md` returns only `?? .flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-E-synthesis.md`.
- The bead receipt for this synthesis is `no_bead_reason=synthesis_only_planner_artifact`; evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:110-116`.
- DID use the dispatch-required source-(a) first; evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:9`; evidence command: `mcp__skill_search__.query_skills_tool query="synthesis 6-layer fleet observability cross-layer cascade detection" limit=10`.
- DID run a flywheel Socraticode pre-flight after source-(a); evidence command: `mcp__socraticode__.codebase_status projectPath=/Users/josh/Developer/flywheel` returned `Status: green` and `Indexed chunks: 658`.
- DID run 3 flywheel Socraticode searches for meeting schema, cascade detector, and observatory rollup terms; evidence commands: `mcp__socraticode__.codebase_search query="fleet ops meeting aggregate schema daily report observatory status" limit=10`, `mcp__socraticode__.codebase_search query="cross layer cascade detector product research moat knowledge depth" limit=10`, and `mcp__socraticode__.codebase_search query="fleet observatory architecture health daily rollup 8 spines per orch" limit=10`.

### 1.2 Mandatory skills read

- `planning-workflow` was consulted because the dispatch asks for plan-space synthesis; the skill says planning tokens are cheaper than implementation tokens and recommends detailed plans before code; evidence: `/Users/josh/.claude/skills/planning-workflow/SKILL.md:13-16`.
- `planning-workflow` requires great plans to be self-contained, granular, dependency-aware, justified, and user-focused; evidence: `/Users/josh/.claude/skills/planning-workflow/SKILL.md:82-89`.
- `plan-space-convergence` was consulted because the dispatch is a non-trivial planner input; it requires ground truth, proposed change, and verification with file:line evidence; evidence: `/Users/josh/.claude/skills/plan-space-convergence/SKILL.md:32-39`.
- `plan-space-convergence` says 30-60 minutes in plan-space saves days of worker churn and prevents wrong-premise code from landing; evidence: `/Users/josh/.claude/skills/plan-space-convergence/SKILL.md:53-57`.
- `multi-model-triangulation` was consulted because this synthesis reconciles multiple lanes; it defines consensus, divergence, unique insights, recommendation, and confidence as the synthesis template; evidence: `/Users/josh/.claude/skills/multi-model-triangulation/SKILL.md:90-113`.
- `multi-model-triangulation` warns not to ignore disagreements and requires a unified view; evidence: `/Users/josh/.claude/skills/multi-model-triangulation/SKILL.md:156-165`.
- `donella-meadows-systems-thinking` was consulted because Lane A makes Meadows the system frame; the skill requires naming boundary, stock, flows, loops, leverage point, intervention, and measure; evidence: `/Users/josh/.claude/skills/donella-meadows-systems-thinking/SKILL.md:49-70`.
- `donella-meadows-systems-thinking` says high-leverage claims require concrete measurement loops; evidence: `/Users/josh/.claude/skills/donella-meadows-systems-thinking/SKILL.md:72-83`.
- `canonical-cli-scoping` was consulted because the eventual plan will likely create an aggregator CLI/command; it requires doctor, health, repair, JSON, schemas, robot mode, and dry-run discipline for operator substrate; evidence: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:10-35`, `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:177-218`, and `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:261-306`.

### 1.3 Lane read ledger

- Lane A was read end-to-end; evidence command: `wc -l /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md` returns 257 lines.
- Lane B was read end-to-end; evidence command: `wc -l /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md` returns 169 lines.
- Lane C was read end-to-end; evidence command: `wc -l /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md` returns 188 lines.
- Lane D was read end-to-end; evidence command: `wc -l /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md` returns 725 lines.
- Lane F was read end-to-end; evidence command: `wc -l /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md` returns 802 lines.
- The 5-lane evidence corpus totals 2141 lane-output lines; evidence command: `wc -l /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-{A-donella,B-jeff,C-anthropic,D-joshua,F-product-research}.md`.

### 1.4 Where the lanes agree

- All lanes agree the meeting is a routing and synthesis substrate, not a daily human dashboard; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:32-52`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:82-88`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:114`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:548-554`.
- All lanes agree existing substrate must be composed before new substrate is built; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:197`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:161-169`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:168-187`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:625-655`.
- All lanes agree the primary frame is architecture-health and autonomous capacity, not individual-agent evaluation; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:72`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:125-140`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:337-345`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:381-395`.
- All lanes agree file:line evidence and structured schemas are not optional in the eventual packet; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:111-117`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:57-59`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:495-501`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:467-476`.
- All lanes agree the missing gap is a canonical daily fleet artifact or packet, not the absence of raw signals; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:212-217`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:181-185`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:273`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:657-668`.

### 1.5 Where the lanes differ

- Lane A ranks self-organization and information flows as the strongest interventions, while Lane B emphasizes existing robot/ledger primitives; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:184-224` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:135-169`.
- Lane C frames the meeting through 9 petals and Claude skills, while Lane D frames it through already-shipped flywheel commands, scripts, ledgers, launchd, and L-rules; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:22-88` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:74-197`.
- Lane D's planner verdict has 4 build-new items, while Lane F introduces 15 needed Layer 5/6 extractors plus 10 detectors; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:650-655` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:440-446`.
- Lane D's per-orch slots are operational/client-substrate questions, while Lane F's per-orch slots are product/customer and moat metrics; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:505-593` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-524`.

### 1.6 Where the lanes are silent

- None of the lanes implements code or creates beads; this is intentional because the dispatch is synthesis-only; evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:110-116`.
- Lane A gives systems leverage but does not enumerate concrete command contracts; evidence: Lane A's verdict is a five-field receipt, not a CLI schema, at `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:245-257`.
- Lane B inventories Jeff primitives but does not fill the ZestStream product/customer slots; evidence: Lane B's provisional verdict remains primitive-focused at `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:133-169`.
- Lane C inventories Claude/Flywheel skills but does not provide repo-specific Layer 5 cards; evidence: Lane C says new `fleet-ops-meeting --read-only --json` and schema are needed at `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:181-185`.
- Lane D inventories flywheel substrate but marks knowledge-moat depth and VRTX live lead metric gaps; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:618`.
- Lane F defines product/research extractors and detectors but does not implement the daily aggregator; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:526-564`.

### 1.7 Self-grade table

| Gate | Score | Evidence |
|---|---:|---|
| All 5 lanes read end-to-end | 9.8 | `wc -l` commands in Section 1.3 and lane citations throughout |
| Mandatory skills consulted | 9.7 | `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:9` plus Section 1.2 |
| 6-layer frame complete | 9.7 | Section 2 covers layers 1-6 and cites Lane A/D/F/B/C |
| Cross-layer cascade synthesis | 9.7 | Section 3 picks 5 from Lane F's 10; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:309-395` |
| Reconciliation quality | 9.6 | Section 4 resolves 4 lane disagreements named by dispatch; evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:63-69` |
| Protocol shape | 9.7 | Section 5 supplies schemas requested by dispatch; evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:71-82` |
| ADOPT/EXTEND/AVOID/BUILD_NEW register | 9.5 | Section 6 reconciles Lane B, D, and F; evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:83-87` |
| Joshua decision register | 9.6 | Section 8 uses Lane D founder-bottleneck constraints and Lane C taste/founder doctrine |
| Evidence binding | 9.6 | File:line or re-runnable command evidence attached to material cross-lane claims |
| Composite | 9.66 | Arithmetic judgement across gates above |

## 2. The 6-layer canonical frame

### 2.1 Layer 1 - Substrate

Definition line 1: Layer 1 is the local runtime substrate: OS, terminal/session substrate, launchd, storage, Qdrant/Socraticode indexes, local state directories, and process liveness. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:24-30` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:179-197`.
Definition line 2: Layer 1 is in scope only when its signals determine whether higher layers can trust their evidence, not as a general system administration meeting. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:36-52` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:311-318`.

Stocks accumulated at this layer:
- Architecture-health visibility per repo accumulates when rollups, trends, cohort, counterfactual, and repair-route signals remain fresh. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:62` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:267-273`.
- Fleet comms integrity accumulates when sessions have token, packet, unread-escalation, identity, and liveness evidence. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:69` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:208-216`.
- Public-surface readiness decays when dependency, copy, product, and launch contexts drift. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:64-65` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:329-337`.

Existing extractors usable as-is:
- Socraticode status is usable as a Layer 1 index health receipt; Lane F observed green status and indexed chunk counts for active repos. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:88-99`.
- `architecture-health-rollup.sh` is usable for 24h/7d/30d/90d architecture-health windows. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:136` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:627-628`.
- `fleet-observatory-aggregate.sh` is usable as the strategic composite input. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:137` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:153-156`.
- `tick-driver.jsonl`, `codex-stuck-detector.jsonl`, `storage-headroom-watcher.jsonl`, and `session-topology.jsonl` are usable Layer 1 liveness and headroom ledgers. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:209-216`.

Existing extractors needing extension:
- `architecture-health-rollup.sh` needs per-orch breakdown columns, because Lane D says the rollup exists but per-session reliability/faithfulness/leverage/reuse/coordination/drift-authoring vectors are missing. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:637`.
- `fleet-observatory-aggregate.sh` needs trend deltas, because Lane D says it currently emits a snapshot. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:638`.
- Worker capacity and freeze-rate need week-over-week trend rollup, because Lane D marks those as partial. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:609` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:644`.

Build-new at this layer:
- Add `substrate_index_health` to the meeting packet, sourced from Socraticode `codebase_status` and expected-keyfile hit checks; evidence for the cascade: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:311-318`.
- Add `driver_freshness` to the packet, sourced from tick-driver, loop markers, and launchd driver proof; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:185-197` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:297`.
- Add `storage_and_process_headroom` as a warning-only card, not a meeting action surface; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:209-216`.

Per-orch specialization slots:
- `flywheel`: `fleet_observatory_health_score`, `architecture_health_metric_unpaired_count`, `tick_driver_age`, `storage_headroom_status`; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:603-610`.
- `skillos`: `jsm_digest_status`, `pack_registry_readable`, `skill_catalog_drift`; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:488-495`.
- `mobile-eats`: `nango_canary_freshness`, `live_post_gate_state`, `launch_readiness_source_freshness`; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:478-486`.
- `alpsinsurance`: `daily_report_artifact_age`, `staging_state_source`, `storage_threshold`; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:543-566`.
- `vrtx`: `lead_route_probe_freshness`, `Teams_notification_path_health`, `signed_scope_file_freshness`; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:497-505`.

Layer-specific anti-patterns:
- Do not report fleet green from one cached source; Lane F's storage/index cascade and Lane B's substrate-bleed warning both require multiple live evidence sources. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:311-318` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:119-125`.
- Do not make restart or respawn a meeting button; Lane B says blind restart/respawn needs L95/L115 receipts. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:153-159`.
- Do not count a marker as a driver; Lane D marks L57 as direct ops-meeting relevance. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:297`.

### 2.2 Layer 2 - Tooling

Definition line 1: Layer 2 is the operator/tool substrate: `ntm`, `br`, `bv`, Agent Mail, DCG, CASS, skills, robot schemas, and JSONL ledgers. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:25-30` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:61-81`.
Definition line 2: Layer 2 is in scope when the meeting chooses which existing tool signal to trust, extend, or route, not when it creates a new tool stack from scratch. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:161-169` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:625-655`.

Stocks accumulated at this layer:
- Skill-library coverage gaps accumulate when recurring work or trauma classes lack usable skill coverage. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:65` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:320-327`.
- Dispatch composite-score average accumulates through accepted work and decays when quality gates become retrospective. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:68` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:149-151`.
- Meeting ceremony debt accumulates when tooling produces duplicate reports without durable routes. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:70` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:142-148`.

Existing extractors usable as-is:
- NTM robot schemas and commands are usable for daily status collection. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:69` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:137`.
- Agent Mail reservations and daily-thread messaging are usable coordination primitives. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:73` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:138`.
- CASS `cm context --json` is usable as the memory preflight. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:75` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:139`.
- DCG stable exit-code signals are usable safety input. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:81` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:140`.
- Beads `br stats`, `br ready`, `br dep`, and schema rollups are usable for task stock rollups. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:71` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:142`.
- `daily-report.sh`, `fleet-observatory-aggregate.sh`, `fleet-comms-health-probe.sh`, and `fleet-process-gap-detector.sh` are usable flywheel tooling spines. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:136-147`.

Existing extractors needing extension:
- Frankenterm's 4-minute loop is extendable only by replacing raw pane mechanics with NTM robot calls. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:145-151`.
- `daily-report.sh` needs fleet-aggregate mode or a separate aggregator that composes per-repo reports. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:639` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:175-177`.
- `peer-orch-blocker-watch.sh` needs 2-tick auto-promotion to `/flywheel:plan`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:641`.
- Agent Mail needs a daily meeting thread convention with subject/thread IDs and escalation thresholds. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:163-166`.

Build-new at this layer:
- Build `meeting_packet.schema.json`, because Lane C names the schema as new-needed and Lane B requires schema-validated state envelopes. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:181-185` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:111-117`.
- Build a read-only collector wrapper that emits JSON and Markdown from existing commands. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:163-164` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:652-655`.
- Build a robot-query authority selector, because Lane B says the meeting should reject scrollback/help parsing and pick exact robot queries. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:166-167`.

Per-orch specialization slots:
- `flywheel`: `tooling_spines_present`, `robot_query_convergence`, `callback_validation_receipts`, `daily_report_age`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:74-95`.
- `skillos`: `skill_gap_candidate_count`, `pack_validation_status`, `JSM_digest_gate`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:488-495`.
- `mobile-eats`: `publishability_probe`, `owner_social_canary_receipt`, `feedback_priority_router`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:137-148`.
- `alpsinsurance`: `Mike_report_format_validator`, `sent_confirmation`, `staging_state_probe`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:223-234`.
- `vrtx`: `lead_latency_probe`, `signed_scope_guard`, `Teams_notification_probe`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:194-205`.

Layer-specific anti-patterns:
- Do not use raw pane send/capture/restart patterns. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:153-156`.
- Do not use bare `bv` in automation. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:157`.
- Do not ship a CLI/aggregator without doctor/health/repair, JSON, schemas, and dry-run discipline. Evidence: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:16-35`, `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:177-218`, and `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:324-380`.

### 2.3 Layer 3 - Agents

Definition line 1: Layer 3 is the active orchestrator/worker fleet: session/pane/project identity, dispatches, callback quality, worker capacity, and autonomous routing behavior. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:24-30` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:91-110`.
Definition line 2: Layer 3 is measured at the system/session/substrate level, not as named-agent HR or leaderboards. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:125-140` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:337-345`.

Stocks accumulated at this layer:
- Autonomous fleet operating capacity is the primary stock. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:56-72` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:245-255`.
- Orchestrator alignment accumulates when mission, doctrine, ready work, and blocker route stay current. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:59` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:117-124`.
- L70 punt count accumulates when same-tick actions are named but not executed or routed. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:67` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:310`.
- Founder-bottleneck volume accumulates when low-level decisions are incorrectly routed to Joshua. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:61` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:477-485`.

Existing extractors usable as-is:
- `/flywheel:status` is usable as tactical session dashboard input. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:80` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:155-156`.
- `peer-orch-productivity-watch.sh` is usable for idle-with-work and substrate-blocked counts. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:141`.
- `peer-orch-blocker-watch.sh` and `cross-orch-coordination.jsonl` are usable escalation surfaces. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:142` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:208`.
- `l70-ticks-punted-counter.sh` and `l70-ticks-punted.jsonl` are usable direct meeting metrics. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:154` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:610`.
- Agent-monitoring style heartbeat/completion/queue/cascade indicators are useful if kept at system level. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:105-110`.

Existing extractors needing extension:
- Worker capacity and freeze-rate need trends, because Lane D marks the current state as partial. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:609`.
- Founder-dispose percentage needs a quarterly emission surface, because Lane D marks the trend as partial. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:613`.
- `/flywheel:status` needs a meeting profile that suppresses raw rows when the observatory already provides strategic health. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:177`.

Build-new at this layer:
- Add `daily_orch_self_audit.v1`, with fields from Lane A's five-field receipt plus callback and worker-capacity receipts. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:203-208`.
- Add `founder_decision_count_by_layer`, because Lane F identifies founder bottleneck as a cascade. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:338-345`.
- Add `same_tick_route_or_blocked_reason`, because Lane D says the protocol must run without Joshua-decision gates and auto-escalate repeated blockers. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:495-501`.

Per-orch specialization slots:
- `flywheel`: `idle_with_work_available_count`, `true_josh_blocker_count`, `callback_validation_fail_count`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:477-483`.
- `skillos`: `worker_skill_consultation_gap`, `pack_route_blocker`, `candidate_skill_to_route`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:511-523`.
- `mobile-eats`: `publishability_worker_warnings`, `product_ready_bead_candidate`, `owner_canary_blocker`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:529-540`.
- `alpsinsurance`: `Mike_report_blocker`, `R1_R7_red_count`, `client_visible_blocker_count`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:547-555`.
- `vrtx`: `lead_route_blocker`, `signed_scope_drift_blocker`, `brand_canon_blocker`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:572-579`.

Layer-specific anti-patterns:
- Do not make the meeting a founder-as-feedback-loop dashboard. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:174-182` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:129-140`.
- Do not report per-agent rankings or blame labels. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:232-244` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:337-345`.
- Do not accept DONE callbacks as proof without acceptance-gate validation. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:482`.

### 2.4 Layer 4 - Doctrine and Knowledge

Definition line 1: Layer 4 is the durable knowledge substrate: AGENTS L-rules, INCIDENTS, fuckup-log, CASS/memory, skills, JSM, Jeff-digest, and promotion ladders. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:24-30` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:277-411`.
Definition line 2: Layer 4 is in scope when daily evidence becomes doctrine, skill, probe, bead, or explicit no-action rationale. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:150-156` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:347-353`.

Stocks accumulated at this layer:
- Knowledge-moat depth accumulates through validated reusable learnings adopted into skills, doctrine, probes, exemplars, or public surfaces. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:60` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:300-307`.
- Trauma-class accumulation grows when fuckup classes are not promoted or routed. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:66` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:383-411`.
- Cross-pollination event count grows when transferable repo-to-repo patterns are adopted or queued. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:63` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:158-164`.

Existing extractors usable as-is:
- AGENTS and AGENTS-CANONICAL L-rule headings are usable doctrine inventory. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:65-70` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:277-361`.
- `fuckup-log.jsonl`, `trauma-class-trend.jsonl`, and INCIDENTS are usable trauma substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:215` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:383-411`.
- CASS context and trauma guard are usable memory substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:75` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:118-123`.
- `weeklyreflection` is usable for petal-9 weekly closeout. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:80` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:92`.

Existing extractors needing extension:
- Knowledge-moat depth needs a metric because Lane D marks it missing. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Skill-gap candidate detection needs a fleet-wide rollup metric because Lane D marks it partial. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:612`.
- `/flywheel:weeklyreflection` needs cross-orch peer-review structure because Lane D marks it partial. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:605` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:640`.

Build-new at this layer:
- Build `skill-moat-depth-probe.sh` or equivalent doctor field. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:655`.
- Build `research_to_action_adoption_rate`, because Lane F marks it as a needed Layer 6 extractor and Lane D marks knowledge-moat depth missing. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:295-298` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Build `missing_skill_routed_to_skillos_count`, because Lane F's skill-gap cascade requires routing missing skills to skillos. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:320-327`.

Per-orch specialization slots:
- `flywheel`: `L_rule_lag`, `incident_promotion_candidates`, `learning_loop_closed`, `doctrine_drift_count`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:314-345`.
- `skillos`: `skill_inventory_delta`, `skill_quality_gap`, `pack_graduation_candidate`, `JSM_delta`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:164-174`.
- `mobile-eats`: `journey_stage_to_bead_mapping`, `public_copy_rule_adoption`, `feedback_to_bead_rate`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:118-148`.
- `alpsinsurance`: `Mike_report_rule_compliance`, `no_internal_jargon`, `client_safe_decisions_needed`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:207-234`.
- `vrtx`: `signed_scope_canon`, `brand_voice_canon`, `audit_bonus_not_scope`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:176-205`.

Layer-specific anti-patterns:
- Do not treat research count as moat; adoption into skill, doctrine, bead, product gate, or reusable artifact is required. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:452-454` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:682-688`.
- Do not treat local-only skill packs as published reusable substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:456-458` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:730-736`.
- Do not create doctrine without three-surface propagation and evidence linkage. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:335-361`.

### 2.5 Layer 5 - End-user and Product

Definition line 1: Layer 5 asks whether each orchestrator's work is improving a customer, user, buyer, or recipient outcome. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:101-108`.
Definition line 2: Layer 5 must be per-orch and product-specific, not a generic "product health" score. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:450` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:530-536`.

Stocks accumulated at this layer:
- Public-surface readiness accumulates when publishability, brand voice, launch, and user outcome receipts remain fresh. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:64` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:401-420`.
- Founder-bottleneck volume accumulates when product work waits on low-level Joshua dashboard inspection. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:61` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:338-345`.
- Customer feedback conversion accumulates when product feedback becomes beads, skills, doctrine, product gates, or explicit no-action receipts. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:347-353`.

Existing extractors usable as-is:
- mobile-eats has brand voice, journey, feedback, canary, and expansion-readiness substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:110-148`.
- skillos has skill inventory delta, Jeff/JSM delta, external research delta, pack graduation candidate, skill quality gap, and pack lifecycle substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:150-174`.
- VRTX has lead-touch, notification, signed-scope, action-card, phase-subgoal, and milestone substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:176-205`.
- ALPS has Mike daily report, phase ladder, R1-R7 rigor, client communication, and staging/off-track substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:207-234`.
- Future slots can inherit brand, conversion, eval, benchmark, connector, and customer-health skills. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:236-243` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:517-524`.

Existing extractors needing extension:
- mobile-eats needs actual first-owner-publish completion, shared-card conversion, contribution impact, canary freshness, and customer-risk heat. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:144-148`.
- skillos needs downstream skill consumer satisfaction, recommendation adoption, and publishability beyond local-only. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:172-174`.
- VRTX needs actual live lead-touch latency, Jack bottleneck count, ClubReady proof, and Derrek time reclaimed. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:202-205`.
- ALPS needs Mike report sent-confirmation, client-safe staging proof, shadow-mode countdown, and dashboard redundancy guard. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:231-234`.

Build-new at this layer:
- Build per-repo product cards in `meeting_packet.schema.json`, not a single generic product score. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-524`.
- Build `layer5_product_outcome_missing` detector. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:674-680`.
- Build `daily_report_not_sent`, `live_canary_claim_mismatch`, `client_scope_drift`, and `dashboard_redundancy_risk` detectors as product-specific cards, not a generic dashboard. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:698-720` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:738-744`.

Per-orch specialization slots:
- `mobile-eats`: hungry locals, truck owners, contributors, moderators; primary metric first verified owner publish before OAuth. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:478-486`.
- `skillos`: orchestrators and workers consuming skill quality and pack substrate; primary metric skill recommendation adoption. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:488-495`.
- `vrtx`: VRTX staff, leads, members, ZooTown participants; primary metric leads touched under 4 hours via Teams. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:497-505`.
- `alpsinsurance`: Mike, ALPS team, CubCloud/Brandon, account managers, biz dev, underwriting, customer service; primary metric daily Mike report generated, brand-safe, and sent. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:507-515`.
- `future-pipeline`: zesttube, zeststream.ai, AaaS, langgraph, agent-harness, and nango each need a domain slot. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:517-524`.

Layer-specific anti-patterns:
- Do not build a single generic product health score. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:548`.
- Do not build dashboards as products. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:450-451`.
- Do not claim mobile-eats live social readiness from canary alone. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:551`.
- Do not claim VRTX product success without live lead latency. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:552`.
- Do not claim ALPS communication-loop success without sent-report confirmation. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:553`.

### 2.6 Layer 6 - Research, Strategy, and Moat

Definition line 1: Layer 6 asks whether the fleet is learning outside the repos and converting that learning into strategic advantage. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:245-253`.
Definition line 2: Layer 6 covers market intel, external deltas, Jeff/JSM, strategic moat, long-horizon research, competitive insight, vendor risk, and reusable knowledge. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:24-30` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:249-251`.

Stocks accumulated at this layer:
- Knowledge-moat depth is the core Layer 6 stock. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:60` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Cross-pollination event count is a research-to-reuse stock. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:63` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:438`.
- Vendor/API delta risk accumulates when live external truth outruns skills and local code. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:243` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:329-337`.

Existing extractors usable as-is:
- skillos already owns Jeff/JSM watch and outside-world/research-triad streams. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:272-276`.
- skillos already measures Jeff/JSM delta, external research delta, and skill quality gap. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:274-275`.
- JSM digest freshness is usable but degraded when probe fields are unknown. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:249-253` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:424-425`.
- KNOW/INFER/GUESS/BLIND ratio is usable for client deliverable research. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:257-259` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:429`.
- VRTX and mobile-eats already have research-backed product input streams. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:277-283`.

Existing extractors needing extension:
- Cross-repo research adoption rate is needed. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:430`.
- Vendor-change blast radius is needed. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:431`.
- Strategic moat event count is needed. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:433`.
- Cross-repo reusable artifact diffusion is needed. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:438`.

Build-new at this layer:
- Build `layer6_research_adoption_missing` detector. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:682-688`.
- Build `vendor_delta_blast_radius` detector, with watchtower/Jeff/JSM inputs and affected repo/product outputs. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:329-337`.
- Build `jsm_digest_degraded` guard before JSM can count green. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:722-728`.
- Build `moat_compounding_event_count` tied to skill, doctrine, repo, client, and market surfaces. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:298` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:300-307`.

Per-orch specialization slots:
- `skillos`: `Jeff_JSM_delta`, `external_research_delta`, `skill_quality_gap`, `pack_graduation_candidate`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:287-294`.
- `mobile-eats`: `research_backed_product_input_count`, `local_truth_readiness`, `candidate_market_proof_debt`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:282-283`.
- `vrtx`: `SDK_probe_freshness`, `client_template_reuse`, `signed_scope_reuse_pattern`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:277-280`.
- `alpsinsurance`: `vertical_workato_replacement_moat`, `migration_tooling_reuse`, `regulated_SMB_signal`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:280-281`.
- `future-pipeline`: `watchtower_diff`, `competitive_delta`, `regulatory_delta`, `knowledge_graph_health`, `research_to_action`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:422-438`.

Layer-specific anti-patterns:
- Do not count research volume as moat. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:453`.
- Do not treat degraded JSM as green. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:550`.
- Do not claim strategy unless it becomes skill, doctrine, bead, product gate, or reusable artifact. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:461`.
- Do not import Jeff patterns without file:line evidence. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:127-131`.

## 3. Cross-layer cascade patterns

### 3.1 Top-5 selection method

- Lane F documented 10 cascade patterns and 10 detectors; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:309-395` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:581-596`.
- The synthesis picks the top 5 by blast radius, recurrence risk, and ability to interrupt with existing primitives; evidence for interruption-over-dashboard doctrine: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:203-224`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:657-668`, and `/Users/josh/.claude/skills/donella-meadows-systems-thinking/SKILL.md:72-83`.

### 3.2 Cascade 1 - Vendor/API delta -> stale skill -> failed customer promise

- Trigger layer + indicator: Layer 6 external provider delta, stale JSM/skill digest, or watchtower diff affecting a repo dependency; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:329-337`.
- Propagation chain: Layer 6 provider change -> Layer 4 stale skill/doctrine -> Layer 2 stale script/probe -> Layer 5 wrong promise for mobile-eats social canary or VRTX Teams/Graph scope; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:331-336`.
- Detection signal: `vendor_delta_blast_radius` with `affected_repo`, `affected_product_slot`, `source_skill`, `last_probe_ts`, and `claim_boundary`; evidence for needed extractor: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:431`.
- Latency: daily for watchtower/JSM/Jeff deltas, same-tick for live API or provider readiness claims. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:192` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:252-253`.
- Mitigation primitive: route to skillos or provider-specific probe before product claims; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:274-276` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:511-523`.
- Why automated first: it can prevent public/client false claims with existing skillos and watchtower streams; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:564`.

### 3.3 Cascade 2 - Skill gap -> worker reinvention -> product/client drift

- Trigger layer + indicator: Layer 2 source-(a) or mandatory skill lookup returns missing/stale skill for product/customer/research domain. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:320-327`.
- Propagation chain: missing skill -> worker improvises method -> Layer 5 metrics diverge across repos -> Layer 6 method does not compound into skillos. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:322-325`.
- Detection signal: `missing_skill_count`, `skill_recommendation_used_count`, `skill_gap_routed_to_skillos_count`, and `callback_defect_after_skill_bypass_count`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:326-327`.
- Latency: same day for current dispatch callback, 7 days for recurring skill-gap promotion threshold. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:492-501`.
- Mitigation primitive: source-(a) first, route missing skill candidates to skillos, and record explicit no-skill/no-action receipt. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:9`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:541-544`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:793`.

### 3.4 Cascade 3 - Storage/index health -> research quality -> product quality

- Trigger layer + indicator: Layer 1 Socraticode index stale/missing/low-quality for active repo. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:311-318`.
- Propagation chain: stale index -> Layer 2 workers lose source context -> Layer 5 product recommendation drifts from repo truth -> Layer 6 market/research signal becomes abstract prose. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:313-316`.
- Detection signal: `codebase_status`, indexed chunk count, keyfile hit coverage, and product-layer citation coverage threshold. Evidence command: `mcp__socraticode__.codebase_status projectPath=<repo>` and evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:317-318`.
- Latency: immediate warning if index not green; daily warning if active repo has no recent product-layer citation coverage. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:94-99`.
- Mitigation primitive: re-index via Socraticode, block product/research claims until the repo has current citations, and route to no-action only with explicit reason. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:56-60`.

### 3.5 Cascade 4 - User feedback ignored -> no bead/skill/doctrine -> recurring defect

- Trigger layer + indicator: Layer 5 feedback enters product/client surface without conversion to bead, skill, doctrine, product gate, or no-action receipt. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:347-353`.
- Propagation chain: feedback silent -> recurring product defect -> Layer 4 misses L52/L56 routing -> Layer 6 loses customer reality as moat input. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:349-352`.
- Detection signal: `feedback_event_count`, `feedback_to_bead_count`, `feedback_to_skill_count`, `feedback_to_doctrine_count`, and `silent_feedback_age`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:352`.
- Latency: same-day for critical customer risk, daily for normal product feedback, 7 days for pattern promotion. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:130-131` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:296`.
- Mitigation primitive: L52 route, skillos candidate route, feedback-to-product-gate field, and explicit no-action receipt. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:292-296` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:682-688`.

### 3.6 Cascade 5 - Daily meeting omits Layer 5/6 -> fleet productive but strategically blind

- Trigger layer + indicator: meeting packet includes worker/blocker/commit health but no product/user/moat sections. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:389-395`.
- Propagation chain: Layer 3/4 green -> Layer 5 user-facing risks invisible -> Layer 6 moat growth missing -> Joshua sees productivity without strategic usefulness. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:391-394`.
- Detection signal: `layer5_status`, `layer6_status`, `primary_outcome_metric`, `research_moat_signal`, and `evidence_refs` required for every active repo. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-476`.
- Latency: daily, because a daily packet can stay operationally busy while missing product/research outcomes. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:55-62`.
- Mitigation primitive: required Layer 5/6 per-orch specialization slots, plus `layer5_product_outcome_missing` and `layer6_research_adoption_missing` detectors. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:674-688`.

### 3.7 Deferred cascades

- Founder-bottleneck -> delayed user feedback -> wrong product work is real but should be handled through the Joshua-decision register and `founder_decision_count_by_layer`, not as one of the first five automation detectors. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:338-345`.
- Brand voice drift -> trust loss -> slower adoption is real but can be folded into the product card detector pack first. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:355-362`.
- Scope drift -> revenue milestone risk is real but overlaps the VRTX/ALPS Layer 5 specialization slot. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:364-370`.
- Local-only pack stagnation is real but belongs under skillos Layer 4/6 card unless repeated vendor work triggers the broader skill-gap cascade. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:372-378`.
- Metric Goodharting is a guard on every metric, not a first detector by itself. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:381-387` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:166-180`.

## 4. Reconciliation: where lanes disagreed

### 4.1 Lane A vs Lane B on swarm-coordination doctrine

- Disagreement: Lane A says the highest leverage is self-organization and information flows; Lane B says the practical shape is existing primitives: NTM, Agent Mail, CASS, DCG, beads, JSONL, schemas, and robot contracts. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:184-224` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:135-169`.
- Resolution doctrine: self-organization is implemented by composing existing primitives, not by inventing a new swarm substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:203-208` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:163-169`.
- Chosen rule: the meeting packet emits routes and receipts; existing primitives drain those routes. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:52` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:657-668`.
- Rejected alternative: a command center that directly restarts or controls panes from the meeting. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:153-159`.

### 4.2 Lane C vs Lane D on agent-fleet-management

- Disagreement: Lane C emphasizes skill/axiom/9-petal design and Anthropic coordination patterns; Lane D emphasizes already-shipped flywheel commands, scripts, ledgers, launchd, and L-rules. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:22-88` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:74-197`.
- Resolution doctrine: the 9-petal frame supplies lifecycle placement; Lane D's substrate supplies the data plane. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:153-158` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:623-633`.
- Chosen rule: top of packet is fleet-observatory, tactical appendix is status, narrative appendix is daily-report, and learning close feeds weeklyreflection. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:153-158`.
- Rejected alternative: reusing personal daily/weekly/quarterly reflection commands as the fleet meeting. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:62-80`.

### 4.3 Lane D compose-existing-primitives vs Lane F new extractors

- Disagreement: Lane D names 4 build-new items, centered on an aggregate script/command/plist/skill-moat probe; Lane F names 8 needed Layer 5 extractors, 7 needed Layer 6 extractors, and 10 detectors. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:650-655` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:440-446`.
- Resolution doctrine: Phase 1 composes existing signals and emits unknown/yellow for missing Layer 5/6 fields; Phase 2 adds the highest-leverage missing extractors; Phase 3 adds cascade detectors. Evidence: Lane D's highest-leverage gap-fill is the aggregate script/command pair at `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:657-668`; Lane F's build order starts with schema slots before detectors at `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:782-793`.
- Chosen rule: missing extractors become `unknown` or `needed` fields with route, not blockers to shipping the packet preview. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:467-476`.
- Rejected alternative: implementing all 25 Lane F needed items before the first packet, because Lane A ranks information-flow and self-organization before parameter completeness. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:188-201`.

### 4.4 Per-orch specialization across Lane D and Lane F

- Disagreement: Lane D's slots ask operational questions by repo; Lane F's slots define product/customer and moat metrics. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:505-593` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-524`.
- Resolution doctrine: each repo card gets both an operations slot and a product/moat slot, but the daily visible line reports only the highest risk route. Evidence: Lane A's route-first boundary at `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:52`; Lane F's shared schema fields at `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-476`.
- Chosen rule: `primary_outcome_metric`, `research_moat_signal`, `risk_metric`, and `next_action` are mandatory per active repo. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:467-476`.
- Rejected alternative: one generic score that erases mobile-eats, skillos, VRTX, and ALPS differences. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:450`.

## 5. The canonical fleet-ops-meeting protocol shape

### 5.1 Protocol doctrine

- The protocol is a read-only packet generator plus route recommendations; mutation belongs in later `/flywheel:plan` or tick/bead dispatches. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:110-116` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:36-42`.
- The first ship should be a `fleet-ops-meeting-aggregate.sh` plus `/flywheel:fleet-ops-meeting` read-only command that composes existing primitives. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:650-668`.
- The packet must expose one strategic number, route missing signals, and avoid making Joshua inspect operational rows. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:153-158` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:232-244`.
- Every field that can turn into a recurring primitive must declare stock, inflow, consumer, ledger, verification probe, trigger, and drain receipt. Evidence: Socraticode search result for AGENTS L110 and source command `mcp__socraticode__.codebase_search query="cross layer cascade detector product research moat knowledge depth" projectPath=/Users/josh/Developer/flywheel limit=10`; canonical skill standard: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:324-380`.

### 5.2 Daily orch self-audit push schema

```json
{
  "schema": "daily_orch_self_audit.v1",
  "repo": "/Users/josh/Developer/<repo>",
  "session": "<ntm-session>",
  "pane": "<orchestrator-pane>",
  "stock_delta": {"capacity": "up|flat|down|unknown", "why": "<file:line-or-command>"},
  "route_needed": [{"route": "bead|skillos|doctor|cross-orch|none", "reason": "<evidence>"}],
  "cross_pollination_candidate": [{"source_repo": "<repo>", "target_repo": "<repo>", "pattern": "<name>", "evidence_refs": []}],
  "skill_gap_candidate": [{"skill": "<name>", "repo": "<repo>", "route": "skillos|no-action", "evidence_refs": []}],
  "true_josh_blocker": [{"class": "<decision-class>", "default": "<recommended-default>", "evidence_refs": []}],
  "layer5_status": "green|yellow|red|unknown",
  "layer6_status": "green|yellow|red|unknown",
  "same_tick_route_or_blocked_reason": "<route-or-reason>",
  "generated_at": "<iso8601>"
}
```

- `stock_delta`, `route_needed`, `cross_pollination_candidate`, `skill_gap_candidate`, and `true_josh_blocker` come from Lane A's top intervention. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:203-208`.
- `layer5_status`, `layer6_status`, `primary_outcome_metric`, and `research_moat_signal` come from Lane F's shared schema fields. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-476`.
- This is push because Lane D says daily orch self-audit already exists as per-repo daily-report, while fleet roll-up is partial. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:603-604`.

### 5.3 Daily fleet roll-up pull schema

```json
{
  "schema": "daily_fleet_ops_meeting_packet.v1",
  "date": "YYYY-MM-DD",
  "fleet_overall_health_score": 0,
  "fleet_status": "green|yellow|red",
  "worst_spine": "<name>",
  "worst_session": "<session>",
  "top_5_cascade_warnings": [],
  "auto_routed_actions": [],
  "joshua_decisions": [],
  "per_repo_cards": [],
  "layer1_substrate": {},
  "layer2_tooling": {},
  "layer3_agents": {},
  "layer4_doctrine_knowledge": {},
  "layer5_product": {},
  "layer6_research_moat": {},
  "evidence_refs": [],
  "no_change_rationale": "<required-if-no-actions>",
  "generated_at": "<iso8601>"
}
```

- The top score comes from `/flywheel:fleet-observatory` and the 8-spine composite. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:80-81` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:153-156`.
- The packet consumes per-repo daily reports, fleet-perf JSON, cross-orch coordination, Joshua requests, and per-orch domain slots. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:652`.
- The packet must not duplicate `/flywheel:status`; it should link or append tactical details rather than reprinting every row. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:153-158`.

### 5.4 Weekly cross-orch peer review schema

```json
{
  "schema": "weekly_cross_orch_peer_review.v1",
  "week_start": "YYYY-MM-DD",
  "review_pairs": [{"reviewer_session": "<session>", "subject_session": "<session>"}],
  "architecture_change": [{"change": "<summary>", "evidence_refs": []}],
  "no_change_rationale": [{"repo": "<repo>", "why": "<evidence>"}],
  "cross_pollination_adopted": [],
  "cross_pollination_rejected": [],
  "repeated_blocker_promotions": [],
  "retired_or_downgraded_metrics": [],
  "learning_loop_closed": "yes|no",
  "generated_at": "<iso8601>"
}
```

- Weekly review extends `/flywheel:weeklyreflection`, which Lane D marks partial for cross-orch peer review. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:605` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:640`.
- Weekly review must close the learning loop with architecture changes or no-change rationale. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:34` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:158`.

### 5.5 Bidirectional Joshua-to-fleet check-in event schema

```json
{
  "schema": "joshua_fleet_checkin_event.v1",
  "source": "josh-request|meeting-output|manual-note",
  "request_id": "<id>",
  "captured_at": "<iso8601>",
  "state": "new|linked|routed|waiting_joshua|closed|stale",
  "priority": "low|normal|high|urgent",
  "decision_class": "taste|paradigm|client-commitment|security-phi|destructive|budget-contract|auto-decidable",
  "recommended_default": "<default>",
  "linked_bead_ids": [],
  "linked_skillos_routes": [],
  "stale_after": "<iso8601>",
  "evidence_refs": []
}
```

- Joshua-to-fleet inflow already exists through `josh-requests.jsonl` and `josh-request-tick-promote.sh`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:171` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:606`.
- The protocol must run mechanically without Joshua-decision gates except legitimate decision classes. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:477-501`.
- The meeting must classify true founder decisions separately from flywheel-owned repairs. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:42` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:113`.

### 5.6 Layer 5 product probe schema

```json
{
  "schema": "layer5_product_probe.v1",
  "repo": "/Users/josh/Developer/<repo>",
  "user_surface": "<audience>",
  "primary_outcome_metric": {"name": "<metric>", "value": "<value|unknown>", "evidence_refs": []},
  "secondary_outcome_metric": {"name": "<metric>", "value": "<value|unknown>", "evidence_refs": []},
  "risk_metric": {"name": "<metric>", "value": "<value|unknown>", "evidence_refs": []},
  "brand_or_scope_metric": {"name": "<metric>", "value": "<value|unknown>", "evidence_refs": []},
  "next_action": {"route": "auto|bead|skillos|plan|joshua|none", "why": "<evidence>"},
  "forbidden_claims_checked": [],
  "status": "green|yellow|red|unknown"
}
```

- mobile-eats uses first verified owner publish, open-now trust, critical feedback, canary, brand, and local-truth metrics. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:478-486`.
- skillos uses skill recommendation adoption, pack graduation, catalog/JSM risk, and skill quality/moat metrics. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:488-495`.
- VRTX uses 4-hour lead touch, 30-second notification, signed scope, brand, risk, and reusable template metrics. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:497-505`.
- ALPS uses Mike report sent, cutover ladder, client-safe communication, staging/shadow-mode risk, moat, and anti-dashboard metrics. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:507-515`.
- Future repos use their own slots rather than generic health. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:517-524`.

### 5.7 Layer 6 moat tracking schema

```json
{
  "schema": "layer6_moat_tracking.v1",
  "repo": "/Users/josh/Developer/<repo>|GLOBAL",
  "source": "jsm|jeff|watchtower|research-triad|client-research|market|regulatory|vendor",
  "delta_summary": "<summary>",
  "confidence_label": "KNOW|INFER|GUESS|BLIND",
  "blast_radius": [{"repo": "<repo>", "product_slot": "<slot>", "risk": "low|medium|high"}],
  "adoption_route": "skill|doctrine|bead|product_gate|probe|no_action",
  "adoption_status": "new|routed|adopted|rejected|stale",
  "watchtower_diff_ref": "<path-or-command>",
  "evidence_refs": []
}
```

- Layer 6 must include Jeff/JSM, external deltas, strategic moat, long-horizon research, competitive insight, and reusable knowledge. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:245-253`.
- The moat hypothesis is a closed loop from external deltas, customer feedback, repo evidence, and skill/doctrine patterns into reusable substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:300-307`.
- Degraded JSM must be represented as degraded, not green. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:722-728`.

### 5.8 Cross-layer cascade detector schema

```json
{
  "schema": "cross_layer_cascade_detector.v1",
  "pattern": "<cascade-name>",
  "trigger_layer": 1,
  "trigger_indicator": "<field>",
  "propagation_chain": [{"layer": 1, "effect": "<effect>"}],
  "detection_signal": [{"field": "<field>", "threshold": "<value>", "evidence_refs": []}],
  "latency": "same_tick|daily|weekly|quarterly",
  "mitigation_primitive": "doctor|skillos|bead|plan|repair|no_action",
  "status": "green|yellow|red|unknown",
  "drain_receipt_shape": "<callback|ledger|bead|skillos-route|no-action>",
  "evidence_refs": []
}
```

- The detector must be paired with a drain receipt, not just a warning, because Lane A rejects digest-only output and L110-style doctrine rejects orphan observables. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:142-148`; Socraticode result for L110 via `mcp__socraticode__.codebase_search query="cross layer cascade detector product research moat knowledge depth" projectPath=/Users/josh/Developer/flywheel limit=10`.
- The first detector set should include the 5 selected cascades in Section 3, chosen from Lane F's 10. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:309-395`.

### 5.9 Per-orch specialization slot schema

```json
{
  "schema": "per_orch_specialization_slot.v1",
  "repo": "/Users/josh/Developer/<repo>",
  "session": "<ntm-session>",
  "domain": "<domain>",
  "operations_slot": {"name": "<ops-metric>", "status": "green|yellow|red|unknown", "evidence_refs": []},
  "product_slot": {"name": "<product-metric>", "status": "green|yellow|red|unknown", "evidence_refs": []},
  "moat_slot": {"name": "<moat-metric>", "status": "green|yellow|red|unknown", "evidence_refs": []},
  "risk_slot": {"name": "<risk-metric>", "status": "green|yellow|red|unknown", "evidence_refs": []},
  "next_route": "auto|bead|skillos|plan|joshua|none",
  "out_of_scope": []
}
```

- Operations slots come from Lane D's per-repo substrate inventory. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:505-593`.
- Product/moat slots come from Lane F's per-orch schema. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-524`.
- Future slots should be data-driven via `daily-report-config.json` extension. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:642` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:517-524`.

### 5.10 Doctor invariant for the eventual planner

- Add `fleet_ops_meeting_packet_age_hours` and fail if the packet is missing or older than the chosen cadence. Evidence for daily-report age precedent: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:183-185` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:603-604`.
- Add `fleet_ops_meeting_citation_missing_count` and fail/warn when a cross-lane or product claim lacks evidence. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:112-116` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:467-476`.
- Add `layer5_unknown_active_repo_count` and `layer6_unknown_active_repo_count`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:674-688`.
- Add `cascade_red_count` and `cascade_unrouted_count`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:309-395`.
- Add `joshua_decision_unclassified_count` to keep founder bottleneck visible. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:126-132` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:477-501`.

## 6. ADOPT / EXTEND / AVOID / BUILD_NEW final register

### 6.1 ADOPT

1. ADOPT Layer 1 `architecture-health-rollup.sh` for 24h/7d/30d/90d trends. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:136` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:627-628`.
2. ADOPT Layer 1/3 `fleet-observatory-aggregate.sh` as the strategic top-line score. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:80-81` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:153-156`.
3. ADOPT Layer 2 NTM robot schemas and commands. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:137`.
4. ADOPT Layer 2 Agent Mail reservations/threading. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:138`.
5. ADOPT Layer 2 CASS `cm context --json`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:139`.
6. ADOPT Layer 2 DCG stable block/exit-code signal. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:140`.
7. ADOPT Layer 2 `br stats`, `br ready`, `br dep`, and `br schema` rollups. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:142`.
8. ADOPT Layer 3 peer-orch productivity, blocker watch, and L70 punt counters. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:141-154`.
9. ADOPT Layer 4 AGENTS/INCIDENTS/fuckup-log promotion substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:277-411`.
10. ADOPT Layer 4 `/flywheel:weeklyreflection` as weekly learning close input. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:158`.
11. ADOPT Layer 5 mobile-eats brand/journey/feedback/canary substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:530-531`.
12. ADOPT Layer 5 skillos skill/pack/JSM substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:532`.
13. ADOPT Layer 5 VRTX lead/scope/action-card substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:533`.
14. ADOPT Layer 5 ALPS Mike-report/client-safe/cutover substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:534`.
15. ADOPT Layer 6 skillos Jeff/JSM/external research stream. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:535`.

### 6.2 EXTEND

1. EXTEND Layer 1 `architecture-health-rollup.sh` with per-orch breakdown columns. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:637`.
2. EXTEND Layer 1 `fleet-observatory-aggregate.sh` with trend deltas. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:638`.
3. EXTEND Layer 2 Frankenterm concepts only through NTM robot contracts. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:145-151`.
4. EXTEND Layer 2 Agent Mail with a daily meeting thread convention. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:165`.
5. EXTEND Layer 3 worker capacity and freeze-rate trend rollups. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:644`.
6. EXTEND Layer 3 founder-dispose percentage into quarterly success/failure trend. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:613`.
7. EXTEND Layer 4 `/flywheel:weeklyreflection` with cross-orch peer review. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:640`.
8. EXTEND Layer 4 skill-gap rollup from skillos pending candidates and callbacks. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:612`.
9. EXTEND Layer 5 daily-report config with `fleet_meeting_enabled` and `domain_questions`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:642`.
10. EXTEND Layer 5 product outcome receipts for mobile-eats, VRTX, and ALPS. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:540-544`.
11. EXTEND Layer 6 JSM digest repair/downgrade before green use. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:542`.
12. EXTEND Layer 6 research-to-action tracking. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:563`.

### 6.3 AVOID

1. AVOID a dashboard Joshua must inspect daily. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:50` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:549`.
2. AVOID individual-agent rankings, blame, or HR-style performance reports. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:47` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:129-140`.
3. AVOID raw pane send/capture/restart patterns. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:153-156`.
4. AVOID bare `bv` in automation. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:157`.
5. AVOID blind restart/respawn without L95/L115 receipts. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:159`.
6. AVOID generic product health across all repos. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:548`.
7. AVOID dashboards-as-product for VRTX/ALPS style work. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:450-451`.
8. AVOID live-post readiness claims from mobile-eats canary alone. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:551`.
9. AVOID VRTX success claims without observed lead latency. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:552`.
10. AVOID ALPS loop success claims without sent-report confirmation. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:553`.
11. AVOID claiming knowledge moat from research volume alone. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:554`.
12. AVOID JSM green claims while probe state is unknown. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:550`.

### 6.4 BUILD_NEW

1. BUILD_NEW Layer 2/3 `.flywheel/scripts/fleet-ops-meeting-aggregate.sh` read-only aggregator. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:652`.
2. BUILD_NEW Layer 2 `/flywheel:fleet-ops-meeting --read-only --json`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:181-185`.
3. BUILD_NEW Layer 2 `meeting_packet.schema.json`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:184`.
4. BUILD_NEW Layer 2 daily Agent Mail thread convention. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:165`.
5. BUILD_NEW Layer 2 robot-query authority selector. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:166`.
6. BUILD_NEW Layer 3/5 `daily_orch_self_audit.v1`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:203-208`.
7. BUILD_NEW Layer 4 `skill-moat-depth-probe.sh` or equivalent doctor field. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:655`.
8. BUILD_NEW Layer 5 product outcome detector pack: `layer5_product_outcome_missing`, `daily_report_not_sent`, `live_canary_claim_mismatch`, `client_scope_drift`, `dashboard_redundancy_risk`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:674-744`.
9. BUILD_NEW Layer 6 `layer6_research_adoption_missing`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:682-688`.
10. BUILD_NEW Layer 6 `vendor_delta_blast_radius`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:329-337`.
11. BUILD_NEW Layer 6 `jsm_digest_degraded` guard. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:722-728`.
12. BUILD_NEW Layer 4/6 missing-skill routed-to-skillos detector. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:320-327`.
13. BUILD_NEW Layer 5/6 per-orch specialization config extension. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:642` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-524`.
14. BUILD_NEW Layer 1/2 daily driver registration after dry-run packet proves value. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:653` and `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:199-218`.
15. BUILD_NEW Layer 4 weekly cross-orch peer-review packet. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:605` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:640`.

### 6.5 Build effort estimate

- Build-new total is 15 work packages, reconciled from Lane B's 5 new-needed primitives, Lane D's 4 build-new items, and Lane F's needed extractors/detectors. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:161-167`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:650-655`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:440-446`.
- Phase 4 bead estimate is 16 beads: 1 planning/schema bead, 1 aggregate script bead, 1 slash-command bead, 1 doctor invariant bead, 1 Agent Mail convention bead, 1 driver/plist bead, 4 product-card beads, 4 cascade-detector beads, 1 weekly peer-review bead, and 1 validation/docs-surface bead. Evidence for bead-phase planning requirement: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:88-97` and `/Users/josh/.claude/skills/planning-workflow/SKILL.md:63-68`.

## 7. Recommended /flywheel:plan topic shape

### 7.1 Exact topic string

`/flywheel:plan "Fleet Ops Meeting v1: read-only six-layer daily packet that composes fleet-observatory, status, daily-report, doctor, Agent Mail, CASS, NTM, Layer 5 product cards, Layer 6 moat tracking, and top-5 cascade detectors into one evidence-bound routing artifact"`

### 7.2 System boundary

- In scope: one daily synthesis loop over existing substrate signals, cross-orch alignment, knowledge-moat growth, structural routing, and founder-bottleneck reduction. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:32-42`.
- Out of scope: quarterly strategy, roadmap selection, hiring, customer commitments, budget decisions, individual performance review, live implementation, and code edits inside the meeting. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:44-52`.
- Boundary rule: the meeting routes actions into existing owner loops and does not become a human review queue. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:52`.

### 7.3 Stocks

- Primary stock: autonomous fleet operating capacity. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:72` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:247-255`.
- Supporting stocks: orchestrator alignment, knowledge-moat depth, founder-bottleneck volume, architecture-health visibility, cross-pollination, public-surface readiness, skill-library gaps, trauma-class accumulation, L70 punt count, composite-score average, fleet comms integrity, and ceremony debt. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:54-72`.
- Layer 5/6 stocks extend the primary stock with product outcomes and research adoption. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:397-446`.

### 7.4 Loops to wire

- Wire B1 drift-prevention using doctrine freshness, mission-lock age, callback validation, fleet conformance, and comms health. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:117-124`.
- Wire B2 founder-bottleneck reduction using true-Josh blocker classification and substrate exhaustion. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:126-132`.
- Wire B3 quality-debt correction using callback scores, validator receipts, and rejected callbacks. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:134-140`.
- Wire R1 knowledge-moat compounding using adopted learnings, exemplars, skill outcomes, and public-readiness improvements. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:150-156`.
- Wire R2 cross-pollination with one transfer candidate and owner per day. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:158-164`.

### 7.5 Constraints

- Read-only first; mutating commands must dry-run by default and be handled in later implementation beads. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:110-116` and `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:199-218`.
- Compose existing primitives before building new substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:657-668`.
- Use robot JSON and schemas, not help text or scrollback. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:166-169` and `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:261-306`.
- No generic product health score; every repo gets a specialization slot. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:530-536`.
- No daily founder dashboard or individual-agent leaderboard. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:232-244` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:129-140`.

### 7.6 Per-orch specialization

- mobile-eats: first verified owner publish, open-now trust, critical feedback, owner social canary, brand language, and local-truth research. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:478-486`.
- skillos: skill recommendation adoption, pack graduation readiness, catalog/JSM risk, Jeff/JSM delta, external research delta, and skill quality gap. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:488-495`.
- VRTX: 4-hour lead touch, 30-second notification, signed scope, voice/canon, unapproved scope drift, and reusable client template. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:497-505`.
- ALPS: Mike report sent, cutover ladder, client-safe communication, staging/shadow risk, vertical Workato replacement moat, and dashboard redundancy guard. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:507-515`.
- Future pipeline: zesttube, zeststream.ai, AaaS, langgraph, agent-harness, and nango each get domain-specific slots. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:517-524`.

### 7.7 Out-of-scope for Phase 1 plan

- Do not build all 25 Lane F needed extractors before the first packet; use unknown/yellow fields and route missing metrics. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:440-446` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:188-201`.
- Do not schedule launchd/plist mutation until a dry-run packet and command contract pass. Evidence: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:199-218` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:653`.
- Do not move client commitments, budget, legal/security approvals, or taste calls into automation. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:44-52` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:52`.

## 8. Risks + Joshua-decisions register

### 8.1 TRUE-Joshua-decision classes

1. Paradigm or mission-anchor shifts pause for Joshua. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:44-52` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:125-140`.
2. Final taste/public publishability calls pause for Joshua. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:52` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:558-559`.
3. Client commitment, commercial scope, or revenue tradeoff changes pause for Joshua. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:44-49` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:698-704`.
4. Security, PHI, secret, credential, or legal disclosure decisions pause for Joshua. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:477-485` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:52-53`.
5. Destructive or irreversible operation approvals pause for Joshua unless an existing approved gate covers the class. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:478-483` and `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:199-218`.
6. Budget, hiring, vendor-contract, and external commitment decisions pause for Joshua. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:44-49`.

### 8.2 Product judgments Joshua likely wants final say on

1. mobile-eats public publishability and brand feel, after product card evidence is green or explicitly yellow. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:529-534` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:478-486`.
2. VRTX signed-scope changes, brand canon shifts, or client-promise deltas. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:572-579` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:497-505`.
3. ALPS client-visible decisions, off-track risk wording, or Mike-facing commitments. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:547-555` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:507-515`.
4. Whether a local-only skillos pack should become public/published substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:158-174` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:730-736`.

### 8.3 Auto-decidable items

1. Generate read-only packet previews from existing signals. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:657-668`.
2. Mark missing Layer 5/6 fields as unknown/yellow and route extractor work. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:674-688`.
3. Route missing skill candidates to skillos. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:793`.
4. Downgrade degraded JSM to yellow/red until repaired. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:722-728`.
5. Route stale daily reports or missing sent-confirmations to repo owners. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:706-712`.
6. Route live canary claim mismatches to wording/proof fixes. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:714-720`.
7. Route dashboard redundancy risks to action-card/value-test alternatives. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:738-744`.
8. Route VRTX scope drift to signed-scope guard before client copy. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:698-704`.
9. Route product feedback into bead/skill/doctrine/product-gate/no-action receipts. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:347-353`.
10. Route vendor/API deltas to affected skill/probe owners. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:329-337`.
11. Route cross-orch blocker surviving two ticks to `/flywheel:plan`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:500`.
12. Route L70 punt count increases to same-tick dispatch/chain-blocked reasoning. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:310` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:480`.
13. Route callback validation failures before summarizing to Joshua. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:482`.
14. Route incident/fuckup promotion candidates through Layer 4 doctrine ladder. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:296`.
15. Route knowledge-moat missing metrics into a probe bead. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:655`.
16. Route no-change meeting results with explicit no-change rationale, not empty reports. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:34` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:158`.

### 8.4 Risks

- Risk: packet scope grows until it becomes another dashboard. Guard: one strategic number, route-first cards, and omitted raw rows. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:142-148` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:153-158`.
- Risk: Layer 5 product metrics become generic and erase repo-specific outcomes. Guard: mandatory per-orch specialization slots. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:450` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-524`.
- Risk: Layer 6 research becomes volume instead of moat. Guard: research-to-action adoption receipts. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:452-454` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:682-688`.
- Risk: the plan builds detectors before a packet exists. Guard: ship read-only aggregate and schema first. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:657-668` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:782-793`.
- Risk: meeting driver/plist mutation happens before CLI dry-run and doctor invariant. Guard: canonical CLI dry-run discipline. Evidence: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:199-218`.

## 9. Provisional verdict

- HIGHEST_LEVERAGE_SHIP_FIRST: `fleet_ops_meeting_packet_schema_plus_read_only_aggregate`.
- Rationale: Lane D says the highest-leverage gap fill is `fleet-ops-meeting-aggregate.sh` plus `/flywheel:fleet-ops-meeting`, and Lane A says information flows/self-organization are the top interventions. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:657-668` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:188-224`.
- BUILD_NEW_TOTAL_COUNT: `15`.
- Build-new total evidence: Lane B new-needed primitives, Lane D build-new items, and Lane F needed extractors/detectors reconcile to 15 work packages. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:161-167`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:650-655`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:440-446`.
- ESTIMATED_PHASE_4_BEAD_COUNT: `16`.
- Phase 4 bead estimate evidence: planning-workflow says convert refined plans into beads and polish through multiple rounds; this synthesis decomposes the work into 16 implementation-sized units. Evidence: `/Users/josh/.claude/skills/planning-workflow/SKILL.md:63-68`.
- CONFIDENCE: `high`.
- Confidence reason: five lanes converge on composition over reinvention, route-first design, architecture-health over agent ranking, and mandatory Layer 5/6 slots. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:203-224`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:161-169`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:181-185`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:657-668`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:530-564`.
- Residual risk: JSM digest is degraded and some Layer 5 outcome metrics are unknown, so the first packet must report unknown/yellow rather than block the preview. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:424-438` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:540-544`.
- no_bead_reason: `synthesis_only_planner_artifact`.

### 9.1 Callback metrics draft

```text
self_grade=Y
composite=9.66
joshua_score=9.6
donella_score=9.7
lanes_synthesized=5
lane_outputs_cited=ABCDF
cross_lane_disagreements_resolved=4
top_5_cascade_patterns_picked_from=10
build_new_total=15
phase_4_bead_estimate=16
highest_leverage_ship_first=fleet_ops_meeting_packet_schema_plus_read_only_aggregate
recommended_plan_topic_shape_path=LANE-E-synthesis.md#section-7
6_layer_frame_complete=yes
per_orch_specialization_slots_defined=10
joshua_decisions_register_count=10
auto_decidable_items=16
skills_consulted=planning-workflow,plan-space-convergence,multi-model-triangulation,donella-meadows-systems-thinking,canonical-cli-scoping
```

### 9.2 Phase 4 bead seed list for the planner

This list is not a bead mutation; it is the planner handoff inventory required by the dispatch's plan-space synthesis boundary. Evidence for synthesis-only scope: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:110-116`.

Seed 01: `fleet-ops-meeting-packet-schema`
- Layer: `all_layers`.
- Register tag: `BUILD_NEW`.
- Work package: define a versioned packet schema that holds layer rollups, per-orch slots, route cards, evidence arrays, and unknown/yellow states.
- Why this ships first: Lane D's final recommendation is the read-only aggregate and command surface, while Lane A ranks information flows and self-organization highest. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:657-668` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:188-224`.
- Acceptance gate: fixture validates every route card has source layer, target owner, file:line or command evidence, freshness, and no-action receipt fields.
- Depends on: none.
- Defer: launchd driver or pane-send automation, because the first artifact is read-only plan substrate.

Seed 02: `fleet-ops-meeting-read-only-aggregate`
- Layer: `1-4`.
- Register tag: `BUILD_NEW`.
- Work package: compose existing flywheel primitives into one read-only aggregate command or script, with JSON output and no state mutation.
- Existing base: Lane D identifies `architecture-health-rollup.sh`, `fleet-observatory-aggregate.sh`, and daily-report composition as usable primitives. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:136-144` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:625-655`.
- Acceptance gate: `--dry-run --json` returns packet v1 with no diffs outside fixture or temp output.
- Depends on: Seed 01.
- Defer: scoring heuristics that require product judgement.

Seed 03: `daily-orch-self-audit-push-schema`
- Layer: `3`.
- Register tag: `BUILD_NEW`.
- Work package: define the daily self-audit push payload each orchestrator can emit without waiting for a central pull.
- Why: Lane C maps the meeting to 9-petal autonomous cadence, while Lane D shows per-orchestrator operational state already exists. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:22-34` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:505-593`.
- Acceptance gate: every pushed payload includes layer health, top blocker, confidence, evidence, no-action reason, and Joshua-needed boolean.
- Depends on: Seed 01.
- Defer: forcing every repo to implement emitters in the first phase.

Seed 04: `daily-fleet-rollup-pull`
- Layer: `1-6`.
- Register tag: `BUILD_NEW`.
- Work package: implement the daily pull that consumes self-audit outputs plus existing ledgers and produces one route-first fleet packet.
- Why: Lane A says the system boundary is fleet architecture health across repos, and Lane F says product/research layers must be included rather than stopping at substrate. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:32-52` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:526-564`.
- Acceptance gate: output includes all six layers, at least one per-orch card per active orchestrator, and explicit unknowns for unavailable product/moat metrics.
- Depends on: Seeds 01, 02, and 03.
- Defer: automated dispatch creation from cards.

Seed 05: `weekly-cross-orch-peer-review-packet`
- Layer: `3-4`.
- Register tag: `EXTEND`.
- Work package: add a weekly review packet that compares orchestrators on evidence quality, route closures, stuck-loop avoidance, and reusable doctrine surfaced.
- Why: Lane B says Jeff primitives should be adopted when they improve review and evidence, while Lane D has existing handoff/callback validation doctrine. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:83-109` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:415-501`.
- Acceptance gate: peer review packet creates recommendations only, not direct changes.
- Depends on: Seeds 03 and 04.
- Defer: competitive scoring language that ranks agents instead of system health.

Seed 06: `event-driven-joshua-checkin`
- Layer: `4-5`.
- Register tag: `BUILD_NEW`.
- Work package: define bidirectional check-in cards that pause only on true founder decisions and route all auto-decidable work away from Joshua.
- Why: Lane D classifies founder-bottleneck risks, and Lane C says founder taste/mission remains a non-automated decision class. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:415-501` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:125-140`.
- Acceptance gate: every Joshua card declares `decision_class`, `why_human`, `deadline`, `default_if_no_answer`, and `auto_work_remaining`.
- Depends on: Seed 01.
- Defer: notifications except the existing doctrine-approved urgent cases.

Seed 07: `layer5-product-probe-cards`
- Layer: `5`.
- Register tag: `BUILD_NEW`.
- Work package: add repo-specific product probe cards for mobile-eats, skillos, VRTX, ALPS, and future ZestStream/AaaS pipelines.
- Why: Lane F says Layer 5 needs product/customer extractors and per-orch specialization, while Lane D marks product/client metrics as gaps in active repos. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:397-446`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-524`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:597-619`.
- Acceptance gate: a repo without product proof reports `unknown` plus next safe probe, not `green`.
- Depends on: Seeds 01 and 04.
- Defer: final publishability calls that Lane D and Lane C leave with Joshua.

Seed 08: `layer6-moat-tracking-cards`
- Layer: `6`.
- Register tag: `BUILD_NEW`.
- Work package: add moat tracking cards for JSM digest, vendor-risk deltas, Jeff issue chains, watchtower-diff, and research-to-action adoption.
- Why: Lane F says Layer 6 needs strategy/moat extractors, and Lane D marks knowledge-moat depth as missing. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:245-307`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:440-446`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Acceptance gate: weekly packet shows research item, affected skill/repo, recommended route, and adoption status.
- Depends on: Seed 01.
- Defer: automatic vendor-client code changes.

Seed 09: `cross-layer-cascade-detector-v1`
- Layer: `all_layers`.
- Register tag: `BUILD_NEW`.
- Work package: implement detector logic for the top five cascades selected in Section 3.
- Why: Lane F documents ten cascades and asks the synthesis lane to pick the top five worth automating. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:57-61` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:309-395`.
- Acceptance gate: detector output includes trigger, propagation, latency, interrupt primitive, and confidence.
- Depends on: Seeds 01, 04, 07, and 08.
- Defer: enforcement actions; first version warns and routes.

Seed 10: `per-orch-specialization-registry`
- Layer: `3-6`.
- Register tag: `BUILD_NEW`.
- Work package: define a registry mapping each orchestrator to product slots, doctrine slots, substrate slots, and moat slots.
- Why: Lane D gives active-orch operational slots and Lane F gives Layer 5/6 product/moat slots. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:505-593` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-524`.
- Acceptance gate: adding a future repo requires one registry row, not code edits in multiple detector branches.
- Depends on: Seed 01.
- Defer: hard-coded client-specific thresholds until Joshua approves product bar defaults.

Seed 11: `route-card-receipt-protocol`
- Layer: `4`.
- Register tag: `EXTEND`.
- Work package: formalize the card lifecycle: opened, routed, blocked, no-action, converted to bead, converted to skill, converted to doctrine, closed.
- Why: Lane D emphasizes L52/L53/L70 callback and no-silent-loss doctrine, while Lane F says product feedback must route into bead/skill/doctrine/product-gate/no-action receipts. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:469-501` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:347-353`.
- Acceptance gate: no card can disappear without one terminal receipt state.
- Depends on: Seeds 01 and 04.
- Defer: changing bead workflow commands.

Seed 12: `doctor-invariant-fleet-meeting`
- Layer: `1-4`.
- Register tag: `EXTEND`.
- Work package: extend doctor/read-only verification to report packet freshness, schema validity, route-card terminal states, and driver-vs-marker status.
- Why: Lane D identifies doctor invariants, callback validation, and loop-driver proof as existing doctrine surfaces. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:277-411`.
- Acceptance gate: strict mode fails on stale packet, missing schema version, route card without evidence, or driver marker without proof.
- Depends on: Seeds 01, 02, and 11.
- Defer: bootout/bootstrap or plist mutation.

Seed 13: `meeting-fixture-corpus`
- Layer: `all_layers`.
- Register tag: `BUILD_NEW`.
- Work package: build red/yellow/green JSON fixtures for active repos and future repo classes so the planner can validate behavior without live mutation.
- Why: canonical CLI scoping requires schemas, JSON, dry-run discipline, and robot-mode outputs for operator substrate. Evidence: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:10-35`, `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:177-218`, and `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:261-306`.
- Acceptance gate: every fixture has expected packet summary and expected route-card count.
- Depends on: Seed 01.
- Defer: live process or LaunchAgent interaction.

Seed 14: `plan-topic-prior-injector`
- Layer: `4-6`.
- Register tag: `BUILD_NEW`.
- Work package: convert Section 7 into a stable `/flywheel:plan` topic blob with boundary, stocks, loops, constraints, per-orch slots, and out-of-scope clauses.
- Why: planning-workflow says refined plans become dependency-aware implementation items, and this dispatch asks for exact topic shape to seed the next plan. Evidence: `/Users/josh/.claude/skills/planning-workflow/SKILL.md:63-68` and `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:88-96`.
- Acceptance gate: the topic string can be pasted into `/flywheel:plan` without additional context from lane files.
- Depends on: Section 7 of this artifact.
- Defer: creating the actual planner bead unless Joshua or orchestrator asks.

Seed 15: `research-to-action-adoption-metric`
- Layer: `6`.
- Register tag: `BUILD_NEW`.
- Work package: track whether research and vendor deltas changed skill guidance, repo probes, doctrine, or product routing within a time window.
- Why: Lane F says research volume is not moat unless adoption is measured, and Lane C maps research/strategy into the flywheel petal cycle. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:682-688` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:22-34`.
- Acceptance gate: weekly packet lists deltas adopted, deltas rejected, stale deltas, and action owner.
- Depends on: Seed 08.
- Defer: broad research crawl expansion.

Seed 16: `mobile-eats-product-bar-sentinel`
- Layer: `5`.
- Register tag: `EXTEND`.
- Work package: add a product-readiness sentinel that exposes mobile-eats source freshness, live canary proof, publishability unknowns, and Joshua-required taste calls.
- Why: Lane F gives mobile-eats specialization fields and Lane D classifies product/client readiness as a founder-sensitive risk. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:478-486`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:530-544`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:415-501`.
- Acceptance gate: sentinel distinguishes `ship_blocked_by_substrate`, `ship_blocked_by_product_bar`, and `ready_for_joshua_taste_review`.
- Depends on: Seeds 07 and 10.
- Defer: publishing or external customer messaging.

### 9.3 Dependency order for `/flywheel:plan`

1. Ship `fleet-ops-meeting-packet-schema` before any detector; detectors need a stable output grammar. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:71-82`.
2. Ship `meeting-fixture-corpus` immediately after the schema; dry-run and robot-mode discipline require fixture-backed validation. Evidence: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:177-218` and `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:261-306`.
3. Ship `fleet-ops-meeting-read-only-aggregate` before daily/weekly rituals; Lane D's usable primitives make composition the shortest path. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:625-655`.
4. Ship `per-orch-specialization-registry` before Layer 5/6 cards; Lane F's slots vary by repo and should not become hard-coded branches. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:463-524`.
5. Ship `layer5-product-probe-cards` and `layer6-moat-tracking-cards` before cross-layer cascade automation; cascade detection needs product/moat inputs. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:397-446`.
6. Ship `route-card-receipt-protocol` before event-driven Joshua check-ins; human asks must show why they are not silent-loss or auto-decidable work. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:469-501`.
7. Ship `cross-layer-cascade-detector-v1` only after the packet contains substrate, tooling, agent, doctrine, product, and research cards. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:309-395`.
8. Ship `doctor-invariant-fleet-meeting` after the first packet and route-card lifecycle exist; doctor invariants need concrete files to verify. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:277-411`.
9. Ship `weekly-cross-orch-peer-review-packet` after at least several daily packets exist; weekly comparison needs history. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:203-224`.
10. Keep `plan-topic-prior-injector` as planner scaffolding, not runtime work; it is complete when Section 7 has become the next `/flywheel:plan` input. Evidence: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:88-96`.

### 9.4 Acceptance gates to carry into implementation

- Gate 01: every packet has `schema_version`; evidence for schema need: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:71-82`.
- Gate 02: every packet has all six layers; evidence for layer frame: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:24-30`.
- Gate 03: every layer has `status`, `freshness`, `evidence`, `routes`, and `unknowns`.
- Gate 04: every evidence item is file:line or re-runnable command; evidence for L113 binding: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:110-116`.
- Gate 05: every route card has one owner and one next action; evidence for route-first intent: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:142-148`.
- Gate 06: every no-action decision has a reason; evidence for no silent-loss doctrine: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:469-501`.
- Gate 07: unknown product/moat metrics report yellow, not green; evidence for Layer 5/6 gaps: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:424-446`.
- Gate 08: `mobile-eats` publishability asks are Joshua cards, not worker-default calls; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:530-544`.
- Gate 09: VRTX client promise drift triggers signed-scope evidence; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:698-704`.
- Gate 10: JSM degradation routes to moat/yellow rather than blocking the whole packet; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:424-438`.
- Gate 11: callback validation failures block summarization; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:482`.
- Gate 12: cascade detector v1 is warning-and-routing only; evidence for planned detector scope: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:309-395`.
- Gate 13: weekly peer review uses history windows, not one-day anecdotes; evidence for trend stock: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:203-224`.
- Gate 14: future repos join through specialization registry rows; evidence for future-pipeline scope: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:24-30`.
- Gate 15: no launchd or plist mutation lands in Phase 1; evidence for dispatch synthesis-only scope: `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:110-116`.
- Gate 16: all CLI work has `--dry-run --json`; evidence: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:199-218`.
- Gate 17: operator output follows robot-mode stable keys; evidence: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:261-306`.
- Gate 18: `architecture_health_metric_unpaired_count` remains visible until paired with route owners; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:603-610`.
- Gate 19: research-to-action metric measures adoption, not article volume; evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:682-688`.
- Gate 20: plan output includes bead dependencies before implementation; evidence: `/Users/josh/.claude/skills/planning-workflow/SKILL.md:63-68`.

### 9.5 Non-goals for the planner

- Non-goal: build a social meeting simulation or agents-around-table ritual. Evidence: Joshua's reframing in the dispatch defines a six-layer system instead. `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:19-30`.
- Non-goal: build a dashboard that Joshua must read daily. Evidence: Lane A rejects dashboard-shaped loops and recommends route-first information flows. `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:142-148`.
- Non-goal: rank individual agents as the primary outcome. Evidence: Lane A and Lane C frame the target as architecture health and autonomous capacity. `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:72` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:125-140`.
- Non-goal: create new substrate before composing existing primitives. Evidence: Lane B and Lane D both converge on adopting/extending current substrate first. `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:161-169` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:625-655`.
- Non-goal: automate founder taste or client promise decisions. Evidence: Lane D founder-bottleneck rules and Lane C founder doctrine leave those classes with Joshua. `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:415-501` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:125-140`.
- Non-goal: enforce cascade mitigations before the detector proves signal quality. Evidence: Lane F provides cascade patterns as detector candidates, not mutation commands. `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:309-395`.
- Non-goal: hide unknown Layer 5/6 product and moat inputs. Evidence: Lane F's extractor inventory includes needed and missing metrics, so unknowns are first-class. `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:397-446`.
- Non-goal: create beads from this synthesis artifact. Evidence: dispatch says no bead creation except optional planner handoff, and this artifact records no_bead_reason. `/tmp/dispatch_lane_e_synthesis_2026-05-05.md:110-116`.

### 9.6 Final synthesis receipt

- The canonical method is `packet schema plus read-only aggregate plus route-card lifecycle`.
- The strongest leverage point is better information flow and self-organization, not more worker volume. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:188-224`.
- The implementation strategy is `compose first, extend second, build detectors after packet proof`. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:161-169`, `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:625-655`, and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md:782-793`.
- The planner should treat the 16 seeds above as provisional bead candidates, not pre-approved mutations. Evidence: planning-workflow requires dependency-aware plan refinement before implementation. `/Users/josh/.claude/skills/planning-workflow/SKILL.md:63-68`.
