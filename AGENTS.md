# Flywheel Canonical Operational Doctrine

## How to read this file

This is the canonical "how agents operate" reference, distributed via
flywheel-loop init to every flywheel-installed repo as
`.flywheel/AGENTS-CANONICAL.md`. Each repo's local AGENTS.md should
reference this file and add only repo-specific operational rules.
Domain rules (what we're building, not how we operate) belong in CLAUDE.md.

## L-Rule Schema

Each L-rule below uses this frontmatter (YAML between `---` fences):

| Field | Type | Required | Meaning |
|---|---|---|---|
| id | string | yes | e.g. L48 (canonical id, never reused) |
| title | string | yes | one-line summary |
| status | enum | yes | long_term \| temporary \| retired |
| shipped | date | yes | YYYY-MM-DD when rule first landed |
| sunset_when | object | if temporary | bead: bd-XXX OR metric: <expr> OR date: YYYY-MM-DD |
| review_due | date | yes | YYYY-MM-DD next mandatory re-evaluation |
| trauma_class | string | yes | grouping label (e.g. phantom-substrate) |
| retired_by | object | if retired | bead/metric/date that triggered + retired_at |
| retired_at | date | if retired | YYYY-MM-DD |

## Rules

## L48 — SUBSTRATE-EXHAUSTION-BEFORE-ESCALATION

---
id: L48
title: Substrate-Exhaustion-Before-Escalation
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: phantom-substrate
---

Before any orchestrator message that asks Josh a credential-shaped,
substrate-corruption-shaped, or service-state-shaped question, it MUST first
climb these rungs and produce a probe ledger:

1. **Substrate probe** — `infisical secrets --path=/<service>`, `infisical secrets list --recursive | grep -i <service>`, `cf-secret list`, `gh secret list`, `op item list` (1Password). Alternate creds frequently already exist under a different path.
2. **Self-heal tool** — look for `scripts/<thing>_repair.sh` (e.g. `bead_db_repair.sh` is Tier 2 autonomous, L35). Run it. Substrate corruption usually has a named recovery path.
3. **Skill recovery section** — every relevant `*-ops` / `*-api` / `*-secrets` skill has a "Common failures" or "Recovery" block. `ls ~/.claude/skills/` and read it.
4. **Cross-repo precedent** — `mcp__socraticode__codebase_search` for the exact error string across `~/Developer/*` (canonical paths only, see L47-class symlink trauma); grep `~/.claude/projects/*/memory/` for prior CASS hits.

Only after 4 rungs return "no resolution" may the orchestrator ping Josh. The
escalation message MUST include a probe ledger of what was attempted:

```text
PROBE_LEDGER bead=bd-XXX
  rung1=infisical/cf-secret/gh-secret -> <result>
  rung2=self-heal-tool=<name> -> <exit_code>
  rung3=skill=<name> recovery -> <result>
  rung4=socraticode "<error>" -> <hits>
remaining_ask=<single concrete thing or NONE>
```

**Cost citation:** alpsinsurance pane 1 idle 2026-04-30 — orchestrator hit
Railway token-scope wall (`projectCreate=ok`, `variableUpsert=Unauthorized`),
framed it as "two yes/no questions for Josh" + "2-minute dashboard operation
from your laptop", and went 30-min heartbeat. Substrate had answers:
`infisical-rotation-ops` skill encodes project-token generation, `railway-api`
skill encodes browserless OTP login, parallel `br` corruption blocker had
`bead_db_repair.sh`-class fix in adjacent repo. Project sat idle for hours on a
wall the substrate could resolve.

**Forbidden orchestrator outputs (when not preceded by probe ledger, grade F):**
"two yes/no questions", "2-minute dashboard operation", "do you want to
generate", "should I attempt ... recovery", anything that frames a credential
or substrate problem as a human-only operation without proof the substrate path
was probed.

**Override:** `JOSHUA_OVERRIDE='<reason>'` permits one ledger-less escalation;
logs to `~/.local/state/flywheel-loop/overrides.jsonl`. One-shot only.

**Doctrine artifact:**
`~/Developer/flywheel/templates/flywheel-install/ESCALATION-LADDER.md.tmpl`
ships the canonical 5-rung structure; flywheel-loop init drops it into every
`.flywheel/` install.

## L29 — NTM-only doctrine

---
id: L29
title: NTM-only doctrine — never operational tmux for pane I/O
status: long_term
shipped: 2026-04-30
review_due: 2027-04-30
trauma_class: dispatch-substrate
---

**Rule:** All pane operations (send, capture, list, save, grep, health, spawn, kill) MUST route through `ntm` verbs. The underlying terminal multiplexer binary is forbidden in operational substrate. Positive-only instruction — never name the wrong tool in deny messages, examples, or cautionary guidance (negation amplifies salience).

**How to apply:**
- Send to a pane → `ntm send <session> --pane=<n> "..."`
- Capture pane → `ntm copy <session>:<pane> -l <N>`
- Search pane → `ntm grep <session> <pattern>`
- Health check → `ntm health <session>`
- Save snapshot → `ntm save <session>`
- All of the above also via `/flywheel:ntm <verb>` slash surface

**Why:** agents have huge pretraining bias toward the underlying multiplexer name and near-zero on `ntm`. Without active reinforcement (positive-only doctrine + ambient slash surface + intent-detection gate), every agent regresses to the wrong tool every session. The `flywheel-loop-dispatch-transport-gate.sh` denies direct underlying-multiplexer-binary dispatch invocations.

**Evidence:** 2026-04-30 audit found 7+ active `~/.claude/{commands,skills,hooks}/` paths still using direct multiplexer calls; pane 2 audit log at `/tmp/picoz-pane2-flywheel-install-audit.md` Section A.7. Cleanup is bd-cwfs2 substep 8 + ongoing.

## L35 — Every Tier 3 classification requires a paired-tool bead

---
id: L35
title: Tier 3 classification requires paired-tool bead
status: long_term
shipped: 2026-04-19
review_due: 2026-10-30
trauma_class: autonomy-ratchet
---

**Rule:** When classifying a blocker Tier 3 (per CLAUDE.md §Tier 3 / AGENTS.md §L22), file a paired bead `bd-tool-to-downgrade-<class>` in the **same tick**. The paired bead asks: "what tool, if it existed, would make this Tier 2 next time?" Track the ratio of Tier 3 classifications with paired tools built within 30 days. Goal: every recurring blocker class has a tool; Tier 3 shrinks to zero — all gates become coded.

**Why:** 2026-04-19 afternoon. Orphan PID 97714 was classified Tier 3 ("shared-state kill requires approval"). That classification is technically correct but autonomy-ratcheting: every time this class appears, a human is needed. No tool gets built. The autonomy stock drains. Meadows: eroding-goal ratchet (`[ER]`).

**The actual failure:** orphan of a dead python child with `ppid=1` is not "shared state." No live process references it. It's routine ops cleanup. A 5-gate verified reap tool (lsof port + ppid=1 + comm=python3 + cwd + pgrep) is clearly Tier 2 — and I built it this session (`scripts/reap_orphan_ingest.sh`) in ~10 minutes after Josh forced the frame.

**Mechanism:** add to sweep.md STEP 2.5 escalation ladder: after 3 consecutive HOLDs on same blocker, Grade C if paired-tool bead exists, Grade D otherwise. Pattern: `bd-tool-to-downgrade-orphan-ingest-child`, `bd-tool-to-downgrade-<next-class>`, etc.

**Evidence:** `scripts/reap_orphan_ingest.sh` shipped this session. Reaped PID 97714 successfully (5 gates passed, SIGTERM, SIGKILL, launchctl respawn verified). Next orphan = autonomous, not a 9hr Tier 3 stall.


## L50 — SOCRATICODE-MANDATORY-IN-EVERY-DISPATCH (every NTM dispatch surveys what we have before writing what we want)

---
id: L50
title: Socraticode-mandatory in every dispatch
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: substrate-amnesia
---

**Rule:** Every NTM dispatch packet sent to a worker pane MUST require socraticode pre-flight before any design or implementation work begins. Worker callbacks MUST report `socraticode_queries=N` and `indexed_chunks_observed=N`. Zero-query callbacks fail the dispatch contract — orchestrator re-dispatches with the survey requirement re-emphasized.

**Why:** Josh 2026-04-30 mission statement: "I need to ensure that every single dispatch ntm wide is using socraticode to look at what we have — that is part of the mission. We know about what exists in every layer of our playground." Without enforcement, agents repeatedly reinvent existing skills/scripts/L-rules. Substrate amnesia is the failure mode where a 4-month-old solution gets re-derived from scratch because nobody surveyed first. The flywheel only compounds when each cycle reads what prior cycles produced.

**Mandatory pre-flight pattern in every dispatch packet:**

```
## MANDATORY PRE-FLIGHT: socraticode survey

Required calls (MCP tool: `mcp__socraticode__codebase_search`):
1. codebase_search query="<domain term 1>" projectPath="<canonical-not-symlink>" limit=10
2. codebase_search query="<domain term 2>" projectPath="<canonical>" limit=10
... (3-5 queries minimum, more for complex tasks)

Use canonical path (not symlink alias). If `indexed_chunks=0` on every
query, abort and re-run on canonical path (L47-class symlink trauma).

Save findings to /tmp/<step>-research-survey.md.
```

**Mandatory callback fields:**
- `socraticode_queries=N` (count of MCP calls actually made)
- `indexed_chunks_observed=N` (sum of indexed_chunks across results — proves canonical path used)

**Forbidden orchestrator outputs (when dispatching):** packets without a socraticode pre-flight section, packets that reference a symlink path instead of canonical, packets that ask the worker to "go figure it out" without surveying.

**Forbidden worker callback outputs (per dispatch contract):** any DONE/BLOCKED message without `socraticode_queries=` field. Orchestrator treats missing field as DRIFT — re-dispatches with reinforced pre-flight.

**Override:** `JOSHUA_OVERRIDE='<reason>'` permits one ledger-less dispatch (extremely rare; reserved for trivial single-line edits where survey overhead exceeds work).

**Cost citation:** four months of project history accreted scattered scripts/configs/hooks/CLIs because each new task started from scratch instead of surveying. Tonight Josh re-stated the mission explicitly. This rule is the mechanical enforcement of the mission.

**Companion rules:** L46 (picoz-local — Axiom 9 commit-message socraticode trailer for substrate-critical commits) is the commit-time check. L50 (this — canonical) is the dispatch-time check. Both layers needed: dispatch-time prevents re-derivation; commit-time prevents merging without evidence.


## L51 — DISPATCH-FILE-RESERVATIONS-MANDATORY (every multi-file worker dispatch reserves files via agent-mail before edits)

---
id: L51
title: Dispatch file reservations mandatory
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: concurrent-worker-drift
---

**Rule:** Every NTM dispatch that asks a worker to edit 1+ files MUST include an agent-mail file reservation step in its pre-flight section. Worker reserves files BEFORE first edit, releases on completion (DONE) or release-on-blocked (BLOCKED). Dispatch packets that name file paths but lack a reservation step are non-compliant per L51.

**Why:** Concurrent workers across multiple panes of a single NTM session, OR across multiple NTM sessions sharing a working tree, race on the same files. The picoz-specific `PICOZ_WORKER_FILES` pathspec hook (per local AGENTS.md and bd-rqrsr) catches one shape of this — accidental cross-attribution at commit time. But it doesn't prevent the underlying race; two workers can edit the same function in parallel and the second commit wins silently. Agent-mail file reservations make the lock explicit and pane-attributable BEFORE edits begin.

**Mechanism:**
- Skill: `agent-mail` is already installed; verbs include `reserve-files`, `release`, `renew_file_reservations`, `force_release_file_reservation`
- Pre-flight in dispatch packet: `mcp__mcp-agent-mail__macro_file_reservation_cycle` with declared file paths
- Worker callbacks must include `files_reserved=<comma-list>` and `files_released=<comma-list>`
- Orchestrator releases held reservations on dispatch timeout (default 60min) via `force_release_file_reservation` per agent-mail SETUP

**Forbidden orchestrator outputs:** dispatch packets that list `PICOZ_WORKER_FILES=...` without a paired `mcp__mcp-agent-mail__reserve_files` step. Pathspec discipline catches collisions at commit; reservation prevents collisions at edit. Both layers needed.

**Override:** `JOSHUA_OVERRIDE='<reason>'` permits one ledger-less dispatch (rare; reserved for trivial single-file orchestrator-pane work where reservation overhead exceeds work).

**Cost citation:** ~3 incidents over the last 60 days where worker-A and worker-B both edited the same file region; second commit silently overwrote first; bug surfaced 2-3 days later when the missing logic was needed in production. The pathspec hook flagged the cross-attribution but the *content drift* was already merged.

**Companion rules:** L50 (socraticode-mandatory) is dispatch-time substrate awareness; L51 (this) is dispatch-time concurrency safety. Both required for every multi-file dispatch.


## L52 — ISSUES-TO-BEADS-OR-EXPLICIT-NO-BEAD-RECEIPT (no observed gap is absorbed silently)

---
id: L52
title: Every observed issue becomes a bead or carries an explicit no_bead_reason receipt
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: silent-finding-loss
---

**Rule:** Every gap, finding, trauma, or unexpected behavior observed during a worker dispatch MUST become one of:
1. A new bead filed in the originating repo's bead DB (or the repo most relevant to the gap), with the bead ID reported in the worker callback
2. An update to an existing bead (referenced by ID in callback)
3. An EXPLICIT `no_bead_reason` field in the callback explaining why this finding is not bead-worthy (e.g. "transient flake, retried clean", "worker-private scratch issue, fixed in same dispatch")

Worker callbacks lacking ALL of bead_ids_filed / bead_ids_updated / no_bead_reason are non-compliant per L52. Orchestrator treats missing field as DRIFT and re-dispatches asking for the missing receipt.

**Why:** picoz Phase A CLI audit (2026-04-19) discovered that pane 4 reported `findings=N beads_filed=0` — observed real defects, didn't bead them, called it done. Without an explicit no_bead_reason, the orchestrator can't distinguish "no findings" from "findings absorbed silently." Silent-finding-loss is the failure mode where every dispatch produces signal but only a fraction makes it into the trackable substrate.

**Mechanism:**
- Pre-flight in dispatch packet: instructions naming the bead DB path (`<repo>/.beads/`) and the `br create` command shape
- Pre-flight: workers MUST use `scripts/br_create_safe.sh` (or local equivalent) per L47-class enforcement, never raw `br create`
- Callback contract: every DONE/BLOCKED includes one of:
  - `beads_filed=bd-XXX,bd-YYY,...`
  - `beads_updated=bd-XXX:status_change,...`
  - `no_bead_reason=<short-text>` (explicit choice, not absence)

**Forbidden worker callback outputs:** any DONE/BLOCKED missing all three fields. Re-dispatch on detection.

**Override:** None. Silent finding loss has no acceptable footprint — even the "trivial" finding gets a single-line no_bead_reason. JOSHUA_OVERRIDE does NOT bypass L52 because the cost of a forgotten finding compounds.

**Cost citation:** Phase A CLI audit (2026-04-19) found 7 launch-relevant defects pane 4 had observed but not beaded. Required orchestrator to manually re-derive findings from worker scrollback and file beads after the fact. ~30 min recovery cost per missed finding. L52 makes the cost zero by mechanically requiring the callback field.

**Companion rules:** L47 (substrate-owner discipline; canonical-substrate claims require enforcement) — L52 enforces the bead-creation substrate across every dispatch, not just commit-time.


## L53 — FUCKUPS-REPORTED-IN-CALLBACK (every blocker / trauma / gap surfaces as a fuckup-log row)

---
id: L53
title: Fuckups reported in every dispatch callback
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: trauma-amnesia
---

**Rule:** Every BLOCKED callback AND every DONE callback that hit a trauma along the way MUST log a fuckup-log row via `flywheel-loop fuckup log` BEFORE sending the callback. The callback then references the fuckup-log row IDs (or the JSONL line numbers, or the trauma_class names) so the orchestrator can correlate the callback with the durable record.

DONE callbacks for clean dispatches MAY skip fuckup logging (no trauma → nothing to log). BLOCKED callbacks MUST always log at least one fuckup row describing the blocker.

**Why:** Without enforcement, traumas survive only in pane scrollback and then evaporate at /clear time or session end. The fuckup-log substrate (shipped 2026-04-30 via ac02fb6 + f8efbec) only compounds value if every dispatch contributes rows. Trauma-amnesia is the failure mode where the same blocker surprises the next worker on the next session because nobody persisted it.

**Mechanism:**
- Pre-flight in dispatch packet: instructions to call `~/.claude/skills/.flywheel/bin/flywheel-loop fuckup log --class=<trauma> --severity=<sev> --what-happened=<text>` on every blocker
- Callback contract: BLOCKED requires `fuckups_logged=<class1>,<class2>,...`; DONE may include `fuckups_logged=` if any traumas were observed (empty is valid for clean DONE)
- Auto-emission complement: even if the worker forgets, hook-blocks/overrides auto-harvest catches volume signals (per L50 doctrine — both manual and automatic)

**Forbidden worker callback outputs:** BLOCKED missing `fuckups_logged=` field; DONE that hit a documented trauma without `fuckups_logged=`.

**Override:** None for BLOCKED. JOSHUA_OVERRIDE does not bypass L53 because escalation without a durable trauma record is exactly the substrate-amnesia mode this rule prevents.

**Cost citation:** br DB wedge recurred multiple times today (2026-04-30) before being captured as a fuckup row. The first 2 wedges left no record other than scrollback; only the third triggered the manual fuckup log entry. With L53 in place, every wedge would have been recorded immediately, and triage would have surfaced "br-db-wedge fired 3 times this session" before the human noticed.

**Companion rules:** L48 (substrate-exhaustion) requires probe ledger before escalating to Josh — the probe ledger and the fuckup-log row are different artifacts (ledger = "what I tried", fuckup-log = "what failed"). Both required, not redundant.


## L54 — SKILL-DEEP-DIVE-ON-BLOCKERS (workers climb the skill tree before declaring a wall)

---
id: L54
title: Skill deep-dive on blockers before BLOCKED callback
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: skill-substrate-bypass
---

**Rule:** Before any worker sends a BLOCKED callback, they MUST climb the skill tree:
1. List skills relevant to the trauma class (`ls ~/.claude/skills/ | grep -i <relevant-keyword>`)
2. Read SKILL.md + any "Recovery" / "Common failures" section in 2-3 most-relevant skills
3. Attempt the recovery path documented in those skills, record outcomes
4. Only after rungs 1-3 produce no resolution may BLOCKED be sent

BLOCKED callbacks must include `skills_consulted=<name1>,<name2>,...` listing every skill whose recovery path was actually executed (not just listed). Empty `skills_consulted=` on a BLOCKED callback is non-compliant — even for trauma classes that have no obvious skill, the worker MUST report the search attempted (e.g. `skills_consulted=NONE_FOUND grep_terms_used=br-db-wedge,beads-corrupt,sqlite-recovery`).

**Why:** We have ~280 skills in `~/.claude/skills/`. Most workers blocked today never consulted a single one before escalating. Skill substrate bypass is the failure mode where 4 months of accreted reusable knowledge sits unread because workers default to "ask the orchestrator" or "ask Josh" before reading the arsenal.

**Mechanism:**
- Pre-flight in dispatch packet: explicit list of "skills likely relevant to this dispatch" (orchestrator does the initial mapping; worker still verifies and consults)
- Callback contract: BLOCKED requires `skills_consulted=<list-or-NONE_FOUND>`. DONE may include the field if skills helped but it's optional for clean DONE.
- Escalation chain (per L48 + L54): substrate probe → self-heal tool → **skill recovery section (L54)** → cross-repo precedent → only then human

**Forbidden worker callback outputs:** BLOCKED missing `skills_consulted=` field; BLOCKED with empty list and no `NONE_FOUND` justification with grep_terms_used.

**When no skill exists for the trauma:** This is the L55 trigger — escalate to skillos session for new skill authoring (see L55 below).

**Cost citation:** alpsinsurance idle 2026-04-30 hours waited at "Railway token Q1/Q2 for Josh" — both `infisical-rotation-ops` and `railway-api` skills exist with recovery sections covering the exact wall (project-token generation + browserless OTP). Worker never read either. L54 makes that read mandatory.

**Companion rules:** L48 (substrate-exhaustion-before-escalation) is the broader 5-rung ladder; L54 is the specific "rung 3" enforcement. Without L54, agents declared L48 satisfied while skipping the skill rung.


## L55 — SKILLOS-ESCALATION-FOR-MISSING-SKILLS (when no skill exists for a trauma class, route to skillos)

---
id: L55
title: Missing-skill escalation routes to skillos session
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: skill-arsenal-gap
---

**Rule:** When L54 deep-dive returns `skills_consulted=NONE_FOUND` for a recurring trauma class (3+ fuckup-log occurrences within 7 days), the trauma is escalated to the **skillos NTM session** as a candidate skill. Escalation mechanism:
1. Worker logs the fuckup with `should_become=skill`
2. Doctor's `fuckup_triage` section flags 3+ `NONE_FOUND` rows of same class as candidate for skillos
3. Orchestrator (or doctor itself, future) sends a draft-skill packet to skillos via `ntm send skillos --pane=1` with the trauma class, evidence sample, and proposed skill name
4. skillos session handles authoring, review, and publication into `~/.claude/skills/<name>/` per its own MISSION/GOAL/STATE
5. Once published, the next worker hitting the same trauma finds the skill via L50 socraticode survey → loop closes

**Why:** The skill arsenal only compounds if missing skills are systematically authored, not ad-hoc patched. Authoring inside consumer sessions (picoz orchestrator pauses to write a skill mid-trade-decision) pollutes the skill with consumer context. Authoring in skillos keeps skills universal-first per skillos MISSION.md.

**Mechanism:**
- Trigger: `flywheel-loop doctor` `fuckup_triage` candidate with `should_become=skill` AND frequency ≥3-in-7d
- Routing: `ntm send skillos --pane=1` with structured packet:
  ```
  CANDIDATE_SKILL trauma_class=<class> frequency=<count> evidence=<3-row-sample> proposed_name=<kebab-case-suggestion> originating_session=<which-session-hit-this>
  ```
- skillos consumes via its own tick loop; worker dispatches don't block waiting for skill authoring (asynchronous)
- New skill ships when ready; L50 socraticode survey makes it discoverable on next dispatch

**Forbidden orchestrator outputs:** sending CANDIDATE_SKILL packets to any session other than skillos. The dedicated session is the only authorized author of new skills (other sessions consume, never write to `~/.claude/skills/`).

**Override:** `JOSHUA_OVERRIDE='<reason>'` permits direct authoring in a non-skillos session for emergencies (e.g. mid-incident response, can't wait for skillos cycle). Logged; reviewed at next petal-9 close.

**Cost citation:** ~280 existing skills accreted ad-hoc across 4 months — many duplicate each other, none have provenance, none were authored against a shared quality bar. L55 prevents the next 280 from accreting the same way.

**Companion rules:** L54 (skill deep-dive on blockers) detects the gap. L55 (this) closes it. skillos MISSION.md (`~/Developer/skillos/.flywheel/MISSION.md`) defines the receiving substrate.

**Receiving substrate state (2026-04-30):** skillos session exists in NTM (`skillos`), repo bootstrapped at `~/Developer/skillos/`, MISSION.md drafted (status=draft awaiting Josh review). L55 enforcement active once MISSION.md locks AND `flywheel-loop init --repo /Users/josh/Developer/skillos` succeeds. Until then, CANDIDATE_SKILL packets queue at `~/.local/state/flywheel/skillos-pending-candidates.jsonl` for skillos to drain on first tick.


## L56 — FUCKUP-LOG → INCIDENTS → CANONICAL-L-RULE PROMOTION LADDER

---
id: L56
title: Fuckup-log → INCIDENTS → canonical-L-rule promotion ladder
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: doctrine-orphaning
---

**Rule:** Doctrine accretion follows a 3-layer ladder, each layer referencing the layer below for evidence:

1. **Layer 1 — fuckup-log (event substrate):** every observed trauma/gap/failure logs a row to `~/.local/state/flywheel/fuckup-log.jsonl` (manual via `flywheel-loop fuckup log` OR auto via `fuckup harvest`).
2. **Layer 2 — INCIDENTS.md (per-component doctrine):** when a trauma class hits frequency threshold (3+ events in 7 days, OR single event with severity=high + cost citation), promote to a per-component INCIDENTS.md entry with Forever-Rule + cost citation + at least ONE fuckup-log row range as evidence.
3. **Layer 3 — canonical L-rule (universal doctrine):** when multiple repos hit the same trauma class OR a single repo's INCIDENTS entry generalizes cleanly cross-repo, promote to a canonical L-rule in `~/Developer/flywheel/AGENTS.md` referencing the source INCIDENTS entries as evidence.

**Why:** Without the ladder, two failure modes recur:

- **Doctrine orphaning:** INCIDENTS.md entries appear with no fuckup-log evidence (un-grounded Forever-Rules that may not reflect real frequency); canonical rules appear with no INCIDENTS entries (premature universalization on N=1 anecdotes).
- **Substrate amnesia:** fuckup-log fills with rows that never get promoted; the same trauma class hits the next agent next week.

**Cost citation:** Tonight (2026-04-30), I logged a `doctrine-accretion` row in fuckup-log for the L51-L55 commit (`0482431`). That was wrong substrate placement — doctrine accretion is a permanent positive event, not a fuckup. Without L56 + a clear ladder, future agents will keep mis-routing signal between layers. L56 mechanizes the routing.

**Mechanism — evidence linkage requirements:**

Every layer-2 INCIDENTS.md entry MUST cite at least one of:

- Specific fuckup-log row range: `~/.local/state/flywheel/fuckup-log.jsonl#L<N>-L<M>`
- Specific bead ID(s): `bd-XXX`
- Specific commit sha(s): `<sha>`

Every layer-3 canonical L-rule MUST cite at least one of:

- INCIDENTS.md entry path: `<repo>/INCIDENTS.md#<entry>` OR `~/.claude/skills/<skill>/references/INCIDENTS.md#<entry>`
- 3+ fuckup-log rows from the same trauma class

`flywheel-loop doctor --strict` will (Step 6d, future) check evidence linkage across layers and flag orphan entries.

**Mechanism — promotion cadence:**

- **Frequency-based:** doctor's `fuckup_triage` section already surfaces 3-in-7d candidates as warn / 5-in-24h candidates as error (commit `71df912`). L56 makes that triage the explicit ladder decision point.
- **Severity-based:** single high-severity event with cost citation (real $ or hours) MAY promote without 3+ frequency, at human discretion via `/flywheel:learn --promote <class>`.
- **Cross-repo emergence:** when 2+ repos' INCIDENTS files have matching entries, candidate for canonical L-rule (manual review).

**Forbidden orchestrator outputs:**

- Authoring a canonical L-rule without citing an INCIDENTS entry OR 3+ fuckup-log rows
- Authoring an INCIDENTS entry without citing fuckup-log evidence (initial seed entries authored before fuckup-log existed are grandfathered — they may cite git commits or trauma narratives instead)
- Logging doctrine accretions / positive events as fuckup-log rows (those belong in INCIDENTS as historical context OR in a future petal-9 close digest, NOT in fuckup-log which is for traumas)

**Companion rules:** L48 (substrate-exhaustion) is the operational discipline; L52 (issues-to-beads) routes findings to bead substrate; L53 (fuckups-reported) ensures layer 1 captures every event; L54 (skill-deep-dive) consumes layer 2 + 3 as recovery substrate. L56 glues all of these into a coherent learning architecture.

**User surface:** `/flywheel:learn` is the unified command that hides the layer routing from the human (orchestrator handles classification). L56 is the architectural rule the command implements.
