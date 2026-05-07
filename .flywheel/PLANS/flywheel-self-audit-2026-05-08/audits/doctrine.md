# Doctrine Layer Audit - 2026-05-08

Bead: `flywheel-3c5eq`

Scope: root `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`,
`templates/flywheel-install/AGENTS.md`, active L-rules through root/template
L126, canonical-only L127/L128 drift, pending worker-close commit doctrine,
MISSION anchor, Three Reasoning Spaces, the six TRUE Joshua-blocker classes,
mission-lock, and the six prior layer audits.

Socraticode receipt: `socraticode_queries=6`, all against
`/Users/josh/Developer/flywheel` with `limit=10`. Queries covered `L-rule`,
MISSION anchor, AGENTS.md surfaces, mission-lock, Joshua-blocker classes, and
Three Reasoning Spaces.

## 1. Inventory

### Doctrine artifacts

| Artifact | Citation | Role |
|---|---|---|
| Root doctrine surface | `AGENTS.md:29`, `AGENTS.md:3703` | Operator-facing canonical doctrine in this repo. Contains 75 active L-rule headings from L29/L35/L48/L50-L126, with numbering holes. |
| Repo-local canonical snapshot | `.flywheel/AGENTS-CANONICAL.md:34`, `.flywheel/AGENTS-CANONICAL.md:3823` | Repo-local snapshot. Contains the same 75 active rules plus canonical-only L127 and L128. |
| Install template doctrine | `templates/flywheel-install/AGENTS.md:29`, `templates/flywheel-install/AGENTS.md:3690` | Doctrine distributed to new flywheel installs. Stops at L126. |
| Three-surface doctrine rule | `AGENTS.md:2338`, `.flywheel/AGENTS-CANONICAL.md:2353`, `templates/flywheel-install/AGENTS.md:2325` | L96 requires root, canonical snapshot, and install template to move as one coherent diff. |
| MISSION anchor document | `.flywheel/MISSION.md:1`, `.flywheel/MISSION.md:3`, `.flywheel/MISSION.md:35`, `.flywheel/MISSION.md:40` | Locked repo mission and self-sustaining company paradigm anchor. |
| Mission anchor canonical wording | `.flywheel/MISSION.md:35`, `.flywheel/MISSION.md:40`, `.flywheel/MISSION.md:43` | North star: self-improving orchestration substrate; command center for Joshua's agent fleet. |
| Three Reasoning Spaces | `/Users/josh/.claude/CLAUDE.md:11`, `/Users/josh/.claude/CLAUDE.md:15`, `/Users/josh/.claude/CLAUDE.md:17` | Plan, bead, and code spaces, with bead ~=5x plan cost and code ~=25x plan cost. |
| Self-audit layer contract | `.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:7`, `.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:17`, `.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:21` | Defines doctrine as audit layer 7 and requires the six-section audit shape. |
| Six TRUE Joshua-blocker classes | `/Users/josh/.claude/commands/flywheel/plan.md:258`, `/Users/josh/.claude/commands/flywheel/plan.md:260`, `/Users/josh/.claude/commands/flywheel/plan.md:264` | Exhaustive list of legitimate human pauses after mission-lock. |
| TRUE-blocker precedence | `/Users/josh/.claude/commands/flywheel/plan.md:218`, `/Users/josh/.claude/commands/flywheel/plan.md:224`, `/Users/josh/.claude/commands/flywheel/plan.md:229` | Deterministic first-fire order for multi-class blockers. |
| Mission-lock cure | `/Users/josh/.claude/commands/flywheel/plan.md:293`, `/Users/josh/.claude/commands/flywheel/plan.md:295`, `/Users/josh/.claude/commands/flywheel/plan.md:297` | Pre-resolves blocker classes 1-4 with approved vendors, tiers, budget, ToS, and secrets. |
| Mission-anchor-init contract | `/Users/josh/.claude/skills/mission-anchor-init/SKILL.md:16`, `/Users/josh/.claude/skills/mission-anchor-init/SKILL.md:18`, `/Users/josh/.claude/skills/mission-anchor-init/SKILL.md:52` | Ritual for creating, opting into, and validating mission anchors. |
| Mission-lock fields | `/Users/josh/.claude/commands/flywheel/plan.md:297`, `/Users/josh/.claude/commands/flywheel/plan.md:298`, `/Users/josh/.claude/commands/flywheel/plan.md:304` | Concrete license-envelope fields used by class checks. |
| External doctrine benchmark | `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:28`, `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:50`, `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:94` | Public benchmark for plan/bead/code costs, staggered swarm launch, and no hard strategic course corrections. |
| Pending worker-close commit rule | `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_worker_close_requires_git_commit.md:7`, `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_worker_close_requires_git_commit.md:16`, `.beads/issues.jsonl:117` | Pending L-rule candidate requiring `git_committed=` and close-handler dirty-scope refusal. |

Inventory count: 15 doctrine artifacts plus 77 L-rule rows below.

### L-rule table

The active root/template doctrine has 75 headings. The repo-local canonical
snapshot has 77 headings because it adds L127 and L128 without root/template
propagation. The plan scope says L1-L126, but the actual active surfaces start
at L29/L35/L48 and then L50; there are no active L1-L28, L30-L34, L36-L47,
L49, L74, L109, or L112-L114 headings in these three files.

| Cohort | IDs | Citations | Count |
|---|---|---|---:|
| Early active rules | L29, L35, L48, L50-L57 | `AGENTS.md:29`, `AGENTS.md:84`, `AGENTS.md:109`, `AGENTS.md:131`, `AGENTS.md:418` | 11 |
| Core substrate and doctrine rules | L58-L73, L75-L91 | `AGENTS.md:471`, `AGENTS.md:1243`, `AGENTS.md:1346`, `AGENTS.md:2173` | 33 |
| Fleet/productivity rules | L92-L108, L110-L111 | `AGENTS.md:2214`, `AGENTS.md:2338`, `AGENTS.md:2542`, `AGENTS.md:3045` | 19 |
| Recent orchestration and substrate rules | L115-L126 | `AGENTS.md:3157`, `AGENTS.md:3443`, `AGENTS.md:3610`, `AGENTS.md:3703` | 12 |
| Canonical-only rules | L127 prediction-lock, L128 EV anchors | `.flywheel/AGENTS-CANONICAL.md:3794`, `.flywheel/AGENTS-CANONICAL.md:3823` | 2 |
| Missing/unused numeric slots | L1-L28, L30-L34, L36-L47, L49, L74, L109, L112-L114 | Absence verified by `rg -n '^## L[0-9]+' AGENTS.md .flywheel/AGENTS-CANONICAL.md templates/flywheel-install/AGENTS.md`; root headings end at `AGENTS.md:3703` and canonical headings end at `.flywheel/AGENTS-CANONICAL.md:3823`. | not active |

## 2. Load-bearing

Method: for each active root L-rule I ran the required grep-shaped census
against the repo while excluding the three doctrine surfaces, then cross-checked
prior audit citations. Criterion: `>=3` repo callsite files outside the three
AGENTS surfaces OR explicit citation in one of the six prior audits.

Result: 73 of 75 root/template L-rules are load-bearing by that criterion.
The only active root rules below threshold are L123 and L124. Prior audits
explicitly surfaced L29, L50, L51, L52, L53, L57, L70, L71, L91, L101, L107,
L112, L115, L120, L125, L126, and pending L127. L112 is a callback/receipt
marker in prior audits, not an active L-rule heading in the three doctrine
surfaces.

| L-rule cohort | Why load-bearing | Evidence |
|---|---|---|
| L48-L57 dispatch and learning foundation | Every rule in this cohort has >=21 repo callsite files except L35, which still has 14. They define substrate exhaustion, NTM-only, socraticode, reservations, bead/no-bead receipts, fuckup logging, skill deep-dives, skillos escalation, promotion ladder, and driver proof. | `AGENTS.md:29`, `AGENTS.md:131`, `AGENTS.md:189`, `AGENTS.md:362`, `AGENTS.md:418`; prior audits cite L50 in `plan-space.md:86` and L51/L52/L53 in `coordination.md:100`. |
| L58-L71 safety, docs, live truth, no-punt, validate/redispatch | Counts range from 11 to 125 repo callsite files; L70 alone had 125. These rules explain why the orchestrator audit's monitor/refill loop is correct doctrine rather than a local optimization. | `AGENTS.md:471`, `AGENTS.md:641`, `AGENTS.md:937`, `AGENTS.md:1098`, `AGENTS.md:1171`; prior audit synthesis points at L70/L71 in `orchestrator.md:7`. |
| L72-L91 storage, identity, docs, idle state, delivery | All but none in this cohort clear >=5 callsite files; L91 is heavily used with 47 repo callsite files and appears in coordination/orchestrator audits. | `AGENTS.md:1243`, `AGENTS.md:1597`, `AGENTS.md:1883`, `AGENTS.md:2173`; prior coordination audit cites L29/L91 in `coordination.md:74`. |
| L92-L108 routing, three-surface doctrine, productivity, shared surfaces | Every active rule in this cohort clears >=8 repo callsite files. L96 is the central rule for this audit because canonical-only L127/L128 violate its three-surface contract. | `AGENTS.md:2214`, `AGENTS.md:2338`, `AGENTS.md:2542`, `AGENTS.md:2873`; prior audits cite L101 in `orchestrator.md:7` and L107 in `coordination.md:79`. |
| L110-L122 recent close and substrate rules | L110, L111, L115, L116, L117, and L120 are high-callsite and directly surfaced today; L120 and L126 form the callback evidence chain. | `AGENTS.md:2969`, `AGENTS.md:3045`, `AGENTS.md:3157`, `AGENTS.md:3443`, `AGENTS.md:3532`; prior audits cite L115/L120 in `orchestrator.md:7` and `coordination.md:35`. |
| L125-L126 sealed substrate and evidence packs | L125 has 7 repo callsite files and appears in bead-space; L126 has 23 callsite files and appears in plan, bead, and coordination audits. | `AGENTS.md:3670`, `AGENTS.md:3703`; prior audits cite L125 in `bead-space.md:105` and L126 in `plan-space.md:83`, `bead-space.md:134`, `coordination.md:36`. |
| Canonical-only L127 prediction-lock | It has 5 repo callsite files and is backed by close-gate tests, but it is not validly canonical under L96 until root/template propagation lands. | `.flywheel/AGENTS-CANONICAL.md:3794`, `.flywheel/AGENTS-CANONICAL.md:3809`, `.flywheel/AGENTS-CANONICAL.md:3813`. |

Load-bearing active root/template L-rules: 73. Load-bearing canonical-only
but three-surface-invalid rules: 1.

## 3. Vestigial

| Rule or surface | Why vestigial/superseded | Evidence | Disposition |
|---|---|---|---|
| L123 raw-terminal historical debt doctor visibility | Only 2 repo callsite files outside AGENTS surfaces and no prior-audit citation. The runtime rule L29 is still load-bearing; L123 may be historical debt visibility rather than current behavior. | `AGENTS.md:3572`; callsite census returned `callsites_repo_excl_surfaces=2`. | Keep as audit-only until the doctor field proves recent hits; otherwise retire or fold into L29/L91. |
| L124 no orchestrator pause for substrate discipline | Only 1 repo callsite file outside AGENTS surfaces and no prior-audit citation. It overlaps L48 substrate-exhaustion and L70 no-punt. | `AGENTS.md:3610`; callsite census returned `callsites_repo_excl_surfaces=1`. | Candidate to merge into L48/L70 or rewire into a measured doctor signal. |
| Canonical-only L128 EV anchors | Useful evidence idea, but only 2 repo callsite files and no root/template propagation. It cannot be treated as canonical under L96. | `.flywheel/AGENTS-CANONICAL.md:3823`, `.flywheel/AGENTS-CANONICAL.md:3835`; root/template stop at `AGENTS.md:3703` and `templates/flywheel-install/AGENTS.md:3690`. | Promote through a real three-surface diff or demote to implementation-local close-gate doctrine. |
| Canonical-only L127 prediction-lock surface | Behaviorally important, but its current surface is split-brain: canonical snapshot has L127 while root/template do not. | `.flywheel/AGENTS-CANONICAL.md:3794`, `AGENTS.md:3703`, `templates/flywheel-install/AGENTS.md:3690`. | Not vestigial as a behavior; invalid as a canonical surface until L96 is repaired. |
| Pending worker-close rule named "L127" | The pending memory says this should become L127, but `.flywheel/AGENTS-CANONICAL.md` already uses L127 for prediction-lock. | `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_worker_close_requires_git_commit.md:21`, `.flywheel/AGENTS-CANONICAL.md:3794`. | Assign the next free ID after reconciling L127/L128; do not land a second L127. |
| L112 references in prior audits | Prior audits cite `L112` as an OK/receipt marker, but no L112 heading exists in root, canonical, or template. | `bead-space.md:45`; absence verified by the three-surface heading scan. | Rename as receipt marker or promote to a real L-rule; do not cite as active doctrine. |

Vestigial/superseded count: 6.

## 4. Missing per agent-flywheel.com gap analysis

1. Come-to-Jesus / plan-vs-actual drift doctrine. The external guide defines
healthy swarms as having no hard strategic course corrections
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:94`)
and the local gap analysis calls for plan-vs-actual drift checks
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:173`).
The orchestrator audit proposed a tick/status drift probe, but no L-rule yet
requires plan-vs-actual prediction at tick close.

2. Outcome-shape benchmarks. The external benchmark gives a concrete success
shape: plan length, bead count, LOC, agent count, commits, and elapsed time
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:187`).
The orchestrator audit proposes a status line; doctrine has no rule yet saying
status must compare current arcs against outcome-shape baselines.

3. Lie-to-them exhaustive re-review technique. The external gap analysis names
the deliberate "assume many misses" adversarial prompt technique
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:157`).
Plan-space found no named local analogue in `/flywheel:plan`,
multi-model-triangulation, or plan-space-convergence (`plan-space.md:123`).
Doctrine should define this as adversarial prompt pressure, not factual evidence.

4. Fungible agents framing. The external guide defines fungible agents as
generalist/interchangeable and names specialist/ringleader agents as
anti-patterns (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:33`,
`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:69`).
Flywheel mostly follows this by using pane workers under common dispatch
contracts, but there is no concise L-rule making fungibility the default
staffing principle when dispatching waves.

5. Clockwork-deity human role. The external guide says the human designs the
machine, launches the swarm, and tends it
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:254`).
Local doctrine aligns through Three Reasoning Spaces and mission-lock
(`/Users/josh/.claude/CLAUDE.md:7`, `/Users/josh/.claude/commands/flywheel/plan.md:260`),
but the phrasing is not wired into status/dispatch as a crisp "Joshua tends;
flywheel owns next action" doctrine surface.

Tier gaps addressed: 5.

## 5. Lessons learned (today's evidence)

1. Pending worker-close commit doctrine is real P0 doctrine debt. Mobile-eats
found 7 of 8 worst closed beads had implementation in a dirty tree with no
close commit, and the memory requires `git_committed=<yes|no_changes|skipped>`
plus dirty-scope refusal (`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_worker_close_requires_git_commit.md:7`,
`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_worker_close_requires_git_commit.md:16`).
This should land as a sibling to L120/L126, but not as L127 unless the
canonical-only L127/L128 numbering drift is resolved first.

2. DCG prose-trigger discipline should become authoring doctrine. The feedback
memory records three blocks on prose contexts and instructs agents to strip or
rephrase dangerous substrings before passing bead/dispatch text through shell
arguments (`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dcg_prose_trigger_strip_dangerous_substrings.md:7`,
`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dcg_prose_trigger_strip_dangerous_substrings.md:15`,
`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dcg_prose_trigger_strip_dangerous_substrings.md:24`).
This is not a DCG bug; it is an authoring rule for Bash-mediated packet bodies.

3. Doctrine-broadcast privacy filtering is already acting as doctrine, but only
as script code. The send script blocks bodies matching
`josh|/Users/josh|flywheel-[a-z0-9]+|zeststream`
(`.flywheel/scripts/doctrine-broadcast-send.sh:66`, `.flywheel/scripts/doctrine-broadcast-send.sh:67`).
Coordination audit shows the broadcast sidechannel is now load-bearing
(`coordination.md:80`, `coordination.md:144`). The filter caught three leak
attempts today per dispatch context; the gap is that refusal counts are not yet
durably logged as doctrine-broadcast authoring receipts.

4. L96 did work today by exposing split-brain doctrine. If this audit only read
`.flywheel/AGENTS-CANONICAL.md`, it would conclude L127/L128 landed. Root and
template prove otherwise (`AGENTS.md:3703`, `templates/flywheel-install/AGENTS.md:3690`,
`.flywheel/AGENTS-CANONICAL.md:3794`). L96 is not decorative; it caught the
surface that would mislead synthesis.

5. The prior audits show doctrine is most useful when it is wired into a tool.
L57 matters because `/flywheel:loop status` needs driver proof; L91 matters
because dispatch delivery is observed, not assumed; L120/L126 matter because
callbacks carry close facts, not self-grade prose. Pure prose rules without
doctor/status/close-handler consumers decay toward vestigial.

## 6. Fix-bead manifest

Recommendations only; no beads filed.

1. **P0 - `[doctrine] reconcile L127/L128 three-surface drift and land worker-close commit rule`**
   Scope: root `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`,
   `templates/flywheel-install/AGENTS.md`, dispatch-template, close-handler
   validator, and callback schema docs.
   Acceptance: prediction-lock and EV-anchor rules either land on all three
   surfaces or are renumbered/demoted; worker-close rule lands with a unique ID;
   DONE callbacks require `git_committed=`; close-handler refuses dirty declared
   scope; tests cover dirty, no-change, and skipped-with-reason cases.

2. **P1 - `[doctrine] codify swarm health gaps: stagger-spawn, plan-vs-actual drift, and outcome-shape status`**
   Scope: new/updated L-rule plus `/flywheel:tick`, `/flywheel:status`, and
   spawn wrapper docs/tests.
   Acceptance: multi-agent spawn has explicit stagger policy or
   `stagger_not_applicable`; tick emits plan-vs-actual drift status; status
   renders outcome-shape ratios; fixtures cover healthy and drifted arcs.

3. **P1 - `[doctrine] codify packet-authoring filters for DCG prose and doctrine-broadcast privacy`**
   Scope: dispatch-template, doctrine-broadcast send script, authoring guidance,
   and tests.
   Acceptance: dangerous-substring prose goes through file bodies or safe
   paraphrases; doctrine-broadcast refusals are logged with counts and no body
   echo; filter matches produce durable receipts; no live secret/path/project
   identifiers leak into peer broadcast bodies.

Fix beads proposed: 3.

## 7. Doctrine surface analysis from prior 6 audits

### L-rules that surfaced as load-bearing today

| Audit | Load-bearing doctrine surfaced |
|---|---|
| Plan-space | L50 Socraticode pressure and L126 evidence-pack/close-gate replacement. It also surfaced missing doctrine for weighted convergence and lie-to-them re-review (`plan-space.md:83`, `plan-space.md:86`, `plan-space.md:123`). |
| Bead-space | L112 as a receipt marker, L125 sealed substrate, and L126 compliance evidence (`bead-space.md:45`, `bead-space.md:105`, `bead-space.md:134`). |
| Code-space | No named L-rule dominated, but the audit exposed missing UBS-before-every-commit enforcement, which should route through future close/pre-commit doctrine (`code-space.md:60`, `code-space.md:84`). |
| Coordination | L29, L51, L91, L107, L120, and L126 were central: NTM-only, file reservations, four-state delivery, shared-surface reservations, close-before-callback, and compliance pack callbacks (`coordination.md:20`, `coordination.md:29`, `coordination.md:35`, `coordination.md:74`, `coordination.md:79`). |
| Orchestrator | L57, L70, L71, L91, L101, L115, and L120 framed driver proof, no-punt, redispatch, delivery, fleet productivity, peer recovery, and callback close (`orchestrator.md:7`, `orchestrator.md:76`, `orchestrator.md:98`, `orchestrator.md:120`). |
| Hygiene | Pending worker-close commit rule, DCG prose-trigger discipline, and stagger-spawn enforcement surfaced as doctrine gaps rather than pure hygiene (`hygiene.md:70`, `hygiene.md:98`, `hygiene.md:106`). |

Convergent load-bearing set from all six audits: L29, L50, L51, L52, L53, L57,
L70, L71, L91, L101, L107, L115, L120, L125, L126, pending worker-close commit
rule, and canonical-only L127 prediction-lock.

### Doctrine layers: load-bearing vs vestigial today

| Layer | Today verdict | Evidence |
|---|---|---|
| Root `AGENTS.md` | Load-bearing and most trustworthy for active canonical doctrine because root/template agree through L126. | `AGENTS.md:29`, `AGENTS.md:3703`; prior audits cite root lines for L29/L51/L120/L126 (`coordination.md:20`, `coordination.md:35`, `coordination.md:36`). |
| `.flywheel/AGENTS-CANONICAL.md` | Load-bearing as a snapshot, but currently divergent after L126. | `.flywheel/AGENTS-CANONICAL.md:3735`, `.flywheel/AGENTS-CANONICAL.md:3794`, `.flywheel/AGENTS-CANONICAL.md:3823`. |
| Install template | Load-bearing for fleet propagation and agrees with root through L126. | `templates/flywheel-install/AGENTS.md:29`, `templates/flywheel-install/AGENTS.md:3690`. |
| MISSION anchor | Load-bearing for self-sustaining fleet framing, but noisy because `.flywheel/MISSION.md` also contains a long request ledger after the lock receipt. | `.flywheel/MISSION.md:35`, `.flywheel/MISSION.md:40`, `.flywheel/MISSION.md:117`. |
| Mission-lock / blocker taxonomy | Load-bearing and high-leverage: it prevents phantom Joshua blockers. | `/Users/josh/.claude/commands/flywheel/plan.md:260`, `/Users/josh/.claude/commands/flywheel/plan.md:262`, `/Users/josh/.claude/commands/flywheel/plan.md:295`. |
| Three Reasoning Spaces | Load-bearing conceptual router; prior audits map directly onto plan, bead, and code-space cost classes. | `/Users/josh/.claude/CLAUDE.md:11`, `/Users/josh/.claude/CLAUDE.md:17`, `/Users/josh/.claude/CLAUDE.md:19`, `.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:47`. |

### Doctrine gaps surfaced

1. No active L-rule for stagger-spawn despite coordination and hygiene both
finding it (`coordination.md:109`, `hygiene.md:70`).
2. No three-surface-valid L-rule for prediction-lock even though canonical-only
L127 exists (`.flywheel/AGENTS-CANONICAL.md:3794`, `AGENTS.md:3703`).
3. No L-rule for DCG prose-trigger authoring despite three observed blocks
(`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dcg_prose_trigger_strip_dangerous_substrings.md:7`).
4. No landed L-rule for worker-close requires git commit despite P0 mobile-eats
evidence (`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_worker_close_requires_git_commit.md:7`).
5. Doctrine-broadcast privacy filter is script-only and lacks durable refusal
receipts (`.flywheel/scripts/doctrine-broadcast-send.sh:66`, `coordination.md:215`).

Doctrine gaps surfaced: 5.

### Convergent fix-bead candidates

The six prior audits produced several overlapping proposals. Synthesis should
dedupe them into three families:

1. **Close/callback evidence chain:** L120/L126 plus pending worker-close commit
rule, UBS-before-commit, generated bead body quality, and compliance-pack
validation. This merges plan/bead/code/coordination/hygiene findings around
"a closed unit must have durable evidence and committed scoped changes."

2. **Swarm launch and progress health:** stagger-spawn, plan-vs-actual drift,
outcome-shape benchmark, hot-pane refill, and loop driver proof. This merges
coordination/orchestrator/hygiene recommendations around "healthy swarms do not
stampede, idle, or drift silently."

3. **Authoring and broadcast hygiene:** DCG prose-trigger, doctrine-broadcast
privacy filter, missing sidechannel consume receipts, and public/de-slopify
patterns. This merges coordination/hygiene/code findings around "packets and
public artifacts must be safe to transmit, parse, and quote."

Meta-section complete: 6 prior audits synthesized.
