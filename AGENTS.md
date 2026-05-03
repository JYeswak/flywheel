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

### Doctrine Note — Skills Library Load-Bearing META-RULE

The skills library is a first-class substrate, not a fallback reference. At every
project start, milestone shift, or mission pivot, consult
`/flywheel:skills-best-practices <domain>` before socraticode or research-triad
work. Adopted skill references belong in mission-lock receipts, dispatch
packets, or bead descriptions so the reusable practice survives beyond the
current pane.

Evidence:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_skills_library_load_bearing.md`.


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


## L57 — LOOP-STATE-MARKER-NOT-DRIVER

---
id: L57
title: Loop state marker is not a driver
status: long_term
shipped: 2026-05-02
review_due: 2026-11-02
trauma_class: loop-state-without-driver
---

**Rule:** A flywheel loop is not active until its driver has been verified; `~/.flywheel/loops/<project>.json active=true`, doctor receipts, and tick receipts are markers, not drivers.

**Why:** Marker-only loops silently fail. A repo can claim `active=true` and emit `tick_complete` receipts while no orchestrator pane receives prompts and no work advances. Mobile-eats hit this on 2026-05-02: the launchd script ran doctor/tick but never called `ntm send`, so the Codex pane sat idle while the substrate claimed the loop was active.

**How to apply:**
- CC orchestrator panes require proof that `Skill("loop", args="<interval> /flywheel:tick")` was invoked from inside the live pane.
- Codex, web, shell, and other non-CC orchestrator panes require an external driver: launchd plist plus a tick script that writes a prompt file and calls `ntm send <session> --pane=<N> --file <prompt> --no-cass-check`.
- For launchd prompt mode, verify all three before saying "loop active": plist loaded, tick script contains `ntm send`, and the recent log contains `event:"ntm_dispatch_sent"`.
- Verify prompt delivery at the pane as a second truth source; `ntm_dispatch_sent` without recent pane evidence is a stale-driver warning.
- Doctor/tick receipts without a driver are observation-only and MUST NOT be reported as an active loop.

**Doctor invariant:** `flywheel-loop doctor --repo <repo>` should report `driver_status=verified|marker_only|stale|missing`. If loop state is active and no driver proof exists, the doctor emits SOFT violation `loop_state_without_driver`; strict mode may fail.

## Audit Playbook

Run this when L57 is suspected or after any loop-driver doctrine change:

1. Enumerate `~/.flywheel/loops/*.json`.
2. For each `active=true` marker, read the loop state and classify orchestrator kind from latest `~/.local/state/flywheel/session-topology.jsonl` plus `ntm health <session> --json`.
3. For Codex, web, shell, or other non-CC orchestrators, require all driver proof: plist loaded, executable tick script, `ntm send --file` in the script, recent `event:"ntm_dispatch_sent"` within 2 cadence windows, and prompt evidence in the target pane.
4. Return exactly one verdict per project:
   - `VERIFIED`: active marker plus live driver proof.
   - `MARKER_ONLY`: active marker exists, but only state files, doctor receipts, or tick receipts exist.
   - `STALE`: driver exists, but send or pane evidence is older than 2 cadence windows.
   - `MISSING_DRIVER`: active non-CC marker and no plist/script/equivalent driver candidate found.
   - `NOT_APPLICABLE_CC`: CC/Claude loop where `Skill("loop")` proof is expected instead of launchd prompt proof.
   - `UNKNOWN`: topology, health, config, or pane evidence contradict each other.
5. Treat `MARKER_ONLY` and `MISSING_DRIVER` as critical silent-failure regressions. Treat `STALE` as high severity until an intentional pause is proven.

First proven canonical: the 2026-05-02 fleet audit caught ALPS as `MARKER_ONLY` within 30 minutes of L57 promotion. See `/tmp/loop_driver_audit_fleet_findings.md` for the initial proof corpus and `~/.claude/skills/flywheel-end-to-end/references/INCIDENTS.md` for the doctrine entry. The launchd prompt reference implementation is `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick`.

**Forbidden outputs:**
- "Loop active" based only on `active=true`
- "Loop running" based only on `tick_complete` or closeout receipts
- Installing a launchd plist that runs doctor/tick but lacks an `ntm send --file` prompt dispatch
- Hardcoding a pane number without topology/config lookup and pane health cross-check

**Evidence:** `~/.local/state/flywheel/fuckup-log.jsonl:201`; `~/.claude/skills/flywheel-end-to-end/references/INCIDENTS.md#loop-state-without-driver-2026-05-02`; `~/.claude/commands/flywheel/loop.md` Codex orchestrator pattern; `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick`; `/Users/josh/Developer/skillos/.flywheel/run-30m-loop.sh`.

**Companion rules:** L29 (NTM-only doctrine) governs the pane transport; L50 makes dispatches survey existing loop substrate; L56 defines the promotion ladder used to lift this incident into canonical doctrine.


## L58 — AGENT-MAIL-TOKENS-NEVER-IN-PANE-TEXT

---
id: L58
title: Agent Mail tokens never in pane-visible text
status: long_term
shipped: 2026-05-02
review_due: 2026-11-02
trauma_class: agent-mail-token-echo-in-pane
---

**Rule:** Agent Mail registration tokens MUST never be placed in visible pane commands, dispatch packets, callbacks, reports, or copied transcript evidence; use MCP-native token fields or vault-backed helpers, and redact before pane capture.

**Why:** Pane scrollback is operational substrate. It is copied by `ntm`, searched by workers, summarized into callbacks, and reused as evidence. Once a `registration_token` value or token-shaped fragment is rendered into that substrate, the exposure has already happened before Agent Mail server-side redaction, DCG, or report hygiene can protect it. This class fired 13 times in 24h across ALPS, skillos, and mobile-eats.

**How to apply:**
- Prefer MCP Agent Mail tools with structured token parameters over shell-visible commands or prose snippets containing `registration_token`.
- Store and load reusable Agent Mail tokens through vault-backed helpers; do not paste tokens into dispatch packets or callback examples.
- When pane evidence is required, capture through a redacting filter first and report only "token-shaped text observed", never the value.
- Before closing Agent Mail work, grep changed files and intended reports for `registration_token` and long token-shaped fragments.
- Do not rotate Agent Mail tokens solely because a pane showed token-shaped text; Joshua must explicitly ask for token rotation.

**Forbidden outputs:**
- Shell examples that include `registration_token=<value>` or equivalent token material.
- Callback lines, reports, or findings that repeat a token-shaped value from pane scrollback.
- Raw `ntm copy` excerpts from panes known to contain Agent Mail token arguments.
- Dispatch packets that instruct workers to paste registration tokens into terminal commands.
- Automatic "rotate token" recommendations without Joshua's explicit instruction.

**Detection and recovery:**
1. Search pane/report evidence for `registration_token`, `sender_token`, and long token-shaped fragments before relaying.
2. If a hit exists, stop using the raw capture; regenerate a redacted excerpt.
3. Verify repo files and `/tmp` reports are clean.
4. Log or update the fuckup row with the path/line of the exposure, not the value.
5. Continue with MCP/vault-mediated Agent Mail operations once output hygiene is restored.

**Future guard surface:** DCG/NTM should gain a transcript/output filter that warns or blocks when pane-copy, callback, or report paths contain Agent Mail token fields. This is a tool-patch follow-up, not a reason to keep relying on doctrine alone.

**Evidence:** `~/.local/state/flywheel/fuckup-log.jsonl` lines 173, 174, 176, 179, 180, 181, 182, 183, 184, 188, 189, 191, and 205; `~/.claude/skills/agent-mail/references/INCIDENTS.md#2026-05-02--agent-mail-token-echo-in-pane-promoted-after-13-transcript-exposures`; `~/.local/state/flywheel/fuckup-processed.jsonl` row 2026-05-02T16:34:16Z.

**Companion rules:** L51 requires Agent Mail reservations before edits; L53 records trauma rows; L56 defines this promotion ladder; the secrets reference (`~/.claude/references/claude-md-secrets.md`) forbids displaying secrets in chat or logs.


## L59 — RECONCILE-SCRIPT-POSTCHECK-STEP

---
id: L59
title: Reconcile scripts must prove clean worktree before success
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: ntm-worktree-conflicts-post-reconcile
---

**Rule:** Any script or runbook that performs or launches a git reconcile
operation (`merge`, `rebase`, `cherry-pick`, branch replacement, or upstream
overlay) MUST run a final postcheck before reporting success:

1. Verify `git status --porcelain` is empty in the target repo.
2. Verify no in-progress reconcile marker remains, at minimum `CHERRY_PICK_HEAD`
   for cherry-pick flows.
3. If either check fails, print `RECONCILE INCOMPLETE`, show the status or
   marker evidence, give the operator the exact resolve/skip/abort action class,
   and exit nonzero.

Build success, test success, a clean `HEAD`, or a runbook exit code is not
enough. The worktree itself is the source of truth for reconcile completion.

**Why:** On 2026-05-02, Joshua ran
`~/Developer/flywheel/.flywheel/PLANS/ntm-local-upstream-reconcile-2026-05-02/launch-on-pane-0.sh`.
The later pane-2 `ntm_rebuild_l57_2026_05_02` dispatch found four unresolved
`UU` files in `~/Developer/ntm` from a paused cherry-pick of `95ed40e0`
(`internal/agent/types.go`, `internal/cli/ensemble_spawn.go`,
`internal/swarm/agent_launcher.go`, `internal/tmux/session.go`). `HEAD`
compiled from a clean archive, but the live worktree was broken. The eventual
resolution was Joshua's explicit `git cherry-pick --skip`; the reconcile script
should have surfaced the incomplete state before anyone treated the reconcile as
done.

**How to apply:**

- End every reconcile launcher and destructive git runbook with a runtime
  postcheck, not just a printed list of verification commands.
- Use `git status --porcelain` rather than human-formatted status text so `UU`
  files, staged leftovers, and uncommitted reconcile output are machine-visible.
- Check in-progress markers such as `CHERRY_PICK_HEAD` after status; a clean
  final message must be backed by the repo's actual `.git` state.
- Treat any non-empty postcheck as a failed reconcile and preserve the operator's
  recovery choices: resolve and continue, skip, or abort.

Reference shell shape:

```bash
final_status=$(cd "$TARGET_REPO" && git status --porcelain)
if [[ -n "$final_status" ]]; then
  echo "RECONCILE INCOMPLETE — worktree not clean:" >&2
  echo "$final_status" >&2
  echo "Action: resolve, skip, or abort the in-progress reconcile before declaring done." >&2
  exit 1
fi

in_progress=$(cd "$TARGET_REPO" && git rev-parse --git-path CHERRY_PICK_HEAD 2>/dev/null || true)
if [[ -n "$in_progress" && -f "$in_progress" ]]; then
  echo "RECONCILE INCOMPLETE — cherry-pick in progress" >&2
  exit 1
fi
```

**Forbidden outputs:**

- "Reconcile complete", "runbook complete", or "success" before the clean
  worktree postcheck passes.
- Reporting source `HEAD` health while ignoring unresolved worktree paths.
- Printing post-run verification commands as a substitute for running the
  mandatory postcheck.
- Treating `UU` paths as a manual cleanup note instead of a failed reconcile.

**Evidence:** `~/.local/state/flywheel/fuckup-log.jsonl` line 216
(`class=ntm-worktree-conflicts-post-reconcile`);
`/tmp/ntm_rebuild_l57_findings.md`; `/tmp/ntm_worktree_cleanup_findings.md`;
`/tmp/ntm_cherrypick_skip_findings.md`;
`~/Developer/flywheel/.flywheel/PLANS/ntm-local-upstream-reconcile-2026-05-02/launch-on-pane-0.sh`;
`~/.local/state/flywheel/fuckup-processed.jsonl` row written by bead
`flywheel-yxzr`.

**Companion rules:** L57 forbids treating markers as proof of live driver state;
L56 defines the fuckup-log to canonical L-rule promotion ladder; L53 records
the trauma row that this rule processes.

## L60 — LOOP-INTEGRITY-5-SIGNAL-CONTRACT

A flywheel-managed session is HEALTHY only when ALL FIVE driver-output signals
fire within the loop interval. `active=true` in `~/.flywheel/loops/<project>.json`
plus a registered launchd plist is necessary but NOT sufficient — those are markers
(L57). Liveness is proven by output, not by configuration.

**The 5 signals (per loop, AND not OR):**
1. `ledger_writes_since_last_tick > 0` — product loop ledger OR canonical `~/.local/state/flywheel-loop/last_tick_<project>.json`; mtime within interval
2. `pane_state_changed_since_last_tick` — any worker pane `state_since` age < interval
3. `receipt_files_written_since_last_tick` — `<repo>/.flywheel/ticks/*.json` OR product-specific receipt path
4. `callback_received_in_last_2_ticks` — `<repo>/.flywheel/dispatch-log.jsonl` `callback_received_at` newer than 2*interval
5. `fuckup_log_decisions_made_since_last_tick` — new rows in `~/.local/state/flywheel/fuckup-processed.jsonl`

**Verdicts:**
- HEALTHY = all 5 fire
- LIMPING = 1-2 signals zero
- DEAD = ≥3 signals zero

**How to apply:**
- `gap-hunt-probe.sh` 9th class `loop-integrity` enforces this on every doctrine tick
- A LIMPING/DEAD loop with `launchd active=true` is a higher-priority repair than a missing-driver loop
- Mobile-eats reference 4-5/5 = HEALTHY proof pattern
- Skillos reference 2/5 → LIMPING proof case 2026-05-03 → fixed via mobile-eats-pattern apply (callback ts 08:10Z, 84 routed decisions, canonical receipt now written)

**Forbidden outputs:**
- Declaring a loop "running" because plist is loaded — must verify ≥3/5 signals
- IDLE_CLEAN tick decision while loop-integrity reports LIMPING|DEAD elsewhere in fleet
- Designing a new product loop without all 5 signal write-paths in the launchd payload

**Evidence:** bead `flywheel-aucl` (loop-integrity gap class shipped 2026-05-03);
`/tmp/loop-integrity-gap-class_findings.md`;
`/tmp/skillos-limping-diagnostic_findings.md` (proof case);
`~/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh` 9th class function;
skillos jsm_sync first callback `~/.local/state/flywheel-loop/last_tick_skillos.json` 2026-05-03 ~08:10Z;
`feedback_loop_state_without_driver` memory entry.

**Companion rules:** L57 (loop-state markers ≠ driver); L52 (issues-to-beads-or-no-bead-reason — applies to LIMPING signal decisions); fleet-onboarding tier 4 health probes (flywheel-vhl5) consume this contract.

## L61 — DOCTRINE-LANDING-WIRES-INTO-AGENTS-AND-README

When new doctrine, INCIDENTS entries, or canonical patterns land via dispatch
or worker callback, the orchestrator MUST update `AGENTS.md` (new L-rule) AND
the relevant `README.md` within the same session. Doctrine without ecosystem
wire-in becomes orphaned doctrine — referenced in beads, dispatch logs, and
fuckup-log rows, but invisible to anyone reading the repo.

**Reason:** `feedback_wire_into_ecosystem` META-RULE has been firing as
reminder for weeks but produced 0 AGENTS.md updates per session repeatedly
(observed 2026-05-03 ~09:10Z by Joshua: "i'm also not seeing enough emphasis
put on readme and agents.md files - didn't we wire that into the flywheel?
why aren't agents doing more of it"). META-RULE without mechanical gate =
META-suggestion.

**How to apply:**
- After any doctrine landing (INCIDENTS write, canonical-cli-scoping skill ship,
  bead-promoted-to-L-rule, new probe shipped), orchestrator runs ecosystem-touch
  before declaring "done":
  1. Append new L-rule to `<repo>/AGENTS.md` with: name, why, how-to-apply,
     forbidden outputs, evidence, companion rules
  2. Update `<repo>/README.md` if doctrine changes the user-facing narrative
     (new CLI, new tick step, new mission) OR if last-updated timestamp >7d
  3. Cross-reference into `~/.claude/projects/-Users-josh-Developer-flywheel/memory/`
     entry if doctrine spans sessions
- Workers receiving dispatches that land doctrine MUST include `agents_md_updated=yes|no`
  in callback fields; orchestrator MUST refuse to call work "done" if `no` without
  explicit no-touch reason
- Skipping ecosystem-touch is a SOFT violation `orch_skipped_ecosystem_touch`
  logged to fuckup-log

**Forbidden outputs:**
- Declaring a tick "complete" or a bead "closed" with new doctrine but
  AGENTS.md/README untouched in the same session
- Filing more new beads without first wiring previous session's doctrine
- "META-RULE acknowledged" responses without immediate ecosystem touch

**Evidence:** This conversation 2026-05-03 ~09:10Z (Joshua flag);
`feedback_wire_into_ecosystem` memory entry (META-RULE source);
4+ doctrine landings tonight (loop-integrity, R1-INCIDENTS, mobile-eats receipt,
FD doctor, skillos pattern) with 0 AGENTS.md updates before this rule landed —
self-validating evidence.

**Companion rules:** L56 (fuckup-log → L-rule promotion ladder ends here, not at INCIDENTS); L52 (every fuckup gets a bead OR no-bead reason — same shape applies to ecosystem touch); `feedback_wire_into_ecosystem` memory.

## L62 — STATE-MD-IS-LATENT-OPPORTUNITY-SUBSTRATE

`/flywheel:learn` MUST mine `.flywheel/STATE.md` files across the fleet roster
daily for improvement opportunities. STATE.md "Next Actions", "Known Gaps",
"Deferred", and "Resume Context" rows are durable signal that the operator
already documented but the learn loop never consumed. Treating fuckup-log as
the only learn input makes STATE.md content invisible to the system that's
supposed to act on it.

**Reason:** Joshua observed 2026-05-03 ~09:30Z that improvement opportunities
documented in STATE.md across repos get manually rediscovered every few days
because nothing automatically extracts them. Same ecosystem-touch failure mode
as L61 (META-RULE without mechanical gate) applied at the data-source level.

**How to apply:**
- `/flywheel:learn --mine-state` extracts opportunities from all fleet
  roster repos' `.flywheel/STATE.md` (and root `STATE.md` if present)
- 5 discovery classes with per-class action shape:
  1. **UNRESOLVED** — "Next Actions" row with no open bead → file P3 bead
  2. **STALE** — "Deferred" row older than 14d → ping with age + cost-of-defer
  3. **PATTERN** — same gap appearing in 3+ repos → file P2 systemic bead
  4. **RECURRING** — gap closed and reopened → trauma-class promotion candidate
  5. **ORPHANED** — "Known Gaps" entry with no bead reference → wire-into-ecosystem
- Each discovery results in one durable decision: bead OR no-bead reason
  (same shape as L52 fuckup-bead-or-no-bead-reason)
- Cap auto-bead at 5/day per repo to prevent ideation flood
- Daily launchd cron at 06:00 local matches morning-review cadence
- Wire into `/flywheel:tick` Step 4q so daily extraction surfaces in tick receipt

**Forbidden outputs:**
- Calling `/flywheel:learn --review` "complete" while STATE.md content unmined for >24h
- Operator manually re-reading STATE.md across repos to find opportunities (=
  the system failed to mine for them; file fuckup-log row class
  `orch_state_md_unmined`)
- Filing the same opportunity-bead twice for the same STATE.md row (idempotency
  via STATE.md-row hash)

**Evidence:** Joshua directive 2026-05-03 ~09:30Z;
bead `flywheel-b6zk` ([flywheel:learn STATE.md miner]);
sibling `flywheel-1rmp` (value-gap-hunter — paradigm-tier scan); 8 fleet repos
each with `.flywheel/STATE.md` containing untapped Next Actions.

**Companion rules:** L52 (durable decision per finding); L61 (every doctrine
landing wires into AGENTS+README — this rule is itself an instance);
`/flywheel:learn` skill at `~/.claude/commands/flywheel/learn.md` is the
extension surface.

## L63 — JEFF-INTEL-NETWORK-IS-CANONICAL-SUBSTRATE-DEPENDENCY

The flywheel ecosystem depends on Jeff Emanuel's substrate (ntm, br, dcg,
frankensqlite, cass, jsm, agent-mail, socraticode, vibe_cockpit) — at least
9 canonical binaries. The ecosystem MUST run a daily intel-network covering:
(1) Jeff's X account, (2) Jeff's website, (3) Jeff's git repos (cloned + indexed),
(4) Jeff's GitHub activity, (5) Jeff's jsm/skills catalog drift. Without intel
network, every Jeff release surprises us at use time and his WIP is invisible
until it breaks our deps.

**Reason:** Joshua observed 2026-05-03 ~09:35Z that despite Jeff being our
#1 substrate dependency, we had ZERO local clones of his repos and ZERO
monitoring of his X/website. We had to manually re-discover his fixes each
session via `gh issue view` (auth-fragile). Same paradigm-tier failure as L62
applied to a different latent-signal source.

**How to apply:**
- `~/Developer/flywheel/.flywheel/scripts/jeff-intel-network.sh` (canonical-cli-scoping)
  pulls all 5 sources daily; auto-clones any missing Jeff repos to `~/Developer/<repo>`;
  auto-indexes each clone via `mcp__socraticode__codebase_index`
- Cadences: hourly X-poll, daily everything else
- launchd plists per source; aggregate digest at `~/.local/state/jeff-intel/digest.jsonl`
- Cross-link new Jeff commits with existing flywheel doctrine; surface in tick
  receipt via Step 4r
- High-signal new artifact (release, blog post, X-thread referencing one of our
  deps) → file P3 bead with link + suggested integration path
- Every Jeff fix-commit applied via jeff-fixes-puller MUST be cross-linked to
  the originating intel-network artifact for provenance

**Forbidden outputs:**
- Calling `jeff-fixes-puller` "complete" without intel-network confirming HEAD
  per repo
- Manually `gh issue view`-ing Jeff repos when intel-network has the fetch
  cached locally
- Re-cloning a Jeff repo we already have without first checking
  `~/Developer/<repo>` (idempotency)
- Indexing flywheel-managed repos via socraticode while Jeff's substrate repos
  remain unindexed (Jeff's are the load-bearing dependency)

**Evidence:** Joshua directive 2026-05-03 ~09:35Z;
audit confirming 0/9 Jeff repos cloned locally; bead `flywheel-1lpv`
([jeff-intel-network] daily monitoring epic);
`reference_jeff_substrate_inventory` memory listing 7+ canonical binaries we
depend on; `feedback_jeff_substrate_version_drift` META-RULE that this rule
mechanizes.

**Companion rules:** L62 (latent-signal-substrate paradigm); L61 (ecosystem
wire-in); L11 Live API Truth (Jeff's repos ARE the live truth for our
substrate calls); `feedback_jeff_issue_chain` (file issues not patches);
`feedback_use_codex_workers` (worker dispatch shape for the daily pull cron).

## L64 — JEFF-IS-MENTOR-NOT-JUST-DEPENDENCY

L63 treats Jeff's repos as substrate to consume. L64 promotes Jeff to MENTOR
to study. The flywheel must run a daily 'what is Jeff up to / what can we
learn' snapshot AND a periodic deep-mine across all Jeff repos to extract
pattern catalog, then internalize patterns we don't already use into our own
doctrine. We are not just users of Jeff's tools; we are students of his method.

**Reason:** Joshua directive 2026-05-03 ~10:10Z: 'I want to embody his
philosophies and methods of working into our ecosystem.' Per memory entry
`feedback_meadows_jeff_mentors`, Jeff is one of TWO explicit mentors for the
flywheel (alongside Donella Meadows). Memory documents that Jeff originated
the fuckup-log concept and L-rule numbering shape that we inherited. There
are likely 10+ more patterns we use unconsciously (or fail to use) that
deeper study would surface.

**How to apply:**
- Layer 1 (deep mine, monthly): cross-repo pattern extraction via
  socraticode across all Jeff repos. Topics: state machine design, error
  handling, callback contracts, schema evolution, doctrine surfaces, README
  shape, test pyramid, telemetry, dispatch patterns, idempotency. Output
  `~/.local/state/jeff-philosophy/patterns.jsonl`.
- Layer 2 (daily snapshot, cron 06:00): pulls last-24h Jeff commits + X +
  website + GH activity + releases via L63 substrate; per-artifact 'what can
  we learn' analysis with verdict {YES_ADOPT | YES_ADAPT | NO_NOT_OUR_DOMAIN
  | NEED_RESEARCH}. Surfaces in `/flywheel:status` morning section.
- Layer 3 (internalization): when deep-mine finds a pattern Jeff uses
  everywhere that we use inconsistently, file P3 bead `adopt-jeff-pattern-<name>`
  with file:line citations. Once adopted, cite in AGENTS.md L-rule as
  'Source: Jeff <repo>:<file>:<line> + ZestStream adaptation'.

**Forbidden outputs:**
- Calling jeff-intel-network 'complete' without Layer 2 daily-snapshot active
- Inventing a flywheel pattern from scratch when Jeff already has a battle-tested
  version in his repos (deep-mine first)
- Writing a new L-rule without first searching the daily-snapshot stream and
  pattern catalog for Jeff's existing convention
- Citing Jeff's pattern as 'inspired by' without specific file:line evidence

**Evidence:** Joshua directive 2026-05-03 ~10:10Z;
bead `flywheel-jeff-philosophy-study` (filed this turn);
`feedback_meadows_jeff_mentors` memory entry; Jeff-originated patterns we
inherited (fuckup-log, L-rule numbering, doctor surface, 7-axis rubric);
sibling rules L11, L60, L61, L62, L63.

**Companion rules:** L63 (substrate dependency — provides clones for mining);
L62 (latent-signal mining paradigm applied to Jeff's work); L61 (ecosystem
wire-in — this rule itself wires); `donella-meadows-systems-thinking` skill
(Donella is the OTHER mentor; Jeff joins her at the same level).

## L65 — CLI-IDENTITY-BEATS-COMMAND-NAME

Command names are not proof of substrate identity. Any tick, doctor, or worker
probe that depends on a short binary name with known collision risk MUST verify
the resolved executable identity before trusting output.

**Reason:** 2026-05-03 vc-relive found `~/.local/bin/vc` correctly symlinked to
Vibe Cockpit, but bare `vc` still resolved first to Homebrew's Vercel CLI through
`/opt/homebrew/bin/vc`. The binary was current, the symlink was correct, and the
operator-facing command was still wrong. Symlink checks alone are markers, not
driver truth.

**How to apply:**
- For collision-prone commands, record both `command -v <name>` and
  `realpath "$(command -v <name>)"` in the probe ledger.
- Validate semantic identity with a robot/help/version probe, not just filename.
  Example: `vc-observability-probe.sh` requires `vc --help` to contain
  `Vibe Cockpit` before reading status surfaces.
- If the command is shadowed, install or repair a front-of-PATH shim and keep the
  canonical absolute path in tick scripts until the shell path is proven.
- Receipt fields that cite a tool must include the resolved binary path when
  feasible (`vc_bin`, `ntm_bin`, `br_bin`, etc.).

**Forbidden outputs:**
- "Binary is installed" based only on `ls ~/.local/bin/<name>` while
  `command -v <name>` resolves elsewhere
- "Symlink correct" as a substitute for command identity proof
- Running collector/doctor probes through bare names without canonical scope when
  the name is shared by another ecosystem tool

**Evidence:** bead `flywheel-8q2x`; `/tmp/vc-relive-phases-2-6_findings.md`;
`/Users/josh/bin/vc -> /Users/josh/.cargo/bin/vc` shim added after
`which vc` resolved to `/opt/homebrew/bin/vc` (Vercel CLI); probe script
`.flywheel/scripts/vc-observability-probe.sh` version `2026-05-03.2`.

**Companion rules:** L57 (markers are not driver truth), L60 (liveness proven by
output), canonical-cli-scoping skill, and L61 (new doctrine must wire into
AGENTS.md + README).

## L66 — OUTBOUND-JEFF-ISSUES-USE-PHASED-COMMAND-GATE

Issues filed to Jeff's repos are part of the flywheel substrate, not casual
GitHub comments. Every future outbound Jeff issue MUST pass through the phased
`/flywheel:jeff-issue` process once implemented, or an equivalent ledger that
proves the same phases.

**Reason:** `mcp_agent_mail#154` passed a 7-axis quality rubric and was a good
issue, but the path bypassed three older canonical proposal artifacts:
G82 source probing, the Jeff issue template, and outbound issue tracking. A
rubric alone catches issue quality; it does not guarantee source freshness,
template discipline, Joshua approval, post-submit body verification, and watcher
registration.

**How to apply:**
- Before drafting: run the source-probe phase against the target repo, local
  clone, issue dedup searches, and command identities.
- Draft with the Jeff issue template unless recent repo tone evidence justifies
  a tighter shape.
- Run the 7-axis rubric from a phase ledger, not from memory.
- Submission requires Joshua approval, idempotency key, non-empty post-submit
  body verification, and outbound tracker registration.
- If the command does not exist yet, workers must write the same phase ledger in
  their receipt and file/update the implementation bead rather than filing ad
  hoc.

**Forbidden outputs:**
- Filing a Jeff issue from a one-off dispatch checklist with no source-probe
  ledger.
- Treating "7/7 rubric PASS" as sufficient when dedup, tracker, or Joshua gate
  evidence is missing.
- Submitting an issue before verifying the posted body is non-empty.
- Filing without updating the outbound issue memory/tracker or giving an
  explicit no-track reason.

**Evidence:** bead `flywheel-svi6`; design artifacts in
`/tmp/jeff-issue-process-DESIGN/`; `mcp_agent_mail#154` receipt
`/tmp/jeff-upstream-token-echo-issue_findings.md`; proposals
`G82-jeff-doctrine-source-probe-2026-04-27.md`,
`jeff-issue-template-2026-04-30.md`, and
`outbound-issue-tracker-phase3-2026-04-30.md`.

**Companion rules:** L61 ecosystem touch, L63 Jeff substrate dependency, L64
Jeff-as-mentor pattern mining, L65 CLI identity proof, and
`dicklesworthstone-stack` skill issue protocol.

## L67 — TRUTH-SOURCE-MUST-BE-LIVE-NOT-CACHED

When `feedback_two_truth_sources_before_decide` requires cross-checking pane
state, the second source MUST be verified-live. `ntm --robot-tail` returns
cached scrollback that may be hours stale and identical across panes; using
it as a truth source produces FALSE second-source confirmation and triggers
spurious recovery actions. Live truth comes from process inspection
(`pgrep -f codex`, `lsof -p <pid>`), agent-mail callbacks landing
in dispatch-log, or scrollback-byte-delta from sequential probes.

**Reason:** Tick 14+15 2026-05-03 ~10:00-11:50Z observed all 4 panes returning
identical stale scrollback from prior day via `--robot-tail`. Misdiagnosed as
"codex-cli-exited" trauma class. Fired 3 spurious codex relaunches into
actually-working panes. Pane 2's jeff-intel-clone-and-index callback at 11:50Z
(177 repos cloned + 79 indexed = 30+ minutes of real work) PROVED pane was
working all along. Two-truth-sources rule is only valid if BOTH sources are
live, not when one is a cached snapshot.

**How to apply:**
- Before declaring a pane "frozen" or "exited", verify with at least one
  live signal:
  - `pgrep -f "codex --dangerously"` to confirm codex process exists
  - Check dispatch-log.jsonl for recent callbacks from that pane
  - Sample `--robot-tail` twice with 30s gap; compare for actual delta
  - Use `frozen-pane-detector.sh` (already does scrollback delta correctly)
- Treat `--robot-tail` output as POSSIBLY stale until proven live by delta
- If only stale truth sources are available, defer-to-human, do not auto-recover
- Do NOT fire codex relaunch based on single `--robot-tail` snapshot —
  scrollback may be cached

**Forbidden outputs:**
- "Pane is frozen because scrollback shows shell prompt" without delta evidence
- Auto-firing codex relaunch when only single `--robot-tail` snapshot supports it
- Adding new fuckup-log trauma class without verifying the trauma is real

**Evidence:** Tick 14 deferred-to-human due to false ambiguity; tick 15 fired
3 spurious codex relaunches into working panes; jeff-intel callback at 11:50Z
(177 repos cloned, 79 indexed, 379400 chunks) proved pane 2 was working;
fuckup-log row class `ntm-robot-tail-returns-stale-cached-scrollback`
2026-05-03 logged this turn.

**Companion rules:** L57 (loop-state markers ≠ driver — same pattern);
L60 (5-signal contract — uses live signals); `feedback_two_truth_sources_before_decide`;
`feedback_pane_state_ntm_health`; frozen-pane-detector.sh script (already
implements scrollback-byte-delta correctly).


## L68 — NO-SILENT-DARKNESS-GOAL-CONTRACT

---
id: L68
title: No silent darkness goal contract
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: silent-darkness
---

**Rule:** The flywheel loop optimizes for `NO_SILENT_DARKNESS`, not merely
"frozen pane detected." A fleet or repo loop is not healthy unless the
measurement loop proves all five L60 signals and all four goal-quality metrics:

1. `silent_dark_minutes=0`
2. `blackout_detection_latency_p95<=2m`
3. `false_recovery_count=0`
4. `unknown_autorecovery_count=0`
5. `L60_signals_present=5/5` for every active loop interval

**Why:** The 2026-05-03 Codex fleet stuck THINKING RCA found that pane-freeze
detection was a symptom frame. The real failure was silent darkness: active loop
markers, stale pane state, missing callbacks, missing receipts, or unprocessed
fuckup decisions could coexist while the system appeared "running." Meadows #3
requires changing the goal before tuning detectors.

**How to apply:**
- Run `.flywheel/scripts/no-silent-darkness-probe.sh --doctor --json` before any
  dispatch/recovery decision that depends on loop liveness.
- Treat `orch_silent_darkness_breach` as a SOFT halt: stop new dispatch and
  recovery actions until the missing L60 signals have a bead, update, or explicit
  no-bead reason.
- Frozen-pane detector output is an input to this contract, not the contract
  itself. A pane can be unfrozen while the loop is still LIMPING or DEAD.
- C5 and later tick consumers MUST preserve the five metric fields in receipts
  and promote repeated SOFT breaches to a fail gate after the consumer is wired.

**Forbidden outputs:**
- Declaring "all clear" because no pane is classified frozen while any L60 signal
  is missing.
- Auto-recovering an UNKNOWN source or a loop with fewer than 5/5 L60 signals.
- Reporting loop health without `silent_dark_minutes`,
  `blackout_detection_latency_p95`, `false_recovery_count`,
  `unknown_autorecovery_count`, and `L60_signals_present`.

**Evidence:** bead `flywheel-o499`; RCA Rev 2 DAG at
`.flywheel/PLANS/codex-fleet-stuck-thinking-RCA-2026-05-03/04-BEADS-DAG-rev2.md`;
probe `.flywheel/scripts/no-silent-darkness-probe.sh`; C10 commit `0cff2d5`;
C11 commit `bb328f8`.

**Companion rules:** L57 (markers are not drivers), L60 (five-signal contract),
L61 (doctrine must wire into AGENTS/README), L67 (truth source must be live),
and `flywheel-doctor-author` producer/measurement/consumer/promotion doctrine.

