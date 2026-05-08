# Flywheel Canonical Operational Doctrine

## How to read this file

This is the canonical "how agents operate" reference, distributed via
flywheel-loop init to every flywheel-installed repo as
`.flywheel/AGENTS-CANONICAL.md`. Each repo's local AGENTS.md should
reference this file and add only repo-specific operational rules.
Domain rules (what we're building, not how we operate) belong in CLAUDE.md.

Fleet propagation cross-link: `.flywheel/scripts/agents-md-fleet-propagator.sh`
audits installed-repo AGENTS.md drift, and `flywheel-loop doctor --scope
agents-md-fleet-propagation --json` exposes the drift count, drift repos, and
last propagation apply health.

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


## L58 — SECRET-MATERIAL-NEVER-IN-PANE-TEXT

---
id: L58
title: Secret material never in pane-visible text
status: long_term
shipped: 2026-05-02
review_due: 2026-11-02
trauma_class: secret-leak
---

**Rule:** Secret material MUST never be placed in visible pane commands, dispatch packets, callbacks, reports, copied transcript evidence, or doctrine examples. This includes Agent Mail registration tokens, Infisical secret values, API keys, bearer tokens, private keys, password-like values, and any token-shaped fragment long enough to authenticate. Use MCP-native token fields, vault-backed helpers, `~/.flywheel/bin/infisical-safe`, or non-visible sinks; redact before pane capture.

**Why:** Pane scrollback is operational substrate. It is copied by `ntm`, searched by workers, summarized into callbacks, and reused as evidence. Once a `registration_token`, Infisical `secretValue`, or token-shaped fragment is rendered into that substrate, the exposure has already happened before server-side redaction or report hygiene can protect it. This class fired 13 times in 24h across ALPS, skillos, and mobile-eats, then recurred in ALPS through raw Infisical table output. Rule vigilance failed; wrapper, DCG, doctor, and aggregator topology are load-bearing.

**How to apply:**
- Prefer MCP Agent Mail tools with structured token parameters over shell-visible commands or prose snippets containing `registration_token`.
- Prefer `~/.flywheel/bin/infisical-safe` over raw `infisical` for any command that can enumerate or read secrets; key-only listing uses `secrets list --silent --output=json | jq -r '.[].secretKey'`.
- Store and load reusable Agent Mail tokens through vault-backed helpers; do not paste tokens into dispatch packets or callback examples.
- When pane evidence is required, capture through a redacting filter first and report only "token-shaped text observed", never the value.
- Before closing secret-adjacent work, grep changed files and intended reports for `registration_token`, `secretValue`, `--plain`, and long token-shaped fragments.
- Do not rotate tokens solely because a pane showed token-shaped text; Joshua must explicitly ask for token rotation.

**Forbidden outputs:**
- Shell examples that include `registration_token=<value>` or equivalent token material.
- Callback lines, reports, or findings that repeat a token-shaped value from pane scrollback.
- Raw `ntm copy` excerpts from panes known to contain Agent Mail token arguments.
- Dispatch packets that instruct workers to paste registration tokens into terminal commands.
- Raw `infisical secrets list`, `infisical secrets get`, `infisical run`, or `infisical export` in pane-visible command paths; route through `infisical-safe` or a reviewed non-visible sink.
- Automatic "rotate token" recommendations without Joshua's explicit instruction.

**Detection and recovery:**
1. Search pane/report evidence for `registration_token`, `sender_token`, `secretValue`, `--plain`, raw `infisical secrets`, and long token-shaped fragments before relaying.
2. If a hit exists, stop using the raw capture; regenerate a redacted excerpt.
3. Verify repo files and `/tmp` reports are clean; then run `flywheel-loop doctor --json` and inspect `secret_leak_count_1h`, `secret_leak_oldest_age_seconds`, and `.secret_leaks[]`.
4. Log or update the fuckup row with the path/line of the exposure, not the value.
5. Continue with MCP/vault-mediated or `infisical-safe` operations once output hygiene is restored.

**Guard surfaces:** DCG blocks raw value-bearing Infisical command shapes before execution; `infisical-safe` rejects unsafe output formats; `flywheel-loop doctor` auto-pauses on fresh `secret-leak` lock-log rows; `cross-repo-trauma-aggregator.sh` writes class-only global trauma rows without copying free-text secret material. Transcript/output filtering remains a follow-up, not a substitute for these guards.

**Evidence:** `~/.local/state/flywheel/fuckup-log.jsonl` lines 173, 174, 176, 179, 180, 181, 182, 183, 184, 188, 189, 191, and 205; `~/.claude/skills/agent-mail/references/INCIDENTS.md#2026-05-02--agent-mail-token-echo-in-pane-promoted-after-13-transcript-exposures`; `~/.local/state/flywheel/fuckup-processed.jsonl` row 2026-05-02T16:34:16Z; `/tmp/flywheel-secret-leak-foundational-fix.md` lines 14-20 and 24-30.

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
- `/flywheel:jeff-intel` is the operator wrapper for doctor/health/repair,
  validation, audit, and dry-run pull/x-poll actions; `daily-jeff-ingest.sh`
  and `jeff-intel-scheduled-runner.sh` remain implementation helpers behind
  that canonical surface.
- Cadences: hourly X-poll, daily everything else
- Active launchd labels:
  `ai.zeststream.flywheel-daily-jeff-ingest` for daily GitHub/git,
  website/RSS, X, JSM, and mirror ingest; `ai.zeststream.flywheel-jeff-x-poll`
  for hourly @doodlestein X capture.
- launchd plists per source; receipts at
  `~/.local/state/jeff-intel/scheduled-runs.jsonl`,
  `~/.local/state/jeff-intel/x-poll.jsonl`, and
  `~/.local/state/flywheel/daily-jeff-ingest.jsonl`
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
- Import contract: run `.flywheel/scripts/jeff-pattern-citation-probe.sh --json`
  before landing doctrine, skills, or plan artifacts that import mentor-corpus
  patterns. The probe exposes `jeff_pattern_uncited_count`; nonzero means the
  artifact is not ready until each import claim has the required Source line.

**Forbidden outputs:**
- Calling jeff-intel-network 'complete' without Layer 2 daily-snapshot active
- Inventing a flywheel pattern from scratch when Jeff already has a battle-tested
  version in his repos (deep-mine first)
- Writing a new L-rule without first searching the daily-snapshot stream and
  pattern catalog for Jeff's existing convention
- Citing Jeff's pattern as 'inspired by' without specific file:line evidence
- Ignoring `jeff_pattern_uncited_count > 0` after a doctrine, skill, or plan
  artifact imports mentor-corpus patterns

**Evidence:** Joshua directive 2026-05-03 ~10:10Z;
bead `flywheel-jeff-philosophy-study` (filed this turn);
`feedback_meadows_jeff_mentors` memory entry; Jeff-originated patterns we
inherited (fuckup-log, L-rule numbering, doctor surface, 7-axis rubric);
sibling rules L11, L60, L61, L62, L63; bead `flywheel-jhcd`; probe
`.flywheel/scripts/jeff-pattern-citation-probe.sh`.

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


## L69 — ORCH-PROBE-AGENT-CONTEXT (probe runs THROUGH agent execution, not orchestrator shell)

---
id: L69
title: ORCH-PROBE-AGENT-CONTEXT
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: orchestrator-probe-discipline
---

Probe truth belongs to the runtime that will execute the work. An orchestrator
shell, pane scrollback, launchd script, or short-name `which` result is not proof
that a worker agent can resolve or run the same command from its own execution
context.

**Reason:** ORX1 H1 diagnosis at 2026-05-03T22:08Z found `which dcg` failed in
Codex tool execution even though raw pane/orchestrator probes later showed PATH
parity. The mismatch was real: Codex commands ran through non-interactive login
zsh (`/bin/zsh -lc`), where `.zprofile` had reset PATH. The earlier conclusion
overreached because the probe mixed agent execution context with orchestrator
shell context.

**How to apply:**
- For Claude Code runtime probes, use the Claude Bash tool from the target
  agent/session, because that is the agent execution context.
- For Codex runtime probes, send the probe through the Codex agent and parse its
  callback. Use `ntm send <session> --pane=<n> --no-cass-check "<probe +
  callback instruction>"`, then validate the callback content rather than only
  reading pane shell state.
- For parity probes, record both layers when relevant:
  `agent_context={ok|fail,path,version,smoke}` and
  `orchestrator_shell_context={ok|fail,path,version}`. Any disagreement is
  `context_drift`, not immediate proof that the tool is globally missing.
- Pair this rule with L65: after proving the probe ran in the right execution
  context, still verify resolved identity (`command -v`, `realpath`, semantic
  help/version/smoke), not just command name.
- If the target agent is unresponsive, classify the cell as
  `runtime_unresponsive`; do not silently substitute an orchestrator-shell probe.

**Forbidden outputs:**
- "`<tool>` is missing because `which <tool>` failed in the orchestrator shell"
  without a companion in-agent probe.
- "`<tool>` is available to Codex" based only on pane shell PATH, launchd PATH,
  or `ntm` scrollback.
- Closing a parity or substrate bead on raw shell evidence when the acceptance
  gate names an agent runtime.
- Treating an in-agent probe timeout as a successful raw-shell fallback.

**Evidence:** `/tmp/orx1-h1-vs-h3-diagnosis.md`; bead `flywheel-cnep`;
ORX1 refinement of `flywheel-orx1`; parent doctrine bead `flywheel-1z65`.

**Companion rules:** L65 (CLI identity proof after context proof), L60
(loop integrity requires the right signal source), L67 (truth source must be
live), `flywheel-1z65` (orchestrator validates callbacks), `flywheel-2p25`
(runtime parity epic), and `flywheel-q03g` (parity probe binary).


## L70 — ORCH-NO-PUNT (next actionable runs same tick, not next tick)

---
id: L70
title: ORCH-NO-PUNT
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: orch-punt-to-next-tick-instead-of-next-actionable
---

When an orchestrator tick concludes by NAMING the next phase / next actionable
thing, the orchestrator MUST execute that next thing in the SAME TICK if
capacity exists. Returning to launchd to wait for the next cron firing is the
trauma class.

**Reason:** 2026-05-03T22:28Z mobile-eats:1 orch concluded "DISPATCH could not
proceed; no ready work. Next phase should be BEADS to convert the next plan
artifact into ready work" — and then sat idle waiting for the next launchd
firing. Same shape as L48-companion `orchestrator-skipped-callback-validation`
(2026-05-03T22:15Z): orchestrator IDENTIFIES the next actionable thing and
THEN PUNTS instead of doing it. Joshua flagged this as a constant problem
the same session: "I can't have this being a constant problem."

**How to apply:**
- When DISPATCH yields `no ready work` AND `next_phase=BEADS` AND ≥1 plan
  artifact awaits conversion, run BEADS phase in the SAME tick before
  returning a callback to launchd.
- When INTEGRATE phase concludes `next_phase=LEARN` AND fuckup-log has unprocessed
  rows, run LEARN in the SAME tick.
- When a worker callback names `next_phase=X` AND current pane has capacity for
  X, chain into X within the same orchestrator turn.
- Tick driver wrappers (`flywheel-loop-tick`, launchd plists) MUST chain phase
  transitions when callback names `next_phase=Y` and capacity exists. Returning
  to cron is the failure mode this rule eliminates.
- Workers receive `chain_if_capacity` instruction in dispatch packet: if your
  conclusion names `next_phase=Y` and you have remaining time/capacity, attempt
  Y immediately, otherwise file the chain reason in callback.

**Forbidden outputs:**
- "DISPATCH could not proceed... Next phase should be BEADS" without an
  immediate BEADS execution attempt in the same tick.
- "Worker idle; will redispatch next tick" when ready beads exist or when plans
  await conversion.
- Returning to launchd as the chosen action when ANY actionable phase is named
  in the conclusion.
- Treating `tick complete` as `work complete` without re-evaluating capacity.

**Mechanical gate:** `flywheel-7lby` (P0) requires:
- Tick driver chains `DISPATCH → BEADS` when `br_ready=0` AND plans exist
- Tick driver chains `BEADS → DISPATCH` when new beads land
- Doctor signal `ticks_punted_count` ≥ 1 → status=fail
- Worker dispatch packet includes `chain_if_capacity` block

**Counter cross-link:** `.flywheel/scripts/l70-ticks-punted-counter.sh` writes
`~/.local/state/flywheel/l70-ticks-punted.jsonl`; `flywheel-loop doctor --scope
l70-ticks-punted --json` exposes `l70_ticks_punted_24h`,
`l70_ticks_punted_rate_pct`, and `l70_ticks_punted_top_signal`.
`.flywheel/scripts/tick-hook-firing-verifier.sh` audits L70 and sibling
tick-close hooks with ledger-backed firing evidence; `flywheel-loop doctor
--scope tick-hook-firing --json` exposes `tick_hook_primitives_audited`,
`tick_hook_primitives_firing`, `tick_hook_primitives_invisibly_broken`, and
`tick_hook_primitives_invisibly_broken_names`.

**Override:** None. There is no `JOSHUA_OVERRIDE` for this — Joshua flagged
this as a recurring fleet-killer and the rule is not negotiable. If a chain
genuinely cannot proceed (capacity exhausted, deadlock detected, etc.), the
callback MUST include `chain_blocked_reason=<concrete cause>`.

**Evidence:** mobile-eats:1 scrollback 2026-05-03T22:28Z; fuckup-log row
`orch-punt-to-next-tick-instead-of-next-actionable`; bead `flywheel-7lby` (P0);
mobile-eats orch ACK 2026-05-03T22:32Z (`MOBILE-EATS ACK orch-no-punt
action=phase-chained` — proof the rule works when applied).

**Companion rules:** L48 (substrate-exhaustion-before-escalation — chain before
escalating), L60 (no-silent-darkness — punted ticks are silent darkness), L61
(ecosystem-wire-in — this rule itself wires), `flywheel-1z65`
(orchestrator validates callbacks — same family of orchestrator-knows-and-punts
trauma), `flywheel-7lby` (mechanical gate implementation),
`feedback_orchestrator_must_dispatch.md`, `feedback_flywheel_never_idles.md`,
`feedback_three_audit_questions_per_surface.md` umbrella.


## L71 — VALIDATE-AND-REDISPATCH-DISCIPLINE

---
id: L71
title: Validate-and-redispatch discipline
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: orchestrator-skipped-callback-validation
---

Every worker callback, closed bead, and changed flywheel surface is a claim
until the validate-and-redispatch discipline produces a mechanical receipt. The
orchestrator MUST validate the claim, document the evidence surface, and route
any finding before it summarizes work as complete or integrates the result.

This doctrine is long-term after B12 (`flywheel-yasl`) proved the full
end-to-end rollout with a staged smoke harness. Executable proof exists for the
core primitives: B03 callback validation, B05 VALIDATE phase, B06 fix-bead
creation, B07 closed-bead reopen candidates, B08 L70 same-tick chaining, B09
learn routing, B11 runtime context parity, ft04 doctrine propagation, f589
callback delivery verification, and B12 final smoke. B13 capture parity and B14
3-Q registry remain companion expansion gates and must not be silently bypassed.

**How to apply:**
- Treat worker `DONE` / `BLOCKED` callbacks as untrusted input until
  `.flywheel/scripts/validate-callback.py` or a successor emits a validation
  receipt with `status=pass`, `fail`, or `unknown`.
- A failed or unknown validation MUST route to exactly one durable outcome
  before summary or integration: fix bead/update, reopen candidate/apply,
  explicit `no_bead_reason`, or BLOCKED callback with evidence.
- Closed beads that cite shipped artifacts MUST be checked by
  `.flywheel/scripts/closed-bead-artifact-scan.py`; missing files, invalid
  schemas, non-executable scripts, and failed smoke commands are not closed
  work.
- Workers MUST verify callback delivery with
  `.flywheel/scripts/verify-callback-delivery.sh` or equivalent pane-log proof
  before exiting cleanly.
- When validation names a next actionable phase, L70 applies: chain the phase in
  the same tick if capacity exists, or emit `chain_blocked_reason=<concrete>`.
- New validation doctrine or surfaces MUST wire into AGENTS.md, README.md,
  memory, canonical paths, and skill guidance in the same session per L61.

**Forbidden outputs:**
- "Worker done", "bead shipped", "validated", or "integrated" based only on a
  callback line, close reason, or worker prose.
- Forwarding worker findings to Joshua as fact before artifact, schema, command,
  or receipt validation runs.
- Closing a validation failure with no fix bead, reopen candidate, no-bead
  receipt, or learn-route record.
- Treating raw orchestrator-shell success as runtime proof when L69 requires an
  in-agent probe.
- Letting a named next phase wait for launchd/cron when same-tick capacity
  exists.

**Evidence:** plan
`.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/00-PLAN.md`;
beads `flywheel-bc7c`, `flywheel-scwo`, `flywheel-0wbf`, `flywheel-zgo3`,
`flywheel-hf58`, `flywheel-8xrn`, `flywheel-i8b6`, `flywheel-zdva`,
`flywheel-u2dr`, `flywheel-ft04`, and `flywheel-f589`; parent doctrine bead
`flywheel-1z65`; mechanical gate bead `flywheel-7lby`; memory entries
`feedback_orchestrator_validates_callbacks.md`,
`feedback_worker_verify_callback_delivered.md`,
`feedback_low_bead_threshold_work_hunt.md`, and
`feedback_three_audit_questions_per_surface.md`.

**Companion rules:** L52 (issue/no-bead receipts), L56 (promotion ladder), L60
(five-signal loop integrity), L61 (ecosystem wire-in), L69 (agent-context
probes), L70 (same-tick chaining), `orchestrator-validation-discipline` skill,
and the validate-and-redispatch discipline memory note.


## L72 — STORAGE-DISCIPLINE-SYSTEM-WIDE

---
id: L72
title: Storage discipline system-wide
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: storage-headroom-blind-growth
---

Disk headroom is a flywheel doctor gate. Growth-heavy work such as Jeff-corpus
diff pulls, library ingestion, Qdrant expansion, large mirror clones, and
dispatch artifact accumulation MUST probe storage before adding bytes. If
`disk_free_pct < 10`, the work aborts before the pull/clone/index step and
routes to a storage bead or explicit blocked receipt. If `disk_free_pct < 5`,
the worker MUST notify via `~/.local/bin/notify --priority 1 "STORAGE LOW"
"<details>"`.

**How to apply:**
- `flywheel-loop doctor --json` MUST include `.storage` with
  `disk_free_gb`, `disk_free_pct`, `developer_dir_gb`, `local_state_gb`,
  `stale_baks_count`, `stale_baks_size_mb`, `qdrant_volumes_size_mb`, and
  `tmp_dispatch_artifacts_count`.
- Doctor status fails when `disk_free_pct < 10` or `stale_baks_count > 5`.
- `doctor-signal-bead-promotion.sh` promotes storage failures to
  `[auto-doctor:storage-low-headroom]` instead of letting RED storage remain a
  human-observed dashboard fact.
- Daily Jeff ingest and other corpus-growth jobs MUST run the storage probe
  before network pulls, clone operations, or indexing work.
- Pruning defaults to dry-run. Apply requires an idempotency key and never
  prunes Docker volumes automatically.

**Forbidden outputs:**
- Starting a growth-heavy clone, pull, mirror, or index job after a storage
  probe reports `<10%` free.
- Treating "storage seems low" as a prose warning without a doctor field,
  storage-history row, bead promotion path, or blocked receipt.
- Running broad destructive cleanup such as Docker volume pruning as an
  automatic response to low storage.
- Hand-deleting per-repo artifacts instead of using the shared storage policy
  and probe receipts.

**Evidence:** bead `flywheel-2zsj`; memory
`feedback_storage_discipline_global.md`; ground-truth probe
`/tmp/jeff-corpus-ground-truth-2026-05-03.md`; storage history
`~/.local/state/flywheel/storage-history.jsonl`; policy
`.flywheel/STORAGE.md`.

**Companion rules:** L48 (probe ladder before escalation), L52 (issue/no-bead
receipts), L56 (doctor signals promote to durable doctrine), L60 (doctor signals
must surface), L61 (doctrine wires into README and canonical paths), L70
(chain repair work instead of punting), L71 (validate every new surface before
calling it shipped).


## L73 — HEADLESS-BROWSER-ORPHAN-LEAK-DOCTOR

---
id: L73
title: Headless browser orphan leak doctor
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: headless-browser-orphan-leak
---

Headless `agent-browser-chrome` processes are a flywheel resource leak, not a
normal Chrome failure. Any browser-control surface that creates an
`agent-browser-chrome-*` user-data-dir MUST have a teardown path or be covered
by the shared doctor/reap contract.

**How to apply:**
- `flywheel-loop doctor --json` MUST expose `.agent_browser_leak` and
  `.headless_agent_browser_count`.
- Doctor status fails when `headless_agent_browser_count > 5` or
  `oldest_age_minutes > 60`.
- `.flywheel/scripts/headless-browser-reap.sh` defaults to dry-run and only
  targets processes whose command or user-data-dir contains
  `agent-browser-chrome`; the primary Chrome profile remains out of scope.
- Applied reaps append receipts to
  `~/.local/state/flywheel/headless-browser-reaps.jsonl`.
- `doctor-signal-bead-promotion.sh` promotes the doctor field to
  `[auto-doctor:headless_browser]` instead of leaving orphan browser leaks as
  manual cleanup work.

**Forbidden outputs:**
- Telling Joshua to restart Chrome before proving whether orphaned
  `agent-browser-chrome` processes hold the singleton lock.
- Killing broad `Google Chrome` process patterns without proving the target
  uses an `agent-browser-chrome-*` profile.
- Reporting the leak fixed without a before/after probe and a doctor field.

**Evidence:** bead `flywheel-3ck3`; scripts
`.flywheel/scripts/headless-browser-probe.sh` and
`.flywheel/scripts/headless-browser-reap.sh`; tests
`tests/headless-browser-probe.sh`.

**Companion rules:** L60 (doctor signal contract), L61 (wire docs and canonical
paths), L70 (chain repair instead of punting), L71 (validate/redispatch before
calling browser cleanup shipped), L72 (resource leak class sibling).


## L75 — ORCH-BLOCKER-COORDINATION

---
id: L75
title: Orchestrator blocker coordination
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: peer-orch-idle-on-blocker
---

When a peer orchestrator hits a flywheel-class blocker, it MUST coordinate with
`flywheel:1` within five minutes. Sitting idle, waiting for a later tick, or
bouncing the blocker to Joshua is the failure mode.

**Flywheel-class blockers:** canonical doctrine drift, missing canonical
L-rules, missing doctor signals, missing shared contracts, missing skills,
cross-repo substrate repair, or any blocker whose owner is the flywheel
orchestrator rather than the peer repo's mission work.

**How to apply:**
- Peer orchestrators write or send a structured xpane packet with
  `blocker_type=flywheel_class`, `blocker_class`, `requested_owner=flywheel:1`,
  `proposed_action`, and `flywheel_orch_action_required`.
- Cross-orch ledger rows in
  `~/.local/state/flywheel/cross-orch-coordination.jsonl` SHOULD include
  `blocker_type` with one of `flywheel_class`, `peer_class`, `external`, or
  `unknown`.
- `flywheel:1` acknowledges or acts on flywheel-class blockers in the same tick
  where capacity exists; L70 applies once the next action is known.
- `flywheel-loop doctor --json` MUST expose
  `.peer_orch_blocker_age_seconds`, `.peer_orch_blocker_watch`, and
  `.peer_orch_idle_on_blocker_count`.
- `.flywheel/scripts/peer-orch-blocker-watch.sh` is the canonical ledger probe.
  Rows older than 300 seconds with no `flywheel:1` ack fail the doctor signal
  and are candidates for auto-promotion.

**Forbidden outputs:**
- "Peer orch is blocked, waiting for callback" when the blocker is
  flywheel-class and no xpane/ledger coordination was sent to `flywheel:1`.
- Asking Joshua to decide or repair a flywheel-owned blocker before
  coordinating with `flywheel:1`.
- Treating raw peer scrollback as a coordination receipt without a ledger row,
  xpane packet, or Agent Mail message.

**Evidence:** bead `flywheel-vc3e`; probe
`.flywheel/scripts/peer-orch-blocker-watch.sh`; test
`tests/peer-orch-blocker-watch.sh`; ledger
`~/.local/state/flywheel/cross-orch-coordination.jsonl`.

**Companion rules:** L60 (doctor signal contract), L70 (same-tick chaining),
L71 (validate/redispatch), L72 (system resource coordination), and L76
(Agent Mail identity continuity for cross-orch packets).


## L76 — AGENTMAIL-IDENTITY-CANONICAL

---
id: L76
title: AgentMail identity canonical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: agentmail-identity-sprawl
---

Every orchestrator and worker MUST resolve its Agent Mail identity from the
durable session:pane registry before using Agent Mail. Ad-hoc
`register_agent` calls are forbidden except inside the resolver-mediated
registration path.

**How to apply:**
- Resolve identity with
  `flywheel-loop identity --session <session> --pane <pane> --json`.
- Canonical registry rows live at
  `~/.local/state/flywheel/agent-mail/sessions/<session>:<pane>.json`.
- Canonical token files live at
  `~/.local/state/flywheel/agent-mail/tokens/<identity>.token` with mode 600.
- First-time registration returns `status=needs_registration` and must be
  handled as an explicit Joshua-disposes decision, not by silently minting a new
  mailbox identity.
- Rotations preserve `predecessor_identity` and `rotation_reason`.
- Cross-orch handshakes carry `identity_resolved=<identity_name>` and never raw
  bearer tokens; token proof stays local as `token_path` and `token_sha256`.
- `flywheel-loop doctor --json` MUST expose `.identity_registry`,
  `identity_registry_drift`, and `identity_token_orphan`.
- `.flywheel/scripts/agentmail-registration-broadcast.sh` MUST broadcast only
  token-safe registration requests to live `needs_registration` orchestrator
  panes, honor active deferral receipts for dead sessions, and expose
  `agentmail_pending_registration_broadcasts_count`.

**Forbidden outputs:**
- Calling Agent Mail `register_agent` directly because a pane lost token context.
- Storing registration tokens only in pane environment variables or scrollback.
- Creating a new identity after compaction/reboot without a registry row linking
  it to its predecessor.
- Sending raw Agent Mail registration tokens through NTM, cross-orch packets,
  callbacks, or daily reports.

**Evidence:** bead `flywheel-g9mi`; memory
`feedback_agentmail_identity_canonical.md`; schema
`.flywheel/validation-schema/v1/agent-mail-identity-registry.schema.json`;
tests `tests/agent-mail-identity-registry.sh`.

**Companion rules:** L58 (secret material never in pane text), L60 (doctor signal
contract), L65 (identity proof beats command name), L70 (chain repair), L71
(validate/redispatch), L73 (runtime leak sibling), and the Agent Mail skill.


## L77 — DAILY-REPORT-LEARNING-ROLLUP

---
id: L77
title: Daily report learning rollup
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: no-daily-narrative
---

Every flywheel-initialized repo SHOULD have one daily narrative report under
`.flywheel/reports/daily-YYYY-MM-DD.md`. The report is the daily synthesis
surface for shipped beads, feedback memories, new trauma classes, doctrine
promotions, Jeff-intel rows, stuck work, next ready work, and cross-orch state.

**How to apply:**
- Generate with `/flywheel:daily-report` or
  `.flywheel/scripts/daily-report.sh --repo <repo> --json`.
- `flywheel-loop doctor --json` MUST expose `.daily_report` and
  `daily_report_age_hours`.
- Doctor status fails when the latest report is older than 36 hours.
- `doctor-signal-bead-promotion.sh` promotes stale or missing reports with the
  `daily_report` symptom instead of leaving narrative drift as a human-noticed
  gap.
- Use `--notify` only when the generated report contains hard blockers.

**Forbidden outputs:**
- Claiming the flywheel learned from a day without a daily report or an explicit
  no-report blocker.
- Sending routine completion notifications when the report has no hard blocker.
- Treating Jeff-intel, fuckup-log, dispatch-log, memory, or doctor state as
  separate daily narratives that do not roll up.

**Evidence:** bead `flywheel-o7dq`; command
`~/.claude/commands/flywheel/daily-report.md`; generator
`.flywheel/scripts/daily-report.sh`; tests `tests/daily-report.sh`.

**Companion rules:** L56 (promotion ladder), L61 (wire into README and canonical
paths), L63 (Jeff-intel network), L70 (chain repair), L71 (validate every
surface), and L72 (storage/headroom as daily-report sibling signal).

## L78 — JEFF-CORPUS-ACCRETIVE-INGESTION

---
id: L78
title: Jeff corpus accretive ingestion
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: bulk-ingest-without-maintenance-plan
---

The Jeff corpus is a maintained learning substrate, not a one-shot bulk index.
After a full verified baseline exists, ongoing ingestion MUST use frozen
baseline + daily SHA diff watcher + diff-only delta indexing + weekly
compaction + doctor storage budget signal.

**How to apply:**
- Baseline state lives at `.flywheel/jeff-corpus/v1/manifest.json` with one row
  per Jeff repo: repo, git SHA, last indexed timestamp, chunk count, repo size,
  and content hash set.
- Daily 03:00Z watcher `.flywheel/scripts/jeff-corpus-diff-watcher.sh` compares
  upstream HEAD to the manifest SHA and writes only changed repos to
  `.flywheel/jeff-corpus/pending-reindex.jsonl`.
- `.flywheel/scripts/jeff-corpus-delta-reindex.sh` uses
  `git diff <old_sha> <new_sha> --name-only` and content-hash deduplication; it
  MUST NOT full-reindex unchanged files.
- Sunday 04:00Z compaction `.flywheel/scripts/jeff-corpus-compact.sh` merges
  v1+v2 into the next baseline, drops superseded chunks, and retires old
  manifests/delta rows to cold storage.
- `flywheel-loop doctor --json` MUST expose `jeff_corpus_v1_total_mb` and
  `jeff_corpus_storage_health` (`GREEN|YELLOW|RED`). RED blocks new ingestion
  until compaction runs.

**Forbidden outputs:**
- "Reindex all Jeff repos nightly" or any recurring full-corpus maintenance
  path after the verified baseline exists.
- Calling Jeff corpus ingestion complete without a manifest, pending queue,
  delta-only path, compaction path, doctor storage signal, and tests.
- Treating a docs-only schedule recommendation as implementation proof without
  the watcher script and deterministic fixture coverage.

**Evidence:** bead `flywheel-15dg`; memory
`feedback_accretive_corpus_ingestion.md`; completed 177/177 Qdrant verification
in `/tmp/jeff-corpus-truth-state.md`; tests `tests/jeff-corpus-accretive.sh`.

**Companion rules:** L60 (doctor signal contract), L63 (Jeff substrate
dependency), L64 (Jeff pattern mining), L72 (storage discipline), L77 (daily
learning rollup), `info-source-watchtower`, `vector-ingest-verification`, and
`qdrant-ops`.

## L79 — STORAGE-OVERRIDE-RECEIPTS-ARE-MECHANICAL

---
id: L79
title: Storage override receipts are mechanical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: manual-storage-threshold-override
---

Joshua-disposed storage threshold exceptions MUST be represented as
`storage-override/v1` receipts, not as prose or one-off environment tweaks.
`flywheel-loop doctor` is the gate owner: it reads active receipts, applies the
lowest valid temporary threshold, exposes override counters, fails closed when
no active receipt applies, and appends `STORAGE-CLEARED` when storage recovers
above the base threshold.

**How to apply:**
- Receipt schema lives at
  `.flywheel/validation-schema/v1/storage-override.schema.json`.
- Active receipts live under
  `~/.local/state/flywheel/storage-overrides/*.json`; event rows live in
  `~/.local/state/flywheel/storage-overrides/events.jsonl`.
- `flywheel-loop doctor --json` MUST expose top-level
  `storage_override_active_count` and `storage_override_expiring_in_min`, plus
  `.storage_override.effective_min_free_pct`.
- `flywheel-loop doctor --storage-min-free-pct N` and
  `FLYWHEEL_STORAGE_MIN_FREE_PCT=N` are explicit base-threshold controls; active
  receipts may only lower the gate temporarily and must expire.
- `sync-canonical-doctrine.sh --apply` propagates the storage override schema to
  flywheel-installed repos alongside canonical doctrine.

**Forbidden outputs:**
- Lowering storage thresholds in pane prose without a schema-valid receipt and
  expiry.
- Treating an expired, wrong-target, or unsigned-but-signature-present receipt
  as active.
- Continuing to apply an override after a `STORAGE-CLEARED` event or after the
  base storage gate passes.

**Evidence:** bead `flywheel-vso8`; schema
`.flywheel/validation-schema/v1/storage-override.schema.json`; tests
`tests/storage-override.sh`; receipts
`~/.local/state/flywheel/storage-overrides/`.

**Companion rules:** L60 (doctor signal contract), L61 (wire-in), L70 (chain
repair), L71 (validate every surface), L72 (storage discipline), and L77 (daily
report surfaces).

## L80 — CLOSED-BEAD-AUDIT-MINING

---
id: L80
title: Closed bead audit mining
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: closed-bead-quality-drift
---

Closed beads are not accepted as complete solely because the close reason says
they shipped. Every worker callback MUST report structured
`did=<n>/<total>`, `didnt=<bead-ids|none>`, and `gaps=<bead-ids|none>`, and any
uncompleted gate or newly-discovered work MUST already have a fix or audit-gap
bead before callback. The orchestrator must treat missing DID/DIDNT/GAPS fields
as a validation failure.

**How to apply:**
- Worker dispatch templates and `/flywheel:worker-tick` require a DID/DIDNT/GAPS
  self-audit before callback.
- `/flywheel:learn --bead-quality-mining` runs
  `.flywheel/scripts/bead-quality-mining.sh --repo <repo> --json`.
- The miner inspects closed beads from the last 48h, parses acceptance gates,
  derives mechanical checks for paths, doctor signals, and skipped tests, then
  creates parented audit-gap beads for unverified gates.
- Closed bead notes get
  `audit_status=full|partial|gap_pending; audit_run_at=<ts>; gap_beads=<ids>`.
- `flywheel-loop doctor --repo <repo> --json` MUST expose
  `closed_bead_audit_pending_count`, `closed_bead_audit_gap_count`, and
  `audit_gap_top_classes`; pending count greater than 2 is a failing signal.

**Forbidden outputs:**
- Closing, summarizing, or routing a worker callback that lacks DID/DIDNT/GAPS
  fields.
- Reporting `didnt=none` or `gaps=none` before auditing every assigned
  acceptance gate.
- Treating a closed bead with missing artifacts, missing doctor signals,
  skipped tests, or non-derivable gates as fully validated without an audit note
  or gap bead.
- Running closed-bead mining repeatedly and creating duplicate audit-gap beads
  for the same original bead and gate.

**Evidence:** bead `flywheel-7yic`; script
`.flywheel/scripts/bead-quality-mining.sh`; tests
`tests/bead-quality-mining.sh`; command docs
`~/.claude/commands/flywheel/worker-tick.md`,
`~/.claude/commands/flywheel/_shared/dispatch-template.md`, and
`~/.claude/commands/flywheel/learn.md`.

**Companion rules:** L52 (beads or no-bead receipt), L53 (fuckups reported in
callbacks), L56 (promotion ladder), L60 (doctor signal contract), L70 (no
punt), and L71 (validate-and-redispatch discipline).

## L81 — DOCS-ARE-LOAD-BEARING-CROSS-PANE-VALIDATED

---
id: L81
title: Docs are load-bearing and require cross-pane validation
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: documentation-substrate
---

Durable operational artifacts need README-grade documentation before they are
considered ready substrate. For load-bearing artifacts, docs are part of the
artifact contract. A worker may draft the README, but the drafting worker may
not be the final validator. Gate 2 validation MUST be performed by a different
pane, and Joshua signoff is required before a README can move from foundation
or reviewed state to validated state.

Load-bearing artifacts include flywheel binaries, launchd plists, hooks,
slash-command contracts, substrate-registry rows, canonical doctrine, and any
script or state machine that another pane relies on for execution decisions.

**How to apply:**
- Worker pane drafts the README at the exact artifact-owned path with
  frontmatter, Mermaid when required, command/reference coverage, side effects,
  error modes, and a real `validation_command`.
- Worker callback identifies the README path and leaves `reviewed_by`,
  `reviewed_at`, `validated_by`, and `validated_at` unset unless the dispatch
  explicitly assigned a separate review role.
- Orchestrator pane performs Gate 2 from a cold read: run the validation
  command, check target path existence, inspect Mermaid and command reference
  coverage, verify See Also paths, and confirm no self-validation.
- If Gate 2 fails, the orchestrator rejects the artifact back to the worker
  with checklist failures. The worker rewrites the README; do not patch-forward
  a failed README to make it look better while preserving the failed premise.
- If Gate 2 passes, the orchestrator fills `reviewed_by` and `reviewed_at`,
  then routes the artifact to Joshua for final signoff.
- Joshua final signoff sets `validated_by` and `validated_at`. Only then may
  the README be treated as validated.
- If the target artifact is retired or removed, the README must move to retired
  state or be removed by an explicit docs-retirement bead; orphaned docs are
  substrate drift.

**SOFT violations:**
- `readme_below_floor`: artifact lacks a README or the inventory grade is F.
- `readme_validated_by_self`: `validated_by` equals `reviewed_by`, or the
  worker that drafted the README also marks it validated.
- `readme_orphaned`: README `target_artifact` path no longer exists.
- `readme_validation_failed`: README `validation_command` exits non-zero.
- `readme_pending_orchestrator_review`: drafted README waits more than 2 hours
  without Gate 2 review.
- `readme_pending_joshua_signoff`: `reviewed_by` is set but `validated_by` is
  null for more than 24 hours.
- `readme_review_timeout`: draft-to-validation round trip exceeds 7 days.

**Forbidden outputs:**
- Claiming load-bearing documentation is validated when the author and reviewer
  are the same pane.
- Treating README text as sufficient when `validation_command` is absent,
  failing, stale, or not run by a separate reviewer.
- Patching a failed README forward after Gate 2 rejection instead of issuing a
  rewrite/reject-and-revert loop.
- Marking a repo's docs substrate caught up when `readme_below_floor`,
  `readme_validated_by_self`, or `readme_validation_failed` is still present.

**Evidence:** bead `flywheel-ic6`; synthesis bead `flywheel-7np`; plan
`.flywheel/plans/cross-pane-protocol-2026-05-01/04-XPANE-SYNTHESIS.md`; Lane 1
doctrine source
`.flywheel/plans/cross-pane-protocol-2026-05-01/01-L69-DOCTRINE-AND-STATE-MACHINE.md`;
documentation-substrate synthesis reporting 732 tracked artifacts and 0 A-grade
docs.

**Companion rules:** L56 (promotion ladder), L60 (doctor signal contract), L61
(wire doctrine into AGENTS/README), L71 (validate-and-redispatch discipline),
L80 (closed-bead audit mining), `flywheel-readme`, and the cross-pane protocol
plan. The source plan called this proposed L69, but L69/L70 were already
allocated before this bead landed; L81 preserves canonical ID uniqueness.

## L82 — CANONICAL-CLI-SCOPING-MANDATORY-FOR-ALL-FLYWHEEL-CLIS

---
id: L82
title: Canonical CLI scoping mandatory for all flywheel CLIs
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: partial-cli-surface
---

Every flywheel CLI surface MUST implement the canonical CLI scoping contract
from `~/.claude/skills/canonical-cli-scoping/SKILL.md` before it is treated as
real operator substrate. CLI work may not ship as a narrow command helper with
doctor/health/repair, validation, self-documentation, schema, and mutation
discipline deferred to a future bead.

**How to apply:**
- Every new or extended CLI dispatch cites `canonical-cli-scoping` and embeds
  its implementation checklist in the bead acceptance gates.
- Before claiming a console-script name, run `which <name>` / `command -v
  <name>` and prove no collision or intentional ownership.
- Every CLI provides `doctor`, `health`, `repair`, `validate`, `audit`, `why`,
  `--info`, `--examples` or `examples`, `quickstart`, `help <topic>`,
  `completion <shell>`, `schema <command>`, and `--json` everywhere.
- Mutating commands provide `--dry-run`, `--explain`, idempotency keys, and an
  audit log. Dry-run JSON uses planned-only keys; applied JSON uses
  actual-only keys.
- Every CLI publishes stable JSON schemas and canonical exit codes:
  0 success, 1 expected/domain failure, 2 usage, 3 transient/upstream, 4 gate
  blocked, 5+ documented domain-specific codes.
- Implementation callbacks run
  `~/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh <cli>`
  and report PASS/FAIL for every checklist cluster, not only the quick checker.

**Forbidden outputs:**
- "CLI shipped" when only the happy-path domain command exists.
- Deferring doctor/health/repair, schema output, JSON mode, or mutation
  dry-run/idempotency to an unnamed future pass.
- Adding a flywheel CLI command without a name-collision precheck.
- Treating internal helper commands as exempt when agents or operators depend
  on them for live decisions.

**Evidence:** bead `flywheel-ic6`; parent epic `flywheel-ntf`; `flywheel-qnc`
for `flywheel-readme`; incident
`INCIDENTS.md#canonical-cli-scoping-missed-on-new-cli-design`; plan
`.flywheel/plans/cross-pane-protocol-2026-05-01/04-XPANE-SYNTHESIS.md`.

**Companion rules:** L61 (wire doctrine into AGENTS/README), L65 (CLI identity
proof), L71 (validate-and-redispatch discipline), L80 (DID/DIDNT/GAPS
callbacks), `canonical-cli-scoping`, and the `flywheel-ntf` repair epic. The
source bead requested L70 for this doctrine, but L70 was already allocated to
ORCH-NO-PUNT before this bead landed; L82 preserves canonical ID uniqueness.

## L83 — FILE-LENGTH-DISCIPLINE-FLEET-WIDE

---
id: L83
title: File length discipline fleet-wide
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: monolithic-file-debt-accumulating
---

Every flywheel-installed repo MUST surface file-length debt mechanically before
monoliths become operational risk. Canonical thresholds are owned by
`~/.claude/skills/canonical-cli-scoping/SKILL.md`: bash/shell 500 lines,
Python 400 lines, Rust 500 lines, and doctrine/docs Markdown 1500 lines.

**How to apply:**
- `flywheel-loop doctor --json` MUST expose `oversized_files_count`,
  `oversized_files`, and `file_length`.
- `.flywheel/scripts/file-length-probe.sh --repo <repo> --json` is the
  canonical probe for threshold checks.
- More than 3 oversized files triggers
  `doctor-signal-bead-promotion.sh` to create or match a
  `[auto-doctor:monolithic_file_debt]` bead.
- Legitimate exceptions require an in-file receipt:
  `canonical-cli-scoping-allow-large: <reason>`. Generated code, reviewed
  doctrine archives, and migration archives are acceptable reasons; silent
  exceptions are not.
- Shell files route to sourced libraries or thin dispatchers; Python files
  route to `python-best-practices`; Rust files route to `rust-best-practices`.

**Forbidden outputs:**
- Adding more behavior to an already oversized operational script without a
  split plan, explicit large-file receipt, or follow-up bead.
- Calling a CLI or loop substrate maintainable while its implementation file is
  over threshold and invisible to doctor.
- Treating docs as exempt when they are active operating doctrine rather than
  deliberate archives.

**Evidence:** bead `flywheel-useh`; probe
`.flywheel/scripts/file-length-probe.sh`; tests `tests/file-length-probe.sh`;
worst offender `~/.claude/skills/.flywheel/bin/flywheel-loop`.

**Companion rules:** L61 (doctrine landing), L70 (same-tick chain-forward),
L71 (validate-and-redispatch discipline), L80 (DID/DIDNT/GAPS callbacks), and
L82 (canonical CLI scoping).

## L84 — LOCKED-WORKER-IDENTITIES-CANONICAL

---
id: L84
title: Locked worker identities canonical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: agent-mail-identity-sprawl-recurring
---

Worker panes MUST keep a durable Agent Mail identity bound to
`(session,pane,role)` across compaction, restart, and Mac reboot. Dispatches
must cite the registry identity; workers must echo that identity in callbacks.

**How to apply:**
- Preallocate rows with
  `.flywheel/scripts/agent-mail-pre-allocate-worker-identities.sh --apply --json`
  from latest `~/.local/state/flywheel/session-topology.jsonl`.
- Registry rows live at
  `~/.local/state/flywheel/agent-mail/sessions/<session>:<pane>.json` and use
  schema `agent-mail-identity-registry/v2` with role
  `orch|worker|callback|archived`.
- `flywheel-loop identity --session <session> --pane <pane> --json` is the
  resolver. If a topology-declared worker pane is missing, the resolver creates
  a deterministic `needs_registration` row instead of requiring ad-hoc
  registration.
- `flywheel-loop doctor --json` MUST expose
  `worker_identity_registered_count` and
  `agentmail_orphan_session_rows_count`.
- Dispatch packets and worker callbacks MUST include
  `identity_name=<registry-identity-name>`.
- Topology shrink archives stale rows instead of minting replacements; archived
  rows preserve provenance.
- A LaunchAgent or equivalent boot-time runner MUST refresh preallocation after
  Mac reboot.

**Forbidden outputs:**
- Registering a fresh worker Agent Mail identity because the pane lost context.
- Dispatching work to a topology-declared worker pane with no registry row.
- Reporting callback completion without `identity_name=<registry-identity-name>`.
- Treating a tokenless worker row as missing identity; it is an explicit
  `needs_registration` identity until Joshua approves a mailbox token.

**Evidence:** bead `flywheel-et7t`; script
`.flywheel/scripts/agent-mail-pre-allocate-worker-identities.sh`; tests
`tests/locked-worker-identities.sh`; schema
`.flywheel/validation-schema/v1/agent-mail-identity-registry.schema.json`.

**Companion rules:** L51 (Agent Mail reservations), L58 (secret material never in pane
text), L65 (identity proof beats command name), L76 (AgentMail identity
canonical), L80 (DID/DIDNT/GAPS callbacks), and the Agent Mail skill.

## L85 — IDLE-STATE-CLASS-CANONICAL

---
id: L85
title: Idle state class canonical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: idle-pane-recovery-hidden-in-watcher
---

Idle worker-pane recovery MUST be driven by a doctor-visible state class, not by
logic buried inside a daemon wrapper. The canonical classifier is
`.flywheel/scripts/idle-state-probe.sh`.

**How to apply:**
- `flywheel-loop doctor --json` MUST expose `idle_state_class`,
  `idle_state_summary`, `idle_dispatching_over_threshold_count`,
  `idle_state_config_path`, and `idle_state_config_loaded`.
- The idle watcher may dispatch only from
  `idle_state_class == "dispatching"` rows emitted by the canonical probe.
- A `dispatching` worker pane older than 5 minutes is a readiness failure:
  either dispatch the worker or repair the watcher.
- Per-repo policy is configured by `idle-state-config/v1`; peer orchestrator
  defaults disable `saturated` and keep `dispatching` plus `light_queue` active
  so they escalate to `flywheel:1` through xpane instead of Joshua.
- Tests must cover all four active classes plus pane-not-waiting, disabled
  config, and `classes_active` filtering before changing the watcher or probe.

**Forbidden outputs:**
- Reporting idle-pane recovery as healthy when the watcher has private
  classification logic not surfaced in doctor JSON.
- Dispatching from `/tmp/idle-pane-auto-dispatch.sh` without a matching
  `dispatching` row from `.flywheel/scripts/idle-state-probe.sh`.
- Treating `saturated` as actionable for peer orchestrators unless their local
  config explicitly enables it.

**Evidence:** bead `flywheel-viux`; probe
`.flywheel/scripts/idle-state-probe.sh`; schema
`.flywheel/validation-schema/v1/idle-state-config.schema.json`; watcher
`/tmp/idle-pane-auto-dispatch.sh`; tests `tests/idle-state-probe.sh`.

**Companion rules:** L50 (socraticode survey), L57 (loop state marker is not a
driver), L70 (same-tick chain-forward), L75 (peer orchestrator blocker
coordination), and L80 (DID/DIDNT/GAPS callbacks).

## L86 — CROSS-SESSION-CALLBACK-RECEIVER-MUST-BE-LIVE

---
id: L86
title: Cross-session callback receiver must be live
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: cross-session-dispatch-no-callback-closure
---

Cross-session work selection is allowed; cross-session worker dispatch is not
allowed unless the remote orchestrator and callback receiver are live and
processing loop work. A dispatch that sends work to a peer session worker while
the peer orchestrator is dead creates invisible callback debt and leaves beads
stuck `in_progress`.

**How to apply:**
- Prefer local flywheel workers for fleet-wide infrastructure work. File or
  update peer-repo beads when the finding belongs there, but do not bypass the
  peer orchestrator's closure loop.
- If a cross-session worker dispatch is unavoidable, first prove
  `remote_session_orch_alive=true` with all three facts: session visible in
  current NTM state, orchestrator/callback pane reachable, and that pane has a
  live loop/callback-processing receipt newer than two cadence windows.
- Dispatch packets MUST record the callback receiver session/pane and the
  liveness proof path. Missing proof means no dispatch.
- `/flywheel:supervisor` MUST model this as
  `cross_session_callback_orphan` and expose `callback_orphan_count` or
  `cross_session_callback_orphan_count` when a cross-session dispatch has no
  matching processed callback before deadline.
- When this class is found after the fact, file an orphan/no-bead receipt that
  names the remote beads and asks the owning orchestrator to close or reopen
  them.

**Forbidden outputs:**
- Sending work directly to another session's worker pane because the task is
  infrastructure-deployment or fleet-wide.
- Treating `ntm send` success to a remote worker as proof the remote
  orchestrator will receive, validate, and close the callback.
- Reporting cross-session watcher health without checking callback receiver
  liveness and orphaned remote `in_progress` beads.
- Asking Joshua why a peer session is idle before checking whether the remote
  orchestrator/callback receiver was alive when work was dispatched.

**Evidence:** bead `flywheel-b8zm`; fuckup forensic
`.flywheel/fuckup-log/2026-05-04T04-00Z-skillos-cross-session-no-callback-closure.md`;
Lane A addendum
`.flywheel/PLANS/orchestrator-workforce-supervision-2026-05-04/01-RESEARCH-A-ADDENDUM.md`;
Phase 2 synthesis
`.flywheel/PLANS/orchestrator-workforce-supervision-2026-05-04/02-REFINE-r2.md`;
no-bead receipt
`.flywheel/validation-receipts/no-bead-cross-session-callback-closure-skillos-20260504T0400Z.json`.

**Companion rules:** L29 (NTM-only pane I/O), L52 (bead or no-bead receipt),
L57 (loop marker is not driver), L61 (doctrine wire-in), L70 (same-tick
chain-forward), L75 (peer orchestrator coordination), L80 (DID/DIDNT/GAPS), and
L85 (idle state class canonical).

## L87 — STALE-ERROR-TEXT-AUTO-PING-RECOVERY

---
id: L87
title: Stale error text auto-ping recovery
status: temporary
shipped: 2026-05-04
sunset_when:
  bead: flywheel-pp1g
review_due: 2026-06-04
trauma_class: ntm-classifier-stale-error-poisoning
---

Until upstream `ntm` resolves stale error text classification, flywheel may
use a bounded no-op ping recovery for panes whose live activity row is
`state=ERROR` only because stale `failed_text` or `api_error` remains in
scrollback above a current `codex_chevron_prompt`.

**How to apply:**
- Detect candidates with `.flywheel/scripts/stale-error-auto-ping.sh --json`.
  Default mode is dry-run and writes no pane input.
- Candidates must satisfy all four facts: `capture_provenance=="live"`,
  `state=="ERROR"`, detected patterns include `codex_chevron_prompt`, and
  detected patterns include `failed_text` or `api_error`.
- Only use `--apply` from a watcher or operator loop after the dry-run output
  lists the candidate pane. Apply sends a no-op ping with `--no-cass-check`,
  then rechecks activity and reports `post_recheck_candidate_count`.
- A true fresh error remains `ERROR` after recheck and must not be counted as
  recovered. Repeated failures should stay visible to idle-state and callback
  validation probes rather than being hidden by the recovery layer.

**Forbidden outputs:**
- Treating stale error auto-ping as an upstream fix. It is a temporary
  flywheel-side recovery layer.
- Sending pings to panes without live capture provenance.
- Sending pings to non-ERROR panes, unavailable captures, or panes missing the
  current Codex chevron prompt.
- Reporting idle watcher health without citing the auto-ping dry-run/apply
  receipt when this recovery was used.

**Evidence:** bead `flywheel-pp1g`; upstream `ntm` issue filed for stale
error-pattern priority; workaround script
`.flywheel/scripts/stale-error-auto-ping.sh`; tests
`tests/stale-error-auto-ping.sh`; receipt `/tmp/ntm-stale-error-evidence.md`.

**Companion rules:** L29 (NTM-only pane I/O), L50 (Socraticode survey), L60
(doctor signal shape), L67 (truth source must be live), L71
(validate-and-redispatch discipline), L80 (DID/DIDNT/GAPS callbacks), and L85
(idle state class canonical).

## L88 — PUBLISHABILITY-BAR-CANONICAL

---
id: L88
title: Publishability bar canonical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: publishability-drift
---

Every flywheel-owned repo should clear a first-look publishability bar: Jeff
would trust the substrate mechanics, Donella would see the feedback system, and
Joshua would be willing to show the work as ZestStream AaaS-grade.

**How to apply:**
- Store the rubric at `.flywheel/PUBLISHABILITY-BAR.md`.
- Store each repo's current assessment at `.flywheel/PUBLISHABILITY-AUDIT.md`.
- Score the seven facets: README front-door, doctrine clarity,
  doctor/health/repair triad, executable tests, idempotent install/uninstall,
  code aesthetic, and demo-ability.
- `flywheel-loop doctor --repo <repo> --json` MUST expose
  `publishability_bar_score` and nested `publishability_bar` evidence.
- Scores below 5 warn. Scores below 3 fail readiness.
- `/flywheel:plan` Phase 3 MUST include the three-judges publishability pass
  for new repos and major features.

**Forbidden outputs:**
- Calling a repo publishable without a recorded `.flywheel/PUBLISHABILITY-AUDIT.md`.
- Treating fixture-only docs as a substitute for doctor JSON and tests.
- Hiding a NO facet in prose instead of filing a targeted follow-up bead or
  explicit no-bead reason.

**Evidence:** bead `flywheel-wcq5`; rubric `.flywheel/PUBLISHABILITY-BAR.md`;
audit template `.flywheel/PUBLISHABILITY-AUDIT.md`; doctor probe
`.flywheel/scripts/publishability-bar.sh`; prompt
`~/.claude/skills/.flywheel/prompts/three-judges-rubric.md`; tests
`tests/publishability-bar.sh`.

**Companion rules:** L50 (Socraticode survey), L52 (issues-to-beads), L60
(doctor signal shape), L71 (validate-and-redispatch discipline), L80
(DID/DIDNT/GAPS), and L83 (file-length discipline).

## L89 — ZESTSTREAM-VOICE-PUBLIC-REPO-CANONICAL

---
id: L89
title: ZestStream voice public repo canonical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: public-work-without-joshua-voice
---

Public ZestStream-owned repos must read as Joshua's work, not generic agency or
anonymous engineering output. The Joshua judge in L88 is bound to the
`zeststream-brand-voice` skill, the `zesttube` reference repo, and the live
ZestStream website voice.

**How to apply:**
- Public ZestStream repos mark `Public repo: yes` in
  `.flywheel/PUBLISHABILITY-AUDIT.md`.
- README, MISSION, and landing copy must carry a scorecard row from
  `zeststream-brand-voice` with composite >=95 before public publish.
- Readiness fails when `brand_voice_composite < 90`,
  `banned_words_count > 0`, or `ungrounded_claims_count > 0`.
- The doctor signal exposes `publishability_bar_score` as an object containing
  `score`, `brand_voice_composite`, `banned_words_count`, and
  `ungrounded_claims_count`.
- Public pushes use `.flywheel/scripts/zeststream-public-prepublish-hook.sh` or
  an equivalent hook before `git push public`.
- Private/internal repos are exempt until they are prepared for public release.
  Client repos use the client brand config instead of ZestStream voice.
  Jeff-owned repos keep Jeff's voice and attribution.

**Forbidden outputs:**
- Saying "this embodies Joshua" without a scorecard log or explicit exemption.
- Shipping public README/MISSION copy with banned ZestStream words or ungrounded
  factual claims.
- Attributing Jeff Emanuel's tools to Joshua.
- Applying ZestStream first-person rules to client-owned or Jeff-owned repos.

**Evidence:** bead `flywheel-06zn`; `zeststream-brand-voice` skill;
`~/Developer/zesttube`; `.flywheel/PUBLISHABILITY-BAR.md`;
`.flywheel/scripts/publishability-bar.sh`;
`.flywheel/scripts/zeststream-public-prepublish-hook.sh`; tests
`tests/publishability-bar.sh` and `tests/zeststream-public-prepublish-hook.sh`.

**Companion rules:** L52 (gap beads for failed facets), L61 (doctrine wire-in),
L71 (validate-and-redispatch), L88 (publishability bar), and the
`zeststream-brand-voice` hard-reject rules.

## L90 — PANE-ACTION-PLAN-REQUIRES-LIVE-CAPTURE

---
id: L90
title: Pane action plan requires live capture
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: orchestrator-pane-action-without-live-truth
---

Before any destructive, interrupting, or recovery pane action, the orchestrator
MUST produce a pane-action receipt from fresh live capture. Robot activity,
stale error text, pane title, old health JSON, or capacity math are hints, not
authority. Clean agent prompt means dispatch/no-op; active work means wait;
unknown means classify unknown and do not destroy.

Required receipt fields are `session`, `pane`, `capture_ts`,
`capture_provenance`, `visible_prompt_class`, `activity_state`,
`target_action`, `allowed_by_rule`, `forbidden_actions_checked`, and
`recovery_postcondition`. A valid probe should fail unless
`capture_provenance == "live"`, `capture_ts` is within the freshness window,
and destructive actions are blocked unless `visible_prompt_class` proves a
recoverable shell or confirmed-dead state.

**Why:** Last-24h fuckup-log evidence shows 38 rows across pane/capacity action
classes: `worker_capacity_gate_failed` 12 rows
`~/.local/state/flywheel/fuckup-log.jsonl#L312-L327`,
`mobile-eats-dispatch-health-gate-fail` 11 rows `#L455-L467`,
`worker-pane-not-waiting-integrate-blocker` 6 rows `#L399-L414`,
`worker_capacity_gate_false_block` 5 rows `#L328-L344`, and
`integrate_worker_not_waiting` 4 rows `#L351-L359`. Memory cross-ref:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_is_the_killer_not_codex.md`.

**How to apply:** enforce a pane-action receipt schema and validator before any
pane-touching action; the validator should expose a machine check equivalent to
`jq -e '.capture_provenance == "live" and (.forbidden_actions_checked | length) > 0 and .allowed_by_rule == true'`.

**Cross-references:** L29 (NTM-only pane I/O), L57 (loop marker is not driver),
L67 (truth source must be live), L71 (validate-and-redispatch), L85 (idle state
class canonical), L87 (stale error auto-ping recovery), and
`feedback_probe_shape_ambiguity_is_not_joshua_gate.md`.

## L91 — DISPATCH-DELIVERY-IS-A-FOUR-STATE-RECEIPT

---
id: L91
title: Dispatch delivery is a four-state receipt
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: dispatch-transport-ack-mistaken-for-work-started
---

`ntm send` proves transport acceptance only. Dispatch is not counted as active
work until a receipt proves four states: `transport_accepted`,
`prompt_visible_in_target`, `prompt_submitted`, and `work_started`. If any
state is false or unknown after the grace window, classify `not_started`, repair
or re-dispatch, and do not count the worker as busy.

The receipt must name the session, pane, dispatch id, send command, capture
proof, and classification source. A valid probe should fail unless transport was
accepted, a fresh target-pane capture or log proves the prompt crossed the input
boundary, and post-send output indicates the worker began processing the new
dispatch rather than merely echoing queued text.

**Why:** Last-24h evidence includes `mobile-eats-dispatch-health-gate-fail` 11
rows `~/.local/state/flywheel/fuckup-log.jsonl#L455-L467`,
`daily_report_missing_dispatch_gate` 4 rows `#L445-L448`, plus individual
transport/callback rows including `codex-queued-not-submitted` `#L290`,
`worker-callback-composed-not-submitted` `#L329`,
`dispatch-callback-missed` `#L340`, `ntm_dispatch_pasted_but_worker_idle`
`#L368`, and `dispatch_transport_prompt_aborted` `#L371`. Memory cross-ref:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dispatch_delivery_validation_required.md`.

**How to apply:** wrap worker dispatch and callback sends in a four-state
receipt validator; the validator should expose a machine check equivalent to
`jq -e '.transport_accepted and .prompt_visible_in_target and .prompt_submitted and .work_started'`.

**Cross-references:** L50 (Socraticode dispatch contract), L57 (driver proof),
L60 (doctor signal shape), L70 (same-tick chain-forward), L71
(validate-and-redispatch), L80 (DID/DIDNT/GAPS), L86 (callback receiver live),
and `feedback_worker_verify_callback_delivered.md`.

## L92 — AUDIT-FINDINGS-ROUTE-BY-DATA

---
id: L92
title: Audit findings route by data
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: audit-findings-joshua-gated-after-data-verdict
---

Audit findings are routed by severity, confidence, coverage, and disposition.
Confirmed critical/high findings halt or create first-wave mitigation beads;
medium/low findings route to refine, polish, or follow-up beads. Zero new
critical/high findings plus converged coverage advances automatically.

Joshua decides product intent, business priority, explicit override,
destructive ops, and security/secret/PHI only. A plan/audit pipeline must not
turn already-scored findings into a new Joshua-disposes pause when the audit
lenses have produced a converged verdict and mechanical routing data.

**Why:** Last-24h evidence includes `three_q_surface_gap` 6 rows
`~/.local/state/flywheel/fuckup-log.jsonl#L376-L476`,
`daily-report-missing-integrate-blocker` 4 rows `#L402-L413`, and
`daily_report_missing_dispatch_gate` 4 rows `#L445-L448`. Memory cross-ref:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_audit_findings_are_data_decided_not_joshua_gated.md`.

**How to apply:** route Phase 3 audit outputs with a severity/composite matrix;
the validator should expose a machine check equivalent to
`jq -e '(.critical_count == 0) and (.composite >= 7) and ((.lens_disagreement // 0) < 2) and (.coverage_converged == true)'` for auto-advance, while critical/high blockers emit mitigation beads instead of prose questions.

**Cross-references:** L52 (issues become beads or no-bead receipts), L56
(promotion ladder), L70 (same-tick chain-forward), L71
(validate-and-redispatch), L80 (closed-bead audit mining), L88 (three-judges
publishability bar), and `feedback_probe_shape_ambiguity_is_not_joshua_gate.md`.

## L93 — JEFF-ISSUE-REQUIRES-WORKAROUND-RESEARCH-FIRST

---
id: L93
title: Jeff issue requires workaround research first
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: upstream-escalation-without-workaround-research
---

Before proposing or filing any Jeff upstream issue, the orchestrator MUST prove workaround research first. The receipt must show indexed-source mining across the failing repo and relevant Jeff dependency repos with at least 2-3 query phrasings and K>=10 results per query, at least five ranked workaround candidates with source citations, and copy-test receipts for the top two candidates on a disposable copy of the affected substrate. A Jeff issue is warranted only when all five or more workarounds fail copy-test, or when the bug is foundational and no workaround exists.

If a reversible workaround passes copy-test, apply the workaround through the repo's normal validation path and document the upstream evidence instead of filing. If filing is warranted, the issue body must include full repro steps, copy-test evidence for every failed workaround, environment factors such as concurrency, version, and live-vs-copy differences, and a fix direction framed as an observed contract gap rather than a prescriptive patch. L93 extends L66; L66's source-probe/rubric/submission gates are necessary but not sufficient without the workaround-research precondition.

**Why:** v2a1 REINDEX repair rolled back after only shallow attempts, and Joshua corrected the reflex to file a Jeff issue with the question: what workarounds do we have in indexed Jeff sources? The Jeff corpus is already load-bearing substrate, and prior issues show this distinction matters: frankensqlite#85 was intentional behavior with a workaround, while beads_rust#270 was a true upstream repair case only after evidence and dogfood receipt existed.

**How to apply:** any dispatch, callback, or draft containing `jeff issue`, `file upstream`, `Jeff-worthy`, or `escalate to Jeff` must link a preceding `*-workarounds-research-*` task or receipt from the last 24 hours. A mechanical validator may treat the receipt as eligible only when this predicate passes: `jq -e '(.socraticode_queries >= 2 and .socraticode_k_per_query >= 10) and (.workarounds_ranked >= 5) and (.top_workarounds_copy_tested >= 2) and ((.jeff_issue_warranted == false) or (.all_workarounds_failed == true or .foundational_no_workaround == true))'`. Doctor should expose `jeff_issue_pending_without_workaround_research_count`, target `0`, and the issue-filing hook should block when no qualifying workaround-research callback exists.

**2026-05-04 beads_rust dep-add note:** skillos hit `br dep add`
`OpenRead root page 184`, then `root page 121` after fresh JSONL rebuild. L93
prevented a duplicate upstream issue: the exact edge failed on installed
`br 0.1.20`, but passed on disposable `br 0.2.4`; direct SQL + flush + rebuild
also passed as a reversible fallback. Receipt:
`/tmp/beads-rust-dep-add-corruption-jeff-issue-output.md`.

**Cross-references:** L48 (substrate exhaustion before escalation), L63 (Jeff intel network), L64 (Jeff as mentor), L66 (outbound Jeff issue phased gate), L71 (validate-and-redispatch), L78 (Jeff corpus accretive ingestion), `feedback_jeff_issue_chain.md`, `feedback_jeff_issue_requires_full_workaround_research_first.md`, `reference_jeff_substrate_inventory.md`, `reference_upstream_issues.md`, and the `jeff-issue-chain` skill.

## L94 — SHARED-SQLITE-WRITES-MUST-SERIALIZE

---
id: L94
title: Shared SQLite writes must serialize
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: sqlite-concurrent-writers
---

Any dispatch, hook, probe, import, rebuild, or repair that can write a shared SQLite database MUST prove single-writer ownership before the write starts. Shared SQLite substrates include repo-local `.beads/beads.db`, flywheel state databases, JSM/skillos state databases, and any SQLite DB read or written by multiple panes, sessions, hooks, or launchd jobs. Parallel workers may read from immutable snapshots; live writes require a named lock or a serialized queue.

Required write receipt fields are `db_path`, `db_fingerprint`, `operation_class`, `writer_owner`, `lock_path`, `lock_acquired_at`, `lock_timeout_seconds`, `competing_writer_count`, `pre_integrity_state`, `post_integrity_state`, and `release_status`. If the lock is unavailable, the work becomes queued or snapshot-read-only; it must not retry live writes in parallel. Repair/reindex paths must treat `br`, `jsm`, and direct `sqlite3` writes as the same write family, not separate safe channels.

**Why:** 2026-05-04 produced a same-day SQLite writer family: v2a1 substrate REINDEX/repair moved live Beads state through b-tree/WAL failure modes, skillos beads-import rebuild did not rewrite malformed pages, and skillos source-refresh hit a parallel state DB lock. Each incident looked local, but the common system failure was unsynchronized writes against shared SQLite state.

**How to apply:** add a pre-dispatch/pre-hook probe equivalent to `pre-dispatch-state-db-lock-check.sh --db <path> --operation <class> --json`; doctor should expose `sqlite_concurrent_writer_risk_count`, `sqlite_write_lock_conflict_count`, and `.sqlite_write_locks.top_conflicts`. A valid receipt should satisfy `jq -e '.lock_acquired == true and .competing_writer_count == 0 and .post_integrity_state != "worse"'` before mutating work is called safe.

**Boundary note:** L94 covers shared-writer concurrency. A single-writer
`br dep add` failure immediately after JSONL rebuild is the adjacent
version-drift/write-path class; apply L93 first, then prefer `br 0.2.4+` or a
validated direct-SQL/flush/rebuild fallback over filing a duplicate upstream
issue.

**Cross-references:** L51 (file reservations), L56 (promotion ladder), L60 (doctor signal contract), L71 (validate-and-redispatch), L72 (storage and repo-local state discipline), L90 (live capture before pane action), `feedback_shared_sqlite_writes_must_serialize.md`, and the 2026-05-04 SQLite trauma rows in `~/.local/state/flywheel/fuckup-log.jsonl`.

## L95 — WORKER-STALL-RECOVERY-PROTOCOL

---
id: L95
title: Worker stall recovery protocol
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: l70-worker-stall-undetected
---

When a dispatched worker remains classified `THINKING` across consecutive orchestrator ticks but its live pane output has not advanced and no callback has landed, the orchestrator MUST run a graduated stall-recovery receipt before declaring work in-flight, idling, or respawning. `THINKING` is not enough truth by itself: it can mean real work, submit lag, a stalled agent, or stale classifier state.

The recovery order is fixed: first capture fresh live pane tail through the canonical NTM pane-capture surface, then send a lightweight non-empty NTM status probe, then wait a 60-90 second grace window for Codex submit lag, then re-capture live tail and recompute robot activity. Only if the pane shows no output advancement and no response after probe plus grace may the orchestrator respawn. After respawn, it MUST relaunch the agent with the canonical bare command, then redispatch the same bead or task id with the same acceptance gates.

Required L95 receipt fields are `stall_detection_ts`, `session`, `pane`, `task_id`, `last_output_hash`, `fresh_output_hash`, `fresh_output_advanced`, `callback_delivered`, `probe_attempted`, `probe_response_ts`, `grace_window_seconds`, `checkpoint_capture_ts`, `robot_activity_before`, `robot_activity_after`, and `resolution`. Allowed `resolution` values are `progressed`, `respawned`, or `redispatched`. A valid receipt should satisfy `jq -e '(.probe_attempted == true) and (.checkpoint_capture_ts != null) and (["progressed","respawned","redispatched"] | index(.resolution))'`.

False-respawn is as bad as false-no-action. If live capture shows active output, preserve the worker and wait. If live capture shows a clean prompt, send the original dispatch or status probe through the normal NTM path. If live capture shows a shell after respawn, relaunch Codex with exactly `codex --dangerously-bypass-approvals-and-sandbox`, with no model or reasoning flags. If the same worker stalls after redispatch, file or update a bead/fuckup route instead of repeating blind probes.

Doctor should expose `worker_stall_count`, `worker_stall_oldest_age_seconds`, and `.worker_stalls[]` with the receipt fields above. A pre-callback-emit gate should warn when any worker has been `THINKING` beyond the configured threshold with unchanged output and no callback. Cross-session stall events should be fleet-mailed or ledgered so mobile-eats, flywheel, skillos, and client sessions aggregate the same trauma class.

**Why:** Mobile-eats pane 2 stayed `THINKING` on `mobile-eats-7wc` after the 2026-05-04T18:01:39Z dispatch while output stopped advancing and pane 1 kept recording in-flight status. Flywheel pane 4 hit the same shape on `idle-pane-mechanical-hook`: a 434-line draft existed, but no report or callback landed until a recovery nudge. Two independent rediscoveries in one day make this canonical doctrine, not local watcher tuning.

**How to apply:** every INTEGRATE/status loop that reports worker work in-flight must compare current live tail hash and callback state against the prior tick. If no advancement crosses the threshold, emit an L95 stall receipt and run the recovery ladder. Do not skip straight from `THINKING` to respawn, and do not keep emitting in-flight receipts after the no-advancement threshold has been crossed.

**Forbidden outputs:**
- Reporting a worker as healthy in-flight when `THINKING` is unchanged across the stall threshold and no fresh output hash or callback proves advancement.
- Respawning a worker before live capture, non-empty probe, grace wait, and checkpoint capture are all recorded.
- Treating robot activity as the sole truth source for stall or recovery decisions.
- Redispatching a different bead after respawn when the stalled bead remains the active obligation and is still safe to retry.

**Cross-references:** L29 (canonical pane I/O), L70 (same-tick chain-forward), L86 (callback receiver live), L87 (stale error auto-ping recovery), L90 (live capture before pane action), L91 (dispatch delivery receipt), L95 receipt fields above, `feedback_orchestrator_is_the_killer_not_codex.md`, `feedback_dispatch_delivery_validation_required.md`, and `feedback_codex_relaunch_command_canonical.md`.

## L96 — DOCTRINE-LANDS-AS-3-SURFACE-DIFF-OR-DOES-NOT-LAND

---
id: L96
title: Doctrine lands as 3-surface diff or does not land
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: canonical-doctrine-single-surface-drift
---

Any canonical L-rule edit MUST land as one coherent three-surface diff in the same commit:

1. `AGENTS.md` root canonical operating doctrine.
2. `.flywheel/AGENTS-CANONICAL.md` repo-local canonical snapshot.
3. `templates/flywheel-install/AGENTS.md` install template for new repos.

If any of the three surfaces cannot be updated and verified in the same commit, the doctrine has not landed. The worker must leave the change uncommitted or file a blocker bead; it must not report a rule as canonical from a single surface.

**Why:** L93-L95 appeared in canonical and template surfaces while the root doctrine path was treated as a separate afterthought in the orchestration narrative. That creates split-brain instructions: new repos and local snapshots can carry rules that the root AGENTS.md contract does not visibly own, or root can move ahead while installs stay stale. Donella #4 and #6: change the system rule and the information flow, not just one artifact.

**How to apply:** every doctrine commit must include a 3-surface receipt equivalent to `for f in AGENTS.md .flywheel/AGENTS-CANONICAL.md templates/flywheel-install/AGENTS.md; do rg '^## L[0-9]+' "$f"; done` plus a divergence probe showing `doctrine_3_surface_divergent_count=0`. The diff review should prove the same L-rule IDs exist on all three surfaces before the commit is allowed.

Doctor must expose `doctrine_3_surface_divergent_count`, `missing_in_agents_md`, `missing_in_template`, and `missing_in_canonical`. Strict doctor fails when the divergent count is nonzero, and doctor-signal promotion files a bead automatically for the drift class.

**Forbidden outputs:**
- "L96 landed" when only one or two of the three surfaces changed.
- "Template will be updated later" without a blocker bead and explicit `blocked_by=`.
- Root-only, canonical-only, or template-only doctrine commits for active L-rules.
- Reporting doctrine propagation complete without a machine-readable 3-surface divergence receipt.

**Cross-references:** L50 (socraticode-mandatory dispatch), L56 (promotion ladder), L61 (ecosystem wire-in), L70 (same-tick chain-forward), L71 (validate-and-redispatch), L93-L95 (same-day drift evidence), `doctrine-3-surface-divergence-probe.sh`, and `feedback_no_ad_hoc_per_repo_doctrine_edits.md`.

## L97 — ORCH-DISPATCHES-ONLY-TO-KNOWN-WORKERS

---
id: L97
title: Orchestrator dispatches only to known workers
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: orchestrator-dispatched-without-worker-identity
---

Every dispatch MUST resolve target pane through the canonical orch-worker-identity manifest at
`~/.local/state/flywheel/orch-worker-identity/<session>.json`. Dispatch is forbidden when the
target pane is not in the manifest's workers list OR when the worker's `registration_status` is
not `active`. Auto-trigger registration broadcast on `needs_registration` and re-probe before dispatch.

**Why:** 2026-05-04 — orchestrators across alps/mobile-eats/vrtx had `fleet_mail_identity=unrecorded`
and dispatched to worker panes by hardcoded pane number with no identity awareness. Workers MINT
identity ad hoc when not found — violating the read-don't-mint rule. skillos doctor failed local
ticks on cross-session drift it didn't own (L92 violation in doctor logic, fixed in same tick).

**How to apply:**
- Dispatch-template skill loads manifest before send; refuses if target pane not active.
- Doctor probe surfaces `orchestrator_unknown_worker_identity_count` (per-orch local) and
  `fleet_identity_drift_count` (cross-session, surface-only, never halts local tick).
- Auto-registration broadcast on `needs_registration` is idempotent and required before dispatch
  resumes; failed broadcast = BLOCKED dispatch with fleet-mail downtime classification.

**Forbidden outputs:**
- Dispatching to pane number without manifest lookup.
- Halting a local tick on cross-session identity drift.
- Minting identity in worker pane when manifest says unregistered (broadcast-then-read pattern only).

**Cross-references:** L51 (file reservations), L86 (cross-session-callback-receiver-must-be-live),
L91 (dispatch-delivery-four-state-receipt), L92 (audit-findings-route-by-data).

## L98 — ARCHITECTURE-HEALTH-MEASURED-NOT-INDIVIDUALS

---
id: L98
title: Architecture health measured not individuals
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: agent-shaming-vs-system-improvement
---

Fleet performance reports MUST measure system-level architecture health:
reliability, faithfulness, leverage, reuse, coordination, and drift-authoring
trends joined to known-worker manifests. Individual agent names may appear only
as tuple-bound identity pointers needed to aggregate the fleet; rankings,
leaderboards, and performance-review language are forbidden. Findings route to
doctrine, skill, probe, or dispatch-template changes, never to individual-agent
action items.

**Why:** The 2026-05-04 mission lock frames flywheel as the command center for a
company outgrowing its founder. Surveillance theater and agent-shaming destroy
that system goal: they move attention from architecture changes to named-agent
judgment. Donella #2, #3, and #6: encode the system goal, measure the actual
goal, and make information flows trigger structural learning. Canonical anchor:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/project_self_sustaining_company_paradigm_2026_05_04.md`.

**How to apply:**
- `.flywheel/scripts/architecture-health-rollup.sh` writes 24h, 7d, 30d, and
  90d JSON to `~/.flywheel/fleet-perf/`.
- Every rollup metric has trend, cohort, and counterfactual context; missing
  pairings increment `architecture_health_metric_unpaired_count`.
- Agent-shaming artifacts increment `agent_shaming_report_detected` and are
  non-compliant with the report policy.
- `/flywheel:status` surfaces only the compact architecture-health line.
- `/flywheel:weeklyreflection` must emit `learning_loop_closed=yes|no` and at
  least one architectural change or explicit no-change-warranted rationale.
- `founder_dispose_pct` trending down quarterly is paradigm-success; flat or
  rising trend is paradigm-failure until paired with a structural change.

**Forbidden outputs:**
- Leaderboards of best or worst agents without architecture context.
- Vanity throughput counts without leverage-tier weighting.
- Surveillance metrics that drive no doctrine, skill, or probe change in 30d.
- Goodhart-prone single metrics without a paired quality probe.
- Dashboards demanding daily founder attention for operational state.
- Performance reviews of named agents.
- One-shot dashboards without trend, cohort, and counterfactual.

**Cross-references:** L61 (ecosystem wire-in), L71
(validate-and-redispatch), L85 (idle-state-class-canonical), L91
(dispatch-delivery-receipt), L97 (orch-dispatches-only-to-known-workers), L99
(worker-recovery-slo-180s), L100 (identity primary key is tuple), and the
self-sustaining-company paradigm memory path above.

## L99 — WORKER-RECOVERY-SLO-180S

---
id: L99
title: Worker recovery SLO 180s
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: silent-frozen-worker-undetected-by-fleet
---

Frozen or failed workers MUST be detected and respawned within 180 seconds. This is the canonical recovery SLO. Detection mechanisms (`frozen-pane-detector` v2, `idle-state-probe`, L95 stall protocol, L91 four-state receipt) are tuned to this budget. The SLO is measured continuously via doctor probe and surfaced in `/flywheel:status`.

**Why:** 2026-05-04 — alps:2 froze and Joshua manually detected it before any flywheel automation flagged it. Default detector thresholds were 300s freeze plus 120s poll, about 7 minutes worst case. The company-outgrowing-founder paradigm requires the system to detect failures faster than the founder can. This aligns with the architecture-health mission anchor: SLOs measure the system, not individuals.

**How to apply:**
- `frozen-pane-detector` v2 thresholds are 90s detect and 30s cadence; timer-identical fast path drops to about 30s for that class.
- Doctor exposes `recovery_latency_p95_seconds_24h` and `recovery_slo_breach_count_24h`.
- `/flywheel:status` surfaces SLO color and breach count.
- `/flywheel:weeklyreflection` consumes the 7d trend; consecutive breaches escalate to substrate change per L98 architecture-health, never to agent shaming.
- Joshua-detected-before-fleet-detected creates an INCIDENTS row plus a structural fix bead.

**Forbidden outputs:**
- Tuning thresholds higher to "reduce noise" without paired SLO measurement.
- Reporting recovery success without latency.
- Agent-level recovery scoring; this is an architecture-level SLO only per L98.
- Threshold tuning that violates per-pane budget caps or creates recovery storms.

**Cross-references:** L85 (idle-state-class), L87 (stale-error-auto-ping), L91 (dispatch-delivery-receipt), L95 (worker-stall-recovery), L98 (architecture-health-measured-not-individuals).

## L100 — IDENTITY-PRIMARY-KEY-IS-SESSION-PANE-PROJECT

---
id: L100
title: Identity primary key is session pane project
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: agent-mail-identity-name-churn
---

Agent Mail identity substrate MUST key durable ownership by
`(session, pane, fleet_mail_project_key)`. `identity_name` is only the current
pointer attached to that tuple. Rotating the name may update the pointer, token
path, predecessor chain, and rotation reason, but it MUST NOT create a new
logical identity owner.

**Why:** CoralRaven's 2026-05-04 gap report showed six independent triggers
rotating names while the actual owner stayed stable: name-policy enforcement,
resolver-MCP generated names, compaction continuity, missing-token recovery,
path canonicalization, and Agent Mail strict-mode preallocation. Counting the
name as the identity created churn, orphan-token residue, cross-session false
halts, and agent-shaming narratives. Donella #5 and #6: change the rule and
surface the right stock/flow metrics.

**How to apply:**
- Registry rows carry `identity_primary_key` and `identity_primary_key_text`
  derived from session, pane, and fleet mail project.
- Rotations preserve `predecessor_identity_chain[]`; allowed
  `rotation_reason` values are `agent-mail-name-policy`,
  `resolver-mcp-generated-identity`, `compaction-continuity`,
  `missing-token-recovery`, `path-canonicalization`, and
  `strict-mode-preallocation`.
- Rotation transactions clean predecessor token residue immediately or surface
  `orphan_tokens_unswept_count`.
- `flywheel-loop doctor --json` exposes `identity_rotation_count_24h`,
  `orphan_tokens_unswept_count`, and `identity_chain_max_length`.
- High churn is an architecture-health signal, never an individual agent score.

**Forbidden outputs:**
- Treating an adjective+noun mailbox name as the durable primary key.
- Minting a new logical identity owner for a known session/pane/project tuple.
- Reporting identity churn as agent failure rather than substrate churn.
- Sending raw Agent Mail tokens through cross-orch coordination while repairing
  tuple drift.

**Cross-references:** L58 (secret material never in pane text), L76
(AgentMail identity canonical), L92 (audit findings route by data), L96
(doctrine three-surface diff), L98 (architecture-health frame), and memory
`feedback_identity_stability_session_pane_project_primary_key.md`.

## L101 — FLYWHEEL-OWNS-CONTINUOUS-FLEET-PRODUCTIVITY

---
id: L101
title: Flywheel owns continuous fleet productivity
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: idle-with-work-available
---

Flywheel:1 owns continuous productivity across the fleet. A peer session may be
quiet only when it is genuinely caught up or blocked by something Joshua must
personally decide or perform. Workers waiting, empty or low ready queues, and
unfiled findings are not downtime; they are a flywheel:1 action signal.

**Why:** Joshua's 2026-05-04 directive in memory
`feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md`
states that every project stays productive unless a true Josh-blocker exists,
and true blockers notify Joshua immediately. Skillos and mobile-eats both went
idle with workers waiting and findings still convertible to beads. The missing
information flow let reports substitute for work. Donella #6 surfaces the stock;
Donella #4 gives flywheel:1 the self-organization loop to compose work for peer
orchestrators.

**States:**
- `productive`: workers are active, commits/callbacks are flowing, or no
  actionable backlog source is present.
- `idle_with_work_available`: workers are waiting past threshold and at least
  one always-available work source is nonzero.
- `substrate_blocked`: peer progress is blocked on a flywheel-owned substrate
  repair with a canonical workaround path.
- `true_josh_blocker`: Joshua-personal action is required, such as a security
  or PHI decision, a paradigm-level shift, or a destructive approval.

**Always-available work hierarchy, in order:**
1. Doctor `errors[]` -> fix-bead per error.
2. `fuckup_triage` candidates -> promotion bead.
3. `closed_bead_audit_pending` -> reopen-or-close evaluation bead.
4. `canonical_drift` / `fleet_repo_l_rule_lag` -> backfill bead.
5. Recent commits without README/AGENTS.md update (L61) -> ecosystem-touch bead.
6. INCIDENTS.md unprocessed events -> promotion bead.
7. Skill citation graph gaps -> audit bead.
8. Gap-hunt-probe findings -> structural-fix bead.
9. Mission-anchor doctrine drift -> mission-lock refresh bead.

**How to apply:**
- `.flywheel/scripts/peer-orch-productivity-watch.sh` reads loop markers,
  topology, worker activity, `br ready`, doctor state, and orchestrator tails.
- `flywheel-loop doctor --json` exposes
  `peer_orch_idle_with_work_available_count`,
  `peer_orch_substrate_blocked_count`, `true_josh_blocker_count`, and
  `peer_orch_productivity_watch`.
- `/flywheel:status` surfaces
  `Fleet productivity: <productive>/<total> | idle-with-work=<N> | substrate-blocked=<N>`.
- `idle_with_work_available` after five minutes triggers an xpane productivity
  escalation packet with three concrete bead-filing or dispatch instructions.
- `true_josh_blocker` triggers the Joshua-notify path: Pushover/mac-alert style
  notification plus a cross-orch ledger row. Substrate corruption with a
  canonical workaround stays flywheel:1-owned.

**Forbidden outputs:**
- Treating "session is idle" as a status report to Joshua.
- Reporting "br ready is empty" as terminal instead of filing beads from the
  hierarchy above.
- Letting a peer orchestrator sit beyond five minutes with workers waiting and
  findings unfiled.
- Notifying Joshua for anything resolvable by xpane productivity escalation.
- Staying silent on a true Josh-blocker.

**Evidence:** memory
`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md`;
script `.flywheel/scripts/peer-orch-productivity-watch.sh`; tests
`tests/peer-orch-productivity-watch.sh`; doctor fields in
`~/.claude/skills/.flywheel/bin/flywheel-loop`; status surface
`~/.claude/commands/flywheel/status.md`.

**Cross-references:** L48 (substrate exhaustion), L61 (ecosystem wire-in), L70
(same-tick chain-forward), L75 (peer orchestrator blocker coordination), L85
(idle-state-class canonical), L92 (audit findings route by data), L98
(architecture-health measured, not individual agents), and L99
(worker-recovery SLO).

## L102 — META-RULE-CACHE-MUST-REFRESH-ON-TICK

---
id: L102
title: META-RULE cache must refresh on every tick
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: fleet-meta-rule-propagation-drift
---

Every tick driver MUST run the canonical META-RULE sync at tick start so that
`<repo>/.flywheel/META-RULE-CACHE.md` mirrors
`/Users/josh/.flywheel/canonical-meta-rules/INDEX.md` (plus the four
`feedback_*.md` rules) on every cycle. Sister orchestrators that share the same
tick driver (flywheel, alpsinsurance, skillos, mobile-eats, vrtx) inherit fleet
META-RULE freshness by construction — no per-repo doctrine edit is required.

**Why:** Prior fleet propagation relied on broadcast capsules + manual
re-reads. Capsules drift, panes compact, sessions reboot. Bake the sync into
the tick path and the canonical META-RULE bundle becomes a stock the tick
keeps refilled, not a flow that has to be remembered (Donella #4 self-organize
+ #6 information). New ntm sessions onboarded after 2026-05-04 inherit the 4
fleet META-RULEs at install time via the `/flywheel:onboard` step.

**How to apply:**
- `flywheel-loop-tick` invokes `/Users/josh/.flywheel/canonical-meta-rules/sync.sh --apply --json`
  immediately after the canonical-doctrine-pull step; result emits as
  `event:"meta_rule_cache_sync"` in the per-tick log.
- `/flywheel:onboard` installs the canonical META-RULE-CACHE on first run
  and stamps the loop record with `meta_rule_sync_enabled: true`.
- Doctor probe `fleet-canonical-rule-freshness-probe.sh --json` reports
  per-session `lag_seconds` + `status` (fresh|stale|missing); follow-up bead
  threads `fleet_canonical_rule_freshness_seconds_max` into doctor JSON.
- Touching the canonical INDEX.md is enough to trigger fleet-wide refresh on
  the next tick across every session running this driver.

**Forbidden outputs:**
- Editing per-repo META-RULE files directly instead of the canonical bundle.
- Skipping the sync step on tick to "save time" — the sync is a few ms.
- Treating the cache as documentation; it is the live freshness substrate.
- Onboarding a new ntm session without running the META-RULE install step.

**Cross-references:** L96 (doctrine-3-surface-diff), L98
(architecture-health-measured-not-individuals), and the canonical-meta-rules
broadcast 2026-05-04. Probe at
`.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh`.

## L103 — FLEET-CONFORMANCE-SCORE-IS-THE-GATE

---
id: L103
title: Fleet conformance score is the gate
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: fragmented-fleet-conformance-drift
---

Every flywheel-installed session MUST expose one bounded fleet-conformance
score that composes doctrine coverage, root AGENTS freshness, mission-lock age,
doctor status, META-RULE cache freshness, and identity drift. The score is the
gate; per-rule and per-axis audits are drill-down only.

**How to apply:**
- `.flywheel/scripts/fleet-conformance-probe.sh --fleet --json` emits
  `fleet_conformance[]`, color counts, worst session, and min score.
- `flywheel-loop doctor --json` exposes `fleet_conformance`,
  `fleet_conformance_red_count`, `fleet_conformance_yellow_count`,
  `fleet_conformance_green_count`, `fleet_conformance_worst_session`, and
  `fleet_conformance_min_score`.
- `/flywheel:status` renders one compact line after Fleet productivity:
  `Fleet conformance: <green>/<total> green | yellow=<N> | red=<N> | worst=<session>:<score>`.
- Red sessions get same-tick `CONFORMANCE-DRIFT` xpane packets via
  `fleet-conformance-probe.sh --apply`; the packet names the session, score,
  repo, and red axes without ranking individual agents.

**Forbidden outputs:**
- Treating separate L-rule, identity, mission-lock, or META-RULE audits as the
  primary fleet health gate when the conformance score is available.
- Publishing per-agent rankings or blame labels from conformance data. This is
  a session/substrate score, not an individual performance score.
- Letting a red conformance session wait for the next tick without either a
  `CONFORMANCE-DRIFT` packet or a concrete `chain_blocked_reason`.

**Evidence:** probe `.flywheel/scripts/fleet-conformance-probe.sh`; tests
`tests/fleet-conformance-probe.sh`; doctor fields in
`~/.claude/skills/.flywheel/bin/flywheel-loop`; status surface
`~/.claude/commands/flywheel/status.md`.

**Cross-references:** L61 (ecosystem wire-in), L70 (same-tick chain-forward),
L96 (doctrine 3-surface diff), L98 (measured system health, not individual
agents), L101 (continuous fleet productivity), and L102 (META-RULE cache
freshness).

## L104 — FLEET-COMMS-MEASURED-NOT-ASSUMED

---
id: L104
title: Fleet comms measured not assumed
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: assumed-open-fleet-comms
---

Open communication lines across the fleet MUST be measured by substrate signals,
not inferred from active loop markers, recent commits, or a single liveness
classifier.

**How to apply:**
- `.flywheel/scripts/fleet-comms-health-probe.sh --fleet --json` scores each
  active session across Agent Mail token freshness, last cross-orch packet age,
  unread escalations, productivity escalation backlog, identity-registry
  liveness, and multi-frame liveness classifier agreement.
- `flywheel-loop doctor --json` exposes `fleet_comms_health`,
  `fleet_comms_silent_session_count`, `fleet_comms_token_stale_count`,
  `fleet_comms_escalation_unread_count`, `fleet_comms_min_score`, and
  `fleet_comms_worst_session`.
- `/flywheel:status` renders one compact line after Fleet conformance:
  `Fleet comms: <healthy>/<total> healthy | silent=<N> | stale-tokens=<N> | unread-esc=<N>`.
- Silent sessions are sessions with no cross-orchestrator packet for more than
  24 hours; they get `COMMS_HEALTH_PING` packets through `--apply`.
- Agent Mail tokens are checked by mtime only. The probe never reads or prints
  raw bearer material.
- Broadcast-script liveness is cross-checked against multi-frame activity. A
  broadcast classifier that says dead while multi-frame activity is alive logs
  `false_positive_classifier`; never trust one liveness source for comms.

**Forbidden outputs:**
- Reporting fleet comms healthy without token freshness, cross-orch packet age,
  unread escalation, identity-registry, and multi-frame classifier evidence.
- Treating `active=true`, doctor receipts, or pane process existence as proof
  that cross-orch communication is open.
- Sending Joshua notifications for routine silence; notify only for true
  substrate corruption such as token expiry beyond the recovery window.
- Publishing per-agent comms rankings or blame labels. This is a session and
  substrate observatory.

**Evidence:** probe `.flywheel/scripts/fleet-comms-health-probe.sh`; tests
`tests/fleet-comms-health-probe.sh`; doctor fields in
`~/.claude/skills/.flywheel/bin/flywheel-loop`; status surface
`~/.claude/commands/flywheel/status.md`.

**Cross-references:** L57 (loop marker is not driver), L75 (peer orchestrator
blocker coordination), L76 (AgentMail identity canonical), L91 (dispatch
delivery receipt), L98 (architecture health measured structurally), L101
(continuous fleet productivity), and L103 (fleet conformance score).

## L105 — PROCESS-GAPS-ARE-MEASURED-AND-AUTO-ROUTED

---
id: L105
title: Process gaps are measured and auto routed
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: process-gap-drift
---

Fuckup classes repeating at least 2x in 24h, doctor errors sticky across at
least 3 ticks, 3-surface drift above 5 rules, unpromoted candidates older than
24h, closed-bead audit gaps, identity drift, and watcher coverage holes are
auto-flagged as process gaps. Top-3 gaps auto-route to fix-beads via
`fleet-process-gap-detector.sh --apply`. Joshua sees one `Fleet process` line,
not a wall of symptoms. Fix the gate, not the leak.

**How to apply:**
- `.flywheel/scripts/fleet-process-gap-detector.sh --json` emits
  `fleet-process-gap-detector/v1` with `open_gap_count`, `top_gaps`,
  `stuck_class_count`, and `process_health_score`.
- `--apply --dry-run` produces the top-3 bead-create plan; actual apply uses
  stable class markers so the same process class does not file duplicate
  fix-beads on every tick.
- `flywheel-loop doctor --json` exposes `fleet_process_gap_detector`,
  `fleet_process_open_gap_count`, `fleet_process_stuck_class_count`,
  `fleet_process_health_score`, and `fleet_process_top_gap_class`.
- `/flywheel:status` renders
  `Fleet process: health=<score> | open-gaps=<N> | top: <class>` after the
  Fleet comms line.

**Forbidden outputs:**
- Reporting recurring process failures as a prose list without a top-class,
  score, and fix-bead route.
- Filing duplicate process fix-beads for the same class and marker.
- Treating the process gap as an individual-agent failure; this is a gate,
  routing, or information-flow leak.
- Adding new manual gates instead of measuring the recurring class and routing
  it to a structural fix.

**Donella read:** #4 self-organization routes recurring classes to fix-beads,
#6 information flows surface the process leak before Joshua does, and #11
parameters stay secondary to changing the gate that produced the leak.

**Evidence:** probe `.flywheel/scripts/fleet-process-gap-detector.sh`; tests
`tests/fleet-process-gap-detector.sh`; doctor fields in
`~/.claude/skills/.flywheel/bin/flywheel-loop`; status surface
`~/.claude/commands/flywheel/status.md`.

**Cross-references:** L50 (Socraticode preflight), L51 (file reservations),
L56 (promotion ladder), L61 (ecosystem wire-in), L96 (3-surface diff), L98
(architecture health measured, not individuals), L101 (continuous fleet
productivity), and L103 (fleet conformance score).

## L106 — FLEET-HEALTH-IS-A-SINGLE-NUMBER-AGGREGATED-FROM-8-SPINES

---
id: L106
title: Fleet health is a single number aggregated from 8 spines
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: dashboard-sprawl-without-strategic-health
---

Fleet health is one composite number: productivity 10% + conformance 15% +
comms 10% + process gaps 15% + architecture 15% + identity 10% + L-rule lag
15% + watcher coverage 10%. Thresholds are >=85 green, 60-84 yellow, and <60
red. `/flywheel:fleet-observatory` is the strategic command-center view;
`/flywheel:status` remains tactical. Joshua sees one number when stepping back,
not 25 fields.

**How to apply:**
- `.flywheel/scripts/fleet-observatory-aggregate.sh --json` reads
  `flywheel-loop doctor --json` once, caches doctor JSON for 60 seconds, and
  emits `fleet_overall_health_score`, per-spine traffic lights, worst spine,
  worst session, top process gaps, and recommended action.
- `flywheel-loop doctor --json` exposes `fleet_observatory_health_score` as
  the lightweight composite field for automation.
- `/flywheel:fleet-observatory` renders the strategic one-screen dashboard;
  use `/flywheel:status` for tactical pane/bead/callback work.

**Forbidden outputs:**
- Showing Joshua 25 raw doctor fields when the strategic ask is fleet health.
- Treating the composite as an individual-agent ranking. This is system-level
  observability, not agent-shaming.
- Re-running every expensive spine separately inside the dashboard instead of
  reading doctor once and using the 60-second cache.

**Evidence:** aggregate `.flywheel/scripts/fleet-observatory-aggregate.sh`;
tests `tests/fleet-observatory-aggregate.sh`; command surface
`~/.claude/commands/flywheel/fleet-observatory.md`; doctor field in
`~/.claude/skills/.flywheel/bin/flywheel-loop`.

**Cross-references:** L61 (ecosystem wire-in), L98 (architecture health
measured structurally), L101 (continuous productivity), L103 (conformance
score), L104 (comms measured), and L105 (process gaps measured).

## L107 — SHARED-SURFACE-WRITES-MUST-RESERVE-ACROSS-PANES

---
id: L107
title: Shared-surface writes must reserve across panes
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: coordination-collision-shared-surface
---

Workers committing to shared surfaces (`flywheel-loop`, doctor-author files,
`AGENTS.md`, `README.md`, `scripts/`, `.flywheel/scripts/`, and dispatch
templates) MUST reserve with
`.flywheel/scripts/shared-surface-reservation-check.sh --reserve <path>
--pane=<N> --task-id=<task>` before `git add`, then release after commit or
before any BLOCKED/DECLINED callback. Cross-pane collisions auto-detect and
log fuckup-log class `coordination-collision-detected`; doctor exposes
`coordination_collision_count_24h` so the trend has a visible decay target.
Never trust pane-local mtime alone.

**How to apply:**
- Check or reserve a path before staging:
  `.flywheel/scripts/shared-surface-reservation-check.sh --reserve <path> --pane=<N> --task-id=<task> --json`
- If another pane holds it, stop before `git add` and callback
  `BLOCKED <task> reason=coordination-collision-detected need="holder pane release or cross-pane coordination"`.
- Release every held path after commit:
  `.flywheel/scripts/shared-surface-reservation-check.sh --release <path> --pane=<N> --task-id=<task> --json`
- Worker callbacks for shared-surface edits include
  `shared_surface_reservations_checked=yes` and
  `shared_surface_reservations_released=yes`.

**Forbidden outputs:**
- Staging or committing shared surfaces without an active same-pane reservation.
- Treating an Agent Mail file reservation as sufficient for shared surfaces;
  L51 prevents codebase file races, L107 prevents pane-level staging races.
- Retrying after a collision without holder evidence, release evidence, or a
  cross-pane coordination packet.
- Reporting the fleet clean while `coordination_collision_count_24h > 0`.

**Evidence:** checker `.flywheel/scripts/shared-surface-reservation-check.sh`;
tests `tests/shared-surface-reservation-check.sh`; dispatch contract
`~/.claude/commands/flywheel/_shared/dispatch-template.md`; doctor field in
`~/.claude/skills/.flywheel/bin/flywheel-loop`.

**Cross-references:** L51 (dispatch file reservations), L75 (peer orchestrator
blocker coordination), L91 (dispatch delivery receipt), L104 (comms measured),
L105 (process gaps measured), and L106 (fleet observatory health).

## L108 — META-RULE-CACHE-IS-CACHE-NOT-CONVERGENCE-GATE

---
id: L108
title: META-RULE cache is cache, not convergence gate
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: cache-freshness-mistaken-for-convergence
---

`META-RULE-CACHE.md` proves cache freshness, not 3-surface convergence.
`sync.sh --check-three-surface` is the convergence gate;
`sync.sh --apply-three-surface` backfills missing canonical L-rules. Tick
checks and logs drift, onboard auto-applies, and the hourly launchd watchdog
logs fleet drift to
`~/.local/state/flywheel/canonical-meta-rules-watchdog.jsonl`. Never conflate
cache mtime with doctrine alignment.

**How to apply:**
- Use `/Users/josh/.flywheel/canonical-meta-rules/sync.sh --check-three-surface --target <repo> --json`
  before reporting doctrine convergence.
- Use `--apply-three-surface` only in onboarding or an explicit repair bead;
  tick and watchdog paths are read-only drift detectors.
- Doctor consumers use `fleet_three_surface_drift_per_session`,
  `fleet_three_surface_drift_total_count`,
  `fleet_three_surface_drift_max_count`, and
  `fleet_three_surface_drift_worst_session`.

**Forbidden outputs:**
- Reporting a repo doctrine surface clean because `META-RULE-CACHE.md` is fresh.
- Auto-applying 3-surface doctrine drift from a normal tick.
- Closing a three-surface drift bead without a machine-readable
  `--check-three-surface` receipt.

**Evidence:** sync gate `/Users/josh/.flywheel/canonical-meta-rules/sync.sh`;
tick wiring `.flywheel/flywheel-loop-tick`; onboard repair
`.flywheel/scripts/flywheel-onboard.sh`; watchdog
`~/Library/LaunchAgents/ai.zeststream.canonical-meta-rules-sync-watchdog.plist`;
doctor fields in `~/.claude/skills/.flywheel/bin/flywheel-loop`.

**Cross-references:** L50 (Socraticode preflight), L51 (file reservations),
L61 (ecosystem wire-in), L96 (3-surface diff), L102 (META-RULE cache refresh),
L105 (process gaps measured), L107 (shared-surface reservations), and
`.flywheel/scripts/doctrine-3-surface-divergence-probe.sh` (repo_role scoping:
template surface is active only for `flywheel_origin` repos).

## L110 — SUBSTRATE-PRIMITIVES-DECLARE-SELF-REPAIR-LOOP

---
id: L110
title: Substrate primitives declare self-repair loop
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: ship-then-orphan-substrate
---

Every flywheel substrate primitive that observes a recurring operational
condition, emits a finding, or produces a durable work artifact MUST declare
its repair or promotion loop in the same artifact that defines the observation.

Observable is not operational. Substrate that observes a recurring condition
without an outflow drain creates the ship-then-orphan failure mode. Six same-axis
gaps close isomorphically with this single primitive: wire-or-explain,
beadsdb-vacuum, worker-watcher, agentmail-registration, substrate-loss, and
skill-promotion-handoff. See
`.flywheel/PARADIGM-substrate-self-organization-2026-05-04.md`.

**Required contract per primitive:**
- `stock`: what accumulates.
- `inflow`: what creates or increments the stock.
- `artifact_class`: `unwired-artifact`, `maintenance-debt`,
  `watcher-coverage`, `identity-registration`, `worker-commit`,
  `skill-candidate`, or `other`.
- `consumer`: command, script, skillos inbox route, bead owner, or `NONE`.
- `deferral_owner` and `deferral_until` when no consumer can run now.
- `owner`: responsible orchestrator, pane, substrate owner, or human.
- `action_ledger`: durable JSONL row written at observation time.
- `verification_probe`: mechanical test that proves the loop closed.
- `tick_status_consequence`: doctor/status field plus warn/error policy.
- `auto_fire_trigger`: predicate that drains the stock automatically, or
  `explicit_no_auto_repair_reason` with owner and escalation threshold.
- `drain_receipt_shape`: callback, ledger row, PR, bead, or skillos relay
  receipt proving the consumer ran.

**Examples:** wire-or-explain ledger row schema; beadsdb-vacuum maintenance
window predicate; agentmail-registration resolver-mediated row; worker-commit
side-branch/reset guard; skillos relay consuming wire-or-explain rows with
`artifact_class=skill-candidate`.

**Enforcement:** `.flywheel/dispatch-log.jsonl` artifact-shipped or
rule-codification row is required at write time. Tick close gates refuse if any
in-scope primitive is missing the required contract fields. Doctor/status
surfaces expose backlog, unconsumed stock, failed drain attempts, and last
successful drain timestamp for every primitive.

**Validator:** `.flywheel/scripts/substrate-loop-contract-validator.sh` owns
`substrate-loop-contract.v1`, emits the bootstrap self-row, and is exposed via
`flywheel-loop doctor --scope substrate-loop-contract --json`.

**Forbidden outputs:**
- Shipping a watcher, ledger, report, finding class, or durable artifact without
  a named consumer or explicit deferral contract.
- Creating a second substrate for skill promotion when the wire-or-explain
  ledger can carry `artifact_class=skill-candidate`.
- Reporting a primitive "done" because it observes a condition while the stock
  has no outflow.
- Leaving action only in prose, pane scrollback, or a plan appendix without a
  durable action ledger row.

**Evidence:** paradigm synthesis
`.flywheel/PARADIGM-substrate-self-organization-2026-05-04.md`, Round 2
Finding 10 skillos-relay amendment, and CoralRaven memory classes
`feedback-substrate-loss-worker-commit-orphan.md` and
`feedback-foundational-tool-error-halt-class.md`.

**Cross-references:** L50 (Socraticode preflight), L56 (promotion ladder), L60
(doctor signal contract), L70 (no-punt chain forward), L71
(validate-and-redispatch), L82 (canonical CLI scope), L96 (3-surface doctrine),
L102 (cache refresh), L107 (shared-surface reservations), and
`feedback_wire_into_ecosystem.md`.

## L111 — REAL-TIME-QUALITY-BAR-ON-EVERY-WORK-BODY

---
id: L111
title: Real-time quality bar on every work body
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: ship-then-polish-later
---

Every body of work — plan output, audit, dispatch result, bead description,
paradigm doc, AGENTS.md edit, memory file, code, callback envelope — MUST pass
at WRITE-TIME (not audit-time, not polish-time) through a five-skill quality
bar. Workers refuse to populate the callback envelope without
`quality_bar_passed=yes` plus per-judge scores; orchestrators refuse to accept
callbacks missing those fields.

**Required gates per artifact:**

1. `/rust-best-practices` (where Rust touched).
2. `/python-best-practices` (where Python touched).
3. `/canonical-cli-scoping` (every CLI surface or path referenced).
4. `/readme-writing` (every doc edit, plan section, or AGENTS chunk).
5. Three-judges sniff (Jeff / Donella / Joshua) — each scored 0-10 against
   `~/.claude/skills/.flywheel/prompts/three-judges-rubric.md`. Composite
   ≥9.5; no single judge <9.0. If the artifact cannot reach the bar, the
   artifact gets fixed, not shipped at lower grade.

**Required callback fields:**

- `quality_bar_passed`: `yes` | `no`
- `rust_clean`: `yes` | `no` | `n/a`
- `python_clean`: `yes` | `no` | `n/a`
- `cli_canonical`: `yes` | `no`
- `readme_quality`: `yes` | `no`
- `jeff_score`, `donella_score`, `joshua_score`: integer 0-10 each
- `self_grade`: composite `N.N/10`

**Rationale (Donella stock/flow/leverage):**

- **Stock:** quality-debt artifacts (plans, doctrine docs, ledger rows, code,
  callbacks shipped without 5-skill + 3-judges check).
- **Inflow:** every dispatch close, every plan phase save, every L-rule
  codification, every bead body write.
- **Outflow before L111:** a "polish round" scheduled for later — that drained
  in theory and never in practice (today: 8 audit lenses, 4 REFINE rounds,
  PARADIGM doc, L110 codification all shipped without the 4-skill + 3-judges
  check).
- **Outflow with L111:** mechanical refusal at write-time. The producer fixes
  the artifact before it lands, not the next plan.
- **Loop:** balancing B (write → 5-skill check → fix or ship). Removes the
  reinforcing R that lets quality-debt accumulate by deferring polish.
- **Leverage point:** Meadows #5 (rules of the system). The rule shifts
  authority over "is this good enough?" from a future polish phase to the
  write-time gate, eliminating the deferred-polish escape hatch.
- **Delay:** zero. Quality bar fires synchronously at write-time, not in a
  later sweep.

**Enforcement:**

- Mechanical gate at callback validation: orchestrators reject callbacks that
  do not include the seven required fields with passing values.
- Inheritance through `flywheel:_shared:dispatch-template`: every dispatch
  prompt embeds the five-skill checklist as an acceptance gate, the same way
  L82 canonical CLI scoping is embedded today.
- Doctor surface: `quality_bar_breach_count_24h` (callbacks with
  `quality_bar_passed=no` or missing fields). Tick close gates refuse with
  warn at >0, error at >3.
- Validator path: `.flywheel/scripts/callback-envelope-schema-validator.sh`;
  scoped doctor:
  `flywheel-loop doctor --repo <repo> --scope callback-envelope-schema --json`.

**Companion rules:**

- L108 (3-surface sync) — quality bar applies to all three surfaces, not just
  the canonical source.
- L110 (substrate self-repair primitive) — L111 is the
  `verification_probe`/`drain_receipt_shape` consumer for `artifact` stock.
  L110 declares the loop; L111 enforces the quality of every artifact passing
  through it.

**Cost citation:** 2026-05-04. Joshua flagged that 8 audit lenses, 4 REFINE
rounds, the substrate-self-organization paradigm doc, and the L110
codification all shipped without 4-skill + 3-judges checks — producing tech
debt on the very plans meant to eliminate it. Direct quote: "every body of
work must pass real-time through `/rust-best-practices`,
`/python-best-practices`, `/canonical-cli-scoping`, `/readme-writing`, and the
3-judges sniff. Not later. Not in polish. AT WRITE-TIME." See
`.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/00-INTENT.md` Finding
11 and `.flywheel/plans/orch-monitor-recovery-auto-act-2026-05-04/00-INTENT.md`
Phase 1 supplemental II.

**Forbidden outputs:**

- Shipping any artifact with `quality_bar_passed=no` or missing per-judge
  scores.
- Deferring quality work to a "polish round" scheduled later.
- Treating the 3-judges rubric as advisory rather than gating.
- Orchestrator accepting a worker callback without the seven required fields.

**Cross-references:** L29 (NTM dispatch hygiene), L50 (Socraticode preflight),
L51 (file reservations), L52 (issues→beads), L53 (fuckups in callback), L57
(loop-state vs driver), L61 (doctrine landing wires AGENTS+README), L70
(no-punt chain forward), L71 (validate-and-redispatch), L82 (canonical CLI
scoping), L96 (3-surface diff), L108 (3-surface cache vs gate), L110
(substrate self-repair primitive),
`~/.claude/skills/.flywheel/prompts/three-judges-rubric.md`,
`.flywheel/PUBLISHABILITY-BAR.md`,
`.flywheel/PARADIGM-substrate-self-organization-2026-05-04.md`,
`feedback_publishability_bar_three_judges.md`,
`feedback_validator_must_check_four_lenses.md`.

**Authored:** 2026-05-04

## L115 — PEER-ORCH-RECOVERY-PERMIT-GATE

---
id: L115
title: Peer orch recovery permit gate
status: long_term
shipped: 2026-05-05
review_due: 2026-11-05
trauma_class: peer-orch-recovery-false-ownership-refusal
---

`flywheel:1` owns recovery of frozen, deaf, or stuck peer orchestrator panes.
Peer orchestrators such as `skillos:1`, `mobile-eats:1`, and similar fleet
orchestrator panes are not untouchable when they are dead; recovering them is
flywheel repo work. The self-respawn boundary remains hard: `flywheel:1` MUST
NOT respawn `flywheel:1`.

**Permit gate:** `.flywheel/scripts/peer-orch-respawn-permit.sh` is the
canonical pre-flight before `/flywheel:respawn` targets a peer
`orchestrator_pane`.

**Canonical 6-step recovery protocol:**

1. Read `~/.local/state/flywheel/session-topology.jsonl` with latest-by-
   `effective_at` semantics for both `flywheel` and the target session.
2. Refuse unless the actor is the latest `flywheel` orchestrator pane.
3. Refuse self-orchestrator recovery: target `flywheel:<orchestrator_pane>` is
   the calling-in-sick path and must be recovered by a peer.
4. Respect `kill-recover-drill.sh` protected-session doctrine. Active client
   and high-risk sessions are refused unless a specific Joshua-approved
   exception is encoded in the permit gate; `skillos:1` peer-orch recovery is
   the validated exception for this rule, while drill damage remains refused.
5. Require freeze evidence before permit: either a hash-identical buffer sample
   across the configured window, or robot activity state in
   `{ERROR, UNKNOWN, deaf}`.
6. On `--apply`, write
   `~/.local/state/flywheel/peer-orch-recovery.jsonl`, then run
   `/flywheel:respawn`; verify the recovered pane is live and log any repeated
   recovery pattern to the learning substrate.

**Doctor contract:** `flywheel-loop doctor --scope peer-orch-recovery --json`
MUST expose `peer_orch_recovery_count_24h`, `last_peer_orch_recovery_ts`,
`peer_orch_recovery_targets_top`, and
`peer_orch_recovery_self_refuse_count_24h`. Status is `warn` when recovery
count exceeds 5 in 24h and `fail` when self-refuse count is nonzero.

**Forbidden outputs:**

- Treating peer orchestrator panes as human-only or untouchable after freeze
  evidence exists.
- Respawning `flywheel:1` from `flywheel:1`.
- Bypassing `.flywheel/scripts/peer-orch-respawn-permit.sh` before peer
  orchestrator recovery.
- Calling a peer-orch recovery clean without a permit/refuse ledger row and
  post-respawn liveness evidence.
- Using stale topology rows instead of latest-by-`effective_at`.

**Evidence:** Joshua correction 2026-05-05T04:38Z; memory
`feedback_flywheel_owns_orch_pane_recovery.md`; bead `flywheel-3rxt3`;
validated recovery of `skillos:1` at 2026-05-05T04:39Z; permit gate
`.flywheel/scripts/peer-orch-respawn-permit.sh`; fixture
`tests/peer-orch-respawn-permit.sh`.

**Cross-references:** L48 (substrate exhaustion), L57 (loop state marker is not
a driver), L70 (same-tick chain-forward), L75 (peer-orch blocker
coordination), L80 (DID/DIDNT/GAPS callbacks), L82 (canonical CLI scoping),
L101 (continuous fleet productivity), L107 (shared-surface reservations), and
L110 (substrate primitives declare self-repair loop).

## L116 — TICK-IS-PROCESS-NOT-DOCUMENT

---
id: L116
title: Tick is process, not document
status: long_term
shipped: 2026-05-05
review_due: 2026-11-05
trauma_class: tick-hook-prose-without-process
---

Tick is a real process, not a markdown document. A primitive that claims
`tick_hook_wired=yes` is not wired until it is registered in
`.flywheel/scripts/tick-driver-manifest.json` and the launchd-backed driver
`/Users/josh/.local/bin/flywheel-tick-driver` produces ledger-backed evidence
for it in `~/.local/state/flywheel/tick-driver.jsonl`.

`/flywheel:tick` remains the human/agent-invocable decision function. L116 adds
the recurring process layer that makes tick-close primitives fire even when no
agent manually re-reads `tick.md`.

Shutdown/resume primitives are first-class manifest entries even though they are
event-driven rather than tick-driven. Register them in
`.flywheel/scripts/tick-driver-manifest.json` with `type: event_driven`; the
driver records them as registered process substrate and skips invocation during
normal tick fires.

For fleet shutdown/reboot recovery, the canonical repo-local state path is
`.flywheel/reboot-recovery/<iso-utc>/` with a `LATEST` symlink; divergent
`.flywheel/recovery/` or `.flywheel/handoffs/` reboot-final paths are drift.

**Required wiring:**

1. Add the primitive to `.flywheel/scripts/tick-driver-manifest.json` with
   `name`, `path`, `args`, and `timeout_sec`.
2. Ensure the primitive writes its own ledger when invoked by the driver.
3. Keep `/Users/josh/Library/LaunchAgents/com.flywheel.tick.plist` loaded with
   StartInterval 300 and ProgramArguments pointing to
   `/Users/josh/.local/bin/flywheel-tick-driver`.
4. Verify `flywheel-loop doctor --scope tick-driver --json` reports
   `tick_driver_last_fire_ts` fresher than two intervals and
   `tick_driver_fires_24h_count > 0`.
5. Run `.flywheel/scripts/tick-hook-firing-verifier.sh --apply --json` so pbt55
   consumes both primitive ledgers and tick-driver fire evidence.

**Doctor contract:** `flywheel-loop doctor --scope tick-driver --json` MUST
expose `tick_driver_daemon_loaded`, `tick_driver_last_exit_status`,
`tick_driver_last_fire_ts`, `tick_driver_fires_24h_count`,
`tick_driver_expected_fires_24h`, `tick_driver_fire_rate_pct`, and
`tick_driver_stalled_class_emitted_count_24h`.

Status is `error` when the daemon is not loaded, when the latest fire is older
than two intervals, or when the normalized fire rate is below 50%. Status is
`warn` when the normalized fire rate is below 80%.

**Forbidden outputs:**

- Claiming `tick_hook_wired=yes` because a script exists or `tick.md` names it.
- Closing a tick-hook primitive without manifest registration and a driver
  ledger row proving it fired.
- Treating launchd plist presence as enough without `tick-driver.jsonl`
  freshness, per L57.
- Adding new tick-close primitives only to prose.

**Evidence:** bead `flywheel-2h6le`; driver
`/Users/josh/.local/bin/flywheel-tick-driver`; LaunchAgent
`/Users/josh/Library/LaunchAgents/com.flywheel.tick.plist`; manifest
`.flywheel/scripts/tick-driver-manifest.json`; fixture
`tests/flywheel-tick-driver.sh`.

**Cross-references:** L57 (loop-state marker is not driver), L70 (same-tick
chain-forward), L102 (META-RULE cache refresh on tick), L110 (substrate
self-repair primitive), L111 (quality bar), L115 (peer-orch recovery), and
pbt55 `tick-hook-firing-verifier.sh`.

## L117 — PEER-ORCH-FREEZE-MONITOR-IS-A-DRIVER

---
id: L117
title: Peer orchestrator freeze monitor is a driver
status: long_term
shipped: 2026-05-05
review_due: 2026-11-05
trauma_class: peer-orch-freeze-without-monitor
---

Peer orchestrator liveness is not proven by a pane being open. A peer
orchestrator freeze monitor must scan current topology, ignore the flywheel
orchestrator's own pane, reuse mk303 stuck classification for peer orch panes,
and call the L115 permit gate before any recovery action.

Auto-respawn is disabled by default. Recovery may mutate only when the monitor
is run with `--apply`, `PEER_ORCH_AUTO_RESPAWN=1` is present, and
`.flywheel/scripts/peer-orch-respawn-permit.sh` returns `decision=permit`.
`flywheel:1` self-recovery remains forbidden.

**Doctor contract:** `flywheel-loop doctor --scope peer-orch-monitor --json`
MUST expose `monitor_last_fire_ts`, `mttr_p95_seconds`,
`false_recovery_count_24h`, `permit_gate_refusals_24h`, `recoveries_24h`, and
`monitor_alive`.

Status is `fail` when false recoveries are nonzero, `warn` when the monitor is
missing or stale, and `pass` only when recent monitor fire evidence exists.

**Forbidden outputs:**

- Claiming peer orchestrators are healthy because topology or panes exist.
- Respawning a peer orchestrator without an L115 permit/refuse decision.
- Treating a disabled plist or script presence as proof that monitoring fired.
- Reporting recovery clean when `false_recovery_count_24h > 0`.

**Evidence:** bead `flywheel-3e5c7`; monitor
`.flywheel/scripts/peer-orch-freeze-monitor.sh`; fixture
`tests/peer-orch-freeze-monitor.sh`; manifest
`.flywheel/scripts/tick-driver-manifest.json`; disabled plist
`.flywheel/launchd/ai.zeststream.peer-orch-freeze-monitor.plist`.

**Cross-references:** L57 (loop-state marker is not driver), L110 (substrate
self-repair primitive), L111 (quality bar), L115 (peer-orch recovery), L116
(tick is process), and pbt55 `tick-hook-firing-verifier.sh`.

## L118 — STABLE-FAILURE-REASON-CODES-BEFORE-PROSE

---
id: L118
title: Stable failure reason codes before prose
status: long_term
shipped: 2026-05-05
review_due: 2026-11-05
trauma_class: prose-only-failure-taxonomy
---

Every agent-readable failure surface MUST carry a stable, machine-parseable
reason code before or beside prose. Human explanation is useful, but a loop,
validator, or downstream worker needs a durable enum to route the failure
without re-parsing English.

**How to apply:**
- New doctor, probe, validator, callback, and repair JSON that can report
  `warn`, `fail`, `blocked`, or `refuse` MUST expose `reason_code` or a named
  equivalent field such as `failed_signal`, `violation.class`, `trauma_class`,
  or `blocked_by`.
- Prefer lowercase snake_case or kebab-case codes already used by the substrate;
  introduce a new enum only when no existing code captures the failure.
- When prose changes but the operational class is unchanged, keep the code
  stable. When a code changes meaning, ship a schema or migration note.
- Beads filed from failures SHOULD include the code in the title or labels so
  repeated failures group mechanically.

**Forbidden outputs:**
- Routing a recurring failure from prose-only strings like "still broken" or
  "could not validate".
- Adding a new validator or doctor field whose failure classes cannot be
  counted with `jq` or `rg` without natural-language parsing.
- Renaming an existing failure code without a compatibility alias or migration
  note.

**Evidence:** Source: Jeff frankensearch:frankensearch/frankensearch/src/index_builder.rs:176 + ZestStream adaptation.
The code-shaped failure pattern appears in the philosophy catalog as
`failure-taxonomy-reason-codes`; flywheel adopts it
for callbacks, doctor JSON, validators, and Beads routing so L52/L53 findings
group by substrate class instead of prose.

**Cross-references:** L50, L52, L53, L56, L60, L64, L71, L80, L111, and
`dicklesworthstone-stack`.

## L119 — TEMPLATES-NAME-SOURCES-NOT-VALUES

---
id: L119
title: Templates name sources, not values
status: long_term
shipped: 2026-05-06
review_due: 2026-11-06
trauma_class: frozen-projection-of-mutable-state
---

Templates name sources, not values.
Any cron, launchd, watcher, scheduler, or dispatch template that references
mutable state must name the authoritative source path and field selector,
never copy the current field value into prompt text.
The receiving pane or agent must read the source at execution time and cite
the path in closeout.
Literal sampled values are allowed only when the value is immutable by
construction or a receipt names why sampling is intentional.
Doctor must count mutable-state literals in prompt templates and fail strict
mode when the count is nonzero.

Canonical token: `templates-name-sources-not-values`.

**Why:** A frozen projection of mutable state is a long-lived prompt, plist,
cron payload, watcher, scheduler, or dispatch template that captured a value at
render/install time and later acted as if that value were still authoritative.
The orch-uptime topology-stale gate, skillos cron-literal blocker payload, and
mobile-eats cached pane metrics all hit the same trauma class:
`frozen-projection-of-mutable-state`.

**How to apply:**
- Long-lived templates may name source paths, selectors, query names, schema
  fields, immutable hashes/version IDs, command names, static repo paths, and
  documented constant labels.
- They MUST NOT bake mutable blocker IDs, active profile names, pane roles or
  IDs, topology rows, freshness timestamps, secret values, current owner names,
  or current recovery decisions into payloads when those values can change
  before fire time.
- At execution time, the receiving pane or agent reads the named source and
  cites the path/selector in closeout.
- Intentional sampling requires a receipt naming why the value is immutable or
  why sampling is safe for the payload lifetime.
- Doctor invariant scans count mutable-state literals in prompt templates;
  existing debt may warn, newly modified templates fail strict mode.

**Forbidden outputs:**
- Installing a cron, launchd plist, watcher, scheduler, or dispatch packet that
  copies current mutable values instead of naming source paths/selectors.
- Treating a rendered prompt, topology row, active CAAM profile, blocker id, or
  recovery decision as durable truth after its source may have changed.
- Claiming a driver is refreshed when its payload can only replay values
  captured at install time.
- Embedding secret values or token fragments in templates; name vault paths or
  secret classes instead per SEC-001.

**Evidence:** Orch-uptime Lane C; skillos Option C Hybrid watcher +
heartbeat-cron fix; cross-orch handoff row 203
`blocker_class=frozen-projection-of-mutable-state`; mobile-eats sibling
topology/cached-metrics pattern.

**Cross-references:** SEC-001 mission-lock secret-values rule, L57
(loop-state marker is not driver), L110 (substrate primitives declare
self-repair loop), and L116 (tick is process, not document).

## L120 — DISPATCH-CALLBACK-MUST-INCLUDE-BR-CLOSE-EXECUTED

---
id: L120
title: Dispatch callback must include br close executed
status: long_term
shipped: 2026-05-06
review_due: 2026-11-06
trauma_class: bg-agent-close-miss
---

Every DONE callback MUST include br_close_executed=<yes|failed|not_applicable>.
Workers MUST run br close BEFORE ntm send DONE; close-step before callback-step
is the canonical worker-tick ordering.

**Why:** Five-instance same-session validation showed `bg-agent-close-miss`
when `br close` came after callback or was absent. Callback transport is a
terminal signal; cleanup listed after `ntm send` is routinely skipped.

**Validation:** skillos was 3-for-3 post-fix after adding the required callback
field and step 8b ordering, versus 4-of-5 missed pre-fix. Flywheel
SHIP-runbook line 45 independently already used `br_close_executed=yes`, so
the field emerged twice as the same substrate shape.

**How to apply:**
- Every DONE envelope contains `br_close_executed=yes` when `br close` exited
  0 before callback, or `br_close_executed=failed` when close was attempted and
  failed.
- `br_close_executed=not_applicable` is valid only for BLOCKED/DECLINED paths
  where ownership returns to the orchestrator instead of closing the bead.
- Worker-tick ordering is close first, callback second; dispatch templates must
  encode that order structurally, not in prose after the callback command.

**Forbidden outputs:**
- DONE callback without `br_close_executed`.
- Worker-tick that closes after callback.
- Treating DONE transport-ack as proof of bead close.

**Callback contract enforcement note:** Callback fields are enforced at the
send-time hook gate. Numeric Socraticode fields are required when schema v2
marks Socraticode required; `unknown` is rejected; the doctor exposes
`dispatch_contract_violations` with amber/red thresholds so callback grammar
drift is visible before close-handler substrate trusts the row.

**Evidence:** Source proposal
`~/.claude/skills/.flywheel/proposals/P-bg-agent-close-miss-2026-05-06.md`;
skillos commits `d4ac88e` and `4e129fd`;
`~/.claude/commands/flywheel/worker-tick.md` step 8b;
`~/.claude/commands/flywheel/_shared/dispatch-template.md` callback contract;
`.flywheel/PLANS/orch-uptime-2026-05-06/SHIP-runbook.md` line 45.

**Cross-references:** L91 (dispatch four-state receipt), L119
(templates-name-sources-not-values), L57 (marker-not-driver), and SEC-002
(credential receipts).

## L121 — LAUNCHD-SERIALIZE-WRAPPERS-MUST-BE-KILL-RESILIENT

---
id: L121
title: Launchd serialize wrappers must be kill resilient
status: long_term
shipped: 2026-05-06
review_due: 2026-11-06
trauma_class: jsm-wrapper-killed-mid-sync-via-kickstart
---

Launchd-managed shell wrappers that supervise a subprocess capable of holding a
SQLite lock, WAL write channel, file lock, queue lease, or similar mutation
boundary MUST install TERM, INT, and EXIT cleanup before fleet use.

**How to apply:**
- Use `~/.claude/skills/.flywheel/scripts/sigterm-trap-helper.sh` or an
  equivalent wrapper contract before spawning the child.
- TERM/INT cleanup forwards termination to the child, waits up to a bounded
  timeout, performs WAL/state recovery, emits a structured JSONL event, and
  uses forced kill only as a last resort.
- EXIT cleanup removes stale state and catches orphaned child cleanup paths.
- `flywheel doctor` exposes the helper's launchd-managed script scan as the
  `sigterm_trap_missing_count` invariant.

**Forbidden outputs:**
- Calling a launchd serialize wrapper production-ready without TERM, INT, and
  EXIT cleanup.
- Restarting a wrapper with a hard kill path when a graceful restart path or
  trap-supervised wrapper exists.
- Treating WAL checkpoint recovery as JSM-specific; the invariant applies to
  any launchd wrapper supervising mutation-capable subprocesses.

**Evidence:** proposal
`~/.claude/skills/.flywheel/proposals/K-jsm-wrapper-killed-mid-sync-via-kickstart-2026-05-06.md`;
skillos artifacts `state/jsm-wrapper-sigterm-handler-2026-05-06.json` and
`tests/unit/test_jsm_wrapper_sigterm_handler.sh`; canonical helper
`~/.claude/skills/.flywheel/scripts/sigterm-trap-helper.sh`; test
`~/.claude/skills/.flywheel/tests/test_sigterm_trap_helper.sh`.

## L122 — BULK-MUTATION-SCRIPTS-MUST-HAVE-SURGICAL-BOUNDS

---
id: L122
title: Bulk mutation scripts must have surgical bounds
status: long_term
shipped: 2026-05-06
review_due: 2026-11-06
trauma_class: scope-creep-on-frontmatter-sweep
---

Any script that performs bulk mutation across a shared skill library,
cross-repo file set, or fleet-shared operating substrate MUST enforce an
in-memory pre/post diff, a per-file diff cap, and a session-level circuit
breaker before its first production run.

**How to apply:**
- Use `~/.claude/skills/.flywheel/scripts/bulk-mutation-surgical-bound.sh` or
  an equivalent guard for every candidate file write.
- The guard reads pre/post content in memory, refuses oversized diffs per file,
  records `aborted-surgical-bound` rows, and opens the circuit after
  `max_consecutive_aborts`.
- Live mutation requires an explicit apply mode; dry-run receipts must show
  `migrated`, `skipped`, `aborted`, and circuit-breaker counts matching intent
  before commit.
- `flywheel doctor` exposes `bulk_mutation_surgical_bound_missing_count` as a
  warn-first invariant for existing script debt.

**Forbidden outputs:**
- Running a broad sweep over shared skills, commands, hooks, scripts, or repo
  files without a dry-run receipt and per-file abort gate.
- Writing a candidate file before diffing the complete pre/post content.
- Continuing mutation after consecutive surgical-bound aborts trip the breaker.

**Evidence:** proposal
`~/.claude/skills/.flywheel/proposals/L-scope-creep-on-frontmatter-sweep-2026-05-06.md`;
skillos artifact `state/skillos-L-promotion-authoring-2026-05-06.md`; canonical
guard `~/.claude/skills/.flywheel/scripts/bulk-mutation-surgical-bound.sh`;
test `~/.claude/skills/.flywheel/tests/test_bulk_mutation_surgical_bound.sh`.

## L123 — L29-RAW-TMUX-HISTORICAL-DEBT-MUST-BE-DOCTOR-VISIBLE

---
id: L123
title: L29 raw tmux historical debt must be doctor visible
status: long_term
shipped: 2026-05-06
review_due: 2026-11-06
trauma_class: dispatch-substrate
---

L29 gate installation is incomplete until existing raw pane-I/O debt is scanned
and surfaced through doctor. Forward gates block new raw operational tmux use;
they do not prove pre-gate scripts, hooks, commands, or repo-local helpers are
clean.

**How to apply:**
- Run `~/.claude/skills/.flywheel/scripts/raw-tmux-audit-doctor.sh --doctor
  --json` across hooks, commands, `scripts/`, and `.flywheel/scripts/`.
- Classify findings as `replace-with-ntm`, `ratchet-via-gate`,
  `accept-with-receipt`, or `test-fixture`.
- File migration beads for `replace-with-ntm`; add in-file receipts for
  legitimate `accept-with-receipt` read-only probes where no ntm verb exists.
- `flywheel doctor` exposes `l29_raw_tmux_operational_violations_count` and
  keeps historical debt visible while the fleet migrates.

**Forbidden outputs:**
- Treating the raw tmux gate as proof existing files are clean.
- Dispatching or documenting worker-pane operation through raw tmux verbs when
  an ntm equivalent exists.
- Hiding raw tmux debt in prose-only audit notes without a doctor-visible count.

**Evidence:** skillos artifact
`/Users/josh/Developer/skillos/state/skillos-L29-promotion-authoring-2026-05-06.md`;
audit receipt `state/skillos-33v8-l29-raw-tmux-audit-2026-05-06.json`;
canonical scanner `~/.claude/skills/.flywheel/scripts/raw-tmux-audit-doctor.sh`;
test `~/.claude/skills/.flywheel/tests/test_raw_tmux_audit_doctor.sh`.

## L124 — SUBSTRATE-DISCIPLINE-NO-ORCHESTRATOR-PAUSE

---
id: L124
title: Substrate discipline no orchestrator pause
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: substrate-discipline
---

Beads substrate corruption, stale recovery debris, and low-disk write pressure
are flywheel-owned auto-ops conditions. The orchestrator does not pause for
manual direction when the safe repair class is already encoded: use `br` as the
only Beads writer, rebuild disposable DB state from clean JSONL, and prune
repo-local substrate bloat before WAL/JSONL writes degrade.

**How to apply:**
- `.beads/issues.jsonl` is written only through `br create`, `br update`, or
  `br close`. Manual append fallback is a violation even when a callback or
  fix-bead path is under pressure.
- `beads.db` and its sidecars are disposable indexes. When
  `br doctor --json` reports `workspace_health=unsafe` and the class is
  rebuildable, run
  `~/.claude/skills/.flywheel/scripts/beads-auto-rebuild-from-jsonl.sh --repo
  <repo> --apply --json` after backing up to `/tmp`.
- `flywheel doctor` exposes three substrate discipline scopes:
  `beads.jsonl.write_discipline`, `beads.recovery.bloat`, and
  `beads.sidecar.staleness`.
- `.flywheel/scripts/storage-prune.sh` archives `.br_recovery/` bloat to
  `/tmp`, removes stale `.beads/*.aside.*` and `.beads/*.bak.*` by exact path,
  and archives old `jeff-corpus/*` entries.
- `/flywheel:tick` enforcement is process-wired through
  `.flywheel/scripts/tick-driver-manifest.json` entries for `storage-prune` and
  `beads-auto-rebuild-from-jsonl`; prose-only wiring does not count.

**Forbidden outputs:**
- Asking Joshua whether to run a clean JSONL-backed Beads DB rebuild.
- Appending issue rows, event rows, fallback close rows, or fix-bead rows
  directly to `.beads/issues.jsonl`.
- Treating `.br_recovery/`, stale sidecars, or low disk as a dashboard warning
  without a doctor field and an auto-prune path.
- Calling substrate recovery shipped without tick-driver manifest evidence.

**Evidence:** memory rules
`feedback_beads_jsonl_writes_via_br_only.md`,
`feedback_substrate_rebuild_is_disposable_not_class_5.md`, and
`feedback_storage_pressure_blocks_substrate.md`; doctor scopes in
`~/.claude/skills/.flywheel/bin/flywheel`; primitive
`~/.claude/skills/.flywheel/scripts/beads-auto-rebuild-from-jsonl.sh`; storage
primitive `.flywheel/scripts/storage-prune.sh`; tick manifest
`.flywheel/scripts/tick-driver-manifest.json`; Jeff WAL/lock prior-art receipt
`/tmp/jeff-wal-lock-prior-art-2026-05-07.md`; storage correlation receipt
`/tmp/storage-substrate-correlation-2026-05-07.md`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

## L129 — WORKER-SUBSTRATE-EXPLICIT

---
id: L129
title: Worker substrate explicit for dispatch and convergence work
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: convergence-audit-bypass-codex-workers
---

Every schema v2 dispatch row and packet header MUST classify the worker
substrate explicitly:
`worker_substrate=codex-pane|claude-pane|background-agent|local` and
`agent_type=codex|claude|unknown`. `/flywheel:dispatch` defaults NTM pane
sends to `worker_substrate=codex-pane agent_type=codex`.

Convergence, adversarial review, audit-wave, and synthesis work requires
`worker_substrate=codex-pane` unless `JOSHUA_OVERRIDE` is present and logged by
the worker-substrate lint gate with reason
`convergence_to_background_agent_blocked` or `joshua_override`.

**Why:** L120-L127 callback enforcement and L128 convergence-proved-with-data
only compose when work travels through the visible NTM dispatch substrate.
Background-agent side channels bypass dispatch-log, close-handler, callback
contract, and validation evidence, so L128's data trail disappears.

**Evidence:** bead `flywheel-2tv3`; plan
`.flywheel/PLANS/dispatch-enforcement-2026-05-01.md`; lint gate
`.flywheel/scripts/dispatch-worker-substrate-gate.sh`; command docs
`~/.claude/commands/flywheel/dispatch.md` and
`~/.claude/commands/flywheel/_shared/dispatch-template.md`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L48, L50, L52, L53, L56, L60, L70, L71, L72, L96, L110,
L116, and L120.

## L125 — ENV-FILE-IS-SEALED-SUBSTRATE

**Trauma class:** `read-tool-secret-leak`
**Generalizes:** L58 (secret material never in pane text)
**Sibling to:** L73 (runtime leak)
**Backed by:** SEC-001..006

`.env*` files are sealed substrate. Reading them via `Read`/`Edit`/`Write`/`cat`/MCP file-tools produces a transcript leak equivalent to the L58 pane-text leak. The Bash-surface guards (`dcg`, `infisical-safe.sh`, infisical PreToolUse hook) DO NOT cover file-read tools — that gap is by Anthropic-spec design, so the fix is doctrine + skill + heuristic, not new Claude-Code tool guards.

**Canonical verification:** `cf-secret <NAME> | shasum -a 256` (single key, fingerprint only).

**Canonical bulk audit:** read each key via per-key fingerprint, never bulk file read. If structure must be enumerated, use `awk -F= '{print $1}' .env*` (names only, never values).

**Forbidden:**
- `Read` tool on `.env*`, `.envrc`, `.secrets`, `*.pem`, `id_rsa*`, `**/credentials*`
- `cat`/`head`/`tail`/`less`/`more` on `.env*`
- Pasting env contents into prompts, code, or comments
- Logging env contents to any file (even temp)
- Sharing `.env*` via mcp filesystem tool

**Allowed:**
- `cf-secret <NAME> | shasum -a 256` for verification
- `awk -F= '{print $1}' .env*` for name enumeration only
- Reading `.env.example` or sentinel files with no real values

**Promotion ladder this rule passed:** fuckup-row → `~/.claude/skills/infisical-secrets/references/INCIDENTS.md` → AGENTS-CANONICAL.md L-rule (here) → `flywheel-install/templates/AGENTS-TEMPLATE.md` broadcast → `canonical-meta-rules-sync` to all flywheel-installed repos.

**Evidence:** mobile-eats:1 cross-orch handoff 2026-05-07T18:30Z (`/tmp/mobile-eats-secret-leak-flywheel-handoff.md`); Joshua directive 2026-05-07 "harden via L-rule + skill discipline, NOT new tool guards"; flywheel:1 ACK at `/tmp/flywheel-ack-mobile-eats-secret-leak-2026-05-07.md`; infisical-secrets skill File-Surface Discipline section to follow.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L58, L73, L56, SEC-001..006; `templates/josh-request-schema.md` 9-class secret-scrub taxonomy; `mission-lock-negative-invariants-validator.sh` (SEC-007 packet validator extension to follow).

## L126 — EVIDENCE-PACK-REPLACES-SELF-GRADE

---
id: L126
title: Evidence pack replaces self-grade
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: self-grade-claim-treated-as-fact
---

Closed is a claim until evidence proves it. New worker closures and new
`/flywheel:plan` close-gate transitions MUST use a beads-compliance evidence
pack instead of worker-claimed four-lens or three-judges self-grades.

**How to apply:**
- New DONE callbacks include `compliance_score=<N>/1000` and
  `compliance_pack_path=<audit-dir>/<bead-id>/`.
- The pack follows
  `~/.claude/skills/beads-compliance-and-completion-verification/references/EVIDENCE-SCHEMAS.md`
  and includes `spec.json`, `evidence.json`, `compliance.json`,
  `theater.json`, `test_depth.json`, `scorecard.md`, and `REPORT.md`.
- The starting close threshold is `compliance_score >= 700/1000`.
  `/flywheel:plan` schema v4 also requires `convergence_streak >= 2` before a
  polish plan can advance through the close gate.
- Legacy four-lens / three-judges rows remain valid history. Do not migrate
  closed beads, and do not rewrite in-flight dispatch contracts. Cutover is
  forward-only for the next `/flywheel:plan` and newly rendered dispatches.
- Plans with `schema_version < 4` may still be evaluated by their legacy
  self-grade fields; plans with `schema_version >= 4` are refused without an
  evidence pack.

**Forbidden outputs:**
- Treating `four_lens=brand:N,sniff:N,jeff:N,public:N` as a close fact for a
  new dispatch.
- Advancing a schema v4 plan to ready without a cited compliance pack and
  score.
- Re-running historical plans only to replace legacy four-lens fields.
- Adopting the beads-compliance mega-swarm tier before Solo tier is proven.

**Evidence:** Joshua directive 2026-05-07 to replace four-lens with
`beads-compliance-and-completion-verification`; skill "One Rule" and
`DESIGN-PHILOSOPHY.md`; close contract in
`~/.claude/commands/flywheel/_shared/dispatch-template.md`; plan schema v4 in
`~/.claude/commands/flywheel/plan.md`; close gate
`.flywheel/scripts/quality-bar-close-gate.sh`; regression
`tests/quality-bar-close-gate.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L61, L80, L91, L111, L120, and
`feedback_evidence_pack_replaces_four_lens.md`.

**Doctrine note: mechanical polish convergence.** For complex `/flywheel:plan`
arcs, polish convergence is mechanical: two consecutive Phase 5 telemetry
artifacts must report `kills_gte_adds=true` and `no_new_deltas=true`. A
vibes-declared "looks converged" claim is rejected by the close gate for complex
plans.

**Doctrine note: kill-first hypothesis slate.** Plans declare 2-5 candidate
strategies including exactly one third alternative; each strategy has a
non-empty `kill_condition`. Phase 3 transition is refused otherwise.

## L127 — PREDICTION-LOCK-RECEIPTS

---
id: L127
title: Prediction-lock receipts for high-risk hypotheses
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: post-hoc-plan-rationalization
---

High-risk `/flywheel:plan` hypotheses MUST be pre-registered before execution
starts. At the Phase 2 to Phase 3 convergence boundary, write
`STATE.json.prediction_lock` plus `STATE.json.predictions[]` rows containing
`prediction`, `ts`, `hash`, and `applies_at_phase`; the hash is SHA-256 over the
canonical JSON serialization of the prediction text. The receipt is immutable
after Phase 2: close gates fail on text/hash mismatch
(`prediction_lock_post_hoc_amendment`) or prediction rows timestamped after the
lock boundary (`prediction_lock_post_hoc_addition`).

**Evidence:** Brenner disposition Proposal 3 in
`.flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/brenner-2026-05-07/01-RESEARCH-DEEP-DIVE.md`;
bead `flywheel-gau3q`; close-gate implementation in
`.flywheel/scripts/quality-bar-close-gate.sh`; regression tests
`tests/test_prediction_lock_receipt.sh` and
`tests/test_prediction_lock_post_hoc_detection.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

## L128 PLAN-CONVERGENCE-PROVED-WITH-DATA

---
id: L128
title: Plan convergence proved with data
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: plan-convergence-by-vibes
---

A flywheel plan cannot ship if it cannot prove convergence with data. Six
mechanisms together constitute the discipline:

1. Hypothesis-slate with kill-conditions `[flywheel-ykkhv]` — every plan
   declares 2-5 candidate strategies including one third-alternative; each has a
   `kill_condition`. Phase 3 transition is refused otherwise.

   Why: kills picoz failure-mode "plans converge by consensus, never declared
   what would falsify them".

2. Prediction-lock receipts `[flywheel-gau3q]` — `STATE.json.predictions[]` is
   content-hashed at Phase 2 to Phase 3 transition; close-gate flags hash deltas
   and post-hoc additions.

   Why: kills picoz failure-mode "post-hoc rationalization without trace".

3. ADD/EDIT/KILL deltas in idea duels `[flywheel-2xsag]` —
   `dueling-idea-wizards` emits structured JSON deltas instead of prose;
   validator rejects prose-only outputs.

   Why: kills picoz failure-mode "idea duels produce prose, not mergeable
   decision objects".

4. Convergence telemetry in polish gate `[flywheel-xhfbw]` — each polish round
   emits adds/edits/kills/no-deltas counts; close-gate requires kills >= adds
   and `no_new_deltas` across 2 consecutive rounds for complex plans.

   Why: kills picoz failure-mode "we said it converged but the data shows
   otherwise".

5. EV-anchored evidence with supports/refutes/informs `[flywheel-d3q0j]` —
   compliance packs may include `evidence[]` with `EV-NNN` anchors and typed
   relations; close-gate refuses unresolved anchors and active findings with
   refuting evidence on file.

   Why: kills picoz failure-mode "audit trail without relational structure".

6. Advanced `/brenner` surfaces for evidence/anomaly/critique/assumption
   recording `[flywheel-26hsk]` — research sessions record via experiment
   encode, evidence add, anomaly create, critique create, and assumption create
   instead of prose summaries.

   Why: kills picoz failure-mode "research conclusions buried in prose, not
   queryable".

Close gate refuses ship if any of mechanisms 1 through 5 fail. Mechanism 6 is
the upstream recording discipline that feeds mechanism 5.

**Source:** Brenner research deep-dive 2026-05-07 in
`.flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/brenner-2026-05-07/`.
Picoz-killer doctrine: Joshua spent 30 days building picoz because no single
rule said convergence had to be proved with data.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

## L130 — DISPATCH-SKILL-REQUIRED-HOOK-GATE

---
id: L130
title: Dispatch skill required hook gate
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: dispatch-wrapper-bypass
---

Raw worker-dispatch `ntm send` commands are rejected unless they carry
`/flywheel:dispatch` wrapper proof. The `dispatch_skill_required` hook gate
matches worker-dispatch language such as dispatch-file reads, worker-tick
parity, and task callback instructions; allow proof is
`FLYWHEEL_DISPATCH_WRAPPER=1`, a `dispatch_skill_version` receipt, or
`JOSHUA_OVERRIDE=1`. Per-gate disable remains available for false-positive
recovery. Without this gate, dispatch-log entries do not exist and L120-L128
enforcement can silent-fail.

**Evidence:** bead `flywheel-wbjg`; hook
`~/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh`; tests
`tests/test_dispatch_skill_required_blocks_raw_send.sh`,
`tests/test_dispatch_skill_required_allows_with_wrapper.sh`,
`tests/test_dispatch_skill_required_warn_mode.sh`, and
`tests/test_dispatch_skill_required_disable_per_gate.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

## L131 — PLIST-COVERAGE-DRIFT-DOCTOR-INVARIANT

---
id: L131
title: Plist coverage drift doctor invariant
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: frozen-projection-of-mutable-state
---

Doctor `plist_coverage_drift` compares live sessions from
`~/.local/state/flywheel/session-topology.jsonl` and `team-roster.jsonl` against
`~/Library/LaunchAgents/com.zeststream.<session>.watcher.plist`. It reports
`sessions_without_plist[]`, `plists_without_session[]`, and `missing_count`;
severity is amber for 1-2 missing active-session watcher plists and red for 3+
missing. Red blocks doctor health.

This closes the `frozen-projection-of-mutable-state` trauma where recovery plans
freeze the fleet roster at authoring time while new sessions are onboarded later
and silently miss reboot survivability coverage.

**Evidence:** bead `flywheel-f7u17`; mobile-eats gap-fill bead
`flywheel-lndxj`; implementation in
`~/.claude/skills/.flywheel/lib/misc.sh` and
`~/.claude/skills/.flywheel/lib/portable/core.sh`; regression
`tests/test_doctor_plist_coverage_drift.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

## L132 — SCHEMA-VERSIONED-INGESTION-JEFF-DOCTRINE

---
id: L132
title: Schema-versioned ingestion is required for Jeff lens pass
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: unversioned-contract-ingestion
---

Every contract, schema, receipt, and payload artifact carries an explicit
`schema_version=N` field or a `<name>/v1` marker. The four-lens validator's Jeff
lens treats bare unversioned artifacts as close blockers because unversioned
ingestion makes contract evolution silent and unauditable.

**Evidence:** memory
`feedback_validator_must_check_four_lenses.md`; validator reason
`contract_without_version`; bead `flywheel-prtr`; fixtures
`tests/test_four_lens_jeff_version_contract_pass.sh` and
`tests/test_four_lens_jeff_version_contract_fail.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

## L133 — DATA-BACKED-DEFERRAL-DOCTOR-SURFACE

---
id: L133
title: Data-backed deferral doctor surface
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: data-decides-not-meatpuppet
---

Doctor surfaces `data_backed_deferral` with saves, overrides, and recent
violation counts from the fleet JSONL receipts. Status is `ok` when recent
violations are zero, `warn` when violations are 1-4, and `fail` at 5 or more.
The doctor field may include a single-line `last_suggested_action` summary, but
must not echo raw pane scrollback or multiline draft text.

This makes the doctrine "data decides, not human meatpuppet" visible every tick:
the lint/enforcement side creates receipt rows, and doctor turns the rows into a
stable machine-readable signal.

**Evidence:** bead `flywheel-7mq1`; implementation in
`~/.claude/skills/.flywheel/lib/misc.sh` and
`~/.claude/skills/.flywheel/lib/portable/core.sh`; regressions
`tests/test_doctor_data_backed_deferral_clean_state.sh`,
`tests/test_doctor_data_backed_deferral_warn_threshold.sh`,
`tests/test_doctor_data_backed_deferral_fail_threshold.sh`, and
`tests/test_doctor_data_backed_deferral_no_raw_pane_text.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

## L134 — TEAM-ROSTER-FRESHNESS-GATES-LOOPS

---
id: L134
title: Team roster freshness gates loops
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: silent-session-loop
---

Doctor surfaces team-roster freshness per session. Pulse age greater than 15
minutes is `DEAD` unless the latest roster event is dormant, paused, or
teardown; `/flywheel:loop` refuses on missing roster rows or stale/missing
pulse rows. Silent sessions cannot keep running loops from stale markers.

**Evidence:** bead `flywheel-32so`; implementation in
`~/.claude/skills/.flywheel/lib/session.sh`,
`~/.claude/skills/.flywheel/lib/portable/core.sh`, and
`~/.claude/commands/flywheel/loop.md`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

## L135 — SKILL-DISCOVERY-CALLBACK-FIELDS

---
id: L135
title: Skill discovery callback fields
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: skill-discovery-substrate-unwired
---

Workers MUST report `skill_discoveries=<N> sd_ids=<list|none>` in DONE and
BLOCKED callbacks. When discoveries are emitted, workers append rows to
`~/.local/state/flywheel/skill-discoveries.jsonl` and include the emitted
`sd-*` IDs. `skill_discoveries>0 sd_ids=none` rejects close. Legal
no-discovery reasons are documented in the dispatch template.

**Evidence:** bead `flywheel-nvny`; dispatch contract
`~/.claude/commands/flywheel/_shared/dispatch-template.md`; worker contract
`~/.claude/commands/flywheel/worker-tick.md`; validator
`.flywheel/scripts/validate-skill-discovery-callback.sh`; tests
`tests/test_skill_discovery_callback_valid.sh` and
`tests/test_skill_discovery_callback_mismatch.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

## L136 — ABSOLUTE-PATH-KEYING-FOR-CROSS-PROJECT-STATE

---
id: L136
title: Absolute path keying for cross-project state
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: basename-keying-collision
---

Cross-project state is keyed by absolute path from `realpath` or `pwd -P`, not
by repo basename. Same-basename workspaces collide silently. Migration rule:
all `cm` calls include `--workspace <abs-path>`, and substrate JSONL uses
`project_path` or `repo_path` rather than basename-only `project` when the row
identifies a workspace.

**Evidence:** Jeff ntm#132, commit `cb0a98de`; bead `flywheel-9f7h6`; memory
`feedback_basename_keying_collision_class.md`; audit receipt
`.flywheel/receipts/flywheel-9f7h6-cm-workspace-audit.md`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
