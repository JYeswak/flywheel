# Lane F Product Research - Fleet Ops Meeting Approved Method

task_id: `b56-laneF-product-research-fleet-ops-meeting-2026-05-05`
date: `2026-05-05`
mode: `RESEARCH_ONLY_PLAN_SPACE`
output_path: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md`

## 1. Method

### 1.1 Contract executed

- DID read the dispatch packet before writing this artifact. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:1`.
- DID execute the source-(a) meta-rule before Socraticode and repo research. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:9`.
- DID use the local implementation of `/flywheel:skills-best-practices` as the rule source. Evidence: `/Users/josh/.claude/commands/flywheel/skills-best-practices.md:1`.
- DID treat source-(a) as mandatory before Socraticode and research-triad work. Evidence: `/Users/josh/.claude/commands/flywheel/skills-best-practices.md:13`.
- DID query source-(a) with the dispatch-required domain. Evidence command: `mcp__skill_search__.query_skills_tool query="product publishability customer end-user research moat brand-voice client-deliverable" limit=10`.
- DID read Lane A as a systems-prior. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:32`.
- DID read Lane C as an Anthropic/pattern-prior. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:62`.
- DID read Lane D as the Joshua/fleet-substrate prior. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:507`.
- DID also read Lane B because it had landed and contained primitives/avoid/new-needed guidance. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:133`.
- DID reserve this output file with Agent Mail before writing. Evidence command: `mcp__mcp_agent_mail__.macro_start_session human_key=/Users/josh/Developer/flywheel file_reservation_paths=.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md`.
- DID NOT edit source code, scripts, plists, LaunchAgents, or beads as part of this lane. Evidence command: this artifact was the only write target named in the Agent Mail reservation command above.
- DID NOT run `br create`. Evidence command: no `br create` command was executed in this Lane F session; bead routing is recorded as `no_bead_reason=research_only_planner_artifact`.

### 1.2 Source-(a) top 10 skill results

- Source-(a) result 1: `zeststream-brand-voice`, effective_score `0.750805`. Evidence command: `mcp__skill_search__.query_skills_tool query="product publishability customer end-user research moat brand-voice client-deliverable" limit=10`.
- Source-(a) result 2: `voice-of-customer`, effective_score `0.728781`. Evidence command: same source-(a) query.
- Source-(a) result 3: `proposal-generation`, effective_score `0.678805`. Evidence command: same source-(a) query.
- Source-(a) result 4: `email-delivery`, effective_score `0.668508`. Evidence command: same source-(a) query.
- Source-(a) result 5: `isp-customer-service`, effective_score `0.652514`. Evidence command: same source-(a) query.
- Source-(a) result 6: `customer-communication`, effective_score `0.644208`. Evidence command: same source-(a) query.
- Source-(a) result 7: `sales-forecasting`, effective_score `0.642873`. Evidence command: same source-(a) query.
- Source-(a) result 8: `client-ecosystem-audit`, effective_score `0.641001`. Evidence command: same source-(a) query.
- Source-(a) result 9: `email-sequence`, effective_score `0.633834`. Evidence command: same source-(a) query.
- Source-(a) result 10: `seo-audit`, effective_score `0.632875`. Evidence command: same source-(a) query.

### 1.3 Top 10 skill read summary

- `zeststream-brand-voice` is load-bearing for brand voice, score copy, ground claims, and client brand voice. Evidence: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:3`.
- `zeststream-brand-voice` requires factual claims to map to ground truth and exposes a 16-dim score with a >=95 threshold. Evidence: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:21` and `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:22`.
- `voice-of-customer` is load-bearing for feedback aggregation, NPS, support themes, feature prioritization, sentiment, churn signals, and feedback loops. Evidence: `/Users/josh/.claude/skills/voice-of-customer/SKILL.md:3`.
- `voice-of-customer` turns scattered customer signals into prioritized, revenue-weighted product decisions. Evidence: `/Users/josh/.claude/skills/voice-of-customer/SKILL.md:21`.
- `proposal-generation` is load-bearing for proposals, SOWs, bids, custom quotes, scope, pricing, timeline, assumptions, and risks. Evidence: `/Users/josh/.claude/skills/proposal-generation/SKILL.md:3`.
- `proposal-generation` requires missing commercial terms to be flagged and client-facing output to receive human review. Evidence: `/Users/josh/.claude/skills/proposal-generation/SKILL.md:30`.
- `email-delivery` is load-bearing for transactional and notification email systems, deliverability, SPF, DKIM, DMARC, templates, bounce handling, and unsubscribe. Evidence: `/Users/josh/.claude/skills/email-delivery/SKILL.md:3`.
- `email-delivery` says open tracking is unreliable and click/conversion should carry more weight. Evidence: `/Users/josh/.claude/skills/email-delivery/SKILL.md:150` and `/Users/josh/.claude/skills/email-delivery/SKILL.md:166`.
- `isp-customer-service` models customer journeys as a finite state machine with transitions, guards, recovery, and rollback. Evidence: `/Users/josh/.claude/skills/isp-customer-service/SKILL.md:19`.
- `customer-communication` is load-bearing for customer emails, incident updates, QBR invites, renewal reminders, proactive outreach, service recovery, and escalation replies. Evidence: `/Users/josh/.claude/skills/customer-communication/SKILL.md:3`.
- `sales-forecasting` builds auditable revenue forecasts and requires human review for external or executive output. Evidence: `/Users/josh/.claude/skills/sales-forecasting/SKILL.md:26` and `/Users/josh/.claude/skills/sales-forecasting/SKILL.md:54`.
- `client-ecosystem-audit` is load-bearing for client discovery, system findings, lead intelligence, peel reports, and integration audits. Evidence: `/Users/josh/.claude/skills/client-ecosystem-audit/SKILL.md:3`.
- `client-ecosystem-audit` requires revenue estimates to state assumptions and confidence ranges and forbids raw PII in client-facing output. Evidence: `/Users/josh/.claude/skills/client-ecosystem-audit/SKILL.md:26` and `/Users/josh/.claude/skills/client-ecosystem-audit/SKILL.md:27`.
- `email-sequence` is load-bearing for onboarding, drip, nurture, trial conversion, win-back, lifecycle, and segmentation sequences. Evidence: `/Users/josh/.claude/skills/email-sequence/SKILL.md:3`.
- `email-sequence` warns that no exit conditions trap users in loops. Evidence: `/Users/josh/.claude/skills/email-sequence/SKILL.md:142`.
- `seo-audit` is load-bearing for SEO audits, crawlability, indexation, Core Web Vitals, and organic traffic health. Evidence: `/Users/josh/.claude/skills/seo-audit/SKILL.md:3`.
- `seo-audit` routes conversion optimization to `page-cro` after ranking work. Evidence: `/Users/josh/.claude/skills/seo-audit/SKILL.md:116`.

### 1.4 Mandatory skill list coverage

- DID read 63 present `SKILL.md` files from the dispatch mandatory and top-10 sets. Evidence command: `for f in <mandatory-and-top10-skill-paths>; do test -f "$f" && nl -ba "$f" >/dev/null; done`.
- DID find 5 dispatch-listed skill names absent from `/Users/josh/.claude/skills`. Evidence command: `test -f /Users/josh/.claude/skills/<skill>/SKILL.md` for `customer-360 research-delegate jeff-intel ultimate-leverage extreme-leverage`.
- Missing skill: `customer-360`. Evidence command: `test -f /Users/josh/.claude/skills/customer-360/SKILL.md || echo MISSING`.
- Missing skill: `research-delegate`. Evidence command: `test -f /Users/josh/.claude/skills/research-delegate/SKILL.md || echo MISSING`.
- Missing skill: `jeff-intel`. Evidence command: `test -f /Users/josh/.claude/skills/jeff-intel/SKILL.md || echo MISSING`.
- Missing skill: `ultimate-leverage`. Evidence command: `test -f /Users/josh/.claude/skills/ultimate-leverage/SKILL.md || echo MISSING`.
- Missing skill: `extreme-leverage`. Evidence command: `test -f /Users/josh/.claude/skills/extreme-leverage/SKILL.md || echo MISSING`.
- The missing `customer-360` skill matters because Layer 5 needs a repo-by-repo product/customer outcome view. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:57`.
- The missing `research-delegate` skill matters because Layer 6 needs a research/strategy/moat substrate. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:80`.
- The missing `jeff-intel` skill matters because the dispatch asks whether existing Jeff/JSM digest surfaces should contribute to Layer 6. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:85`.
- The missing `ultimate-leverage` and `extreme-leverage` skills matter because the dispatch explicitly frames moat and strategy extraction. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:78`.

### 1.5 Prior outputs used as priors

- Lane A defines the meeting boundary as substrate signals, cross-orchestrator alignment, knowledge-moat growth, structural routing, and founder bottleneck reduction. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:32`.
- Lane A names knowledge-moat depth, founder-bottleneck volume, architecture-health visibility, cross-pollination, public-surface readiness, and skill-library gaps as stocks. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:54`.
- Lane A's reinforcing knowledge-moat loop maps substrate signals to synthesis to reusable doctrine to better extraction. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:150`.
- Lane A warns about Goodhart and surveillance loops when metrics become ranking or pressure surfaces. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:166`.
- Lane C maps the nine-petal flywheel to the three reasoning spaces and operator loop. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:22`.
- Lane C inventories existing skills relevant to daily ops and identifies that a dedicated fleet ops method still needs a new synthesis layer. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:62` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-C-anthropic.md:181`.
- Lane D identifies skillos as needing skill submissions, JSM/Jeff monitor status, external deltas, pack graduation, skill gaps, and recommended dispatch candidates. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:507`.
- Lane D identifies mobile-eats as needing public readiness, brand voice, Nango canary, payment readiness, PHI and launch flags, and next user-facing bead. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:525`.
- Lane D identifies ALPS as needing the Mike daily report, Mike decisions needed, work shipped, blockers, mypy/PR burndown, R1-R7 cadence, and Nango health. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:543`.
- Lane D identifies VRTX as needing leads touched under 4 hours, next gate, blockers, signed-scope drift, client brand voice, and CubCloud/ZestStream scope status. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:568`.
- Lane D says daily fleet roll-up is partial, knowledge-moat depth is missing, skill-gap rollup is partial, and founder bottleneck is partial. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:603` and `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Lane B says adopt primitives for kernel snapshots, diffusion, substrate migrations, research-backed docs, and evaluator gates. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:135`.
- Lane B says new daily-review substrate is needed for daily Jeff/JSM delta synthesis, script-backed oracles, and translation from Jeff substrate changes to flywheel action. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-B-jeff.md:161`.

### 1.6 Socraticode survey

- DID verify `/Users/josh/Developer/mobile-eats` exists before Socraticode search. Evidence command: `test -d /Users/josh/Developer/mobile-eats`.
- DID verify `/Users/josh/Developer/skillos` exists before Socraticode search. Evidence command: `test -d /Users/josh/Developer/skillos`.
- DID verify `/Users/josh/Developer/vrtx` exists before Socraticode search. Evidence command: `test -d /Users/josh/Developer/vrtx`.
- DID verify `/Users/josh/Developer/alpsinsurance` exists before Socraticode search. Evidence command: `test -d /Users/josh/Developer/alpsinsurance`.
- Socraticode status for mobile-eats was green with 1,127 indexed chunks. Evidence command: `mcp__socraticode__.codebase_status projectPath=/Users/josh/Developer/mobile-eats`.
- Socraticode status for skillos was green with 1,739 indexed chunks. Evidence command: `mcp__socraticode__.codebase_status projectPath=/Users/josh/Developer/skillos`.
- Socraticode status for vrtx was green with 6,404 indexed chunks. Evidence command: `mcp__socraticode__.codebase_status projectPath=/Users/josh/Developer/vrtx`.
- Socraticode status for alpsinsurance was green with 68,228 indexed chunks. Evidence command: `mcp__socraticode__.codebase_status projectPath=/Users/josh/Developer/alpsinsurance`.
- Indexed chunks observed total: `77,498`. Evidence command: the four `mcp__socraticode__.codebase_status` calls above.
- Socraticode queries run: `12`. Evidence commands: three `mcp__socraticode__.codebase_search` calls per repo for mobile-eats, skillos, vrtx, and alpsinsurance.

## 2. Layer 5 - End-User / Product Per Repo

### 2.1 Layer 5 definition

- Layer 5 is the layer that asks whether each orchestrator's current work is making a customer, user, buyer, or recipient outcome better. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:54`.
- Layer 5 must cover end-user outcomes, product readiness, client deliverable quality, launch/publishability, brand voice, customer feedback, and revenue-facing signals. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:57`.
- Layer 5 must produce per-orchestrator specialization rather than one generic fleet field. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:56`.
- Layer 5 should not become a daily dashboard that Joshua inspects manually; Lane A explicitly places dashboard hunts outside the preferred system boundary. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:32`.

### 2.2 mobile-eats: product/customer surface

- mobile-eats is a public/product repo where the product promise is already written as "Find the trucks, trust the stop, and help the next person eat well." Evidence: `/Users/josh/Developer/mobile-eats/docs/mobile-eats-brand-voice.md:13`.
- mobile-eats has a local brand voice rule that says the app should feel like a helpful local rather than a control panel. Evidence: `/Users/josh/Developer/mobile-eats/docs/mobile-eats-brand-voice.md:3`.
- mobile-eats has user-facing copy rules that explicitly hide internal implementation terms from customers. Evidence: `/Users/josh/Developer/mobile-eats/docs/mobile-eats-brand-voice.md:17` and `/Users/josh/Developer/mobile-eats/docs/mobile-eats-brand-voice.md:26`.
- mobile-eats has a product positioning statement: community-operated, owner-verified food truck map for Missoula. Evidence: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:7`.
- mobile-eats has two primary jobs-to-be-done: customer open-now trust/share and owner realtime location/menu syndication. Evidence: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:14`.
- mobile-eats uses source-backed design inputs, including competitor UI, reviews, local roster evidence, LBSN research, and crowdsourced map-quality work. Evidence: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:21`.
- mobile-eats already maps owner and customer perspectives before implementation. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:8`.
- mobile-eats requires future feature beads to name the journey perspective and journey stage improved. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:12`.
- mobile-eats has a UX baseline with navigation green and forms/errors/accessibility yellow. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:14`.
- mobile-eats defines shared journey stages from trigger to retain. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:33`.
- mobile-eats defines nearby hungry customer value as open-now trust without guessing. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:46`.
- mobile-eats defines owner first value as publishing before connector setup. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:181`.
- mobile-eats defines owner success as first verified owner publish before OAuth requirement. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:203`.
- mobile-eats defines low-digital-maturity owner success as claim started to first queued/published update completion. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:205` and `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:231`.
- mobile-eats defines event owner success as event publish to shared-card clicks and follows. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:233` and `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:258`.
- mobile-eats defines moderator success as disputed updates resolved without degrading open-now trust. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:260` and `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:285`.
- mobile-eats has a cross-perspective matrix with product requirements for trigger, orient, decide, act, recover, and retain. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:287`.
- mobile-eats has explicit next-build additions for intent modes, trust panel, hotspot planning, owner portal publish-first, community impact, moderation risk grouping, and share cards. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:298`.
- mobile-eats has feedback severity classification that treats payment, unsafe, scam, data leak, security, and cannot-publish issues as critical. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/feedback.ts:374`.
- mobile-eats has feedback priority logic mapping critical to P0 and high to P1. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/feedback.ts:385`.
- mobile-eats has owner social canary payload and receipt types that include provider, runtime lane, owner approval, truth boundary, credential boundary, redacted evidence, and no live posting attempt. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/nango-webhook.ts:130` and `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/nango-webhook.ts:146`.
- mobile-eats readiness signals include topology, provider, webhook, n8n, n8n social bridge dry run, owner social canary, and live post gate. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:30`.
- mobile-eats owner-social canary detail keeps everyday live posting off unless separate approval clears. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:460`.
- mobile-eats candidate market data separates source ledger, local truth readiness, ops load readiness, and unit economics readiness. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/expansion-markets.ts:87`.

### 2.3 mobile-eats: usable Layer 5 extractors

- Usable extractor: public readiness score from publishability, brand voice, canary, live post gate, and local truth readiness. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:30`.
- Usable extractor: customer/owner journey stage coverage from `docs/customer-journey-wireframe-v1.md`. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:33`.
- Usable extractor: user feedback criticality and P0/P1 routing from feedback severity and priority functions. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/feedback.ts:374` and `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/feedback.ts:385`.
- Usable extractor: brand-safe user language from `docs/mobile-eats-brand-voice.md`. Evidence: `/Users/josh/Developer/mobile-eats/docs/mobile-eats-brand-voice.md:17`.
- Usable extractor: expansion market proof debt from `sourcePlaceholders` and readiness fields. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/expansion-markets.ts:106`.
- Needed extractor: actual completion rate for first owner publish before OAuth. Evidence for metric definition: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:203`.
- Needed extractor: shared-card continuation and conversion rate. Evidence for metric definition: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:91`.
- Needed extractor: community contribution impact rate. Evidence for proposed addition: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:306`.
- Needed extractor: canary freshness age and live-post gate drift. Evidence for canary gate surface: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:30`.
- Needed extractor: payment/PHI/security customer-risk heat. Evidence for severity keywords: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/feedback.ts:374`.

### 2.4 skillos: product/customer surface

- skillos mission was locked around expert stewardship of the whole skill system. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:2`.
- skillos commitments include skill-system expertise ledger, Jeff/JSM watch, research-triad intake, and pack graduation discipline. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:10`.
- skillos measurements include skill inventory delta, Jeff/JSM delta, external research delta, pack graduation candidate, and skill quality gap. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:17`.
- skillos accountabilities include inventory knowledge, usage routing, quality/freshness judgment, Jeff/JSM watch, external delta intake, and skill/pack/doctrine routing. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:33`.
- skillos has a repo-local pack registry with schema `skillos.skillpack.registry.v1`. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:2`.
- skillos has a `skills-os-router-pack` whose purpose is operating inventory, routing, quality, and autoresearch safely. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:8` and `/Users/josh/Developer/skillos/state/packs/registry.json:11`.
- skillos pack distribution is local-only and requires confidentiality gate, human review, and validation exit zero for promotion. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:22` and `/Users/josh/Developer/skillos/state/packs/registry.json:34`.
- skillos pack graduation requires command surfaces, validation exit, member SKILL.md, member self-test, source policy, publish gate, and readonly validator. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:53`.
- skillos has a vendor-wranglers candidate pack with four members: cloudflare-api, gh-cli, vercel, and gcloud. Evidence: `/Users/josh/Developer/skillos/state/skillpack-candidate-vendor-wranglers-2026-05-05T0500Z.json:6`.
- skillos candidate pack validation includes list, doctor, validate, install dry-run, why, py_compile, unittest, br lint, and br dep cycles. Evidence: `/Users/josh/Developer/skillos/state/skillpack-candidate-vendor-wranglers-2026-05-05T0500Z.json:22`.
- skillos digest shows catalog health and drift: qdrant 414 skills, filesystem 422 skills, count drift 8, freshness 93.2%. Evidence: `/Users/josh/Developer/skillos/state/digest-2026-04-30.md:15`.

### 2.5 skillos: usable Layer 5 extractors

- Usable extractor: skill inventory delta. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:18`.
- Usable extractor: Jeff/JSM delta. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:19`.
- Usable extractor: external research delta. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:20`.
- Usable extractor: pack graduation candidate. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:21`.
- Usable extractor: skill quality gap. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:22`.
- Usable extractor: pack lifecycle and distribution status. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:13` and `/Users/josh/Developer/skillos/state/packs/registry.json:30`.
- Needed extractor: downstream skill consumer satisfaction or callback defect rate. Evidence for absence: no such metric appears in the mission measurement list at `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:17`.
- Needed extractor: skill recommendation adoption rate across dispatches. Evidence for routing accountability: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:36`.
- Needed extractor: skill-pack public/publishability readiness beyond local-only. Evidence for current local-only state: `/Users/josh/Developer/skillos/state/packs/registry.json:23`.

### 2.6 VRTX: product/customer surface

- VRTX mission status is Phase 1 lead-system delivery after kickoff. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:1`.
- VRTX north star is every lead, every form, every channel touched within 4 hours via Teams without Jack as bottleneck. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:6`.
- VRTX Phase 1 subgoals include ZooTown, unified lead tracking, AI follow-up, 4-hour fallback, 36-hour re-touch, cold-lead re-engagement, ClubReady booking, and manager inbox AI scrubbing. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:13`.
- VRTX gate question requires every dispatch, commit, or edit to serve the 4-hour touch goal or one of eight subgoals. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:24`.
- VRTX manifest says the success metric is `leads_touched_under_4hr_via_teams_no_jack_bottleneck`. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:6`.
- VRTX manifest says the longer-term product surface is Teams action cards, content production line, feedback rows, and operations ranked by urgency. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:12`.
- VRTX signed scope is the source of truth for client-facing collateral. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:1`.
- VRTX signed scope includes Phase 1 lead system deliverables and Phase 2/3 deliverables. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:18`, `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:28`, and `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:39`.
- VRTX signed scope drift rule says scope wins over conflicting collateral. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:56`.
- VRTX system map says the production boundary for lead replies is Teams as the human decision boundary. Evidence: `/Users/josh/Developer/vrtx/docs/vrtx-system-map.md:186`.
- VRTX system map says dashboards are not the product; ranked action cards are the product. Evidence: `/Users/josh/Developer/vrtx/docs/vrtx-system-map.md:206`.
- VRTX runbook says the North Star is notification within 30 seconds and human or AI follow-up within 4 hours. Evidence: `/Users/josh/Developer/vrtx/docs/runbooks/01-phase-1-leads.md:9`.
- VRTX runbook defines Gravity Forms -> n8n -> PostgreSQL -> Microsoft Lists -> Teams/Mailchimp flow. Evidence: `/Users/josh/Developer/vrtx/docs/runbooks/01-phase-1-leads.md:28`.
- VRTX proposal frames the problem as FB lead to delayed manual handling versus Teams ping and AI follow-up. Evidence: `/Users/josh/Developer/vrtx/docs/proposal-vrtx-2026-04-03.md:16`.
- VRTX proposal lists real-time notification, lead routing, AI follow-up, 4-hour fallback, ClubReady integration, and source tracking. Evidence: `/Users/josh/Developer/vrtx/docs/proposal-vrtx-2026-04-03.md:29`.

### 2.7 VRTX: usable Layer 5 extractors

- Usable extractor: leads touched under 4 hours via Teams. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:7`.
- Usable extractor: 30-second lead notification. Evidence: `/Users/josh/Developer/vrtx/docs/runbooks/01-phase-1-leads.md:11`.
- Usable extractor: signed-scope coverage/drift. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:56`.
- Usable extractor: Teams action-card product boundary. Evidence: `/Users/josh/Developer/vrtx/docs/vrtx-system-map.md:206`.
- Usable extractor: Phase 1 subgoal coverage. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:13`.
- Usable extractor: scope and revenue milestone state. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:55`.
- Needed extractor: actual lead-touch latency observed from live leads. Evidence for metric target: `/Users/josh/Developer/vrtx/manifest.yml:7`.
- Needed extractor: Jack approval bottleneck count. Evidence for bottleneck: `/Users/josh/Developer/vrtx/MISSION.md:8`.
- Needed extractor: ClubReady booking proof rate. Evidence for deliverable: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:24`.
- Needed extractor: Derrek production-line time reclaimed. Evidence for production-line correction: `/Users/josh/Developer/vrtx/MISSION.md:53`.

### 2.8 ALPS: product/customer surface

- ALPS locked mission honors Mike-approved 12-week engagement, Workato cutover by mid-July, HubSpot-first dev-staging-prod, daily Mike-loop, and CubCloud handoff. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:10`.
- ALPS phase ladder shows substrate ready, connector/admin foundation partial, HubSpot dev unblocked-untested, staging gated, production sequenced, and Workato cutover sequenced. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:19`.
- ALPS always-on rigor includes daily Mike report, convergence audit, CI green, reconciliation drift, bead discipline, audit immutability, and doctor strict pass. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:32`.
- ALPS load-bearing docs include mission, goal, state, lock log, engagement plan, implementation roadmap, top priorities, stakeholders, pivot, CLAUDE.md, and AGENTS.md. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:91`.
- ALPS client communication rule says Mike never sees bead IDs, doctor verdicts, infisical/migration/dispatch internals, secrets, env vars, or codepaths. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:118`.
- ALPS Mike daily report cadence is locked at mission lock and currently manual until auto-cadence ships. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:1` and `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:18`.
- ALPS Mike daily report format is exactly four sections. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:22`.
- ALPS May 5 report exists and uses outcome language, next steps, decisions needed, and off-track risks. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:1`.
- ALPS May 5 report says staging is not fully green and shadow-mode timing depends on staging going green. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:28`.
- ALPS partner map identifies Mike as primary client contact familiar with Workato. Evidence: `/Users/josh/Developer/alpsinsurance/planning/PARTNERS.md:39`.
- ALPS discovery anchors identify department-level UX truth and warn against another dashboard unless it is valuable and easy to use. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:285` and `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:295`.
- ALPS engagement plan lists HubSpot knowledge loss, Hawksoft manual sync, customer portal gap, workflow complexity, and reporting gaps as quantified pain points. Evidence: `/Users/josh/Developer/alpsinsurance/planning/ENGAGEMENT-PLAN.md:18`.
- ALPS engagement plan states 400,000+ HubSpot contacts and duplication/data quality/workflow complexity challenges. Evidence: `/Users/josh/Developer/alpsinsurance/planning/ENGAGEMENT-PLAN.md:32`.

### 2.9 ALPS: usable Layer 5 extractors

- Usable extractor: Mike daily report age and format compliance. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:22`.
- Usable extractor: staging green/off-track status from the report. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:28`.
- Usable extractor: phase ladder state. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:19`.
- Usable extractor: R1-R7 rigor cadence. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:32`.
- Usable extractor: client-visible communication hygiene. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:31`.
- Usable extractor: customer/system pain quantified by hours and dollars. Evidence: `/Users/josh/Developer/alpsinsurance/planning/ENGAGEMENT-PLAN.md:20`.
- Needed extractor: confirmation that the daily Mike report was actually sent to Mike. Evidence for current convention: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:14`.
- Needed extractor: staging green proof collapsed into client-safe language. Evidence for current off-track state: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:28`.
- Needed extractor: shadow-mode countdown once staging is green. Evidence for dependency: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:32`.
- Needed extractor: dashboard-redundancy guard for new product surfaces. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:295`.

### 2.10 Future repo specialization candidates

- Future repo `zesttube`: likely Layer 5 slot should track rendered-video publishability, asset-provider drift, Remotion fragility, and viewer-facing quality. Evidence for repo sensitivity: `/Users/josh/Developer/flywheel/AGENTS.md:1`.
- Future repo `zeststream.ai`: likely Layer 5 slot should track public website publishability, brand voice composite, conversion CTA health, SEO/CRO readiness, and lead capture. Evidence for brand/publishability skill: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:3`.
- Future repo `aaas`: likely Layer 5 slot should track customer onboarding, health, revenue forecast, and conversion. Evidence for customer health skill: `/Users/josh/.claude/skills/customer-health-scoring/SKILL.md:3`.
- Future repo `langgraph`: likely Layer 5 slot should track harness pass rate, user-facing agent behavior, and model/provider regression. Evidence for evaluation surface: `/Users/josh/.claude/skills/evaluation-framework/SKILL.md:16`.
- Future repo `agent-harness`: likely Layer 5 slot should track benchmark reproducibility, eval quality, and regression severity. Evidence for evaluation framework: `/Users/josh/.claude/skills/evaluation-framework/SKILL.md:20`.
- Future repo `nango`: likely Layer 5 slot should track integration canaries, provider drift, OAuth/app-review gates, and customer-visible connector readiness. Evidence for mobile-eats Nango canary surface: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/nango-webhook.ts:130`.

## 3. Layer 6 - Research / Strategy / Moat

### 3.1 Layer 6 definition

- Layer 6 asks whether the fleet is learning what matters outside the repos and turning that learning into strategic advantage. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:78`.
- Layer 6 must cover market intel, external deltas, Jeff/JSM updates, strategic moat, long-horizon research, competitive insight, and reusable knowledge. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:80`.
- Layer 6 must say whether existing JSM digest / Jeff intel / x-digest surfaces should be included. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:85`.
- The current JSM digest reports unknown update/conflict/doctor state because identity validation failed before probes. Evidence: `/Users/josh/.local/state/jsm/digest.md:8`.
- The current JSM digest says to run `/jsm-review` to triage new skills, drift, and updates. Evidence: `/Users/josh/.local/state/jsm/digest.md:23`.

### 3.2 Existing Layer 6 primitives

- `research-triad` is a required skill for ZestStream peel reports and research-grounded decisions. Evidence: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:15`.
- `zeststream-peel-report` defines KNOW/INFER/GUESS/BLIND labels and warns that unlabeled claims are hallucination risk. Evidence: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:34` and `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:38`.
- `zeststream-peel-report` explicitly calls validated artifact honesty the heart of ZestStream's moat. Evidence: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:40`.
- `competitive-intelligence` is part of the mandatory skill set and should cover competitor/market watch. Evidence command: `test -f /Users/josh/.claude/skills/competitive-intelligence/SKILL.md`.
- `info-source-watchtower` is part of the mandatory skill set and should cover external source monitoring. Evidence command: `test -f /Users/josh/.claude/skills/info-source-watchtower/SKILL.md`.
- `regulatory-monitoring` is part of the mandatory skill set and should cover policy/regulatory deltas. Evidence command: `test -f /Users/josh/.claude/skills/regulatory-monitoring/SKILL.md`.
- `codex-watchtower` is part of the mandatory skill set and should cover Codex-side runtime/provider changes. Evidence command: `test -f /Users/josh/.claude/skills/codex-watchtower/SKILL.md`.
- `agent-sdk-landscape` is part of the mandatory skill set and should cover agent SDK/provider ecosystem shifts. Evidence command: `test -f /Users/josh/.claude/skills/agent-sdk-landscape/SKILL.md`.
- `knowledge-base-management` measures usefulness by ticket deflection rather than vanity pageviews. Evidence: `/Users/josh/.claude/skills/knowledge-base-management/SKILL.md:15`.
- `knowledge-graph` frames a graph as a reasoning substrate for agents to traverse and share structured understanding. Evidence: `/Users/josh/.claude/skills/knowledge-graph/SKILL.md:16` and `/Users/josh/.claude/skills/knowledge-graph/SKILL.md:20`.
- `operationalizing-expertise` turns corpus, quote bank, triangulated kernel, operator library, and validators into executable artifacts. Evidence: `/Users/josh/.claude/skills/operationalizing-expertise/SKILL.md:15`.
- `evaluation-framework` says evaluation without rubric is opinion and the rubric is the contract between desired behavior and measured behavior. Evidence: `/Users/josh/.claude/skills/evaluation-framework/SKILL.md:20`.
- `analytics-tracking` requires a tracking plan before code to avoid tribal knowledge drift. Evidence: `/Users/josh/.claude/skills/analytics-tracking/SKILL.md:102`.
- `ab-testing` has explicit experiment config, assignment, tracking, conversion, and concurrent experiment patterns. Evidence: `/Users/josh/.claude/skills/ab-testing/SKILL.md:75`.

### 3.3 Existing fleet Layer 6 signals

- skillos already owns Jeff/JSM watch and outside-world/research-triad streams. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:43`.
- skillos already measures Jeff/JSM delta, external research delta, and skill quality gap. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:17`.
- skillos current JSM hardening plan forbids live JSM probes or real-HOME mutation until sandbox-auth proof exists. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:25`.
- VRTX has SDK/integration research that used Socraticode first and live PyPI/npm probes. Evidence: `/Users/josh/Developer/vrtx/audits/2026-04-28-sdk-research.md:1`.
- VRTX research locked official/preferred SDK choices for Microsoft Graph and other systems. Evidence: `/Users/josh/Developer/vrtx/audits/2026-04-28-sdk-research.md:271`.
- VRTX ecosystem wiring plans and decisions are explicitly framed as reusable across ZestStream clients. Evidence: `/Users/josh/Developer/vrtx/audits/2026-04-29-flywheel-decisions-locked.md:1`.
- ALPS has a build-vs-fork moat analysis that says the moat is not the workflow engine but vertical positioning, AI-first recipe authoring, and migration tooling. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/planning/build-vs-fork.md:181`.
- ALPS engagement plan gives quantified strategic value and manual overhead, which can feed a revenue/moat extractor. Evidence: `/Users/josh/Developer/alpsinsurance/planning/ENGAGEMENT-PLAN.md:7`.
- mobile-eats has source-backed product research for competitor UI, reviews, local roster, LBSN, and crowdsource quality. Evidence: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:21`.
- mobile-eats has candidate-market source placeholders and local-truth/unit-economics readiness, which can feed launch strategy. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/expansion-markets.ts:87`.

### 3.4 Layer 6 usable extractors

- Usable extractor: external research delta from skillos mission measurements. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:20`.
- Usable extractor: Jeff/JSM delta from skillos mission measurements. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:19`.
- Usable extractor: skill quality gap from skillos mission measurements. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:22`.
- Usable extractor: local-only pack promotion readiness. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:22`.
- Usable extractor: JSM digest freshness/health. Evidence: `/Users/josh/.local/state/jsm/digest.md:3`.
- Usable extractor: KNOW/INFER/GUESS/BLIND ratio for client deliverable research. Evidence: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:34`.
- Usable extractor: knowledge-base usefulness by deflection metric. Evidence: `/Users/josh/.claude/skills/knowledge-base-management/SKILL.md:15`.
- Usable extractor: research-backed product input count for mobile-eats and VRTX. Evidence: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:21` and `/Users/josh/Developer/vrtx/audits/2026-04-28-sdk-research.md:1`.
- Needed extractor: cross-repo research adoption rate, measured as "research item became skill, doctrine, bead, or product gate". Evidence for missing stock: Lane D says knowledge-moat depth is missing at `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Needed extractor: vendor-change blast radius by affected repo/product. Evidence for vendor dependency: VRTX SDK research lists live API probes at `/Users/josh/Developer/vrtx/audits/2026-04-28-sdk-research.md:271`.
- Needed extractor: competitor/product-market delta translated into next repo action. Evidence for competitor/product research source: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:21`.
- Needed extractor: "moat compounding events per week" across skill, doctrine, repo, client, and market surfaces. Evidence for moat frame: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:40`.

### 3.5 Layer 6 provisional moat hypothesis

- Hypothesis: ZestStream's operational moat is not any single repo, workflow engine, model, or provider; it is the closed loop that turns external deltas, customer feedback, repo evidence, and skill/doctrine patterns into reusable execution substrate. Evidence for validated-artifact moat: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:40`.
- Hypothesis support: ALPS says the Workato replacement moat is vertical positioning, AI-first recipe authoring, and migration tooling rather than the engine. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/planning/build-vs-fork.md:181`.
- Hypothesis support: skillos mission owns skill inventory, usage routing, quality/freshness judgment, Jeff/JSM watch, external delta intake, and skill/pack/doctrine routing. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:33`.
- Hypothesis support: mobile-eats turns product/customer research into journey gates and future bead requirements. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:12`.
- Hypothesis support: VRTX turns client discovery into action-card product boundaries and scope-safe deliverables. Evidence: `/Users/josh/Developer/vrtx/docs/vrtx-system-map.md:206`.
- Hypothesis support: ALPS turns technical substrate state into Mike-visible daily outcomes while hiding internal jargon. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:22`.

## 4. Cross-Layer Cascade Patterns

### 4.1 Cascade pattern 1: storage/index health -> research quality -> product quality

- Trigger: Socraticode index becomes stale, missing, or low-quality for a repo. Evidence for Socraticode dependence: `/Users/josh/Developer/flywheel/AGENTS.md:50`.
- Layer 1/2 effect: workers lose source context and re-derive existing substrate. Evidence: `/Users/josh/Developer/flywheel/AGENTS.md:50`.
- Layer 5 effect: product recommendations drift away from actual repo/product state. Evidence from mobile-eats source-backed design reliance: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:21`.
- Layer 6 effect: market/research signal no longer maps to local proof, so moat events become abstract prose. Evidence from peel report validate-not-assume rule: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:73`.
- Detector needed: daily `codebase_status` chunk age/green status per active repo plus delta between expected key files and Socraticode hits. Evidence command pattern: `mcp__socraticode__.codebase_status projectPath=<repo>`.
- Meeting surface: one line per repo when index is not green or when product-layer citation coverage falls below threshold. Evidence for lane requirement: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:50`.

### 4.2 Cascade pattern 2: skill gap -> worker reinvention -> client/product drift

- Trigger: source-(a) or mandatory skill lookup finds missing or stale skill coverage. Evidence for this lane's missing skills: command `test -f /Users/josh/.claude/skills/customer-360/SKILL.md || echo MISSING`.
- Layer 2 effect: workers improvise customer/product/research methods instead of using reusable practice. Evidence for source-(a) meta-rule: `/Users/josh/Developer/flywheel/AGENTS.md:50`.
- Layer 5 effect: customer-specific metrics become inconsistent across mobile-eats, VRTX, ALPS, and skillos. Evidence for per-repo specialization requirement: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:156`.
- Layer 6 effect: moat does not compound because method is not captured as a skill. Evidence for skillos routing mandate: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:33`.
- Detector needed: `missing_skill_count`, `skill_recommendation_used_count`, and `skill_gap_routed_to_skillos_count`. Evidence for missing-skill policy: `/Users/josh/Developer/flywheel/AGENTS.md:54`.
- Meeting surface: "skill gaps affecting today's product/research layers" with target repo and recommended skill owner. Evidence for Lane F role: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:126`.

### 4.3 Cascade pattern 3: vendor/API delta -> stale skill -> failed customer promise

- Trigger: provider, SDK, API, or CLI behavior changes. Evidence for live API volatility rule: `/Users/josh/Developer/flywheel/AGENTS.md:1`.
- Layer 2 effect: skill guidance or scripts become stale. Evidence for skillos Jeff/JSM and external delta stream: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:43`.
- Layer 5 mobile-eats effect: Nango/social canary or live-post gate becomes wrong while product says social sync is ready. Evidence for canary/live-post signals: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:30`.
- Layer 5 VRTX effect: SDK or Graph behavior changes can break Teams/Microsoft scope promises. Evidence for VRTX SDK research scope: `/Users/josh/Developer/vrtx/audits/2026-04-28-sdk-research.md:1`.
- Layer 6 effect: research/strategy loses live truth. Evidence for direct-source-probe discipline in VRTX research: `/Users/josh/Developer/vrtx/audits/2026-04-28-sdk-research.md:271`.
- Detector needed: vendor-delta-to-repo blast-radius map and stale-source threshold per skill. Evidence for JSM digest currently degraded: `/Users/josh/.local/state/jsm/digest.md:8`.

### 4.4 Cascade pattern 4: founder bottleneck -> delayed user feedback -> wrong product work

- Trigger: daily meeting asks Joshua to manually inspect dashboards or make too many low-level decisions. Evidence for founder bottleneck stock: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:61`.
- Layer 4 effect: orchestrators wait on human attention instead of product/user signals. Evidence for L48 escalation doctrine: `/Users/josh/Developer/flywheel/AGENTS.md:48`.
- Layer 5 effect: VRTX lead latency, ALPS daily report send, or mobile-eats publish readiness stalls behind non-product gates. Evidence for VRTX 4-hour goal: `/Users/josh/Developer/vrtx/MISSION.md:8`.
- Layer 6 effect: strategic signal becomes "what Josh noticed" instead of repeatable research/market/intel routing. Evidence for skillos accountabilities: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:33`.
- Detector needed: `founder_decision_count_by_layer` and `human_review_required_but_no_structural_reason_count`. Evidence for Lane A founder bottleneck stock: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:61`.
- Meeting surface: only decisions that are truly customer, contract, credential, legal, or strategy owner decisions. Evidence for ALPS Mike report "decisions needed" pattern: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:28`.

### 4.5 Cascade pattern 5: user feedback ignored -> no bead/skill/doctrine -> recurring defect

- Trigger: feedback enters repo or product surface without conversion to issue, bead, skill, or doctrine. Evidence for issue-to-bead doctrine: `/Users/josh/Developer/flywheel/AGENTS.md:52`.
- Layer 5 effect: mobile-eats trust-risk reports or ALPS/VRTX client asks are absorbed silently. Evidence for mobile-eats feedback class severity: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/feedback.ts:374`.
- Layer 6 effect: customer reality never becomes moat; it remains scrollback. Evidence for operationalizing expertise provenance requirement: `/Users/josh/.claude/skills/operationalizing-expertise/SKILL.md:52`.
- Detector needed: `feedback_event_count`, `feedback_to_bead_count`, `feedback_to_skill_count`, `feedback_to_doctrine_count`, and `silent_feedback_age`. Evidence for L52 callback routing: `/Users/josh/Developer/flywheel/AGENTS.md:52`.
- Meeting surface: top unconverted product/customer feedback items, not a generic feedback dashboard. Evidence for dashboard anti-pattern in ALPS: `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:295`.

### 4.6 Cascade pattern 6: brand voice drift -> trust loss -> slower client/customer adoption

- Trigger: copy or report language diverges from the relevant brand voice. Evidence for brand-voice trigger: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:3`.
- Layer 5 mobile-eats effect: implementation terms leak into public copy. Evidence for mobile-eats forbidden implementation terms: `/Users/josh/Developer/mobile-eats/docs/mobile-eats-brand-voice.md:26`.
- Layer 5 ALPS effect: Mike sees internal jargon or secret/process terms instead of outcome language. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:31`.
- Layer 5 VRTX effect: signed scope or client promise language drifts. Evidence for signed-scope drift rule: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:56`.
- Layer 6 effect: public ZestStream credibility weakens and moat evidence sounds generic. Evidence for ZestStream brand/claims grounding: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:21`.
- Detector needed: per-repo `brand_voice_composite`, `banned_words_count`, `unsupported_claims_count`, and `client_scope_drift_count`. Evidence for ZestStream composite threshold: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:22`.

### 4.7 Cascade pattern 7: scope drift -> product work grows -> revenue milestone risk

- Trigger: product work adds audit bonuses or new features that replace signed deliverables. Evidence for VRTX signed-scope drift rule: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:56`.
- Layer 5 VRTX effect: the 4-hour lead system loses time to non-scope work. Evidence for VRTX gate question: `/Users/josh/Developer/vrtx/MISSION.md:24`.
- Layer 5 ALPS effect: dashboard redundancy or scope expansion consumes capacity without client adoption. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:295`.
- Layer 6 effect: strategy report becomes an idea generator instead of a moat compounding gate. Evidence for proposal/client scope discipline: `/Users/josh/.claude/skills/proposal-generation/SKILL.md:30`.
- Detector needed: `scope_line_items_green`, `audit_bonus_count`, `unapproved_scope_delta_count`, and `milestone_risk_count`. Evidence for VRTX milestone fields: `/Users/josh/Developer/vrtx/manifest.yml:55`.

### 4.8 Cascade pattern 8: local-only pack stagnation -> no skill diffusion -> repeated vendor work

- Trigger: skillos pack remains local-only/candidate without promotion or explicit no-publish reason. Evidence for current local-only state: `/Users/josh/Developer/skillos/state/packs/registry.json:23`.
- Layer 2 effect: other repos keep re-solving vendor/skill routing problems. Evidence for vendor-wranglers candidate pack: `/Users/josh/Developer/skillos/state/skillpack-candidate-vendor-wranglers-2026-05-05T0500Z.json:6`.
- Layer 5 effect: VRTX/ALPS/mobile-eats product gates relying on vendor integrations move slower. Evidence for VRTX integrations: `/Users/josh/Developer/vrtx/docs/proposal-vrtx-2026-04-03.md:29`.
- Layer 6 effect: external/JSM/Jeff knowledge does not compound through the skill library. Evidence for skillos mission streams: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:43`.
- Detector needed: `candidate_pack_age`, `validation_status`, `blocked_publish_reason`, `downstream_reuse_count`. Evidence for pack validation commands: `/Users/josh/Developer/skillos/state/skillpack-candidate-vendor-wranglers-2026-05-05T0500Z.json:22`.

### 4.9 Cascade pattern 9: metric Goodharting -> superficial green -> user harm

- Trigger: meeting scores become targets for individual agents or generic dashboards. Evidence for Lane A Goodhart warning: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:166`.
- Layer 5 effect: mobile-eats can score publishability while real owner/customer action rates stay unknown. Evidence for mobile-eats needed first-publish metric: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:203`.
- Layer 5 VRTX effect: "lead system green" can hide live lead latency if not tied to observed lead events. Evidence for lead-latency target: `/Users/josh/Developer/vrtx/manifest.yml:7`.
- Layer 5 ALPS effect: daily report can exist but not be sent. Evidence for manual send convention: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:14`.
- Layer 6 effect: research count can grow without adoption. Evidence for missing knowledge-moat depth: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Detector needed: every Layer 5/6 score must include a paired outcome or adoption receipt. Evidence for evaluation rubric contract: `/Users/josh/.claude/skills/evaluation-framework/SKILL.md:20`.

### 4.10 Cascade pattern 10: daily fleet meeting omits Layer 5/6 -> fleet productive but strategically blind

- Trigger: daily meeting focuses on workers, commits, and blockers but omits end-user/product/research/moat. Evidence for Lane F mandate: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:54`.
- Layer 3/4 effect: orchestrators stay busy and compliant while product outcomes remain unmeasured. Evidence for L101 continuous productivity: `/Users/josh/Developer/flywheel/AGENTS.md:2521`.
- Layer 5 effect: user-facing risks like ALPS sent-report status, VRTX lead touch, or mobile-eats canary freshness are not visible. Evidence for per-repo Layer 5 surfaces: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:525`.
- Layer 6 effect: knowledge-moat growth stays missing. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Detector needed: daily report schema must require Layer 5 and Layer 6 sections with repo-specific slot completion. Evidence for schema specialization requirement: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:156`.

## 5. Per-Layer Extractor Inventory

### 5.1 Layer 5 extractor inventory

- L5-01 mobile-eats public readiness composite: EXISTS-PARTIAL. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:30`.
- L5-02 mobile-eats brand voice and public copy guard: EXISTS. Evidence: `/Users/josh/Developer/mobile-eats/docs/mobile-eats-brand-voice.md:17`.
- L5-03 mobile-eats owner/customer journey coverage: EXISTS. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:33`.
- L5-04 mobile-eats first owner publish completion: NEEDED. Evidence for target metric: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:203`.
- L5-05 mobile-eats feedback criticality routing: EXISTS. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/feedback.ts:374`.
- L5-06 mobile-eats expansion local-truth proof debt: EXISTS-PARTIAL. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/expansion-markets.ts:87`.
- L5-07 skillos skill inventory delta: EXISTS. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:18`.
- L5-08 skillos skill quality gap: EXISTS. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:22`.
- L5-09 skillos pack lifecycle/promotion state: EXISTS. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:13`.
- L5-10 skillos downstream consumer satisfaction: NEEDED. Evidence for absent measurement list: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:17`.
- L5-11 VRTX 4-hour lead-touch metric: EXISTS-PARTIAL. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:7`.
- L5-12 VRTX 30-second lead notification metric: EXISTS-PARTIAL. Evidence: `/Users/josh/Developer/vrtx/docs/runbooks/01-phase-1-leads.md:11`.
- L5-13 VRTX signed-scope drift metric: EXISTS. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:56`.
- L5-14 VRTX actual live lead latency: NEEDED. Evidence for target: `/Users/josh/Developer/vrtx/MISSION.md:8`.
- L5-15 ALPS Mike daily report age/format: EXISTS-PARTIAL. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:22`.
- L5-16 ALPS Mike report sent-confirmation: NEEDED. Evidence for manual send step: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:14`.
- L5-17 ALPS staging/off-track client-safe status: EXISTS-PARTIAL. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:28`.
- L5-18 ALPS dashboard redundancy guard: EXISTS-PARTIAL. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:295`.
- L5-19 future zeststream.ai brand/conversion/publishability: NEEDED. Evidence for brand score substrate: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:22`.
- L5-20 future agent-harness/langgraph evaluation quality: NEEDED. Evidence for eval rubric substrate: `/Users/josh/.claude/skills/evaluation-framework/SKILL.md:20`.

### 5.2 Layer 6 extractor inventory

- L6-01 JSM digest freshness/status: EXISTS-PARTIAL. Evidence: `/Users/josh/.local/state/jsm/digest.md:3`.
- L6-02 JSM digest probe health: EXISTS-BUT-DEGRADED. Evidence: `/Users/josh/.local/state/jsm/digest.md:8`.
- L6-03 Jeff/JSM delta from skillos: EXISTS. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:19`.
- L6-04 external research delta from skillos: EXISTS. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:20`.
- L6-05 skill quality gap from skillos: EXISTS. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:22`.
- L6-06 KNOW/INFER/GUESS/BLIND ratio: EXISTS. Evidence: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:34`.
- L6-07 research-to-action adoption rate: NEEDED. Evidence for missing knowledge-moat depth: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- L6-08 vendor-delta blast radius: NEEDED. Evidence for VRTX API probe volatility: `/Users/josh/Developer/vrtx/audits/2026-04-28-sdk-research.md:271`.
- L6-09 competitor/product-market delta: EXISTS-PARTIAL. Evidence: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:21`.
- L6-10 strategic moat event count: NEEDED. Evidence for moat concept: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:40`.
- L6-11 skill-pack promotion readiness: EXISTS. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:53`.
- L6-12 local-only publish blocker reason: EXISTS-PARTIAL. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:30`.
- L6-13 regulatory/compliance delta: NEEDED. Evidence for regulatory skill presence: command `test -f /Users/josh/.claude/skills/regulatory-monitoring/SKILL.md`.
- L6-14 knowledge graph/KB health: NEEDED. Evidence for knowledge-graph role: `/Users/josh/.claude/skills/knowledge-graph/SKILL.md:20`.
- L6-15 cross-repo reusable artifact diffusion: NEEDED. Evidence for VRTX decisions reused across clients: `/Users/josh/Developer/vrtx/audits/2026-04-29-flywheel-decisions-locked.md:1`.

### 5.3 Extractor counts

- Layer 5 usable extractors counted here: `12`. Evidence: inventory rows L5-01, L5-02, L5-03, L5-05, L5-06, L5-07, L5-08, L5-09, L5-11, L5-12, L5-13, L5-15.
- Layer 5 needed extractors counted here: `8`. Evidence: inventory rows L5-04, L5-10, L5-14, L5-16, L5-17, L5-18, L5-19, L5-20.
- Layer 6 usable extractors counted here: `8`. Evidence: inventory rows L6-01, L6-02, L6-03, L6-04, L6-05, L6-06, L6-09, L6-11.
- Layer 6 needed extractors counted here: `7`. Evidence: inventory rows L6-07, L6-08, L6-10, L6-12, L6-13, L6-14, L6-15.
- Cascade detectors needed counted here: `10`. Evidence: Section 4 patterns 1 through 10 each names a detector.

## 6. Anti-Patterns Specific To Layers 5 And 6

- Anti-pattern 1: generic "product health" across all repos. Reason: mobile-eats, skillos, VRTX, and ALPS have materially different users and value surfaces. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:156`.
- Anti-pattern 2: dashboards as product. Reason: VRTX and ALPS both say ranked action surfaces beat dashboard hunts. Evidence: `/Users/josh/Developer/vrtx/docs/vrtx-system-map.md:206` and `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:295`.
- Anti-pattern 3: brand/publishability score without user outcome receipt. Reason: brand voice can pass while first-publish, lead latency, or report-sent remains unknown. Evidence: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:22`.
- Anti-pattern 4: research-count as moat. Reason: Lane D says knowledge-moat depth is missing, so research volume alone is not enough. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Anti-pattern 5: client-facing reports leak internal substrate language. Reason: ALPS explicitly forbids Mike seeing bead IDs, doctor verdicts, infisical/migration/dispatch internals, secrets, env vars, codepaths, commits, PRs, and file paths. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:31`.
- Anti-pattern 6: product promises without signed-scope reconciliation. Reason: VRTX signed scope wins over conflicting collateral. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:56`.
- Anti-pattern 7: live-post/social readiness claims from canary presence alone. Reason: mobile-eats explicitly keeps everyday live posting off until separate live-post approval clears. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:460`.
- Anti-pattern 8: local-only skill pack treated as published substrate. Reason: skillos pack distribution is currently local-only with publish gates. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:22`.
- Anti-pattern 9: open-rate-centric email/product metrics. Reason: email-delivery says open tracking is unreliable and click/conversion should be favored. Evidence: `/Users/josh/.claude/skills/email-delivery/SKILL.md:150` and `/Users/josh/.claude/skills/email-delivery/SKILL.md:166`.
- Anti-pattern 10: A/B or analytics work without a tracking plan. Reason: analytics-tracking says no tracking plan produces tribal knowledge and drift. Evidence: `/Users/josh/.claude/skills/analytics-tracking/SKILL.md:102`.
- Anti-pattern 11: metric as agent ranking. Reason: Lane A warns about Goodhart/surveillance loops. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:166`.
- Anti-pattern 12: strategy claims that do not become skill, doctrine, bead, product gate, or reusable artifact. Reason: operationalizing-expertise requires auditable provenance and executable artifacts. Evidence: `/Users/josh/.claude/skills/operationalizing-expertise/SKILL.md:52`.

## 7. Per-Orchestrator Specialization Slots In Ops Report Schema

### 7.1 Required shared schema fields

- `repo`: canonical repo path. Evidence for canonical path discipline: `/Users/josh/Developer/flywheel/AGENTS.md:50`.
- `orchestrator_session`: NTM session name. Evidence for NTM doctrine: `/Users/josh/Developer/flywheel/AGENTS.md:29`.
- `layer5_status`: `green|yellow|red|unknown`. Evidence for Layer 5 mandate: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:54`.
- `layer6_status`: `green|yellow|red|unknown`. Evidence for Layer 6 mandate: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:78`.
- `user_surface`: repo-specific user/customer/client recipient. Evidence for per-repo specialization: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:156`.
- `primary_outcome_metric`: repo-specific top Layer 5 metric. Evidence for Lane D per-repo fields: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:525`.
- `research_moat_signal`: repo-specific top Layer 6 signal. Evidence for Lane D knowledge-moat gap: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- `evidence_refs`: list of file:line or command receipts. Evidence for L113 binding in dispatch: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:178`.
- `next_action`: specific action for orchestrator, worker, skillos, or no action. Evidence for Lane A structural routing boundary: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:32`.
- `human_ask`: only if truly owner/client/credential/legal/strategy. Evidence for L48 escalation ladder: `/Users/josh/Developer/flywheel/AGENTS.md:48`.

### 7.2 mobile-eats specialization slot

- `user_surface`: hungry locals, truck owners, community contributors, moderators. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:44`.
- `primary_outcome_metric`: first verified owner publish before OAuth. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:203`.
- `secondary_outcome_metric`: open-now trust and share/navigate continuation. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:46`.
- `risk_metric`: critical feedback count for payment, unsafe, scam, data leak, security, or cannot-publish. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/feedback.ts:374`.
- `canary_metric`: owner social canary readiness and live-post gate state. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:30`.
- `brand_metric`: banned implementation terms and local/helper language compliance. Evidence: `/Users/josh/Developer/mobile-eats/docs/mobile-eats-brand-voice.md:17`.
- `moat_metric`: source-backed local-truth research and candidate market proof debt. Evidence: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:21` and `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/expansion-markets.ts:106`.

### 7.3 skillos specialization slot

- `user_surface`: orchestrators and workers consuming skill routing, skill quality, and pack substrate. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:33`.
- `primary_outcome_metric`: skill recommendation adoption and reduced skill-substrate bypass. Evidence for routing accountability: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:36`.
- `secondary_outcome_metric`: pack candidate graduation readiness. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:53`.
- `risk_metric`: catalog drift, stale skills, degraded JSM, local-only pack blockers. Evidence: `/Users/josh/Developer/skillos/state/digest-2026-04-30.md:15` and `/Users/josh/.local/state/jsm/digest.md:8`.
- `moat_metric`: Jeff/JSM delta, external research delta, skill quality gap, and pack graduation candidate. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:17`.
- `next_action_shape`: route missing skills to skillos or record explicit no-skill reason. Evidence for L55 route: `/Users/josh/Developer/flywheel/AGENTS.md:55`.

### 7.4 VRTX specialization slot

- `user_surface`: Derek, Jack, Rene, VRTX staff, leads, members, ZooTown participants. Evidence: `/Users/josh/Developer/vrtx/docs/proposal-vrtx-2026-04-03.md:1`.
- `primary_outcome_metric`: leads touched under 4 hours via Teams without Jack bottleneck. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:8`.
- `secondary_outcome_metric`: lead notification under 30 seconds. Evidence: `/Users/josh/Developer/vrtx/docs/runbooks/01-phase-1-leads.md:11`.
- `scope_metric`: signed Phase 1/2/3 line-item status. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:18`.
- `brand_metric`: VRTX voice/canon state and signed-scope voice drift. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:25`.
- `risk_metric`: unapproved scope drift, unresolved strategic decisions, live-route proof gaps. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:45`.
- `moat_metric`: reusable client automation template extracted from VRTX patterns. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:5`.

### 7.5 ALPS specialization slot

- `user_surface`: Mike, ALPS team, CubCloud/Brandon, account managers, biz dev, underwriting, customer service. Evidence: `/Users/josh/Developer/alpsinsurance/planning/PARTNERS.md:39` and `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:275`.
- `primary_outcome_metric`: daily Mike report generated, brand-safe, and sent. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:6`.
- `secondary_outcome_metric`: Workato cutover ladder state and staging/shadow-mode readiness. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:19`.
- `client_comm_metric`: outcome language, no internal jargon, decisions needed, off-track risk. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:22`.
- `risk_metric`: staging not green, shadow-mode delay, open customer-visible decisions. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:28`.
- `moat_metric`: migration tooling and vertical regulated-SMB Workato replacement. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/planning/build-vs-fork.md:181`.
- `anti_dashboard_metric`: number of new surfaces justified against dashboard redundancy rule. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:295`.

### 7.6 Future repo specialization slots

- `zesttube`: `render_publishability`, `asset_provider_probe_freshness`, `viewer_quality`, `brand_voice`, `Remotion_fragility`. Evidence for ZestTube fragile Remotion note: `/Users/josh/Developer/flywheel/AGENTS.md:1`.
- `zeststream.ai`: `brand_voice_composite`, `CTA_conversion`, `SEO_health`, `lead_capture`, `unsupported_claims`. Evidence: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:22`.
- `aaas`: `customer_onboarding_stage`, `customer_health_score`, `forecast_confidence`, `conversion_signal`, `service_recovery`. Evidence for customer health skill: `/Users/josh/.claude/skills/customer-health-scoring/SKILL.md:3`.
- `langgraph`: `eval_baseline`, `golden_regression`, `provider_delta`, `agent_behavior_quality`, `user_task_success`. Evidence: `/Users/josh/.claude/skills/evaluation-framework/SKILL.md:16`.
- `agent-harness`: `benchmark_reproducibility`, `rubric_coverage`, `model_comparison_delta`, `regression_severity`, `CI_eval_status`. Evidence: `/Users/josh/.claude/skills/evaluation-framework/SKILL.md:20`.
- `nango`: `provider_canary_freshness`, `OAuth_scope_receipt`, `app_review_blocker`, `credential_boundary`, `customer_connector_readiness`. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/nango-webhook.ts:130`.

## 8. Provisional Verdict For Planner

### 8.1 What can be adopted now

- Adopt Layer 5 as a per-orchestrator product/customer slot, not a generic fleet score. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:156`.
- Adopt mobile-eats Layer 5 from existing brand voice, journey, feedback, canary, and expansion-readiness substrate. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:33`.
- Adopt skillos Layer 5 from skill inventory delta, Jeff/JSM delta, external research delta, pack graduation candidate, and skill quality gap. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:17`.
- Adopt VRTX Layer 5 from lead touch latency, signed scope, Teams action cards, and revenue milestone state. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:8`.
- Adopt ALPS Layer 5 from Mike report cadence, client-safe communication, phase ladder, and staging/shadow-mode state. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:22`.
- Adopt Layer 6 from skillos streams, JSM digest, research-triad/peel-report discipline, vendor-delta watch, and knowledge-moat adoption. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:43`.
- Adopt cascade detectors for the 10 patterns in Section 4. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:106`.

### 8.2 What should be extended

- Extend daily report schema with repo-specific Layer 5 and Layer 6 specialization slots. Evidence: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:156`.
- Extend skillos to own missing skill routes for `customer-360`, `research-delegate`, `jeff-intel`, `ultimate-leverage`, and `extreme-leverage` if planner deems them real substrate gaps. Evidence command: `test -f /Users/josh/.claude/skills/<missing>/SKILL.md`.
- Extend JSM digest repair before trusting it as a Layer 6 green signal. Evidence: `/Users/josh/.local/state/jsm/digest.md:8`.
- Extend product outcome receipt capture for mobile-eats first owner publish, VRTX live lead latency, and ALPS report sent-confirmation. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:203`, `/Users/josh/Developer/vrtx/manifest.yml:7`, and `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:14`.
- Extend research-to-action adoption tracking to close the current knowledge-moat depth gap. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.

### 8.3 What should not be built

- Do not build a single generic product health score. Evidence for per-orch specialization: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:156`.
- Do not build a dashboard Joshua has to inspect daily. Evidence for Lane A boundary: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:32`.
- Do not treat JSM digest as green while it reports unknown status from identity validation failure. Evidence: `/Users/josh/.local/state/jsm/digest.md:8`.
- Do not claim mobile-eats live social posting readiness from canary alone. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:460`.
- Do not claim VRTX product success without live lead latency evidence. Evidence for metric target: `/Users/josh/Developer/vrtx/manifest.yml:7`.
- Do not claim ALPS communication loop success without sent-report confirmation. Evidence for manual send step: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:14`.
- Do not claim knowledge moat from research volume without adoption into skills, doctrine, beads, product gates, or reusable artifacts. Evidence for missing knowledge-moat depth: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.

### 8.4 Highest-leverage recommendations

- Highest-leverage Layer 5 fix: implement a repo-specific product/customer slot with one primary outcome metric, one risk metric, one brand/scope metric, and one next action. Evidence for specialization: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:156`.
- Highest-leverage mobile-eats first metric: first verified owner publish before OAuth plus canary freshness. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:203` and `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:30`.
- Highest-leverage VRTX first metric: observed live lead touch latency and 30-second Teams notification proof. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:7` and `/Users/josh/Developer/vrtx/docs/runbooks/01-phase-1-leads.md:11`.
- Highest-leverage ALPS first metric: Mike report sent-confirmation plus staging/shadow-mode client-safe state. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:14` and `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:28`.
- Highest-leverage skillos first metric: skill recommendation adoption and local-only/candidate pack graduation blockers. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:53`.
- Highest-leverage Layer 6 fix: research-to-action adoption rate, because Lane D already identified knowledge-moat depth as missing. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Highest-leverage cascade detector: vendor/API delta -> stale skill -> failed customer promise, because VRTX/mobile-eats/ALPS all rely on external providers. Evidence: `/Users/josh/Developer/vrtx/audits/2026-04-28-sdk-research.md:271`.

### 8.5 Self-grade

| Gate | Grade | Evidence |
|---|---:|---|
| source-(a) first | 10.0 | `/tmp/dispatch_lane_f_product_research_2026-05-05.md:9` plus source-(a) query command |
| mandatory skill reading | 9.6 | 63 present `SKILL.md` files read; 5 missing reported with `test -f` commands |
| prior use | 9.7 | Lane A/B/C/D citations in Section 1.5 |
| Layer 5 coverage | 9.6 | mobile-eats, skillos, VRTX, ALPS, future repo slots in Sections 2 and 7 |
| Layer 6 coverage | 9.5 | JSM, skillos, research-triad, moat, vendor-delta, knowledge adoption in Section 3 |
| cascade patterns | 9.7 | 10 cross-layer detector patterns in Section 4 |
| anti-patterns | 9.6 | 12 anti-patterns in Section 6 |
| L113 evidence binding | 9.6 | file:line or command evidence attached to all material DID/DID NOT claims |
| research-only discipline | 9.8 | no source edit, no bead create, one reserved output artifact |
| composite | 9.62 | arithmetic self-assessment across gates above |

### 8.6 Callback metrics

- `skills_best_practices_top_10_cited=yes`
- `skills_read_count=63`
- `skills_missing=customer-360,research-delegate,jeff-intel,ultimate-leverage,extreme-leverage`
- `socraticode_queries=12`
- `indexed_chunks_observed=77498`
- `layer_5_extractors_usable=12`
- `layer_5_extractors_needed=8`
- `layer_6_extractors_usable=8`
- `layer_6_extractors_needed=7`
- `cascade_patterns_documented=10`
- `cascade_detectors_needed=10`
- `per_orch_specialization_slots_defined=10`
- `antipatterns_addressed=12`
- `no_bead_reason=research_only_planner_artifact`

## Appendix A - Daily Meeting Card Sketches

### A.1 mobile-eats daily card

- Card title: `mobile-eats product readiness`. Evidence for product repo focus: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:7`.
- Card audience: hungry locals, owners, community helpers, moderators. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:44`.
- Card north star: find open-now trucks with trust and owner publish flow. Evidence: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:14`.
- Card green condition: first owner publish, canary fresh, no critical feedback, brand language clean. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:203`.
- Card yellow condition: canary stale, owner publish unmeasured, feedback P1s open, or expansion proof debt grows. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/expansion-markets.ts:106`.
- Card red condition: critical payment/security/cannot-publish feedback, live-post claim without approval, or public copy leaks internal terms. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/feedback.ts:374`.
- Card `product_signal`: `first_owner_publish_before_oauth`. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:203`.
- Card `trust_signal`: `open_now_confidence_and_stale_recovery`. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:48`.
- Card `feedback_signal`: `critical_feedback_count`. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/feedback.ts:374`.
- Card `canary_signal`: `owner_social_canary_status`. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:30`.
- Card `brand_signal`: `implementation_terms_leaked_count`. Evidence: `/Users/josh/Developer/mobile-eats/docs/mobile-eats-brand-voice.md:26`.
- Card `moat_signal`: `source_backed_local_truth_inputs`. Evidence: `/Users/josh/Developer/mobile-eats/docs/wireframe-v1.md:21`.
- Card `next_action`: route to owner-publish, canary, feedback, or expansion-proof bead. Evidence for future bead journey rule: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:12`.
- Card forbidden output: "Mobile Eats ready" without one user-outcome receipt. Evidence for user-outcome metric: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:203`.
- Card forbidden output: "social sync ready" from dry-run/canary alone. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:460`.

### A.2 skillos daily card

- Card title: `skillos skill substrate readiness`. Evidence for skillos mission focus: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:2`.
- Card audience: orchestrators, workers, skill consumers, future skill authors. Evidence for accountabilities: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:33`.
- Card north star: know available skills, route usage, judge quality/freshness, watch Jeff/JSM, ingest research, and route skill/pack/doctrine. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:33`.
- Card green condition: catalog drift controlled, JSM/Jeff delta fresh, skill quality gaps routed, packs have validation and publish blockers explicit. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:53`.
- Card yellow condition: JSM digest degraded, local-only pack aged, missing skill not routed, or source freshness unknown. Evidence: `/Users/josh/.local/state/jsm/digest.md:8`.
- Card red condition: workers block without skill consultation or repeat skill gaps remain unrouted. Evidence for L54/L55 doctrine: `/Users/josh/Developer/flywheel/AGENTS.md:54` and `/Users/josh/Developer/flywheel/AGENTS.md:55`.
- Card `product_signal`: `skill_recommendation_adoption_rate`. Evidence for usage routing: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:36`.
- Card `quality_signal`: `skill_quality_gap_count`. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:22`.
- Card `pack_signal`: `pack_graduation_candidate_state`. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:21`.
- Card `jsm_signal`: `jsm_digest_status`. Evidence: `/Users/josh/.local/state/jsm/digest.md:8`.
- Card `jeff_signal`: `jeff_jsm_delta_count`. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:19`.
- Card `research_signal`: `external_research_delta_count`. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:20`.
- Card `next_action`: route to skillos, jsm-review, pack validation, or explicit no-action. Evidence for `/jsm-review` prompt: `/Users/josh/.local/state/jsm/digest.md:23`.
- Card forbidden output: calling local-only pack reusable outside local-only boundary. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:23`.
- Card forbidden output: presenting JSM as healthy while digest probes are unknown. Evidence: `/Users/josh/.local/state/jsm/digest.md:8`.

### A.3 VRTX daily card

- Card title: `VRTX 4-hour lead system`. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:1`.
- Card audience: Derek, Jack, Rene, Kirstin, VRTX leads, VRTX members, ZooTown participants. Evidence: `/Users/josh/Developer/vrtx/docs/proposal-vrtx-2026-04-03.md:1`.
- Card north star: every lead touched within 4 hours via Teams without Jack as bottleneck. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:8`.
- Card green condition: live lead notifications under 30 seconds, follow-up under 4 hours, signed scope green, no unresolved route-window blocker. Evidence: `/Users/josh/Developer/vrtx/docs/runbooks/01-phase-1-leads.md:11`.
- Card yellow condition: route/window proof pending, lead latency not measured, scope drift warning, or strategic decision parked. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:45`.
- Card red condition: live leads not touched inside 4 hours, Jack bottleneck reappears, or client-facing deliverable conflicts with signed scope. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:56`.
- Card `product_signal`: `leads_touched_under_4hr_via_teams`. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:7`.
- Card `speed_signal`: `lead_notification_under_30_seconds`. Evidence: `/Users/josh/Developer/vrtx/docs/runbooks/01-phase-1-leads.md:11`.
- Card `scope_signal`: `signed_scope_line_item_status`. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:18`.
- Card `delivery_signal`: `phase_1_subgoal_coverage`. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:13`.
- Card `brand_signal`: `voice_canonical_and_mirror_state`. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:25`.
- Card `moat_signal`: `reusable_client_template_extracted`. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:5`.
- Card `next_action`: ship route proof, scope coverage, latency evidence, or Derrek marketing workflow walkthrough. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:52`.
- Card forbidden output: "Phase 1 green" without observed lead latency. Evidence: `/Users/josh/Developer/vrtx/manifest.yml:7`.
- Card forbidden output: treating audit bonuses as replacements for signed scope. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:60`.

### A.4 ALPS daily card

- Card title: `ALPS Mike-loop and cutover readiness`. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:10`.
- Card audience: Mike, ALPS operators, Brandon/CubCloud, Josh, account management, underwriting, biz dev. Evidence: `/Users/josh/Developer/alpsinsurance/planning/PARTNERS.md:39`.
- Card north star: Workato cutover by mid-July through HubSpot-first dev/staging/prod and daily Mike-loop. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:10`.
- Card green condition: Mike report sent, staging green, shadow-mode countdown active, R1-R7 no red, no client-visible blocker. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:32`.
- Card yellow condition: report drafted not sent, staging not green, or shadow-mode start delayed. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:28`.
- Card red condition: Mike report stale/missing, Workato cutover blocker becomes client action, or internal jargon leaks. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:31`.
- Card `product_signal`: `mike_report_sent_today`. Evidence for manual send step: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:14`.
- Card `cutover_signal`: `phase_ladder_state`. Evidence: `/Users/josh/Developer/alpsinsurance/continue-here.md:19`.
- Card `client_comm_signal`: `daily_report_format_compliance`. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:22`.
- Card `risk_signal`: `staging_green_and_shadow_mode_dependency`. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:28`.
- Card `moat_signal`: `vertical_workato_replacement_migration_tooling`. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/planning/build-vs-fork.md:181`.
- Card `anti_dashboard_signal`: `dashboard_redundancy_justified`. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:295`.
- Card `next_action`: client-safe staging status, send report, dispatch cutover blocker, or route dashboard request to value test. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:24`.
- Card forbidden output: "Mike-loop green" without sent-report receipt. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:14`.
- Card forbidden output: exposing bead IDs, doctor internals, secret names, codepaths, commits, PRs, or file paths to Mike. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:31`.

## Appendix B - Detector Specs

### B.1 Detector 1: `layer5_product_outcome_missing`

- Purpose: detect a repo card with no primary product/customer outcome metric. Evidence for Layer 5 mandate: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:54`.
- Input: daily ops schema `primary_outcome_metric`. Evidence for schema slot: Section 7.1 of this artifact.
- Trigger: metric absent or value `unknown` for an active repo. Evidence for active repo set: Lane D per-repo sections at `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:525`.
- Severity: yellow unless repo has client/public launch commitment, then red. Evidence for public/client commitments: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:18` and `/Users/josh/Developer/alpsinsurance/continue-here.md:10`.
- Drain: orchestrator files or dispatches the missing extractor or records explicit no-product-surface reason. Evidence for L52 routing: `/Users/josh/Developer/flywheel/AGENTS.md:52`.

### B.2 Detector 2: `layer6_research_adoption_missing`

- Purpose: detect research volume without adoption into action. Evidence for knowledge-moat gap: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Input: research artifacts, skillos external delta, JSM digest, vendor-delta rows. Evidence for skillos external delta: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:20`.
- Trigger: research item older than 7 days with no skill, doctrine, bead, product gate, or explicit no-action receipt. Evidence for layer routing doctrine: `/Users/josh/Developer/flywheel/AGENTS.md:56`.
- Severity: yellow for isolated row, red for repeated same domain. Evidence for frequency promotion doctrine: `/Users/josh/Developer/flywheel/AGENTS.md:56`.
- Drain: skillos route, doctrine route, bead route, product gate, or no-action receipt. Evidence for skillos accountabilities: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:33`.

### B.3 Detector 3: `brand_voice_claim_gap`

- Purpose: detect unsupported claims or brand drift in client/public surfaces. Evidence: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:21`.
- Input: report/copy artifacts, brand config, banned words, ground truth entries. Evidence: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:20`.
- Trigger: unsupported factual claim, composite below threshold, banned word, or repo-specific forbidden language. Evidence: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:22`.
- Severity: red for public/client deliverable, yellow for internal draft. Evidence for client-facing human review: `/Users/josh/.claude/skills/proposal-generation/SKILL.md:30`.
- Drain: rewrite, cite, mark human review, or declare not client/public-facing. Evidence for peel KNOW/INFER/GUESS/BLIND rule: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:34`.

### B.4 Detector 4: `client_scope_drift`

- Purpose: catch product/deliverable drift against signed client scope. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:56`.
- Input: signed scope, manifest, mission, deliverable artifact, daily card. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:1`.
- Trigger: client-facing promise not in signed scope and not labeled audit bonus. Evidence: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:60`.
- Severity: red for VRTX live deliverable, yellow for draft research. Evidence for VRTX mission gate: `/Users/josh/Developer/vrtx/MISSION.md:24`.
- Drain: restore scope, label audit bonus, or park strategic decision. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:45`.

### B.5 Detector 5: `daily_report_not_sent`

- Purpose: separate report existence from customer communication completion. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:14`.
- Input: daily report artifact path, send receipt, review state. Evidence for report storage: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:44`.
- Trigger: final report exists but no send confirmation by cadence close. Evidence for 16:00 manual send: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:14`.
- Severity: yellow same day, red if stale over 24 hours for R1. Evidence for R1 metric: `/Users/josh/Developer/alpsinsurance/continue-here.md:32`.
- Drain: send, record sent receipt, or explicit blocker. Evidence for format and decisions sections: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/README.md:22`.

### B.6 Detector 6: `live_canary_claim_mismatch`

- Purpose: detect live-readiness claims that exceed canary/proof boundary. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:460`.
- Input: canary receipt, live-post gate status, report copy, callback text. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/nango-webhook.ts:146`.
- Trigger: copy says live social posting is ready while live gate remains disabled or separate approval absent. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/launch-ops-readiness.ts:460`.
- Severity: red for public/client copy, yellow for internal note. Evidence for mobile-eats public copy rule: `/Users/josh/Developer/mobile-eats/docs/mobile-eats-brand-voice.md:26`.
- Drain: downgrade wording, capture live approval, or keep canary as one-shot proof only. Evidence: `/Users/josh/Developer/mobile-eats/next-app/lib/mobile-eats/nango-webhook.ts:169`.

### B.7 Detector 7: `jsm_digest_degraded`

- Purpose: prevent degraded JSM digest from being treated as a green Layer 6 signal. Evidence: `/Users/josh/.local/state/jsm/digest.md:8`.
- Input: digest updated timestamp and probe fields. Evidence: `/Users/josh/.local/state/jsm/digest.md:3`.
- Trigger: updates/conflicts/needs_push/local_only/doctor failed checks are unknown. Evidence: `/Users/josh/.local/state/jsm/digest.md:10`.
- Severity: yellow while fallback signals exist, red if JSM is used for promotion decisions. Evidence for skillos JSM safe boundary: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:25`.
- Drain: `/jsm-review`, guarded runner repair, or explicit no-JSM-decision. Evidence: `/Users/josh/.local/state/jsm/digest.md:23`.

### B.8 Detector 8: `pack_local_only_stagnation`

- Purpose: keep local-only/candidate packs from being mistaken for reusable published substrate. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:23`.
- Input: pack registry lifecycle, target, validation, promotion requirements. Evidence: `/Users/josh/Developer/skillos/state/packs/registry.json:53`.
- Trigger: candidate/gated local-only pack has downstream demand and no promotion/no-publish receipt. Evidence for candidate vendor pack: `/Users/josh/Developer/skillos/state/skillpack-candidate-vendor-wranglers-2026-05-05T0500Z.json:6`.
- Severity: yellow for no downstream demand, red for repeated vendor failures. Evidence for skillos routing accountabilities: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:33`.
- Drain: validate, promote, route to human review, or record no-publish reason. Evidence for promotion requirements: `/Users/josh/Developer/skillos/state/packs/registry.json:34`.

### B.9 Detector 9: `dashboard_redundancy_risk`

- Purpose: stop new dashboards that duplicate existing surfaces without user value. Evidence: `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:295`.
- Input: proposed product surface, user ask, existing dashboards/views, action-card alternative. Evidence for VRTX action-card preference: `/Users/josh/Developer/vrtx/docs/vrtx-system-map.md:206`.
- Trigger: new dashboard proposed with no explicit user ask or action workflow. Evidence for ALPS dashboard rule: `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:297`.
- Severity: yellow for internal tool, red for client-facing scope expansion. Evidence for VRTX signed scope: `/Users/josh/Developer/vrtx/docs/SIGNED-SCOPE.md:56`.
- Drain: convert to action card, defer, or cite explicit user value. Evidence for ALPS "build only if ops user asks" rule: `/Users/josh/Developer/alpsinsurance/knowledge/wave-3/discovery-anchors.md:299`.

### B.10 Detector 10: `metric_goodhart_risk`

- Purpose: prevent daily meeting metrics from becoming agent ranking or superficial green. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:166`.
- Input: daily report metrics, scoring text, human-visible summaries. Evidence for fleet health one-number risk context: `/Users/josh/Developer/flywheel/AGENTS.md:2791`.
- Trigger: metric reported without outcome receipt, adoption receipt, or no-receipt reason. Evidence for evaluation rubric contract: `/Users/josh/.claude/skills/evaluation-framework/SKILL.md:20`.
- Severity: yellow by default, red if metric drives ranking or punitive action. Evidence for Lane A surveillance-loop warning: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:166`.
- Drain: add paired outcome/adoption receipt or remove metric from meeting surface. Evidence for Donella information-flow framing: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:115`.

## Appendix C - Skill-To-Layer Mapping

- `zeststream-brand-voice` maps to L5 brand, L5 publishability, and L6 claim-grounding. Evidence: `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md:3`.
- `voice-of-customer` maps to L5 customer feedback, L5 churn signal, and L6 feedback-to-roadmap. Evidence: `/Users/josh/.claude/skills/voice-of-customer/SKILL.md:21`.
- `proposal-generation` maps to L5 client deliverable, L5 scope, and L5 commercial risk. Evidence: `/Users/josh/.claude/skills/proposal-generation/SKILL.md:30`.
- `email-delivery` maps to L5 customer communication, L5 deliverability, and L5 conversion reliability. Evidence: `/Users/josh/.claude/skills/email-delivery/SKILL.md:166`.
- `customer-communication` maps to L5 client daily reports, L5 incident notes, and L5 service recovery. Evidence: `/Users/josh/.claude/skills/customer-communication/SKILL.md:3`.
- `sales-forecasting` maps to L5 revenue-facing product metrics and L6 strategy forecast. Evidence: `/Users/josh/.claude/skills/sales-forecasting/SKILL.md:26`.
- `client-ecosystem-audit` maps to L5 client discovery and L6 reusable client intelligence. Evidence: `/Users/josh/.claude/skills/client-ecosystem-audit/SKILL.md:3`.
- `email-sequence` maps to VRTX lead nurture, ALPS client comms, and mobile-eats owner retention. Evidence: `/Users/josh/.claude/skills/email-sequence/SKILL.md:52`.
- `seo-audit` maps to public product discoverability and future zeststream.ai slot. Evidence: `/Users/josh/.claude/skills/seo-audit/SKILL.md:3`.
- `launch-strategy` maps to mobile-eats public launch, VRTX milestone launch, and future product launch gating. Evidence: `/Users/josh/.claude/skills/launch-strategy/SKILL.md:3`.
- `ux-audit` maps to L5 usability, user journey, and pre-launch UX risk. Evidence: `/Users/josh/.claude/skills/ux-audit/SKILL.md:3`.
- `web-visual-qa` maps to L5 visual/product QA for public surfaces. Evidence: `/Users/josh/.claude/skills/web-visual-qa/SKILL.md:3`.
- `research-triad` maps to L6 external research and source triangulation. Evidence: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:15`.
- `multi-model-triangulation` maps to L6 research confidence and strategy synthesis. Evidence command: `test -f /Users/josh/.claude/skills/multi-model-triangulation/SKILL.md`.
- `multi-document-rag` maps to L6 multi-source knowledge retrieval. Evidence command: `test -f /Users/josh/.claude/skills/multi-document-rag/SKILL.md`.
- `knowledge-base-management` maps to L6 knowledge usefulness and L5 support deflection. Evidence: `/Users/josh/.claude/skills/knowledge-base-management/SKILL.md:15`.
- `knowledge-graph` maps to L6 shared reasoning substrate and cross-repo relationship tracing. Evidence: `/Users/josh/.claude/skills/knowledge-graph/SKILL.md:20`.
- `operationalizing-expertise` maps to L6 method capture, L6 quote/provenance, and skill/doctrine outputs. Evidence: `/Users/josh/.claude/skills/operationalizing-expertise/SKILL.md:52`.
- `evaluation-framework` maps to L5 product quality gates and L6 strategy/eval scoring. Evidence: `/Users/josh/.claude/skills/evaluation-framework/SKILL.md:20`.
- `analytics-tracking` maps to L5 outcome instrumentation and L6 adoption metrics. Evidence: `/Users/josh/.claude/skills/analytics-tracking/SKILL.md:102`.
- `ab-testing` maps to L5 product experiments and L6 learning cadence. Evidence: `/Users/josh/.claude/skills/ab-testing/SKILL.md:75`.
- `ga4` maps to L5 public conversion tracking and L6 product-market learning. Evidence: `/Users/josh/.claude/skills/ga4/SKILL.md:3`.
- `churn-prediction` maps to L5 retention risk and L6 customer-health strategy. Evidence: `/Users/josh/.claude/skills/churn-prediction/SKILL.md:3`.
- `zeststream-peel-report` maps to L5 client deliverable, L6 validate-not-assume moat, and KNOW/INFER/GUESS/BLIND discipline. Evidence: `/Users/josh/.claude/skills/zeststream-peel-report/SKILL.md:40`.
- `zeststream-n8n` maps to L5 client integration product gates and L6 platform reuse. Evidence: `/Users/josh/.claude/skills/zeststream-n8n/SKILL.md:16`.

## Appendix D - Planner-Ready Build Order

- Step 1: add shared Layer 5/6 schema slots to the daily meeting schema. Evidence for schema specialization requirement: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:156`.
- Step 2: wire mobile-eats card with existing docs and code first because it has the richest public product substrate. Evidence: `/Users/josh/Developer/mobile-eats/docs/customer-journey-wireframe-v1.md:33`.
- Step 3: wire VRTX card around 4-hour lead touch and signed-scope drift because the client milestone is active. Evidence: `/Users/josh/Developer/vrtx/MISSION.md:8`.
- Step 4: wire ALPS card around Mike-loop and staging/shadow-mode because the daily report already exists. Evidence: `/Users/josh/Developer/alpsinsurance/reports/mike-daily/2026-05-05.md:1`.
- Step 5: wire skillos card around skill/JSM/research deltas because it owns the skill substrate. Evidence: `/Users/josh/Developer/skillos/state/mission-skill-system-expertise-2026-05-03T2219Z.json:33`.
- Step 6: add detector `layer6_research_adoption_missing` because Lane D calls knowledge-moat depth missing. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md:611`.
- Step 7: repair or downgrade JSM digest before treating it as green. Evidence: `/Users/josh/.local/state/jsm/digest.md:8`.
- Step 8: only then add future repo slots for zesttube, zeststream.ai, aaas, langgraph, agent-harness, and nango. Evidence for future repo list: `/tmp/dispatch_lane_f_product_research_2026-05-05.md:62`.
- Step 9: keep anti-Goodhart pairing by requiring each score to cite an outcome/adoption receipt. Evidence: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-A-donella.md:166`.
- Step 10: route missing skill candidates to skillos rather than implementing in planner code. Evidence for L55 skillos routing: `/Users/josh/Developer/flywheel/AGENTS.md:55`.

## Appendix E - Final Evidence Ledger

- Evidence ledger source count: dispatch, source-(a) command, 63 skill reads, 12 Socraticode searches, 4 Socraticode status checks, Lane A/B/C/D, mobile-eats, skillos, VRTX, ALPS, JSM digest.
- Evidence ledger citation density can be rechecked with: `rg -n "Evidence:|Evidence command:" /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md | wc -l`.
- File line count can be rechecked with: `wc -l /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md`.
- Required section coverage can be rechecked with: `rg -n "^## [1-8]\\. " /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md`.
- Top-10 source-(a) citation coverage can be rechecked by searching `Source-(a) result`. Evidence command: `rg -n "Source-\\(a\\) result" /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md`.
- Callback metric coverage can be rechecked by searching `Callback metrics`. Evidence command: `rg -n "Callback metrics|skills_read_count|socraticode_queries|indexed_chunks_observed" /Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-F-product-research.md`.
